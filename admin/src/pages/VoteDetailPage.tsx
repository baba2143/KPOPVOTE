import React, { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  Button,
  Grid,
  Chip,
  Alert,
  CircularProgress,
  LinearProgress,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
} from '@mui/material';
import {
  ArrowBack as ArrowBackIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
} from '@mui/icons-material';
import { useNavigate, useParams } from 'react-router-dom';
import { format } from 'date-fns';
import { getVoteDetail, getRanking, deleteVote } from '../services/voteService';
import { InAppVote, RankingResponse } from '../types/vote';

export const VoteDetailPage: React.FC = () => {
  const navigate = useNavigate();
  const { voteId } = useParams<{ voteId: string }>();
  const [vote, setVote] = useState<InAppVote | null>(null);
  const [ranking, setRanking] = useState<RankingResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadData = async () => {
    if (!voteId) return;

    try {
      setLoading(true);
      setError(null);

      const [voteData, rankingData] = await Promise.all([
        getVoteDetail(voteId),
        getRanking(voteId),
      ]);

      setVote(voteData);
      setRanking(rankingData);
    } catch (err) {
      console.error('Error loading vote detail:', err);
      setError('投票情報の読み込みに失敗しました');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();

    // Refresh ranking every 5 seconds for active votes
    const interval = setInterval(() => {
      if (vote?.status === 'active' && voteId) {
        getRanking(voteId)
          .then(setRanking)
          .catch(console.error);
      }
    }, 5000);

    return () => clearInterval(interval);
  }, [voteId, vote?.status]);

  const handleBack = () => {
    navigate('/votes');
  };

  const handleDelete = async () => {
    if (!voteId || !vote) return;

    const confirmed = window.confirm(
      `「${vote.title}」を削除してもよろしいですか？\nこの操作は取り消せません。`
    );

    if (!confirmed) return;

    try {
      await deleteVote(voteId);
      navigate('/votes');
    } catch (err) {
      console.error('Error deleting vote:', err);
      setError('投票の削除に失敗しました');
    }
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

  if (loading) {
    return (
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
    );
  }

  if (error || !vote || !ranking) {
    return (
      <Box>
        <Button startIcon={<ArrowBackIcon />} onClick={handleBack} sx={{ mb: 2 }}>
          戻る
        </Button>
        <Alert severity="error">{error || '投票が見つかりません'}</Alert>
      </Box>
    );
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', gap: 1, mb: 3 }}>
        <Button startIcon={<ArrowBackIcon />} onClick={handleBack}>
          戻る
        </Button>
        <Box sx={{ flexGrow: 1 }} />
        <Button startIcon={<EditIcon />} variant="outlined" disabled>
          編集（未実装）
        </Button>
        <Button
          startIcon={<DeleteIcon />}
          variant="outlined"
          color="error"
          onClick={handleDelete}
        >
          削除
        </Button>
      </Box>

      {/* Vote Information */}
      <Paper sx={{ p: 3, mb: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
          <Typography variant="h5" component="h1">
            {vote.title}
          </Typography>
          <Chip
            label={getStatusLabel(vote.status)}
            color={getStatusColor(vote.status)}
          />
        </Box>

        <Typography variant="body1" color="text.secondary" paragraph>
          {vote.description}
        </Typography>

        <Grid container spacing={2}>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <Typography variant="caption" color="text.secondary">
              開始日時
            </Typography>
            <Typography variant="body2">
              {format(new Date(vote.startDate), 'yyyy/MM/dd HH:mm')}
            </Typography>
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <Typography variant="caption" color="text.secondary">
              終了日時
            </Typography>
            <Typography variant="body2">
              {format(new Date(vote.endDate), 'yyyy/MM/dd HH:mm')}
            </Typography>
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <Typography variant="caption" color="text.secondary">
              必要ポイント
            </Typography>
            <Typography variant="body2">{vote.requiredPoints}</Typography>
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <Typography variant="caption" color="text.secondary">
              総投票数
            </Typography>
            <Typography variant="body2" sx={{ fontWeight: 'bold' }}>
              {vote.totalVotes.toLocaleString()}
            </Typography>
          </Grid>
        </Grid>
      </Paper>

      {/* Ranking */}
      <Paper sx={{ p: 3 }}>
        <Typography variant="h6" gutterBottom>
          ランキング
          {vote.status === 'active' && (
            <Typography
              component="span"
              variant="caption"
              color="text.secondary"
              sx={{ ml: 2 }}
            >
              （5秒ごとに自動更新）
            </Typography>
          )}
        </Typography>

        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>順位</TableCell>
                <TableCell>選択肢</TableCell>
                <TableCell align="right">得票数</TableCell>
                <TableCell align="right">得票率</TableCell>
                <TableCell>進捗</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {ranking.ranking.map((item, index) => (
                <TableRow key={item.choiceId}>
                  <TableCell>
                    <Typography variant="h6" component="span">
                      {index + 1}
                    </Typography>
                  </TableCell>
                  <TableCell>{item.label}</TableCell>
                  <TableCell align="right">
                    {item.voteCount.toLocaleString()}
                  </TableCell>
                  <TableCell align="right">
                    {item.percentage.toFixed(1)}%
                  </TableCell>
                  <TableCell sx={{ width: '40%' }}>
                    <LinearProgress
                      variant="determinate"
                      value={item.percentage}
                      sx={{ height: 10, borderRadius: 5 }}
                    />
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </Paper>
    </Box>
  );
};
