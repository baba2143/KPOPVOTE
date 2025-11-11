import React from 'react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { Paper, Typography, Box, CircularProgress } from '@mui/material';
import { format } from 'date-fns';
import { TrendData } from '../../services/dashboardService';

interface UserGrowthChartProps {
  data: TrendData[];
  loading?: boolean;
}

export const UserGrowthChart: React.FC<UserGrowthChartProps> = ({
  data,
  loading = false,
}) => {
  // Format data for chart
  const chartData = data.map(item => ({
    ...item,
    date: format(new Date(item.date), 'MM/dd'),
  }));

  return (
    <Paper sx={{ p: 3 }}>
      <Typography variant="h6" gutterBottom>
        ユーザー登録推移（直近30日）
      </Typography>
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
      ) : chartData.length === 0 ? (
        <Box
          sx={{
            display: 'flex',
            justifyContent: 'center',
            alignItems: 'center',
            height: 300,
          }}
        >
          <Typography color="text.secondary">
            データがありません
          </Typography>
        </Box>
      ) : (
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="date" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Bar dataKey="count" fill="#82ca9d" name="新規登録数" />
          </BarChart>
        </ResponsiveContainer>
      )}
    </Paper>
  );
};
