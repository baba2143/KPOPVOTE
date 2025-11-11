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
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Visibility as VisibilityIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { format } from 'date-fns';
import { listVotes, deleteVote } from '../services/voteService';
import { InAppVote } from '../types/vote';
import { VoteFormDialog } from '../components/vote/VoteFormDialog';

type StatusFilter = 'all' | 'upcoming' | 'active' | 'ended';

export const VoteListPage: React.FC = () => {
  const navigate = useNavigate();
  const [votes, setVotes] = useState<InAppVote[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('all');
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [selectedVote, setSelectedVote] = useState<InAppVote | null>(null);

  const loadVotes = async (status?: 'upcoming' | 'active' | 'ended') => {
    try {
      setLoading(true);
      setError(null);
      const data = await listVotes(status);
      setVotes(data);
    } catch (err) {
      console.error('Error loading votes:', err);
      setError('投票の読み込みに失敗しました');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const status = statusFilter === 'all' ? undefined : statusFilter;
    loadVotes(status);
  }, [statusFilter]);

  const handleStatusFilterChange = (
    _event: React.SyntheticEvent,
    newValue: StatusFilter
  ) => {
    setStatusFilter(newValue);
  };

  const handleCreateClick = () => {
    setCreateDialogOpen(true);
  };

  const handleCreateSuccess = () => {
    setCreateDialogOpen(false);
    loadVotes(statusFilter === 'all' ? undefined : statusFilter);
  };

  const handleDeleteClick = (vote: InAppVote) => {
    setSelectedVote(vote);
    setDeleteDialogOpen(true);
  };

  const handleDeleteConfirm = async () => {
    if (!selectedVote) return;

    try {
      await deleteVote(selectedVote.voteId);
      setDeleteDialogOpen(false);
      setSelectedVote(null);
      loadVotes(statusFilter === 'all' ? undefined : statusFilter);
    } catch (err) {
      console.error('Error deleting vote:', err);
      setError('投票の削除に失敗しました');
    }
  };

  const handleDeleteCancel = () => {
    setDeleteDialogOpen(false);
    setSelectedVote(null);
  };

  const handleDetailClick = (voteId: string) => {
    navigate(`/votes/${voteId}`);
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'upcoming':
        return '開始前';
      case 'active':
        return '投票中';
      case 'ended':
        return '終了';
      default:
        return status;
    }
  };

  const getStatusColor = (
    status: string
  ): 'default' | 'primary' | 'success' | 'error' => {
    switch (status) {
      case 'upcoming':
        return 'default';
      case 'active':
        return 'success';
      case 'ended':
        return 'error';
      default:
        return 'default';
    }
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
          独自投票管理
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleCreateClick}
        >
          新規作成
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      <Paper sx={{ mb: 3 }}>
        <Tabs
          value={statusFilter}
          onChange={handleStatusFilterChange}
          sx={{ borderBottom: 1, borderColor: 'divider' }}
        >
          <Tab label="全て" value="all" />
          <Tab label="開始前" value="upcoming" />
          <Tab label="投票中" value="active" />
          <Tab label="終了" value="ended" />
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
      ) : votes.length === 0 ? (
        <Paper sx={{ p: 3, textAlign: 'center' }}>
          <Typography color="text.secondary">
            投票がありません
          </Typography>
        </Paper>
      ) : (
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>タイトル</TableCell>
                <TableCell>ステータス</TableCell>
                <TableCell>開始日時</TableCell>
                <TableCell>終了日時</TableCell>
                <TableCell align="right">選択肢数</TableCell>
                <TableCell align="right">総投票数</TableCell>
                <TableCell align="center">操作</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {votes.map((vote) => (
                <TableRow key={vote.voteId} hover>
                  <TableCell>{vote.title}</TableCell>
                  <TableCell>
                    <Chip
                      label={getStatusLabel(vote.status)}
                      color={getStatusColor(vote.status)}
                      size="small"
                    />
                  </TableCell>
                  <TableCell>
                    {format(new Date(vote.startDate), 'yyyy/MM/dd HH:mm')}
                  </TableCell>
                  <TableCell>
                    {format(new Date(vote.endDate), 'yyyy/MM/dd HH:mm')}
                  </TableCell>
                  <TableCell align="right">{vote.choices.length}</TableCell>
                  <TableCell align="right">
                    {vote.totalVotes.toLocaleString()}
                  </TableCell>
                  <TableCell align="center">
                    <IconButton
                      size="small"
                      color="primary"
                      onClick={() => handleDetailClick(vote.voteId)}
                      title="詳細を表示"
                    >
                      <VisibilityIcon />
                    </IconButton>
                    <IconButton
                      size="small"
                      color="error"
                      onClick={() => handleDeleteClick(vote)}
                      title="削除"
                    >
                      <DeleteIcon />
                    </IconButton>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      {/* Create Dialog */}
      <VoteFormDialog
        open={createDialogOpen}
        onClose={() => setCreateDialogOpen(false)}
        onSuccess={handleCreateSuccess}
      />

      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteDialogOpen} onClose={handleDeleteCancel}>
        <DialogTitle>投票の削除</DialogTitle>
        <DialogContent>
          <DialogContentText>
            「{selectedVote?.title}」を削除してもよろしいですか？
            <br />
            この操作は取り消せません。
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleDeleteCancel}>キャンセル</Button>
          <Button onClick={handleDeleteConfirm} color="error" variant="contained">
            削除
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};
