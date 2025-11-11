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
  TextField,
  InputAdornment,
} from '@mui/material';
import { Add as AddIcon, Search as SearchIcon } from '@mui/icons-material';
import { format } from 'date-fns';
import { listIdols } from '../services/idolService';
import { IdolMaster } from '../types/idol';
import { IdolFormDialog } from '../components/idol/IdolFormDialog';

export const IdolListPage: React.FC = () => {
  const [idols, setIdols] = useState<IdolMaster[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [groupNameFilter, setGroupNameFilter] = useState('');

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
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => setCreateDialogOpen(true)}
        >
          新規追加
        </Button>
      </Box>

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
              {idols.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={4} align="center">
                    <Typography color="text.secondary">
                      アイドルが登録されていません
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                idols.map((idol) => (
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
    </Box>
  );
};
