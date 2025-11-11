import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  TextField,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  IconButton,
  Chip,
  CircularProgress,
  Alert,
  Tooltip,
} from '@mui/material';
import {
  Info as InfoIcon,
  AttachMoney as MoneyIcon,
  Block as BlockIcon,
  CheckCircle as RestoreIcon,
} from '@mui/icons-material';
import { searchUsers } from '../services/userService';
import { UserListItem } from '../types/user';
import { UserDetailDialog } from '../components/user/UserDetailDialog';
import { GrantPointDialog } from '../components/user/GrantPointDialog';
import { SuspendUserDialog } from '../components/user/SuspendUserDialog';

export const UserListPage: React.FC = () => {
  const [users, setUsers] = useState<UserListItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedUser, setSelectedUser] = useState<UserListItem | null>(null);
  const [detailDialogOpen, setDetailDialogOpen] = useState(false);
  const [pointDialogOpen, setPointDialogOpen] = useState(false);
  const [suspendDialogOpen, setSuspendDialogOpen] = useState(false);

  useEffect(() => {
    loadUsers();
  }, []);

  const loadUsers = async (query?: string) => {
    try {
      setLoading(true);
      setError(null);
      const data = await searchUsers(query);
      setUsers(data);
    } catch (err) {
      console.error('Failed to load users:', err);
      setError('ユーザーの読み込みに失敗しました');
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = () => {
    loadUsers(searchQuery || undefined);
  };

  const handleSearchKeyPress = (event: React.KeyboardEvent) => {
    if (event.key === 'Enter') {
      handleSearch();
    }
  };

  const handleOpenDetailDialog = (user: UserListItem) => {
    setSelectedUser(user);
    setDetailDialogOpen(true);
  };

  const handleOpenPointDialog = (user: UserListItem) => {
    setSelectedUser(user);
    setPointDialogOpen(true);
  };

  const handleOpenSuspendDialog = (user: UserListItem) => {
    setSelectedUser(user);
    setSuspendDialogOpen(true);
  };

  const handleCloseDialogs = () => {
    setDetailDialogOpen(false);
    setPointDialogOpen(false);
    setSuspendDialogOpen(false);
    setSelectedUser(null);
  };

  const handleActionComplete = () => {
    handleCloseDialogs();
    loadUsers(searchQuery || undefined);
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('ja-JP', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });
  };

  if (loading && users.length === 0) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">ユーザー管理</Typography>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      <Box display="flex" gap={2} mb={3}>
        <TextField
          label="メールアドレスで検索"
          variant="outlined"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          onKeyPress={handleSearchKeyPress}
          placeholder="例: user@example.com"
          fullWidth
          id="search-user-email"
          name="searchQuery"
        />
      </Box>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>メール</TableCell>
              <TableCell>表示名</TableCell>
              <TableCell align="right">ポイント</TableCell>
              <TableCell>ステータス</TableCell>
              <TableCell>登録日</TableCell>
              <TableCell align="center">アクション</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {users.map((user) => (
              <TableRow key={user.uid}>
                <TableCell>{user.email}</TableCell>
                <TableCell>{user.displayName || '-'}</TableCell>
                <TableCell align="right">{user.points}</TableCell>
                <TableCell>
                  {user.isSuspended ? (
                    <Chip label="停止中" color="error" size="small" />
                  ) : (
                    <Chip label="アクティブ" color="success" size="small" />
                  )}
                </TableCell>
                <TableCell>{formatDate(user.createdAt)}</TableCell>
                <TableCell align="center">
                  <Tooltip title="詳細を表示">
                    <IconButton
                      size="small"
                      color="primary"
                      onClick={() => handleOpenDetailDialog(user)}
                    >
                      <InfoIcon />
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="ポイント付与">
                    <IconButton
                      size="small"
                      color="primary"
                      onClick={() => handleOpenPointDialog(user)}
                    >
                      <MoneyIcon />
                    </IconButton>
                  </Tooltip>
                  {user.isSuspended ? (
                    <Tooltip title="停止を解除">
                      <IconButton
                        size="small"
                        color="success"
                        onClick={() => handleOpenSuspendDialog(user)}
                      >
                        <RestoreIcon />
                      </IconButton>
                    </Tooltip>
                  ) : (
                    <Tooltip title="アカウント停止">
                      <IconButton
                        size="small"
                        color="error"
                        onClick={() => handleOpenSuspendDialog(user)}
                      >
                        <BlockIcon />
                      </IconButton>
                    </Tooltip>
                  )}
                </TableCell>
              </TableRow>
            ))}
            {users.length === 0 && !loading && (
              <TableRow>
                <TableCell colSpan={6} align="center">
                  ユーザーが見つかりませんでした
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>

      <UserDetailDialog
        open={detailDialogOpen}
        user={selectedUser}
        onClose={handleCloseDialogs}
      />
      <GrantPointDialog
        open={pointDialogOpen}
        user={selectedUser}
        onClose={handleCloseDialogs}
        onSuccess={handleActionComplete}
      />
      <SuspendUserDialog
        open={suspendDialogOpen}
        user={selectedUser}
        onClose={handleCloseDialogs}
        onSuccess={handleActionComplete}
      />
    </Box>
  );
};
