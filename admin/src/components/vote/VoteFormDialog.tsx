import React, { useState, useEffect } from 'react';
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
  ToggleButtonGroup,
  ToggleButton,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Checkbox,
  Avatar,
  Chip,
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Edit as EditIcon,
  Group as GroupIcon,
} from '@mui/icons-material';
import { createVote, updateVote, uploadVoteCoverImage } from '../../services/voteService';
import { listIdols } from '../../services/idolService';
import { InAppVoteCreateRequest, InAppVoteUpdateRequest, InAppVote } from '../../types/vote';
import { IdolMaster } from '../../types/idol';

interface VoteFormDialogProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
  mode?: 'create' | 'edit';
  initialVote?: InAppVote;
}

type ChoiceInputMode = 'manual' | 'idol';

export const VoteFormDialog: React.FC<VoteFormDialogProps> = ({
  open,
  onClose,
  onSuccess,
  mode = 'create',
  initialVote,
}) => {
  // Basic information
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [requiredPoints, setRequiredPoints] = useState(0);
  const [isFeatured, setIsFeatured] = useState(false);

  // Cover image
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);

  // Choice input mode
  const [inputMode, setInputMode] = useState<ChoiceInputMode>('manual');

  // Manual input mode
  const [manualChoices, setManualChoices] = useState<string[]>(['', '']);

  // Idol selection mode
  const [allIdols, setAllIdols] = useState<IdolMaster[]>([]);
  const [groupFilter, setGroupFilter] = useState<string>('all');
  const [selectedIdolIds, setSelectedIdolIds] = useState<string[]>([]);
  const [loadingIdols, setLoadingIdols] = useState(false);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Load idols when dialog opens and idol mode is selected
  useEffect(() => {
    if (open && inputMode === 'idol' && allIdols.length === 0) {
      loadIdols();
    }
  }, [open, inputMode]);

  // Set initial values in edit mode
  useEffect(() => {
    if (open && mode === 'edit' && initialVote) {
      setTitle(initialVote.title);
      setDescription(initialVote.description);
      setStartDate(initialVote.startDate.slice(0, 16)); // Convert to datetime-local format
      setEndDate(initialVote.endDate.slice(0, 16));
      setRequiredPoints(initialVote.requiredPoints);
      setIsFeatured(initialVote.isFeatured || false);
      if (initialVote.coverImageUrl) {
        setPreviewUrl(initialVote.coverImageUrl);
      }
      // Load existing choices for display (read-only in edit mode)
      if (initialVote.choices && initialVote.choices.length > 0) {
        const choiceLabels = initialVote.choices.map((c) => c.label);
        setManualChoices(choiceLabels);
      }
    }
  }, [open, mode, initialVote]);

  const loadIdols = async () => {
    try {
      setLoadingIdols(true);
      const idols = await listIdols();
      setAllIdols(idols);
    } catch (err) {
      console.error('Error loading idols:', err);
      setError('アイドル一覧の取得に失敗しました');
    } finally {
      setLoadingIdols(false);
    }
  };

  // Get unique group names
  const groupNames = Array.from(
    new Set(allIdols.map((idol) => idol.groupName))
  ).sort();

  // Filtered idols based on group filter
  const filteredIdols =
    groupFilter === 'all'
      ? allIdols
      : allIdols.filter((idol) => idol.groupName === groupFilter);

  // Selected idol objects
  const selectedIdols = allIdols.filter((idol) =>
    selectedIdolIds.includes(idol.idolId)
  );

  // Manual input mode handlers
  const handleAddManualChoice = () => {
    setManualChoices([...manualChoices, '']);
  };

  const handleRemoveManualChoice = (index: number) => {
    if (manualChoices.length <= 2) {
      setError('選択肢は最低2つ必要です');
      return;
    }
    const newChoices = manualChoices.filter((_, i) => i !== index);
    setManualChoices(newChoices);
  };

  const handleManualChoiceChange = (index: number, value: string) => {
    const newChoices = [...manualChoices];
    newChoices[index] = value;
    setManualChoices(newChoices);
  };

  // Idol selection mode handlers
  const handleToggleIdol = (idolId: string) => {
    setSelectedIdolIds((prev) =>
      prev.includes(idolId)
        ? prev.filter((id) => id !== idolId)
        : [...prev, idolId]
    );
  };

  // Cover image handler
  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      setSelectedFile(file);
      const reader = new FileReader();
      reader.onloadend = () => {
        setPreviewUrl(reader.result as string);
      };
      reader.readAsDataURL(file);
      setError(null);
    }
  };

  const handleInputModeChange = (
    _event: React.MouseEvent<HTMLElement>,
    newMode: ChoiceInputMode | null
  ) => {
    if (newMode !== null) {
      setInputMode(newMode);
      setError(null);
    }
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

    // Validate choices
    if (inputMode === 'manual') {
      const validChoices = manualChoices.filter((c) => c.trim() !== '');
      if (validChoices.length < 2) {
        setError('選択肢は最低2つ必要です');
        return false;
      }
    } else {
      if (selectedIdolIds.length < 2) {
        setError('アイドルを最低2人選択してください');
        return false;
      }
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

      // Upload cover image if selected
      let coverImageUrl: string | undefined;
      if (selectedFile) {
        console.log('Uploading new cover image...');
        setUploading(true);
        try {
          coverImageUrl = await uploadVoteCoverImage(selectedFile);
          console.log('Cover image uploaded successfully:', coverImageUrl);
          setUploading(false);
        } catch (uploadError) {
          console.error('Cover image upload failed:', uploadError);
          setUploading(false);
          throw new Error('画像のアップロードに失敗しました');
        }
      } else if (mode === 'edit' && initialVote?.coverImageUrl) {
        // Keep existing cover image in edit mode if no new image selected
        console.log('Keeping existing cover image:', initialVote.coverImageUrl);
        coverImageUrl = initialVote.coverImageUrl;
      }

      if (mode === 'edit' && initialVote) {
        // Edit mode: update existing vote
        const updateData: InAppVoteUpdateRequest = {
          voteId: initialVote.voteId,
          title: title.trim(),
          description: description.trim(),
          startDate: new Date(startDate).toISOString(),
          endDate: new Date(endDate).toISOString(),
          requiredPoints,
          ...(coverImageUrl && { coverImageUrl }),
          isFeatured,
        };

        console.log('Updating vote with data:', updateData);
        await updateVote(updateData);
      } else {
        // Create mode: create new vote
        const choices =
          inputMode === 'manual'
            ? manualChoices.filter((c) => c.trim() !== '').map((c) => c.trim())
            : selectedIdols.map((idol) => idol.name);

        const createData: InAppVoteCreateRequest = {
          title: title.trim(),
          description: description.trim(),
          choices,
          startDate: new Date(startDate).toISOString(),
          endDate: new Date(endDate).toISOString(),
          requiredPoints,
          ...(coverImageUrl && { coverImageUrl }),
          isFeatured,
        };

        await createVote(createData);
      }

      handleClose();
      onSuccess();
    } catch (err) {
      console.error(`Error ${mode === 'edit' ? 'updating' : 'creating'} vote:`, err);
      setError(`投票の${mode === 'edit' ? '更新' : '作成'}に失敗しました`);
    } finally {
      setLoading(false);
      setUploading(false);
    }
  };

  const handleClose = () => {
    setTitle('');
    setDescription('');
    setStartDate('');
    setEndDate('');
    setRequiredPoints(0);
    setIsFeatured(false);
    setSelectedFile(null);
    setPreviewUrl(null);
    setInputMode('manual');
    setManualChoices(['', '']);
    setSelectedIdolIds([]);
    setGroupFilter('all');
    setError(null);
    onClose();
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="md" fullWidth>
      <DialogTitle>{mode === 'edit' ? '投票編集' : '新規投票作成'}</DialogTitle>
      <DialogContent>
        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 2 }}>
          {/* Basic Information */}
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

          {/* Cover Image Upload */}
          <Box>
            <Typography variant="subtitle1" gutterBottom>
              カバー画像（16:9推奨、最大5MB）
            </Typography>
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <Button
                variant="outlined"
                component="label"
                disabled={uploading}
              >
                {selectedFile ? '画像を変更' : '画像を選択'}
                <input
                  type="file"
                  hidden
                  accept="image/jpeg,image/png,image/webp"
                  onChange={handleFileSelect}
                />
              </Button>
              {previewUrl && (
                <Box
                  sx={{
                    width: '100%',
                    maxWidth: 400,
                    border: '1px solid #ddd',
                    borderRadius: 1,
                    overflow: 'hidden',
                  }}
                >
                  <img
                    src={previewUrl}
                    alt="Cover preview"
                    style={{
                      width: '100%',
                      height: 'auto',
                      display: 'block',
                    }}
                  />
                </Box>
              )}
              {uploading && (
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <CircularProgress size={20} />
                  <Typography variant="body2">アップロード中...</Typography>
                </Box>
              )}
            </Box>
          </Box>

          {/* Featured Flag */}
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Checkbox
              id="vote-is-featured"
              checked={isFeatured}
              onChange={(e) => setIsFeatured(e.target.checked)}
            />
            <Typography variant="body1">
              HOMEに表示（注目の投票として表示されます）
            </Typography>
          </Box>

          {/* Choice Input Mode Toggle - Only in create mode */}
          {mode === 'create' && (
            <Box>
              <Typography variant="subtitle1" gutterBottom>
                選択肢の入力方法
              </Typography>
              <ToggleButtonGroup
                value={inputMode}
                exclusive
                onChange={handleInputModeChange}
                fullWidth
              >
                <ToggleButton value="manual">
                  <EditIcon sx={{ mr: 1 }} />
                  手動入力
                </ToggleButton>
                <ToggleButton value="idol">
                  <GroupIcon sx={{ mr: 1 }} />
                  アイドルから選択
                </ToggleButton>
              </ToggleButtonGroup>
            </Box>
          )}

          {/* Manual Input Mode - Only in create mode */}
          {mode === 'create' && inputMode === 'manual' && (
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
                  onClick={handleAddManualChoice}
                >
                  追加
                </Button>
              </Box>

              {manualChoices.map((choice, index) => (
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
                    onChange={(e) => handleManualChoiceChange(index, e.target.value)}
                    required
                  />
                  <IconButton
                    color="error"
                    onClick={() => handleRemoveManualChoice(index)}
                    disabled={manualChoices.length <= 2}
                  >
                    <DeleteIcon />
                  </IconButton>
                </Box>
              ))}
            </Box>
          )}

          {/* Idol Selection Mode - Only in create mode */}
          {mode === 'create' && inputMode === 'idol' && (
            <Box>
              {loadingIdols ? (
                <Box sx={{ display: 'flex', justifyContent: 'center', py: 3 }}>
                  <CircularProgress />
                </Box>
              ) : (
                <>
                  <FormControl fullWidth sx={{ mb: 2 }}>
                    <InputLabel id="group-filter-label">
                      グループフィルター
                    </InputLabel>
                    <Select
                      labelId="group-filter-label"
                      id="group-filter"
                      value={groupFilter}
                      onChange={(e) => setGroupFilter(e.target.value)}
                      label="グループフィルター"
                    >
                      <MenuItem value="all">すべて</MenuItem>
                      {groupNames.map((groupName) => (
                        <MenuItem key={groupName} value={groupName}>
                          {groupName}
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>

                  <Box
                    sx={{
                      maxHeight: 300,
                      overflow: 'auto',
                      border: '1px solid',
                      borderColor: 'divider',
                      borderRadius: 1,
                      p: 1,
                    }}
                  >
                    {filteredIdols.length === 0 ? (
                      <Typography
                        variant="body2"
                        color="text.secondary"
                        align="center"
                        sx={{ py: 3 }}
                      >
                        アイドルが登録されていません
                      </Typography>
                    ) : (
                      filteredIdols.map((idol) => (
                        <Box
                          key={idol.idolId}
                          sx={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: 1,
                            py: 1,
                            px: 1,
                            cursor: 'pointer',
                            '&:hover': { bgcolor: 'action.hover' },
                            borderRadius: 1,
                          }}
                          onClick={() => handleToggleIdol(idol.idolId)}
                        >
                          <Checkbox
                            checked={selectedIdolIds.includes(idol.idolId)}
                            readOnly
                          />
                          <Avatar
                            src={idol.imageUrl || undefined}
                            alt={idol.name}
                            sx={{ width: 40, height: 40 }}
                          />
                          <Box sx={{ flexGrow: 1 }}>
                            <Typography variant="body1">{idol.name}</Typography>
                            <Typography variant="caption" color="text.secondary">
                              {idol.groupName}
                            </Typography>
                          </Box>
                        </Box>
                      ))
                    )}
                  </Box>

                  {selectedIdols.length > 0 && (
                    <Box sx={{ mt: 2 }}>
                      <Typography variant="subtitle2" gutterBottom>
                        選択済み ({selectedIdols.length})
                      </Typography>
                      <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                        {selectedIdols.map((idol) => (
                          <Chip
                            key={idol.idolId}
                            avatar={<Avatar src={idol.imageUrl || undefined} />}
                            label={idol.name}
                            onDelete={() => handleToggleIdol(idol.idolId)}
                          />
                        ))}
                      </Box>
                    </Box>
                  )}
                </>
              )}
            </Box>
          )}

          {/* Edit Mode: Read-only choice display */}
          {mode === 'edit' && initialVote && initialVote.choices && (
            <Box>
              <Typography variant="subtitle1" gutterBottom>
                選択肢（編集不可）
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                {initialVote.choices.map((choice, index) => (
                  <Chip
                    key={choice.choiceId}
                    label={`${index + 1}. ${choice.label} (${choice.voteCount}票)`}
                    variant="outlined"
                  />
                ))}
              </Box>
              <Alert severity="info" sx={{ mt: 1 }}>
                投票開始後は選択肢を変更できません
              </Alert>
            </Box>
          )}
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
          {mode === 'edit' ? '更新' : '作成'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};
