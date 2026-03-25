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
  TextField,
  InputAdornment,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
  List,
  ListItem,
  ListItemText,
  Tabs,
  Tab,
  LinearProgress,
  Chip,
  Badge,
  IconButton,
} from '@mui/material';
import {
  Add as AddIcon,
  Search as SearchIcon,
  FileDownload as FileDownloadIcon,
  FileUpload as FileUploadIcon,
  SwapHoriz as SwapHorizIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { listIdols, exportIdolsToCSV, importIdolsFromCSV, replaceIdolsFromCSV, deleteIdol, ImportResult, ImportProgress, ReplaceResult, ReplaceProgress } from '../services/idolService';
import { IdolMaster } from '../types/idol';
import { IdolFormDialog } from '../components/idol/IdolFormDialog';
import { GroupList } from '../components/group/GroupList';

export const IdolListPage: React.FC = () => {
  const [tabValue, setTabValue] = useState(0);
  const [idols, setIdols] = useState<IdolMaster[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [groupNameFilter, setGroupNameFilter] = useState('');
  const [importDialogOpen, setImportDialogOpen] = useState(false);
  const [importLoading, setImportLoading] = useState(false);
  const [importResult, setImportResult] = useState<ImportResult | null>(null);
  const [importProgress, setImportProgress] = useState<ImportProgress | null>(null);
  const [selectedChar, setSelectedChar] = useState<string>('ALL');
  const fileInputRef = useRef<HTMLInputElement>(null);
  const replaceFileInputRef = useRef<HTMLInputElement>(null);
  const [replaceDialogOpen, setReplaceDialogOpen] = useState(false);
  const [replaceConfirmDialogOpen, setReplaceConfirmDialogOpen] = useState(false);
  const [replaceLoading, setReplaceLoading] = useState(false);
  const [replaceResult, setReplaceResult] = useState<ReplaceResult | null>(null);
  const [replaceProgress, setReplaceProgress] = useState<ReplaceProgress | null>(null);
  const [pendingReplaceFile, setPendingReplaceFile] = useState<File | null>(null);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [selectedIdol, setSelectedIdol] = useState<IdolMaster | null>(null);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [deleteLoading, setDeleteLoading] = useState(false);

  // Alphabet index
  const ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ#'.split('');

  // Get first character for indexing
  const getFirstChar = (name: string): string => {
    const firstChar = name.charAt(0).toUpperCase();
    return /[A-Z]/.test(firstChar) ? firstChar : '#';
  };

  // Group idols by first character
  const groupedIdols = idols.reduce((acc, idol) => {
    const char = getFirstChar(idol.name);
    if (!acc[char]) acc[char] = [];
    acc[char].push(idol);
    return acc;
  }, {} as Record<string, IdolMaster[]>);

  // Filter idols by selected character
  const filteredIdols = selectedChar === 'ALL'
    ? idols
    : (groupedIdols[selectedChar] || []);

  const loadIdols = async (groupName?: string) => {
    try {
      setLoading(true);
      setError(null);
      const data = await listIdols(groupName);
      setIdols(data);
    } catch (err) {
      console.error('Error loading idols:', err);
      setError('アイドル一覧の取得に失敗しました');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadIdols();
  }, []);

  const handleSearch = () => {
    loadIdols(groupNameFilter || undefined);
  };

  const handleCreateSuccess = () => {
    setCreateDialogOpen(false);
    loadIdols(groupNameFilter || undefined);
  };

  const handleEditClick = (idol: IdolMaster) => {
    setSelectedIdol(idol);
    setEditDialogOpen(true);
  };

  const handleEditSuccess = () => {
    setEditDialogOpen(false);
    setSelectedIdol(null);
    loadIdols(groupNameFilter || undefined);
  };

  const handleDeleteClick = (idol: IdolMaster) => {
    setSelectedIdol(idol);
    setDeleteDialogOpen(true);
  };

  const handleDeleteConfirm = async () => {
    if (!selectedIdol) return;

    try {
      setDeleteLoading(true);
      await deleteIdol(selectedIdol.idolId);
      setDeleteDialogOpen(false);
      setSelectedIdol(null);
      loadIdols(groupNameFilter || undefined);
    } catch (err) {
      console.error('Error deleting idol:', err);
      setError('アイドルの削除に失敗しました');
    } finally {
      setDeleteLoading(false);
    }
  };

  const handleDeleteCancel = () => {
    setDeleteDialogOpen(false);
    setSelectedIdol(null);
  };

  const handleExport = async () => {
    try {
      await exportIdolsToCSV();
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
      setImportProgress(null);

      const result = await importIdolsFromCSV(file, (progress) => {
        setImportProgress(progress);
      });
      setImportResult(result);

      if (result.success || result.created > 0) {
        loadIdols(groupNameFilter || undefined);
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

      const result = await replaceIdolsFromCSV(pendingReplaceFile, (progress) => {
        setReplaceProgress(progress);
      });
      setReplaceResult(result);

      if (result.success || result.created > 0) {
        loadIdols(groupNameFilter || undefined);
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

  const handleCloseReplaceDialog = () => {
    setReplaceDialogOpen(false);
    setReplaceResult(null);
  };

  const handleCancelReplace = () => {
    setReplaceConfirmDialogOpen(false);
    setPendingReplaceFile(null);
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
          アイドルマスター管理
        </Typography>
      </Box>

      <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
        <Tabs value={tabValue} onChange={(e, newValue) => setTabValue(newValue)}>
          <Tab label="メンバー" />
          <Tab label="グループ" />
        </Tabs>
      </Box>

      {tabValue === 0 ? (
        <>
          <Box
            sx={{
              display: 'flex',
              justifyContent: 'flex-end',
              alignItems: 'center',
              mb: 3,
            }}
          >
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
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      <Box sx={{ mb: 3, display: 'flex', gap: 1 }}>
        <TextField
          placeholder="グループ名で検索"
          value={groupNameFilter}
          onChange={(e) => setGroupNameFilter(e.target.value)}
          onKeyPress={(e) => {
            if (e.key === 'Enter') {
              handleSearch();
            }
          }}
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon />
              </InputAdornment>
            ),
          }}
          sx={{ flexGrow: 1, maxWidth: 400 }}
        />
        <Button variant="outlined" onClick={handleSearch}>
          検索
        </Button>
        {groupNameFilter && (
          <Button
            variant="text"
            onClick={() => {
              setGroupNameFilter('');
              loadIdols();
            }}
          >
            クリア
          </Button>
        )}
      </Box>

      {/* Alphabet Index */}
      <Box sx={{ mb: 3 }}>
        <Typography variant="subtitle2" sx={{ mb: 1 }}>
          アルファベット順:
        </Typography>
        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
          <Chip
            label="ALL"
            onClick={() => setSelectedChar('ALL')}
            color={selectedChar === 'ALL' ? 'primary' : 'default'}
            variant={selectedChar === 'ALL' ? 'filled' : 'outlined'}
            size="small"
          />
          {ALPHABET.map((char) => {
            const count = groupedIdols[char]?.length || 0;
            const hasData = count > 0;
            return (
              <Badge
                key={char}
                badgeContent={hasData ? count : 0}
                color="primary"
                invisible={!hasData || selectedChar === char}
                sx={{ '& .MuiBadge-badge': { fontSize: '0.6rem' } }}
              >
                <Chip
                  label={char}
                  onClick={() => hasData && setSelectedChar(char)}
                  color={selectedChar === char ? 'primary' : 'default'}
                  variant={selectedChar === char ? 'filled' : 'outlined'}
                  disabled={!hasData}
                  size="small"
                  sx={{ minWidth: 32 }}
                />
              </Badge>
            );
          })}
        </Box>
        <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
          表示中: {selectedChar === 'ALL' ? `全${idols.length}件` : `${selectedChar} (${filteredIdols.length}件)`}
        </Typography>
      </Box>

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
                <TableCell>名前</TableCell>
                <TableCell>グループ名</TableCell>
                <TableCell>作成日時</TableCell>
                <TableCell align="right">操作</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredIdols.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} align="center">
                    <Typography color="text.secondary">
                      {selectedChar === 'ALL'
                        ? 'アイドルが登録されていません'
                        : `「${selectedChar}」で始まるアイドルが見つかりません`}
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                filteredIdols.map((idol) => (
                  <TableRow key={idol.idolId} hover>
                    <TableCell>
                      <Avatar
                        src={idol.imageUrl || undefined}
                        alt={idol.name}
                        sx={{ width: 48, height: 48 }}
                      >
                        {idol.name.charAt(0)}
                      </Avatar>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body1" fontWeight="medium">
                        {idol.name}
                      </Typography>
                    </TableCell>
                    <TableCell>{idol.groupName}</TableCell>
                    <TableCell>
                      {idol.createdAt
                        ? format(new Date(idol.createdAt), 'yyyy/MM/dd HH:mm')
                        : '-'}
                    </TableCell>
                    <TableCell align="right">
                      <IconButton
                        size="small"
                        onClick={() => handleEditClick(idol)}
                        title="編集"
                      >
                        <EditIcon />
                      </IconButton>
                      <IconButton
                        size="small"
                        color="error"
                        onClick={() => handleDeleteClick(idol)}
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

      <IdolFormDialog
        open={createDialogOpen}
        onClose={() => setCreateDialogOpen(false)}
        onSuccess={handleCreateSuccess}
        mode="create"
      />

      {/* Edit Dialog */}
      {selectedIdol && (
        <IdolFormDialog
          open={editDialogOpen}
          onClose={() => {
            setEditDialogOpen(false);
            setSelectedIdol(null);
          }}
          onSuccess={handleEditSuccess}
          mode="edit"
          initialIdol={selectedIdol}
        />
      )}

      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteDialogOpen} onClose={handleDeleteCancel}>
        <DialogTitle>アイドルの削除</DialogTitle>
        <DialogContent>
          <DialogContentText>
            「{selectedIdol?.name}」を削除してもよろしいですか？
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
              {importProgress && (
                <Box sx={{ width: '100%', mt: 3 }}>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                    <Typography variant="body2">
                      処理中: {importProgress.current}/{importProgress.total} 件
                    </Typography>
                    <Typography variant="body2">
                      {Math.round((importProgress.current / importProgress.total) * 100)}%
                    </Typography>
                  </Box>
                  <LinearProgress
                    variant="determinate"
                    value={(importProgress.current / importProgress.total) * 100}
                    sx={{ height: 8, borderRadius: 4 }}
                  />
                  <Box sx={{ mt: 2, display: 'flex', gap: 2, justifyContent: 'center' }}>
                    <Typography variant="caption" color="success.main">
                      新規: {importProgress.created}件
                    </Typography>
                    <Typography variant="caption" color="info.main">
                      更新: {importProgress.updated}件
                    </Typography>
                  </Box>
                  <Alert severity="info" sx={{ mt: 2 }}>
                    処理中はブラウザを閉じないでください
                  </Alert>
                </Box>
              )}
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
          ⚠️ 全置換インポート
        </DialogTitle>
        <DialogContent>
          <Alert severity="warning" sx={{ mb: 2 }}>
            既存のアイドルマスターを全て削除し、CSVデータで置き換えます。
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
        </>
      ) : (
        <GroupList />
      )}
    </Box>
  );
};
