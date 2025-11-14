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
  CardActions,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  DialogContentText,
  TextField,
  Divider,
  IconButton,
  Collapse,
  List,
  ListItem,
  ListItemText,
} from '@mui/material';
import {
  Delete as DeleteIcon,
  Warning as WarningIcon,
  ExpandMore as ExpandMoreIcon,
  ExpandLess as ExpandLessIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import { format } from 'date-fns';
import {
  getReportedPosts,
  deleteCommunityPost,
  getCommunityStats,
} from '../services/communityService';
import { ReportedPost, CommunityStats } from '../types/community';

export const CommunityMonitorPage: React.FC = () => {
  const [posts, setPosts] = useState<ReportedPost[]>([]);
  const [stats, setStats] = useState<CommunityStats | null>(null);
  const [loading, setLoading] = useState(false);
  const [statsLoading, setStatsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [deletingPost, setDeletingPost] = useState<ReportedPost | null>(null);
  const [deleteReason, setDeleteReason] = useState('');
  const [deleteLoading, setDeleteLoading] = useState(false);
  const [expandedPosts, setExpandedPosts] = useState<Set<string>>(new Set());

  const loadPosts = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await getReportedPosts(50);
      setPosts(data);
    } catch (err) {
      console.error('Error loading reported posts:', err);
      setError('報告された投稿の取得に失敗しました');
    } finally {
      setLoading(false);
    }
  };

  const loadStats = async () => {
    try {
      setStatsLoading(true);
      const data = await getCommunityStats();
      setStats(data);
    } catch (err) {
      console.error('Error loading community stats:', err);
      // Don't show error for stats, it's not critical
    } finally {
      setStatsLoading(false);
    }
  };

  useEffect(() => {
    loadPosts();
    loadStats();
  }, []);

  const handleDeleteClick = (post: ReportedPost) => {
    setDeletingPost(post);
    setDeleteReason('');
  };

  const handleDeleteConfirm = async () => {
    if (!deletingPost) return;

    try {
      setDeleteLoading(true);
      await deleteCommunityPost(deletingPost.postId, deleteReason || undefined);
      setDeletingPost(null);
      setDeleteReason('');
      loadPosts();
      loadStats();
    } catch (err) {
      console.error('Error deleting post:', err);
      setError('投稿の削除に失敗しました');
    } finally {
      setDeleteLoading(false);
    }
  };

  const handleDeleteCancel = () => {
    setDeletingPost(null);
    setDeleteReason('');
  };

  const toggleExpand = (postId: string) => {
    const newExpanded = new Set(expandedPosts);
    if (newExpanded.has(postId)) {
      newExpanded.delete(postId);
    } else {
      newExpanded.add(postId);
    }
    setExpandedPosts(newExpanded);
  };

  const handleRefresh = () => {
    loadPosts();
    loadStats();
  };

  const getReasonLabel = (reason: string): string => {
    const reasonMap: { [key: string]: string } = {
      spam: 'スパム',
      harassment: '嫌がらせ・暴言',
      inappropriate: '不適切なコンテンツ',
      other: 'その他',
    };
    return reasonMap[reason] || reason;
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
          コミュニティ監視
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
      {statsLoading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', mb: 3 }}>
          <CircularProgress size={24} />
        </Box>
      ) : stats ? (
        <Box sx={{ display: 'flex', gap: 2, mb: 3, flexWrap: 'wrap' }}>
          <Box sx={{ flex: '1 1 200px', minWidth: 200 }}>
            <Paper sx={{ p: 2 }}>
              <Typography variant="subtitle2" color="text.secondary">
                総投稿数
              </Typography>
              <Typography variant="h4">{stats.totalPosts}</Typography>
            </Paper>
          </Box>
          <Box sx={{ flex: '1 1 200px', minWidth: 200 }}>
            <Paper sx={{ p: 2 }}>
              <Typography variant="subtitle2" color="text.secondary">
                報告された投稿
              </Typography>
              <Typography variant="h4" color="warning.main">
                {stats.reportedPosts}
              </Typography>
            </Paper>
          </Box>
          <Box sx={{ flex: '1 1 200px', minWidth: 200 }}>
            <Paper sx={{ p: 2 }}>
              <Typography variant="subtitle2" color="text.secondary">
                削除済み投稿
              </Typography>
              <Typography variant="h4" color="error.main">
                {stats.deletedPosts}
              </Typography>
            </Paper>
          </Box>
          <Box sx={{ flex: '1 1 200px', minWidth: 200 }}>
            <Paper sx={{ p: 2 }}>
              <Typography variant="subtitle2" color="text.secondary">
                アクティブユーザー
              </Typography>
              <Typography variant="h4" color="success.main">
                {stats.activeUsers}
              </Typography>
            </Paper>
          </Box>
        </Box>
      ) : null}

      <Typography variant="h6" gutterBottom>
        報告された投稿一覧
      </Typography>

      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
          <CircularProgress />
        </Box>
      ) : posts.length === 0 ? (
        <Alert severity="success">報告された投稿はありません</Alert>
      ) : (
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
          {posts.map((post) => {
            const isExpanded = expandedPosts.has(post.postId);
            return (
              <Card
                key={post.postId}
                sx={{
                  bgcolor: '#fff3cd',
                  border: '2px solid',
                  borderColor: 'warning.main',
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
                        <Typography variant="h6" color="warning.dark">
                          {post.reportCount}件の報告
                        </Typography>
                      </Box>
                      <Typography variant="body2" color="text.secondary">
                        投稿ID: {post.postId}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        ユーザーID: {post.userId}
                      </Typography>
                      {post.createdAt && (
                        <Typography variant="body2" color="text.secondary">
                          投稿日時: {format(new Date(post.createdAt), 'yyyy/MM/dd HH:mm')}
                        </Typography>
                      )}
                    </Box>
                    <IconButton
                      onClick={() => toggleExpand(post.postId)}
                      aria-label="詳細表示"
                    >
                      {isExpanded ? <ExpandLessIcon /> : <ExpandMoreIcon />}
                    </IconButton>
                  </Box>

                  <Paper sx={{ p: 2, bgcolor: 'white', mb: 2 }}>
                    <Typography variant="subtitle2" gutterBottom>
                      投稿内容:
                    </Typography>
                    <Typography variant="body1">{post.content}</Typography>
                  </Paper>

                  <Collapse in={isExpanded} timeout="auto" unmountOnExit>
                    <Divider sx={{ my: 2 }} />
                    <Typography variant="subtitle2" gutterBottom>
                      報告詳細:
                    </Typography>
                    <List dense>
                      {post.reports.map((report, index) => (
                        <ListItem key={report.reportId} sx={{ pl: 0 }}>
                          <ListItemText
                            primary={
                              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                <Chip
                                  label={getReasonLabel(report.reason)}
                                  size="small"
                                  color="error"
                                />
                                <Typography variant="body2" color="text.secondary">
                                  報告者: {report.reporterId}
                                </Typography>
                              </Box>
                            }
                            secondary={
                              report.reportedAt
                                ? format(new Date(report.reportedAt), 'yyyy/MM/dd HH:mm')
                                : '-'
                            }
                          />
                        </ListItem>
                      ))}
                    </List>
                  </Collapse>
                </CardContent>

                <CardActions sx={{ justifyContent: 'flex-end', px: 2, pb: 2 }}>
                  <Button
                    variant="contained"
                    color="error"
                    startIcon={<DeleteIcon />}
                    onClick={() => handleDeleteClick(post)}
                  >
                    投稿を削除
                  </Button>
                </CardActions>
              </Card>
            );
          })}
        </Box>
      )}

      {/* Delete Confirmation Dialog */}
      <Dialog
        open={!!deletingPost}
        onClose={handleDeleteCancel}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>投稿の削除</DialogTitle>
        <DialogContent>
          <DialogContentText sx={{ mb: 2 }}>
            この投稿を削除してもよろしいですか？この操作は取り消せません。
          </DialogContentText>

          {deletingPost && (
            <Paper sx={{ p: 2, bgcolor: 'grey.100', mb: 2 }}>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                投稿内容:
              </Typography>
              <Typography variant="body1">{deletingPost.content}</Typography>
            </Paper>
          )}

          <TextField
            label="削除理由（任意）"
            fullWidth
            multiline
            rows={3}
            value={deleteReason}
            onChange={(e) => setDeleteReason(e.target.value)}
            placeholder="例: スパム投稿のため削除"
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={handleDeleteCancel} disabled={deleteLoading}>
            キャンセル
          </Button>
          <Button
            onClick={handleDeleteConfirm}
            color="error"
            variant="contained"
            disabled={deleteLoading}
            startIcon={deleteLoading ? <CircularProgress size={20} /> : <DeleteIcon />}
          >
            {deleteLoading ? '削除中...' : '削除'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};
