import React from 'react';
import { Paper, Typography, Box, CircularProgress } from '@mui/material';

interface StatCardProps {
  title: string;
  value: number | null;
  loading?: boolean;
  icon?: React.ReactNode;
  color?: string;
}

export const StatCard: React.FC<StatCardProps> = ({
  title,
  value,
  loading = false,
  icon,
  color = 'primary.main',
}) => {
  return (
    <Paper
      sx={{
        p: 3,
        textAlign: 'center',
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'center',
      }}
    >
      {icon && (
        <Box sx={{ display: 'flex', justifyContent: 'center', mb: 1, color }}>
          {icon}
        </Box>
      )}
      <Typography variant="h6" color="text.secondary" gutterBottom>
        {title}
      </Typography>
      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', my: 2 }}>
          <CircularProgress size={40} />
        </Box>
      ) : (
        <Typography variant="h3" sx={{ color, fontWeight: 'bold' }}>
          {value !== null ? value.toLocaleString() : '-'}
        </Typography>
      )}
    </Paper>
  );
};
