import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Box,
  Typography,
  Chip,
  CircularProgress,
  Alert,
  Grid,
  Divider,
} from '@mui/material';
import { UserListItem, UserDetail } from '../../types/user';
import { getUserDetail } from '../../services/userService';

interface UserDetailDialogProps {
  open: boolean;
  user: UserListItem | null;
  onClose: () => void;
}

export const UserDetailDialog: React.FC<UserDetailDialogProps> = ({
  open,
  user,
  onClose,
}) => {
  const [userDetail, setUserDetail] = useState<UserDetail | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (open && user) {
      loadUserDetail();
    } else {
      setUserDetail(null);
      setError(null);
    }
  }, [open, user]);

  const loadUserDetail = async () => {
    if (!user) return;

    try {
      setLoading(true);
      setError(null);
      const detail = await getUserDetail(user.uid);
      setUserDetail(detail);
    } catch (err) {
      console.error('Failed to load user detail:', err);
      setError('ユーザー詳細の読み込みに失敗しました');
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleString('ja-JP', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle>ユーザー詳細</DialogTitle>
      <DialogContent>
        {loading && (
          <Box display="flex" justifyContent="center" py={4}>
            <CircularProgress />
          </Box>
        )}

        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        {userDetail && (
          <Box>
            <Grid container spacing={2}>
              <Grid size={12}>
                <Typography variant="subtitle2" color="textSecondary">
                  UID
                </Typography>
                <Typography variant="body1" sx={{ wordBreak: 'break-all' }}>
                  {userDetail.uid}
                </Typography>
              </Grid>

              <Grid size={{ xs: 12, md: 6 }}>
                <Typography variant="subtitle2" color="textSecondary">
                  メールアドレス
                </Typography>
                <Typography variant="body1">{userDetail.email}</Typography>
              </Grid>

              <Grid size={{ xs: 12, md: 6 }}>
                <Typography variant="subtitle2" color="textSecondary">
                  表示名
                </Typography>
                <Typography variant="body1">
                  {userDetail.displayName || '-'}
                </Typography>
              </Grid>

              <Grid size={{ xs: 12, md: 6 }}>
                <Typography variant="subtitle2" color="textSecondary">
                  ポイント
                </Typography>
                <Typography variant="body1">{userDetail.points}</Typography>
              </Grid>

              <Grid size={{ xs: 12, md: 6 }}>
                <Typography variant="subtitle2" color="textSecondary">
                  ステータス
                </Typography>
                {userDetail.isSuspended ? (
                  <Chip label="停止中" color="error" size="small" />
                ) : (
                  <Chip label="アクティブ" color="success" size="small" />
                )}
              </Grid>

              <Grid size={12}>
                <Divider sx={{ my: 1 }} />
              </Grid>

              <Grid size={{ xs: 12, md: 6 }}>
                <Typography variant="subtitle2" color="textSecondary">
                  タスク参加数
                </Typography>
                <Typography variant="body1">{userDetail.taskCount}</Typography>
              </Grid>

              <Grid size={{ xs: 12, md: 6 }}>
                <Typography variant="subtitle2" color="textSecondary">
                  投票数
                </Typography>
                <Typography variant="body1">{userDetail.voteCount}</Typography>
              </Grid>

              <Grid size={12}>
                <Divider sx={{ my: 1 }} />
              </Grid>

              <Grid size={12}>
                <Typography variant="subtitle2" color="textSecondary">
                  登録日時
                </Typography>
                <Typography variant="body1">
                  {formatDate(userDetail.createdAt)}
                </Typography>
              </Grid>

              {userDetail.isSuspended && userDetail.suspendReason && (
                <>
                  <Grid size={12}>
                    <Typography variant="subtitle2" color="textSecondary">
                      停止理由
                    </Typography>
                    <Typography variant="body1">
                      {userDetail.suspendReason}
                    </Typography>
                  </Grid>

                  {userDetail.suspendUntil && (
                    <Grid size={12}>
                      <Typography variant="subtitle2" color="textSecondary">
                        停止期限
                      </Typography>
                      <Typography variant="body1">
                        {formatDate(userDetail.suspendUntil)}
                      </Typography>
                    </Grid>
                  )}
                </>
              )}
            </Grid>
          </Box>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>閉じる</Button>
      </DialogActions>
    </Dialog>
  );
};
