import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Chip,
  CircularProgress,
  Alert,
} from '@mui/material';
import { getAdminLogs } from '../services/logService';
import { AdminLog } from '../types/log';

export const AdminLogPage: React.FC = () => {
  const [logs, setLogs] = useState<AdminLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadLogs();
  }, []);

  const loadLogs = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await getAdminLogs(100);
      setLogs(data);
    } catch (err) {
      console.error('Failed to load logs:', err);
      setError('ログの読み込みに失敗しました');
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (dateString: string | null) => {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleString('ja-JP', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  const getLogTypeLabel = (log: AdminLog) => {
    if (log.type === 'admin_action') {
      return log.actionType === 'suspend' ? 'アカウント停止' : 'アカウント復旧';
    }
    return log.transactionType === 'grant' ? 'ポイント付与' : 'ポイント減算';
  };

  const getLogTypeColor = (log: AdminLog): 'error' | 'success' | 'warning' | 'info' => {
    if (log.type === 'admin_action') {
      return log.actionType === 'suspend' ? 'error' : 'success';
    }
    return log.transactionType === 'grant' ? 'success' : 'warning';
  };

  const getLogDetails = (log: AdminLog) => {
    if (log.type === 'admin_action') {
      return log.reason || '-';
    }
    return `${log.points > 0 ? '+' : ''}${log.points}pt: ${log.reason}`;
  };

  const getLogDate = (log: AdminLog) => {
    return log.type === 'admin_action' ? log.performedAt : log.createdAt;
  };

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">システムログ</Typography>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>日時</TableCell>
              <TableCell>操作種別</TableCell>
              <TableCell>対象ユーザー</TableCell>
              <TableCell>詳細</TableCell>
              <TableCell>実行者</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {logs.map((log) => (
              <TableRow key={log.id}>
                <TableCell>{formatDate(getLogDate(log))}</TableCell>
                <TableCell>
                  <Chip
                    label={getLogTypeLabel(log)}
                    color={getLogTypeColor(log)}
                    size="small"
                  />
                </TableCell>
                <TableCell>
                  {log.type === 'admin_action'
                    ? log.targetUserEmail
                    : log.targetUserEmail}
                </TableCell>
                <TableCell>{getLogDetails(log)}</TableCell>
                <TableCell>
                  {log.type === 'admin_action'
                    ? log.performerEmail
                    : log.granterEmail}
                </TableCell>
              </TableRow>
            ))}
            {logs.length === 0 && !loading && (
              <TableRow>
                <TableCell colSpan={5} align="center">
                  ログがありません
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
};
