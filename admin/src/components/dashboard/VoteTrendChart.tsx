import React from 'react';
import {
  LineChart,
  Line,
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

interface VoteTrendChartProps {
  data: TrendData[];
  loading?: boolean;
}

export const VoteTrendChart: React.FC<VoteTrendChartProps> = ({
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
        投票トレンド（直近30日）
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
          <LineChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="date" />
            <YAxis />
            <Tooltip />
            <Legend />
            <Line
              type="monotone"
              dataKey="count"
              stroke="#8884d8"
              activeDot={{ r: 8 }}
              name="投票数"
            />
          </LineChart>
        </ResponsiveContainer>
      )}
    </Paper>
  );
};
