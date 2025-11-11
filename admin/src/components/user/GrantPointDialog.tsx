import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Box,
  Typography,
  Alert,
  CircularProgress,
} from '@mui/material';
import { UserListItem } from '../../types/user';
import { grantPoints } from '../../services/userService';

interface GrantPointDialogProps {
  open: boolean;
  user: UserListItem | null;
  onClose: () => void;
  onSuccess: () => void;
}

export const GrantPointDialog: React.FC<GrantPointDialogProps> = ({
  open,
  user,
  onClose,
  onSuccess,
}) => {
  const [points, setPoints] = useState<string>('');
  const [reason, setReason] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const handleClose = () => {
    setPoints('');
    setReason('');
    setError(null);
    setSuccess(false);
    onClose();
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!user) return;

    const pointsNum = parseInt(points, 10);
    if (isNaN(pointsNum) || pointsNum === 0) {
      setError('有効なポイント数を入力してください');
      return;
    }

    if (!reason.trim()) {
      setError('理由を入力してください');
      return;
    }

    try {
      setLoading(true);
      setError(null);
      await grantPoints({
        uid: user.uid,
        points: pointsNum,
        reason: reason.trim(),
      });
      setSuccess(true);
      setTimeout(() => {
        handleClose();
        onSuccess();
      }, 1500);
    } catch (err) {
      console.error('Failed to grant points:', err);
      setError('ポイントの付与に失敗しました');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <form onSubmit={handleSubmit}>
        <DialogTitle>ポイント付与・減算</DialogTitle>
        <DialogContent>
          {user && (
            <Box mb={2}>
              <Typography variant="body2" color="textSecondary">
                ユーザー: {user.email}
              </Typography>
              <Typography variant="body2" color="textSecondary">
                現在のポイント: {user.points}
              </Typography>
            </Box>
          )}

          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}

          {success && (
            <Alert severity="success" sx={{ mb: 2 }}>
              ポイントを付与しました
            </Alert>
          )}

          <TextField
            label="ポイント数"
            type="number"
            value={points}
            onChange={(e) => setPoints(e.target.value)}
            fullWidth
            margin="normal"
            required
            disabled={loading || success}
            helperText="正の数で付与、負の数で減算"
            id="grant-points-amount"
            name="points"
          />

          <TextField
            label="理由"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            fullWidth
            margin="normal"
            required
            multiline
            rows={3}
            disabled={loading || success}
            placeholder="例: イベント参加特典、違反行為によるペナルティ"
            id="grant-points-reason"
            name="reason"
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose} disabled={loading}>
            キャンセル
          </Button>
          <Button
            type="submit"
            variant="contained"
            disabled={loading || success}
            startIcon={loading && <CircularProgress size={16} />}
          >
            実行
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  );
};
