import React, { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  IconButton,
  Alert,
  CircularProgress,
  Tabs,
  Tab,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  FormControlLabel,
  Switch,
  Snackbar,
  Autocomplete,
} from '@mui/material';
import {
  Send as SendIcon,
  Schedule as ScheduleIcon,
  Cancel as CancelIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { ja } from 'date-fns/locale';
import {
  pushNotificationService,
  NotificationTargetType,
  NotificationStatus,
  AdminNotification,
} from '../services/pushNotificationService';
import { listGroups } from '../services/groupService';
import { listIdols } from '../services/idolService';
import { GroupMaster } from '../types/group';
import { IdolMaster } from '../types/idol';

type StatusFilter = 'all' | NotificationStatus;

interface TargetOption {
  id: string;
  name: string;
  type: 'group' | 'member';
  groupName?: string;
}

export const PushNotificationPage: React.FC = () => {
  // State for notification list
  const [notifications, setNotifications] = useState<AdminNotification[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');
  const [hasMore, setHasMore] = useState(false);

  // State for form
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [targetType, setTargetType] = useState<NotificationTargetType>('all');
  const [selectedTarget, setSelectedTarget] = useState<TargetOption | null>(null);
  const [deepLinkUrl, setDeepLinkUrl] = useState('');
  const [isScheduled, setIsScheduled] = useState(false);
  const [scheduledAt, setScheduledAt] = useState('');

  // State for target options
  const [groups, setGroups] = useState<GroupMaster[]>([]);
  const [idols, setIdols] = useState<IdolMaster[]>([]);
  const [targetOptions, setTargetOptions] = useState<TargetOption[]>([]);
  const [loadingTargets, setLoadingTargets] = useState(false);

  // State for dialogs
  const [confirmDialogOpen, setConfirmDialogOpen] = useState(false);
  const [cancelDialogOpen, setCancelDialogOpen] = useState(false);
  const [selectedNotification, setSelectedNotification] = useState<AdminNotification | null>(null);
  const [sending, setSending] = useState(false);

  // State for snackbar
  const [snackbar, setSnackbar] = useState<{ open: boolean; message: string; severity: 'success' | 'error' }>({
    open: false,
    message: '',
    severity: 'success',
  });

  // Load notifications
  const loadNotifications = async (status?: NotificationStatus) => {
    try {
      setLoading(true);
      setError(null);
      const response = await pushNotificationService.getNotifications({
        limit: 50,
        status,
      });
      setNotifications(response.notifications);
      setHasMore(response.hasMore);
    } catch (err) {
      console.error('Error loading notifications:', err);
      setError('通知履歴の読み込みに失敗しました');
    } finally {
      setLoading(false);
    }
  };

  // Load groups and idols for target selection
  const loadTargetOptions = async () => {
    try {
      setLoadingTargets(true);
      const [groupsData, idolsData] = await Promise.all([
        listGroups(),
        listIdols(),
      ]);
      setGroups(groupsData);
      setIdols(idolsData);
    } catch (err) {
      console.error('Error loading target options:', err);
    } finally {
      setLoadingTargets(false);
    }
  };

  useEffect(() => {
    const status = statusFilter === 'all' ? undefined : statusFilter;
    loadNotifications(status);
  }, [statusFilter]);

  useEffect(() => {
    loadTargetOptions();
  }, []);

  // Update target options based on target type
  useEffect(() => {
    if (targetType === 'group') {
      setTargetOptions(groups.map(g => ({
        id: g.groupId,
        name: g.name,
        type: 'group' as const,
      })));
    } else if (targetType === 'member') {
      setTargetOptions(idols.map(i => ({
        id: i.idolId,
        name: i.name,
        type: 'member' as const,
        groupName: i.groupName,
      })));
    } else {
      setTargetOptions([]);
    }
    setSelectedTarget(null);
  }, [targetType, groups, idols]);

  const handleStatusFilterChange = (
    _event: React.SyntheticEvent,
    newValue: StatusFilter
  ) => {
    setStatusFilter(newValue);
  };

  const handleSendClick = () => {
    if (!title.trim() || !body.trim()) {
      setSnackbar({
        open: true,
        message: 'タイトルと本文は必須です',
        severity: 'error',
      });
      return;
    }

    if ((targetType === 'group' || targetType === 'member') && !selectedTarget) {
      setSnackbar({
        open: true,
        message: '配信対象を選択してください',
        severity: 'error',
      });
      return;
    }

    if (isScheduled && !scheduledAt) {
      setSnackbar({
        open: true,
        message: '配信日時を指定してください',
        severity: 'error',
      });
      return;
    }

    setConfirmDialogOpen(true);
  };

  const handleConfirmSend = async () => {
    try {
      setSending(true);
      setConfirmDialogOpen(false);

      const request = {
        title: title.trim(),
        body: body.trim(),
        targetType,
        targetId: selectedTarget?.id,
        deepLinkUrl: deepLinkUrl.trim() || undefined,
      };

      if (isScheduled) {
        await pushNotificationService.scheduleNotification({
          ...request,
          scheduledAt: new Date(scheduledAt).toISOString(),
        });
        setSnackbar({
          open: true,
          message: '通知を予約しました',
          severity: 'success',
        });
      } else {
        const result = await pushNotificationService.sendNotification(request);
        setSnackbar({
          open: true,
          message: `${result.sentCount}件の通知を送信しました`,
          severity: 'success',
        });
      }

      // Reset form
      setTitle('');
      setBody('');
      setTargetType('all');
      setSelectedTarget(null);
      setDeepLinkUrl('');
      setIsScheduled(false);
      setScheduledAt('');

      // Reload notifications
      const status = statusFilter === 'all' ? undefined : statusFilter;
      loadNotifications(status);
    } catch (err: any) {
      console.error('Error sending notification:', err);
      setSnackbar({
        open: true,
        message: err.message || '通知の送信に失敗しました',
        severity: 'error',
      });
    } finally {
      setSending(false);
    }
  };

  const handleCancelClick = (notification: AdminNotification) => {
    setSelectedNotification(notification);
    setCancelDialogOpen(true);
  };

  const handleConfirmCancel = async () => {
    if (!selectedNotification) return;

    try {
      await pushNotificationService.cancelNotification(selectedNotification.id);
      setCancelDialogOpen(false);
      setSelectedNotification(null);
      setSnackbar({
        open: true,
        message: '通知をキャンセルしました',
        severity: 'success',
      });
      const status = statusFilter === 'all' ? undefined : statusFilter;
      loadNotifications(status);
    } catch (err: any) {
      console.error('Error cancelling notification:', err);
      setSnackbar({
        open: true,
        message: err.message || '通知のキャンセルに失敗しました',
        severity: 'error',
      });
    }
  };

  const getStatusLabel = (status: NotificationStatus) => {
    switch (status) {
      case 'pending':
        return '予約中';
      case 'sent':
        return '配信済み';
      case 'cancelled':
        return 'キャンセル';
      case 'failed':
        return '失敗';
      default:
        return status;
    }
  };

  const getStatusColor = (status: NotificationStatus): 'default' | 'primary' | 'success' | 'error' | 'warning' => {
    switch (status) {
      case 'pending':
        return 'primary';
      case 'sent':
        return 'success';
      case 'cancelled':
        return 'default';
      case 'failed':
        return 'error';
      default:
        return 'default';
    }
  };

  const getTargetLabel = (notification: AdminNotification) => {
    if (notification.targetType === 'all') {
      return '全ユーザー';
    }
    if (notification.targetName) {
      return `${notification.targetType === 'group' ? 'グループ' : 'メンバー'}: ${notification.targetName}`;
    }
    return notification.targetType;
  };

  const formatDateTime = (dateString?: string) => {
    if (!dateString) return '-';
    return format(new Date(dateString), 'yyyy/MM/dd HH:mm', { locale: ja });
  };

  return (
    <Box>
      <Box
        sx={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          mb: 3,
        }}
      >
        <Typography variant="h4" component="h1">
          プッシュ通知
        </Typography>
        <Button
          variant="outlined"
          startIcon={<RefreshIcon />}
          onClick={() => loadNotifications(statusFilter === 'all' ? undefined : statusFilter)}
        >
          更新
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {/* Notification Form */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Typography variant="h6" gutterBottom>
          新規通知作成
        </Typography>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
          <TextField
            label="タイトル"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            fullWidth
            required
            inputProps={{ maxLength: 50 }}
            helperText={`${title.length}/50`}
          />
          <TextField
            label="本文"
            value={body}
            onChange={(e) => setBody(e.target.value)}
            fullWidth
            required
            multiline
            rows={3}
            inputProps={{ maxLength: 200 }}
            helperText={`${body.length}/200`}
          />
          <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
            <FormControl sx={{ minWidth: 200, flex: 1 }}>
              <InputLabel>配信対象</InputLabel>
              <Select
                value={targetType}
                label="配信対象"
                onChange={(e) => setTargetType(e.target.value as NotificationTargetType)}
              >
                <MenuItem value="all">全ユーザー</MenuItem>
                <MenuItem value="group">グループ別</MenuItem>
                <MenuItem value="member">メンバー別</MenuItem>
              </Select>
            </FormControl>
            {(targetType === 'group' || targetType === 'member') && (
              <Autocomplete
                sx={{ minWidth: 250, flex: 1 }}
                options={targetOptions}
                getOptionLabel={(option) =>
                  option.groupName ? `${option.name} (${option.groupName})` : option.name
                }
                value={selectedTarget}
                onChange={(_e, value) => setSelectedTarget(value)}
                loading={loadingTargets}
                renderInput={(params) => (
                  <TextField
                    {...params}
                    label={targetType === 'group' ? 'グループを選択' : 'メンバーを選択'}
                    required
                  />
                )}
              />
            )}
          </Box>
          <TextField
            label="ディープリンクURL（任意）"
            value={deepLinkUrl}
            onChange={(e) => setDeepLinkUrl(e.target.value)}
            fullWidth
            placeholder="例: kpopvote://votes/xxx"
            helperText="通知タップ時の遷移先URL"
          />
          <Box sx={{ display: 'flex', gap: 2, alignItems: 'center', flexWrap: 'wrap' }}>
            <FormControlLabel
              control={
                <Switch
                  checked={isScheduled}
                  onChange={(e) => setIsScheduled(e.target.checked)}
                />
              }
              label="予約配信"
            />
            {isScheduled && (
              <TextField
                label="配信日時"
                type="datetime-local"
                value={scheduledAt}
                onChange={(e) => setScheduledAt(e.target.value)}
                required
                InputLabelProps={{ shrink: true }}
                inputProps={{
                  min: new Date().toISOString().slice(0, 16),
                }}
                sx={{ minWidth: 250 }}
              />
            )}
          </Box>
          <Box>
            <Button
              variant="contained"
              startIcon={isScheduled ? <ScheduleIcon /> : <SendIcon />}
              onClick={handleSendClick}
              disabled={sending}
              size="large"
            >
              {sending ? '送信中...' : isScheduled ? '予約する' : '今すぐ送信'}
            </Button>
          </Box>
        </Box>
      </Paper>

      {/* Notification History */}
      <Typography variant="h6" gutterBottom>
        配信履歴
      </Typography>
      <Paper sx={{ mb: 3 }}>
        <Tabs
          value={statusFilter}
          onChange={handleStatusFilterChange}
          sx={{ borderBottom: 1, borderColor: 'divider' }}
        >
          <Tab label="全て" value="all" />
          <Tab label="予約中" value="pending" />
          <Tab label="配信済み" value="sent" />
          <Tab label="キャンセル" value="cancelled" />
          <Tab label="失敗" value="failed" />
        </Tabs>
      </Paper>

      {loading ? (
        <Box
          sx={{
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            height: 300,
          }}
        >
          <CircularProgress />
        </Box>
      ) : notifications.length === 0 ? (
        <Paper sx={{ p: 3, textAlign: 'center' }}>
          <Typography color="text.secondary">
            通知履歴がありません
          </Typography>
        </Paper>
      ) : (
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>タイトル</TableCell>
                <TableCell>本文</TableCell>
                <TableCell>配信対象</TableCell>
                <TableCell>ステータス</TableCell>
                <TableCell>予約日時</TableCell>
                <TableCell>配信日時</TableCell>
                <TableCell align="right">配信数</TableCell>
                <TableCell align="center">操作</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {notifications.map((notification) => (
                <TableRow key={notification.id} hover>
                  <TableCell sx={{ maxWidth: 150, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {notification.title}
                  </TableCell>
                  <TableCell sx={{ maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {notification.body}
                  </TableCell>
                  <TableCell>{getTargetLabel(notification)}</TableCell>
                  <TableCell>
                    <Chip
                      label={getStatusLabel(notification.status)}
                      color={getStatusColor(notification.status)}
                      size="small"
                    />
                  </TableCell>
                  <TableCell>{formatDateTime(notification.scheduledAt)}</TableCell>
                  <TableCell>{formatDateTime(notification.sentAt)}</TableCell>
                  <TableCell align="right">
                    {notification.sentCount !== undefined ? (
                      <>
                        {notification.sentCount.toLocaleString()}
                        {notification.failedCount !== undefined && notification.failedCount > 0 && (
                          <Typography variant="caption" color="error" component="span" sx={{ ml: 1 }}>
                            (失敗: {notification.failedCount})
                          </Typography>
                        )}
                      </>
                    ) : (
                      '-'
                    )}
                  </TableCell>
                  <TableCell align="center">
                    {notification.status === 'pending' && (
                      <IconButton
                        size="small"
                        color="error"
                        onClick={() => handleCancelClick(notification)}
                        title="キャンセル"
                      >
                        <CancelIcon />
                      </IconButton>
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      {hasMore && (
        <Box sx={{ mt: 2, textAlign: 'center' }}>
          <Typography variant="body2" color="text.secondary">
            さらに古い履歴があります
          </Typography>
        </Box>
      )}

      {/* Confirm Send Dialog */}
      <Dialog open={confirmDialogOpen} onClose={() => setConfirmDialogOpen(false)}>
        <DialogTitle>
          {isScheduled ? '通知を予約しますか？' : '通知を送信しますか？'}
        </DialogTitle>
        <DialogContent>
          <DialogContentText component="div">
            <Box sx={{ mb: 2 }}>
              <Typography variant="subtitle2">タイトル:</Typography>
              <Typography>{title}</Typography>
            </Box>
            <Box sx={{ mb: 2 }}>
              <Typography variant="subtitle2">本文:</Typography>
              <Typography>{body}</Typography>
            </Box>
            <Box sx={{ mb: 2 }}>
              <Typography variant="subtitle2">配信対象:</Typography>
              <Typography>
                {targetType === 'all' ? '全ユーザー' : selectedTarget?.name || '-'}
              </Typography>
            </Box>
            {isScheduled && scheduledAt && (
              <Box>
                <Typography variant="subtitle2">配信日時:</Typography>
                <Typography>
                  {format(new Date(scheduledAt), 'yyyy年MM月dd日 HH:mm', { locale: ja })}
                </Typography>
              </Box>
            )}
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setConfirmDialogOpen(false)}>キャンセル</Button>
          <Button onClick={handleConfirmSend} color="primary" variant="contained">
            {isScheduled ? '予約する' : '送信する'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Cancel Notification Dialog */}
      <Dialog open={cancelDialogOpen} onClose={() => setCancelDialogOpen(false)}>
        <DialogTitle>通知をキャンセル</DialogTitle>
        <DialogContent>
          <DialogContentText>
            「{selectedNotification?.title}」の予約をキャンセルしますか？
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCancelDialogOpen(false)}>戻る</Button>
          <Button onClick={handleConfirmCancel} color="error" variant="contained">
            キャンセルする
          </Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
      >
        <Alert
          onClose={() => setSnackbar({ ...snackbar, open: false })}
          severity={snackbar.severity}
          sx={{ width: '100%' }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};
