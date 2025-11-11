import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Box,
  IconButton,
  Typography,
  Alert,
  CircularProgress,
} from '@mui/material';
import { Add as AddIcon, Delete as DeleteIcon } from '@mui/icons-material';
import { createVote } from '../../services/voteService';
import { InAppVoteCreateRequest } from '../../types/vote';

interface VoteFormDialogProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
}

export const VoteFormDialog: React.FC<VoteFormDialogProps> = ({
  open,
  onClose,
  onSuccess,
}) => {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [requiredPoints, setRequiredPoints] = useState(0);
  const [choices, setChoices] = useState<string[]>(['', '']);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleAddChoice = () => {
    setChoices([...choices, '']);
  };

  const handleRemoveChoice = (index: number) => {
    if (choices.length <= 2) {
      setError('選択肢は最低2つ必要です');
      return;
    }
    const newChoices = choices.filter((_, i) => i !== index);
    setChoices(newChoices);
  };

  const handleChoiceChange = (index: number, value: string) => {
    const newChoices = [...choices];
    newChoices[index] = value;
    setChoices(newChoices);
  };

  const validate = (): boolean => {
    if (!title.trim()) {
      setError('タイトルを入力してください');
      return false;
    }

    if (!description.trim()) {
      setError('説明を入力してください');
      return false;
    }

    if (!startDate) {
      setError('開始日時を選択してください');
      return false;
    }

    if (!endDate) {
      setError('終了日時を選択してください');
      return false;
    }

    const start = new Date(startDate);
    const end = new Date(endDate);

    if (end <= start) {
      setError('終了日時は開始日時より後である必要があります');
      return false;
    }

    if (requiredPoints < 0) {
      setError('必要ポイント数は0以上である必要があります');
      return false;
    }

    const validChoices = choices.filter((c) => c.trim() !== '');
    if (validChoices.length < 2) {
      setError('選択肢は最低2つ必要です');
      return false;
    }

    return true;
  };

  const handleSubmit = async () => {
    if (!validate()) {
      return;
    }

    try {
      setLoading(true);
      setError(null);

      const validChoices = choices.filter((c) => c.trim() !== '');

      const data: InAppVoteCreateRequest = {
        title: title.trim(),
        description: description.trim(),
        choices: validChoices.map((c) => c.trim()),
        startDate: new Date(startDate).toISOString(),
        endDate: new Date(endDate).toISOString(),
        requiredPoints,
      };

      await createVote(data);
      handleClose();
      onSuccess();
    } catch (err) {
      console.error('Error creating vote:', err);
      setError('投票の作成に失敗しました');
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    setTitle('');
    setDescription('');
    setStartDate('');
    setEndDate('');
    setRequiredPoints(0);
    setChoices(['', '']);
    setError(null);
    onClose();
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="md" fullWidth>
      <DialogTitle>新規投票作成</DialogTitle>
      <DialogContent>
        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 2 }}>
          <TextField
            id="vote-title"
            name="title"
            label="タイトル"
            fullWidth
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            required
          />

          <TextField
            id="vote-description"
            name="description"
            label="説明"
            fullWidth
            multiline
            rows={3}
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            required
          />

          <Box sx={{ display: 'flex', gap: 2 }}>
            <TextField
              id="vote-start-date"
              name="startDate"
              label="開始日時"
              type="datetime-local"
              fullWidth
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              InputLabelProps={{ shrink: true }}
              required
            />

            <TextField
              id="vote-end-date"
              name="endDate"
              label="終了日時"
              type="datetime-local"
              fullWidth
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              InputLabelProps={{ shrink: true }}
              required
            />
          </Box>

          <TextField
            id="vote-required-points"
            name="requiredPoints"
            label="必要ポイント数"
            type="number"
            fullWidth
            value={requiredPoints}
            onChange={(e) => setRequiredPoints(parseInt(e.target.value) || 0)}
            inputProps={{ min: 0 }}
            required
          />

          <Box>
            <Box
              sx={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                mb: 1,
              }}
            >
              <Typography variant="subtitle1">選択肢（最低2つ）</Typography>
              <Button
                size="small"
                startIcon={<AddIcon />}
                onClick={handleAddChoice}
              >
                追加
              </Button>
            </Box>

            {choices.map((choice, index) => (
              <Box
                key={index}
                sx={{ display: 'flex', gap: 1, mb: 1, alignItems: 'center' }}
              >
                <TextField
                  id={`vote-choice-${index}`}
                  name={`choices[${index}]`}
                  label={`選択肢 ${index + 1}`}
                  fullWidth
                  value={choice}
                  onChange={(e) => handleChoiceChange(index, e.target.value)}
                  required
                />
                <IconButton
                  color="error"
                  onClick={() => handleRemoveChoice(index)}
                  disabled={choices.length <= 2}
                >
                  <DeleteIcon />
                </IconButton>
              </Box>
            ))}
          </Box>
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={handleClose} disabled={loading}>
          キャンセル
        </Button>
        <Button
          onClick={handleSubmit}
          variant="contained"
          disabled={loading}
          startIcon={loading ? <CircularProgress size={20} /> : null}
        >
          作成
        </Button>
      </DialogActions>
    </Dialog>
  );
};
