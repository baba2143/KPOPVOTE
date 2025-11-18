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
  DialogActions,
  List,
  ListItem,
  ListItemText,
  Tabs,
  Tab,
  LinearProgress,
  Chip,
  Badge,
} from '@mui/material';
import {
  Add as AddIcon,
  Search as SearchIcon,
  FileDownload as FileDownloadIcon,
  FileUpload as FileUploadIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { listIdols, exportIdolsToCSV, importIdolsFromCSV, ImportResult, ImportProgress } from '../services/idolService';
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
                CSVインポート
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
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredIdols.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={4} align="center">
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
      />

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
        </>
      ) : (
        <GroupList />
      )}
    </Box>
  );
};
