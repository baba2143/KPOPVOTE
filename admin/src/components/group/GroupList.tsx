import React, { useState, useEffect, useRef } from 'react';
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
  List,
  ListItem,
  ListItemText,
  LinearProgress,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  FileDownload as FileDownloadIcon,
  FileUpload as FileUploadIcon,
  SwapHoriz as SwapHorizIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import {
  listGroups,
  deleteGroup,
  exportGroupsToCSV,
  importGroupsFromCSV,
  replaceGroupsFromCSV,
  ImportResult,
  ReplaceResult,
  ReplaceProgress,
} from '../../services/groupService';
import { GroupMaster } from '../../types/group';
import { GroupFormDialog } from './GroupFormDialog';

export const GroupList: React.FC = () => {
  const [groups, setGroups] = useState<GroupMaster[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [editingGroup, setEditingGroup] = useState<GroupMaster | undefined>(undefined);
  const [deletingGroup, setDeletingGroup] = useState<GroupMaster | null>(null);
  const [deleteLoading, setDeleteLoading] = useState(false);
  const [importDialogOpen, setImportDialogOpen] = useState(false);
  const [importLoading, setImportLoading] = useState(false);
  const [importResult, setImportResult] = useState<ImportResult | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const replaceFileInputRef = useRef<HTMLInputElement>(null);
  const [replaceDialogOpen, setReplaceDialogOpen] = useState(false);
  const [replaceConfirmDialogOpen, setReplaceConfirmDialogOpen] = useState(false);
  const [replaceLoading, setReplaceLoading] = useState(false);
  const [replaceResult, setReplaceResult] = useState<ReplaceResult | null>(null);
  const [replaceProgress, setReplaceProgress] = useState<ReplaceProgress | null>(null);
  const [pendingReplaceFile, setPendingReplaceFile] = useState<File | null>(null);

  const loadGroups = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await listGroups();
      setGroups(data);
    } catch (err) {
      console.error('Error loading groups:', err);
      setError('グループ一覧の取得に失敗しました');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadGroups();
  }, []);

  const handleCreateSuccess = () => {
    setCreateDialogOpen(false);
    loadGroups();
  };

  const handleEditClick = (group: GroupMaster) => {
    setEditingGroup(group);
  };

  const handleEditSuccess = () => {
    setEditingGroup(undefined);
    loadGroups();
  };

  const handleDeleteClick = (group: GroupMaster) => {
    setDeletingGroup(group);
  };

  const handleDeleteConfirm = async () => {
    if (!deletingGroup) return;

    try {
      setDeleteLoading(true);
      await deleteGroup(deletingGroup.groupId);
      setDeletingGroup(null);
      loadGroups();
    } catch (err: any) {
      console.error('Error deleting group:', err);
      const errorMessage = err.message || 'グループの削除に失敗しました';
      setError(errorMessage);
      setDeletingGroup(null);
    } finally {
      setDeleteLoading(false);
    }
  };

  const handleDeleteCancel = () => {
    setDeletingGroup(null);
  };

  const handleExport = async () => {
    try {
      await exportGroupsToCSV();
    } catch (err) {
      console.error('Error exporting CSV:', err);
      setError('CSVエクスポートに失敗しました');
    }
  };

  const handleImportClick = () => {
    fileInputRef.current?.click();
  };

  const handleFileSelect = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    try {
      setImportLoading(true);
      setImportDialogOpen(true);
      setImportResult(null);

      const result = await importGroupsFromCSV(file);
      setImportResult(result);

      if (result.success) {
        loadGroups();
      }
    } catch (err) {
      console.error('Error importing CSV:', err);
      setError('CSVインポートに失敗しました');
      setImportDialogOpen(false);
    } finally {
      setImportLoading(false);
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    }
  };

  const handleCloseImportDialog = () => {
    setImportDialogOpen(false);
    setImportResult(null);
  };

  const handleReplaceClick = () => {
    replaceFileInputRef.current?.click();
  };

  const handleReplaceFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    // ファイルを保存して確認ダイアログを開く
    setPendingReplaceFile(file);
    setReplaceConfirmDialogOpen(true);

    if (replaceFileInputRef.current) {
      replaceFileInputRef.current.value = '';
    }
  };

  const handleReplaceConfirm = async () => {
    if (!pendingReplaceFile) return;

    try {
      setReplaceConfirmDialogOpen(false);
      setReplaceLoading(true);
      setReplaceDialogOpen(true);
      setReplaceResult(null);
      setReplaceProgress(null);

      const result = await replaceGroupsFromCSV(pendingReplaceFile, (progress) => {
        setReplaceProgress(progress);
      });
      setReplaceResult(result);

      if (result.success || result.created > 0) {
        loadGroups();
      }
    } catch (err) {
      console.error('Error replacing CSV:', err);
      setError('全置換インポートに失敗しました');
      setReplaceDialogOpen(false);
    } finally {
      setReplaceLoading(false);
      setPendingReplaceFile(null);
    }
  };

  const handleCancelReplace = () => {
    setReplaceConfirmDialogOpen(false);
    setPendingReplaceFile(null);
  };

  const handleCloseReplaceDialog = () => {
    setReplaceDialogOpen(false);
    setReplaceResult(null);
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
        <Typography variant="body2" color="text.secondary">
          K-POPグループのマスターデータを管理します
        </Typography>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Button
            variant="outlined"
            startIcon={<FileDownloadIcon />}
            onClick={handleExport}
          >
            CSVエクスポート
          </Button>
          <Button
            variant="outlined"
            startIcon={<FileUploadIcon />}
            onClick={handleImportClick}
          >
            CSVインポート（マージ）
          </Button>
          <Button
            variant="outlined"
            color="warning"
            startIcon={<SwapHorizIcon />}
            onClick={handleReplaceClick}
          >
            全置換インポート
          </Button>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => setCreateDialogOpen(true)}
          >
            新規追加
          </Button>
        </Box>
      </Box>
      <input
        ref={fileInputRef}
        type="file"
        accept=".csv"
        style={{ display: 'none' }}
        onChange={handleFileSelect}
      />
      <input
        ref={replaceFileInputRef}
        type="file"
        accept=".csv"
        style={{ display: 'none' }}
        onChange={handleReplaceFileSelect}
      />

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
          <CircularProgress />
        </Box>
      ) : (
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>画像</TableCell>
                <TableCell>グループ名</TableCell>
                <TableCell>作成日時</TableCell>
                <TableCell align="right">操作</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {groups.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={4} align="center">
                    <Typography color="text.secondary">
                      グループが登録されていません
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                groups.map((group) => (
                  <TableRow key={group.groupId} hover>
                    <TableCell>
                      <Avatar
                        src={group.imageUrl || undefined}
                        alt={group.name}
                        sx={{ width: 48, height: 48 }}
                      >
                        {group.name.charAt(0)}
                      </Avatar>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body1" fontWeight="medium">
                        {group.name}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      {group.createdAt
                        ? format(new Date(group.createdAt), 'yyyy/MM/dd HH:mm')
                        : '-'}
                    </TableCell>
                    <TableCell align="right">
                      <IconButton
                        size="small"
                        onClick={() => handleEditClick(group)}
                        title="編集"
                      >
                        <EditIcon />
                      </IconButton>
                      <IconButton
                        size="small"
                        color="error"
                        onClick={() => handleDeleteClick(group)}
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
      <GroupFormDialog
        open={createDialogOpen}
        onClose={() => setCreateDialogOpen(false)}
        onSuccess={handleCreateSuccess}
      />

      {/* Edit Dialog */}
      {editingGroup && (
        <GroupFormDialog
          open={!!editingGroup}
          onClose={() => setEditingGroup(undefined)}
          onSuccess={handleEditSuccess}
          group={editingGroup}
        />
      )}

      {/* Delete Confirmation Dialog */}
      <Dialog
        open={!!deletingGroup}
        onClose={handleDeleteCancel}
        aria-labelledby="delete-dialog-title"
      >
        <DialogTitle id="delete-dialog-title">グループの削除</DialogTitle>
        <DialogContent>
          <DialogContentText>
            「{deletingGroup?.name}」を削除してもよろしいですか？
            <br />
            このグループに所属するアイドルがいる場合は削除できません。
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

      {/* Import Result Dialog */}
      <Dialog
        open={importDialogOpen}
        onClose={importLoading ? undefined : handleCloseImportDialog}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>CSVインポート</DialogTitle>
        <DialogContent>
          {importLoading ? (
            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', py: 3 }}>
              <CircularProgress />
              <Typography sx={{ mt: 2 }}>インポート中...</Typography>
            </Box>
          ) : importResult ? (
            <>
              {importResult.success ? (
                <Alert severity="success" sx={{ mb: 2 }}>
                  インポートが完了しました
                </Alert>
              ) : (
                <Alert severity="error" sx={{ mb: 2 }}>
                  エラーが発生しました。すべての行を確認してください。
                </Alert>
              )}

              <Box sx={{ mb: 2 }}>
                <Typography variant="body2">
                  新規作成: {importResult.created}件
                </Typography>
                <Typography variant="body2">
                  更新: {importResult.updated}件
                </Typography>
              </Box>

              {importResult.errors.length > 0 && (
                <>
                  <Typography variant="subtitle2" color="error" sx={{ mb: 1 }}>
                    エラー詳細:
                  </Typography>
                  <List dense sx={{ maxHeight: 300, overflow: 'auto', bgcolor: 'background.paper' }}>
                    {importResult.errors.map((error, index) => (
                      <ListItem key={index}>
                        <ListItemText
                          primary={`${error.line}行目: ${error.error}`}
                          secondary={Object.entries(error.data).map(([key, value]) => `${key}: ${value}`).join(', ')}
                        />
                      </ListItem>
                    ))}
                  </List>
                </>
              )}
            </>
          ) : null}
        </DialogContent>
        <DialogActions>
          {!importLoading && (
            <Button onClick={handleCloseImportDialog}>閉じる</Button>
          )}
        </DialogActions>
      </Dialog>

      {/* Replace Confirm Dialog */}
      <Dialog
        open={replaceConfirmDialogOpen}
        onClose={handleCancelReplace}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle sx={{ color: 'warning.main' }}>
          全置換インポート
        </DialogTitle>
        <DialogContent>
          <Alert severity="warning" sx={{ mb: 2 }}>
            既存のグループマスターを全て削除し、CSVデータで置き換えます。
            <br />
            <strong>この操作は取り消せません。</strong>
          </Alert>
          <Typography variant="body2" sx={{ mb: 1 }}>
            選択ファイル: {pendingReplaceFile?.name}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            続行しますか？
          </Typography>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCancelReplace}>キャンセル</Button>
          <Button
            variant="contained"
            color="warning"
            onClick={handleReplaceConfirm}
          >
            全置換実行
          </Button>
        </DialogActions>
      </Dialog>

      {/* Replace Result Dialog */}
      <Dialog
        open={replaceDialogOpen}
        onClose={replaceLoading ? undefined : handleCloseReplaceDialog}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>全置換インポート</DialogTitle>
        <DialogContent>
          {replaceLoading ? (
            <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', py: 3 }}>
              <CircularProgress />
              <Typography sx={{ mt: 2 }}>
                {replaceProgress?.phase === 'deleting' ? '既存データを削除中...' : 'インポート中...'}
              </Typography>
              {replaceProgress && replaceProgress.phase === 'importing' && (
                <Box sx={{ width: '100%', mt: 3 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                    <Typography variant="body2">
                      処理中: {replaceProgress.current}/{replaceProgress.total} 件
                    </Typography>
                    <Typography variant="body2">
                      {Math.round((replaceProgress.current / replaceProgress.total) * 100)}%
                    </Typography>
                  </Box>
                  <LinearProgress
                    variant="determinate"
                    value={(replaceProgress.current / replaceProgress.total) * 100}
                    sx={{ height: 8, borderRadius: 4 }}
                  />
                  <Box sx={{ mt: 2, display: 'flex', gap: 2, justifyContent: 'center' }}>
                    <Typography variant="caption" color="success.main">
                      新規: {replaceProgress.created}件
                    </Typography>
                  </Box>
                </Box>
              )}
              <Alert severity="warning" sx={{ mt: 2 }}>
                処理中はブラウザを閉じないでください
              </Alert>
            </Box>
          ) : replaceResult ? (
            <>
              {replaceResult.success ? (
                <Alert severity="success" sx={{ mb: 2 }}>
                  全置換インポートが完了しました
                </Alert>
              ) : (
                <Alert severity="error" sx={{ mb: 2 }}>
                  エラーが発生しました。すべての行を確認してください。
                </Alert>
              )}

              <Box sx={{ mb: 2 }}>
                <Typography variant="body2">
                  削除: {replaceResult.deleted}件
                </Typography>
                <Typography variant="body2">
                  新規作成: {replaceResult.created}件
                </Typography>
              </Box>

              {replaceResult.errors.length > 0 && (
                <>
                  <Typography variant="subtitle2" color="error" sx={{ mb: 1 }}>
                    エラー詳細:
                  </Typography>
                  <List dense sx={{ maxHeight: 300, overflow: 'auto', bgcolor: 'background.paper' }}>
                    {replaceResult.errors.map((error, index) => (
                      <ListItem key={index}>
                        <ListItemText
                          primary={`${error.line}行目: ${error.error}`}
                          secondary={Object.entries(error.data).map(([key, value]) => `${key}: ${value}`).join(', ')}
                        />
                      </ListItem>
                    ))}
                  </List>
                </>
              )}
            </>
          ) : null}
        </DialogContent>
        <DialogActions>
          {!replaceLoading && (
            <Button onClick={handleCloseReplaceDialog}>閉じる</Button>
          )}
        </DialogActions>
      </Dialog>
    </Box>
  );
};
