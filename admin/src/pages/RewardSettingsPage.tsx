/**
 * Reward Settings Management Page
 * 報酬設定管理ページ
 */

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
  IconButton,
  Chip,
  CircularProgress,
  Alert,
  Tooltip,
  TextField,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  FormControlLabel,
  Switch,
} from '@mui/material';
import {
  Edit as EditIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import {
  getRewardSettings,
  updateRewardSetting,
} from '../services/rewardService';
import { RewardSetting } from '../types/reward';

export const RewardSettingsPage: React.FC = () => {
  const [settings, setSettings] = useState<RewardSetting[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [selectedSetting, setSelectedSetting] = useState<RewardSetting | null>(null);
  const [editedPoints, setEditedPoints] = useState<number>(0);
  const [editedDescription, setEditedDescription] = useState<string>('');
  const [editedIsActive, setEditedIsActive] = useState<boolean>(true);
  const [updating, setUpdating] = useState(false);

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await getRewardSettings();
      setSettings(data);
    } catch (err) {
      console.error('Failed to load reward settings:', err);
      setError('報酬設定の読み込みに失敗しました');
    } finally {
      setLoading(false);
    }
  };

  const handleOpenEditDialog = (setting: RewardSetting) => {
    setSelectedSetting(setting);
    setEditedPoints(setting.basePoints);
    setEditedDescription(setting.description);
    setEditedIsActive(setting.isActive);
    setEditDialogOpen(true);
  };

  const handleCloseEditDialog = () => {
    setEditDialogOpen(false);
    setSelectedSetting(null);
  };

  const handleUpdateSetting = async () => {
    if (!selectedSetting) return;

    try {
      setUpdating(true);
      await updateRewardSetting({
        actionType: selectedSetting.actionType,
        basePoints: editedPoints,
        description: editedDescription,
        isActive: editedIsActive,
      });

      await loadSettings();
      handleCloseEditDialog();
    } catch (err) {
      console.error('Failed to update setting:', err);
      setError('報酬設定の更新に失敗しました');
    } finally {
      setUpdating(false);
    }
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
        <Typography variant="h4" component="h1">
          報酬設定管理
        </Typography>
        <Tooltip title="再読み込み">
          <IconButton onClick={loadSettings}>
            <RefreshIcon />
          </IconButton>
        </Tooltip>
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
              <TableCell>アクション種別</TableCell>
              <TableCell>説明</TableCell>
              <TableCell align="right">基本ポイント</TableCell>
              <TableCell align="center">有効</TableCell>
              <TableCell align="center">最終更新</TableCell>
              <TableCell align="center">操作</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {settings.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} align="center">
                  報酬設定がありません
                </TableCell>
              </TableRow>
            ) : (
              settings.map((setting) => (
                <TableRow key={setting.id}>
                  <TableCell>
                    <Typography variant="body2" fontWeight="bold">
                      {setting.actionType}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">{setting.description}</Typography>
                  </TableCell>
                  <TableCell align="right">
                    <Typography variant="body1" fontWeight="bold">
                      {setting.basePoints}P
                    </Typography>
                  </TableCell>
                  <TableCell align="center">
                    <Chip
                      label={setting.isActive ? '有効' : '無効'}
                      color={setting.isActive ? 'success' : 'default'}
                      size="small"
                    />
                  </TableCell>
                  <TableCell align="center">
                    <Typography variant="body2" color="text.secondary">
                      {new Date(setting.updatedAt).toLocaleString('ja-JP')}
                    </Typography>
                  </TableCell>
                  <TableCell align="center">
                    <Tooltip title="編集">
                      <IconButton
                        size="small"
                        onClick={() => handleOpenEditDialog(setting)}
                      >
                        <EditIcon />
                      </IconButton>
                    </Tooltip>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Edit Dialog */}
      <Dialog open={editDialogOpen} onClose={handleCloseEditDialog} maxWidth="sm" fullWidth>
        <DialogTitle>報酬設定の編集</DialogTitle>
        <DialogContent>
          {selectedSetting && (
            <Box sx={{ pt: 2 }}>
              <Typography variant="subtitle2" gutterBottom>
                アクション種別
              </Typography>
              <Typography variant="body1" fontWeight="bold" mb={2}>
                {selectedSetting.actionType}
              </Typography>

              <TextField
                label="説明"
                fullWidth
                value={editedDescription}
                onChange={(e) => setEditedDescription(e.target.value)}
                margin="normal"
                multiline
                rows={2}
              />

              <TextField
                label="基本ポイント"
                type="number"
                fullWidth
                value={editedPoints}
                onChange={(e) => setEditedPoints(Number(e.target.value))}
                margin="normal"
                inputProps={{ min: 0 }}
              />

              <FormControlLabel
                control={
                  <Switch
                    checked={editedIsActive}
                    onChange={(e) => setEditedIsActive(e.target.checked)}
                  />
                }
                label="有効化"
                sx={{ mt: 2 }}
              />
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseEditDialog}>キャンセル</Button>
          <Button
            onClick={handleUpdateSetting}
            variant="contained"
            disabled={updating}
          >
            {updating ? '更新中...' : '更新'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};
