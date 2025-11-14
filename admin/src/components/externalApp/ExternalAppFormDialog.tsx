import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  Box,
  Alert,
  CircularProgress,
  Tabs,
  Tab,
  Avatar,
  Typography,
} from '@mui/material';
import { CloudUpload as UploadIcon } from '@mui/icons-material';
import {
  createExternalApp,
  updateExternalApp,
  uploadAppIcon,
} from '../../services/externalAppService';
import {
  ExternalAppMaster,
  ExternalAppCreateRequest,
  ExternalAppUpdateRequest,
} from '../../types/externalApp';

interface ExternalAppFormDialogProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
  app?: ExternalAppMaster; // For edit mode
}

interface TabPanelProps {
  children?: React.ReactNode;
  index: number;
  value: number;
}

function TabPanel(props: TabPanelProps) {
  const { children, value, index, ...other } = props;

  return (
    <div
      role="tabpanel"
      hidden={value !== index}
      id={`icon-tabpanel-${index}`}
      aria-labelledby={`icon-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ py: 2 }}>{children}</Box>}
    </div>
  );
}

export const ExternalAppFormDialog: React.FC<ExternalAppFormDialogProps> = ({
  open,
  onClose,
  onSuccess,
  app,
}) => {
  const isEditMode = !!app;

  const [appName, setAppName] = useState('');
  const [appUrl, setAppUrl] = useState('');
  const [iconUrl, setIconUrl] = useState('');
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [tabValue, setTabValue] = useState(0);
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Initialize form for edit mode
  useEffect(() => {
    if (app) {
      setAppName(app.appName);
      setAppUrl(app.appUrl || '');
      setIconUrl(app.iconUrl || '');
    }
  }, [app]);

  const handleTabChange = (_event: React.SyntheticEvent, newValue: number) => {
    setTabValue(newValue);
    setError(null);
  };

  const handleFileSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      setSelectedFile(file);
      // Create preview URL
      const reader = new FileReader();
      reader.onloadend = () => {
        setPreviewUrl(reader.result as string);
      };
      reader.readAsDataURL(file);
      setError(null);
    }
  };

  const validate = (): boolean => {
    if (!appName.trim()) {
      setError('アプリ名を入力してください');
      return false;
    }

    if (appUrl.trim() && !isValidUrl(appUrl.trim())) {
      setError('有効なURLを入力してください');
      return false;
    }

    return true;
  };

  const isValidUrl = (url: string): boolean => {
    try {
      new URL(url);
      return true;
    } catch {
      return false;
    }
  };

  const handleSubmit = async () => {
    if (!validate()) {
      return;
    }

    try {
      setLoading(true);
      setError(null);

      let finalIconUrl = iconUrl;

      // Upload icon if file is selected
      if (tabValue === 1 && selectedFile) {
        setUploading(true);
        try {
          finalIconUrl = await uploadAppIcon(selectedFile);
        } catch (uploadError) {
          console.error('Upload error:', uploadError);
          setError('アイコンのアップロードに失敗しました');
          setUploading(false);
          setLoading(false);
          return;
        }
        setUploading(false);
      } else if (tabValue === 0 && iconUrl.trim()) {
        // Use URL directly
        finalIconUrl = iconUrl.trim();
      }

      if (isEditMode && app) {
        // Update mode
        const updateData: ExternalAppUpdateRequest = {
          appName: appName.trim(),
          appUrl: appUrl.trim() || undefined,
          iconUrl: finalIconUrl || undefined,
        };
        await updateExternalApp(app.appId, updateData);
      } else {
        // Create mode
        const createData: ExternalAppCreateRequest = {
          appName: appName.trim(),
          appUrl: appUrl.trim() || undefined,
          iconUrl: finalIconUrl || undefined,
        };
        await createExternalApp(createData);
      }

      handleClose();
      onSuccess();
    } catch (err) {
      console.error('Error saving external app:', err);
      setError(
        isEditMode
          ? '外部アプリの更新に失敗しました'
          : '外部アプリの作成に失敗しました'
      );
    } finally {
      setLoading(false);
      setUploading(false);
    }
  };

  const handleClose = () => {
    setAppName('');
    setAppUrl('');
    setIconUrl('');
    setSelectedFile(null);
    setPreviewUrl(null);
    setTabValue(0);
    setError(null);
    onClose();
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle>
        {isEditMode ? '外部アプリ編集' : '新規外部アプリ追加'}
      </DialogTitle>
      <DialogContent>
        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 2 }}>
          <TextField
            id="app-name"
            name="appName"
            label="アプリ名"
            fullWidth
            value={appName}
            onChange={(e) => setAppName(e.target.value)}
            required
            placeholder="例: IDOL CHAMP"
          />

          <TextField
            id="app-url"
            name="appUrl"
            label="アプリURL（オプション）"
            fullWidth
            value={appUrl}
            onChange={(e) => setAppUrl(e.target.value)}
            placeholder="https://example.com"
          />

          <Box>
            <Typography variant="subtitle2" sx={{ mb: 1 }}>
              アイコン画像（オプション）
            </Typography>
            <Tabs
              value={tabValue}
              onChange={handleTabChange}
              aria-label="icon input method"
            >
              <Tab label="URL入力" id="icon-tab-0" />
              <Tab label="ファイルアップロード" id="icon-tab-1" />
            </Tabs>

            <TabPanel value={tabValue} index={0}>
              <TextField
                id="icon-url"
                name="iconUrl"
                label="アイコンURL"
                fullWidth
                value={iconUrl}
                onChange={(e) => setIconUrl(e.target.value)}
                placeholder="https://example.com/icon.png"
              />
              {iconUrl && (
                <Box sx={{ mt: 2, display: 'flex', justifyContent: 'center' }}>
                  <Avatar
                    src={iconUrl}
                    alt="Icon Preview"
                    sx={{ width: 80, height: 80 }}
                    variant="rounded"
                  />
                </Box>
              )}
            </TabPanel>

            <TabPanel value={tabValue} index={1}>
              <Button
                component="label"
                variant="outlined"
                startIcon={<UploadIcon />}
                fullWidth
              >
                ファイルを選択
                <input
                  type="file"
                  hidden
                  accept="image/jpeg,image/png,image/webp,image/svg+xml"
                  onChange={handleFileSelect}
                />
              </Button>
              {selectedFile && (
                <Box sx={{ mt: 2 }}>
                  <Typography variant="body2" color="text.secondary">
                    選択されたファイル: {selectedFile.name}
                  </Typography>
                  {previewUrl && (
                    <Box sx={{ mt: 1, display: 'flex', justifyContent: 'center' }}>
                      <Avatar
                        src={previewUrl}
                        alt="Icon Preview"
                        sx={{ width: 80, height: 80 }}
                        variant="rounded"
                      />
                    </Box>
                  )}
                </Box>
              )}
              <Typography
                variant="caption"
                color="text.secondary"
                sx={{ mt: 1, display: 'block' }}
              >
                対応形式: JPEG, PNG, WebP, SVG（最大2MB）
              </Typography>
            </TabPanel>
          </Box>
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={handleClose} disabled={loading}>
          キャンセル
        </Button>
        <Button
          onClick={handleSubmit}
          variant="contained"
          disabled={loading}
          startIcon={
            loading ? (
              <CircularProgress size={20} />
            ) : uploading ? (
              <CircularProgress size={20} />
            ) : null
          }
        >
          {uploading
            ? 'アップロード中...'
            : loading
            ? isEditMode
              ? '更新中...'
              : '作成中...'
            : isEditMode
            ? '更新'
            : '作成'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};
