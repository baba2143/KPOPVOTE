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
import { suspendUser } from '../../services/userService';

interface SuspendUserDialogProps {
  open: boolean;
  user: UserListItem | null;
  onClose: () => void;
  onSuccess: () => void;
}

export const SuspendUserDialog: React.FC<SuspendUserDialogProps> = ({
  open,
  user,
  onClose,
  onSuccess,
}) => {
  const [reason, setReason] = useState('');
  const [suspendUntil, setSuspendUntil] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const isSuspending = user ? !user.isSuspended : false;

  const handleClose = () => {
    setReason('');
    setSuspendUntil('');
    setError(null);
    setSuccess(false);
    onClose();
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!user) return;

    const suspend = !user.isSuspended;

    if (suspend && !reason.trim()) {
      setError('停止理由を入力してください');
      return;
    }

    try {
      setLoading(true);
      setError(null);
      await suspendUser({
        uid: user.uid,
        suspend,
        reason: reason.trim() || undefined,
        suspendUntil: suspendUntil || undefined,
      });
      setSuccess(true);
      setTimeout(() => {
        handleClose();
        onSuccess();
      }, 1500);
    } catch (err) {
      console.error('Failed to suspend user:', err);
      setError(
        isSuspending
          ? 'アカウントの停止に失敗しました'
          : 'アカウントの復旧に失敗しました'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <form onSubmit={handleSubmit}>
        <DialogTitle>
          {isSuspending ? 'アカウント停止' : 'アカウント復旧'}
        </DialogTitle>
        <DialogContent>
          {user && (
            <Box mb={2}>
              <Typography variant="body2" color="textSecondary">
                ユーザー: {user.email}
              </Typography>
              <Typography variant="body2" color="textSecondary">
                現在のステータス:{' '}
                {user.isSuspended ? '停止中' : 'アクティブ'}
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
              {isSuspending
                ? 'アカウントを停止しました'
                : 'アカウントを復旧しました'}
            </Alert>
          )}

          {isSuspending ? (
            <>
              <TextField
                label="停止理由"
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                fullWidth
                margin="normal"
                required
                multiline
                rows={3}
                disabled={loading || success}
                placeholder="例: 利用規約違反、不適切な投稿、スパム行為"
                id="suspend-reason"
                name="reason"
              />

              <TextField
                label="停止期限（オプション）"
                type="datetime-local"
                value={suspendUntil}
                onChange={(e) => setSuspendUntil(e.target.value)}
                fullWidth
                margin="normal"
                disabled={loading || success}
                InputLabelProps={{
                  shrink: true,
                }}
                helperText="指定しない場合は無期限停止"
                id="suspend-until"
                name="suspendUntil"
              />
            </>
          ) : (
            <TextField
              label="復旧理由（オプション）"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              fullWidth
              margin="normal"
              multiline
              rows={2}
              disabled={loading || success}
              placeholder="例: 期限到達、状況改善確認"
              id="restore-reason"
              name="reason"
            />
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose} disabled={loading}>
            キャンセル
          </Button>
          <Button
            type="submit"
            variant="contained"
            color={isSuspending ? 'error' : 'success'}
            disabled={loading || success}
            startIcon={loading && <CircularProgress size={16} />}
          >
            {isSuspending ? '停止する' : '復旧する'}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  );
};
