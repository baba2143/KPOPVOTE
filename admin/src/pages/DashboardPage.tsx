import React, { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Grid,
  Alert,
} from '@mui/material';
import {
  People as PeopleIcon,
  HowToVote as VoteIcon,
  Star as StarIcon,
  Forum as ForumIcon,
} from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import {
  DashboardStats,
  TrendData,
  subscribeToStatistics,
  getVoteTrend,
  getUserGrowth,
} from '../services/dashboardService';
import { StatCard } from '../components/dashboard/StatCard';
import { VoteTrendChart } from '../components/dashboard/VoteTrendChart';
import { UserGrowthChart } from '../components/dashboard/UserGrowthChart';

export const DashboardPage: React.FC = () => {
  const { user } = useAuth();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [voteTrend, setVoteTrend] = useState<TrendData[]>([]);
  const [userGrowth, setUserGrowth] = useState<TrendData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // Subscribe to real-time statistics
    const unsubscribe = subscribeToStatistics((newStats) => {
      setStats(newStats);
      setLoading(false);
    });

    // Load trend data
    Promise.all([getVoteTrend(), getUserGrowth()])
      .then(([voteTrendData, userGrowthData]) => {
        setVoteTrend(voteTrendData);
        setUserGrowth(userGrowthData);
      })
      .catch((err) => {
        console.error('Error loading trend data:', err);
        setError('グラフデータの読み込みに失敗しました');
      });

    return unsubscribe;
  }, []);

  return (
    <Box sx={{ width: '100%', overflow: 'hidden' }}>
      <Typography variant="h4" component="h1" gutterBottom>
        ダッシュボード
      </Typography>
      <Typography variant="body1" color="text.secondary" paragraph>
        ようこそ、{user?.email || '管理者'}さん
      </Typography>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {/* Statistics Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid size={{ xs: 12, sm: 6, md: 6, lg: 3 }}>
          <StatCard
            title="総ユーザー数"
            value={stats?.totalUsers ?? null}
            loading={loading}
            icon={<PeopleIcon sx={{ fontSize: 40 }} />}
            color="primary.main"
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 6, lg: 3 }}>
          <StatCard
            title="アクティブ投票"
            value={stats?.activeVotes ?? null}
            loading={loading}
            icon={<VoteIcon sx={{ fontSize: 40 }} />}
            color="success.main"
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 6, lg: 3 }}>
          <StatCard
            title="登録アイドル"
            value={stats?.totalIdols ?? null}
            loading={loading}
            icon={<StarIcon sx={{ fontSize: 40 }} />}
            color="warning.main"
          />
        </Grid>
        <Grid size={{ xs: 12, sm: 6, md: 6, lg: 3 }}>
          <StatCard
            title="コミュニティ投稿"
            value={stats?.communityPosts ?? null}
            loading={loading}
            icon={<ForumIcon sx={{ fontSize: 40 }} />}
            color="info.main"
          />
        </Grid>
      </Grid>

      {/* Vote Trend Chart */}
      <Box sx={{ width: '100%', mb: 4 }}>
        <VoteTrendChart data={voteTrend} loading={loading} />
      </Box>

      {/* User Growth Chart */}
      <Box sx={{ width: '100%' }}>
        <UserGrowthChart data={userGrowth} loading={loading} />
      </Box>
    </Box>
  );
};
