import React, { useState, useEffect } from 'react';
import {
  Box,
  Button,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Typography,
  CircularProgress,
  Alert,
  Avatar,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  DialogContentText,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Link as LinkIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { listExternalApps, deleteExternalApp } from '../services/externalAppService';
import { ExternalAppMaster } from '../types/externalApp';
import { ExternalAppFormDialog } from '../components/externalApp/ExternalAppFormDialog';

export const ExternalAppListPage: React.FC = () => {
  const [apps, setApps] = useState<ExternalAppMaster[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [editingApp, setEditingApp] = useState<ExternalAppMaster | undefined>(undefined);
  const [deletingApp, setDeletingApp] = useState<ExternalAppMaster | null>(null);
  const [deleteLoading, setDeleteLoading] = useState(false);

  const loadApps = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await listExternalApps();
      setApps(data);
    } catch (err) {
      console.error('Error loading external apps:', err);
      setError('外部アプリ一覧の取得に失敗しました');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadApps();
  }, []);

  const handleCreateSuccess = () => {
    setCreateDialogOpen(false);
    loadApps();
  };

  const handleEditClick = (app: ExternalAppMaster) => {
    setEditingApp(app);
  };

  const handleEditSuccess = () => {
    setEditingApp(undefined);
    loadApps();
  };

  const handleDeleteClick = (app: ExternalAppMaster) => {
    setDeletingApp(app);
  };

  const handleDeleteConfirm = async () => {
    if (!deletingApp) return;

    try {
      setDeleteLoading(true);
      await deleteExternalApp(deletingApp.appId);
      setDeletingApp(null);
      loadApps();
    } catch (err) {
      console.error('Error deleting external app:', err);
      setError('外部アプリの削除に失敗しました');
      setDeletingApp(null);
    } finally {
      setDeleteLoading(false);
    }
  };

  const handleDeleteCancel = () => {
    setDeletingApp(null);
  };

  return (
    <Box sx={{ p: 3 }}>
      <Box
        sx={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          mb: 3,
        }}
      >
        <Typography variant="h4" component="h1">
          外部アプリマスター管理
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setCreateDialogOpen(true)}
        >
          新規追加
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
        投票アプリケーションやサイトのマスターデータを管理します
      </Typography>

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
          <CircularProgress />
        </Box>
      ) : (
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>アイコン</TableCell>
                <TableCell>アプリ名</TableCell>
                <TableCell>URL</TableCell>
                <TableCell>作成日時</TableCell>
                <TableCell align="right">操作</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {apps.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} align="center">
                    <Typography color="text.secondary">
                      外部アプリが登録されていません
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                apps.map((app) => (
                  <TableRow key={app.appId} hover>
                    <TableCell>
                      <Avatar
                        src={app.iconUrl || undefined}
                        alt={app.appName}
                        sx={{ width: 48, height: 48 }}
                        variant="rounded"
                      >
                        {app.appName.charAt(0)}
                      </Avatar>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body1" fontWeight="medium">
                        {app.appName}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      {app.appUrl ? (
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                          <Typography
                            variant="body2"
                            color="primary"
                            sx={{
                              maxWidth: 300,
                              overflow: 'hidden',
                              textOverflow: 'ellipsis',
                              whiteSpace: 'nowrap',
                            }}
                          >
                            {app.appUrl}
                          </Typography>
                          <IconButton
                            size="small"
                            onClick={() => window.open(app.appUrl, '_blank')}
                            title="URLを開く"
                          >
                            <LinkIcon fontSize="small" />
                          </IconButton>
                        </Box>
                      ) : (
                        <Typography variant="body2" color="text.secondary">
                          -
                        </Typography>
                      )}
                    </TableCell>
                    <TableCell>
                      {app.createdAt
                        ? format(new Date(app.createdAt), 'yyyy/MM/dd HH:mm')
                        : '-'}
                    </TableCell>
                    <TableCell align="right">
                      <IconButton
                        size="small"
                        onClick={() => handleEditClick(app)}
                        title="編集"
                      >
                        <EditIcon />
                      </IconButton>
                      <IconButton
                        size="small"
                        color="error"
                        onClick={() => handleDeleteClick(app)}
                        title="削除"
                      >
                        <DeleteIcon />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      {/* Create Dialog */}
      <ExternalAppFormDialog
        open={createDialogOpen}
        onClose={() => setCreateDialogOpen(false)}
        onSuccess={handleCreateSuccess}
      />

      {/* Edit Dialog */}
      {editingApp && (
        <ExternalAppFormDialog
          open={!!editingApp}
          onClose={() => setEditingApp(undefined)}
          onSuccess={handleEditSuccess}
          app={editingApp}
        />
      )}

      {/* Delete Confirmation Dialog */}
      <Dialog
        open={!!deletingApp}
        onClose={handleDeleteCancel}
        aria-labelledby="delete-dialog-title"
      >
        <DialogTitle id="delete-dialog-title">外部アプリの削除</DialogTitle>
        <DialogContent>
          <DialogContentText>
            「{deletingApp?.appName}」を削除してもよろしいですか？
            <br />
            この操作は取り消せません。
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleDeleteCancel} disabled={deleteLoading}>
            キャンセル
          </Button>
          <Button
            onClick={handleDeleteConfirm}
            color="error"
            variant="contained"
            disabled={deleteLoading}
            startIcon={deleteLoading ? <CircularProgress size={20} /> : <DeleteIcon />}
          >
            {deleteLoading ? '削除中...' : '削除'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};
