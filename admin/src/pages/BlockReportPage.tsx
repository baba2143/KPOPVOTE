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
  Block as BlockIcon,
  ExpandMore as ExpandMoreIcon,
  ExpandLess as ExpandLessIcon,
  Refresh as RefreshIcon,
  Person as PersonIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import { getBlockReports } from '../services/blockReportService';
import { BlockReport, BlockReportStats } from '../types/blockReport';

export const BlockReportPage: React.FC = () => {
  const [reports, setReports] = useState<BlockReport[]>([]);
  const [stats, setStats] = useState<BlockReportStats | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [expandedReports, setExpandedReports] = useState<Set<string>>(new Set());

  const loadReports = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await getBlockReports(50);
      setReports(data.reports);
      setStats(data.stats);
    } catch (err) {
      console.error('Error loading block reports:', err);
      setError('ブロックレポートの取得に失敗しました');
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
        <Box>
          <Typography variant="h4" component="h1">
            ブロックレポート管理
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
            Apple App Store Guideline 1.2 対応 - ユーザーブロック時の自動通報
          </Typography>
        </Box>
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
                総ブロック数
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
        ブロックレポート一覧
      </Typography>

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
          <CircularProgress />
        </Box>
      ) : reports.length === 0 ? (
        <Alert severity="success">ブロックレポートはありません</Alert>
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
                        <BlockIcon color="error" />
                        <Chip
                          icon={<PersonIcon />}
                          label="ユーザーブロック"
                          color="error"
                          size="small"
                          variant="outlined"
                        />
                        {getStatusChip(report.status)}
                      </Box>
                      <Typography variant="body2" color="text.secondary">
                        レポートID: {report.reportId}
                      </Typography>
                      {report.createdAt && (
                        <Typography variant="body2" color="text.secondary">
                          ブロック日時: {format(new Date(report.createdAt), 'yyyy/MM/dd HH:mm')}
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
                      理由:
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
                        <strong>ブロックしたユーザーID:</strong> {report.reporterId}
                      </Typography>
                      <Typography variant="body2">
                        <strong>ブロックされたユーザーID:</strong> {report.reportedUserId}
                      </Typography>
                      <Typography variant="body2">
                        <strong>タイプ:</strong> {report.type}
                      </Typography>
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
