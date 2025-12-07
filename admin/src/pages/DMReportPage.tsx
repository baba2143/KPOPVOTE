import React, { useState, useEffect } from 'react';
import {
  Box,
  Button,
  Paper,
  Typography,
  CircularProgress,
  Alert,
  Card,
  CardContent,
  Chip,
  IconButton,
  Collapse,
  Divider,
} from '@mui/material';
import {
  Warning as WarningIcon,
  ExpandMore as ExpandMoreIcon,
  ExpandLess as ExpandLessIcon,
  Refresh as RefreshIcon,
  Message as MessageIcon,
  Person as PersonIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { getDMReports } from '../services/dmReportService';
import { DMReport, DMReportStats } from '../types/dmReport';

export const DMReportPage: React.FC = () => {
  const [reports, setReports] = useState<DMReport[]>([]);
  const [stats, setStats] = useState<DMReportStats | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [expandedReports, setExpandedReports] = useState<Set<string>>(new Set());

  const loadReports = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await getDMReports(50);
      setReports(data.reports);
      setStats(data.stats);
    } catch (err) {
      console.error('Error loading DM reports:', err);
      setError('DM通報の取得に失敗しました');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadReports();
  }, []);

  const toggleExpand = (reportId: string) => {
    const newExpanded = new Set(expandedReports);
    if (newExpanded.has(reportId)) {
      newExpanded.delete(reportId);
    } else {
      newExpanded.add(reportId);
    }
    setExpandedReports(newExpanded);
  };

  const handleRefresh = () => {
    loadReports();
  };

  const getStatusChip = (status: string) => {
    switch (status) {
      case 'pending':
        return <Chip label="未対応" color="warning" size="small" />;
      case 'reviewed':
        return <Chip label="確認済み" color="info" size="small" />;
      case 'resolved':
        return <Chip label="解決済み" color="success" size="small" />;
      default:
        return <Chip label={status} size="small" />;
    }
  };

  const getReportTypeChip = (type: string) => {
    if (type === 'message') {
      return (
        <Chip
          icon={<MessageIcon />}
          label="メッセージ通報"
          color="error"
          size="small"
          variant="outlined"
        />
      );
    }
    return (
      <Chip
        icon={<PersonIcon />}
        label="ユーザー通報"
        color="secondary"
        size="small"
        variant="outlined"
      />
    );
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
          DM通報管理
        </Typography>
        <Button
          variant="outlined"
          startIcon={<RefreshIcon />}
          onClick={handleRefresh}
          disabled={loading}
        >
          更新
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Statistics */}
      {stats && (
        <Box sx={{ display: 'flex', gap: 2, mb: 3, flexWrap: 'wrap' }}>
          <Box sx={{ flex: '1 1 200px', minWidth: 200 }}>
            <Paper sx={{ p: 2 }}>
              <Typography variant="subtitle2" color="text.secondary">
                総通報数
              </Typography>
              <Typography variant="h4">{stats.totalReports}</Typography>
            </Paper>
          </Box>
          <Box sx={{ flex: '1 1 200px', minWidth: 200 }}>
            <Paper sx={{ p: 2 }}>
              <Typography variant="subtitle2" color="text.secondary">
                未対応
              </Typography>
              <Typography variant="h4" color="warning.main">
                {stats.pendingReports}
              </Typography>
            </Paper>
          </Box>
          <Box sx={{ flex: '1 1 200px', minWidth: 200 }}>
            <Paper sx={{ p: 2 }}>
              <Typography variant="subtitle2" color="text.secondary">
                対応済み
              </Typography>
              <Typography variant="h4" color="success.main">
                {stats.reviewedReports}
              </Typography>
            </Paper>
          </Box>
        </Box>
      )}

      <Typography variant="h6" gutterBottom>
        通報一覧
      </Typography>

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
          <CircularProgress />
        </Box>
      ) : reports.length === 0 ? (
        <Alert severity="success">DM通報はありません</Alert>
      ) : (
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
          {reports.map((report) => {
            const isExpanded = expandedReports.has(report.reportId);
            return (
              <Card
                key={report.reportId}
                sx={{
                  bgcolor: report.status === 'pending' ? '#fff3cd' : '#f5f5f5',
                  border: '2px solid',
                  borderColor: report.status === 'pending' ? 'warning.main' : 'grey.300',
                }}
              >
                <CardContent>
                  <Box
                    sx={{
                      display: 'flex',
                      justifyContent: 'space-between',
                      alignItems: 'flex-start',
                      mb: 2,
                    }}
                  >
                    <Box>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                        <WarningIcon color="warning" />
                        {getReportTypeChip(report.reportType)}
                        {getStatusChip(report.status)}
                      </Box>
                      <Typography variant="body2" color="text.secondary">
                        通報ID: {report.reportId}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        会話ID: {report.conversationId}
                      </Typography>
                      {report.createdAt && (
                        <Typography variant="body2" color="text.secondary">
                          通報日時: {format(new Date(report.createdAt), 'yyyy/MM/dd HH:mm')}
                        </Typography>
                      )}
                    </Box>
                    <IconButton
                      onClick={() => toggleExpand(report.reportId)}
                      aria-label="詳細表示"
                    >
                      {isExpanded ? <ExpandLessIcon /> : <ExpandMoreIcon />}
                    </IconButton>
                  </Box>

                  <Paper sx={{ p: 2, bgcolor: 'white', mb: 2 }}>
                    <Typography variant="subtitle2" gutterBottom>
                      通報理由:
                    </Typography>
                    <Typography variant="body1">{report.reason}</Typography>
                  </Paper>

                  <Collapse in={isExpanded} timeout="auto" unmountOnExit>
                    <Divider sx={{ my: 2 }} />
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
                      <Typography variant="subtitle2" gutterBottom>
                        詳細情報:
                      </Typography>
                      <Typography variant="body2">
                        <strong>通報者ID:</strong> {report.reporterId}
                      </Typography>
                      <Typography variant="body2">
                        <strong>対象ユーザーID:</strong> {report.reporteeId}
                      </Typography>
                      {report.messageId && (
                        <Typography variant="body2">
                          <strong>メッセージID:</strong> {report.messageId}
                        </Typography>
                      )}
                      {report.messageContent && (
                        <Paper sx={{ p: 2, bgcolor: 'grey.100', mt: 1 }}>
                          <Typography variant="subtitle2" gutterBottom>
                            通報されたメッセージ内容:
                          </Typography>
                          <Typography variant="body2">{report.messageContent}</Typography>
                        </Paper>
                      )}
                    </Box>
                  </Collapse>
                </CardContent>
              </Card>
            );
          })}
        </Box>
      )}
    </Box>
  );
};
