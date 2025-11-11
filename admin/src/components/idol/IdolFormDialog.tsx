import React, { useState } from 'react';
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
import { createIdol, uploadIdolImage } from '../../services/idolService';
import { IdolCreateRequest } from '../../types/idol';

interface IdolFormDialogProps {
  open: boolean;
  onClose: () => void;
  onSuccess: () => void;
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
      id={`image-tabpanel-${index}`}
      aria-labelledby={`image-tab-${index}`}
      {...other}
    >
      {value === index && <Box sx={{ py: 2 }}>{children}</Box>}
    </div>
  );
}

export const IdolFormDialog: React.FC<IdolFormDialogProps> = ({
  open,
  onClose,
  onSuccess,
}) => {
  const [name, setName] = useState('');
  const [groupName, setGroupName] = useState('');
  const [imageUrl, setImageUrl] = useState('');
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [tabValue, setTabValue] = useState(0);
  const [loading, setLoading] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);

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
    if (!name.trim()) {
      setError('名前を入力してください');
      return false;
    }

    if (!groupName.trim()) {
      setError('グループ名を入力してください');
      return false;
    }

    return true;
  };

  const handleSubmit = async () => {
    if (!validate()) {
      return;
    }

    try {
      setLoading(true);
      setError(null);

      let finalImageUrl = '';

      // Upload image if file is selected
      if (tabValue === 1 && selectedFile) {
        setUploading(true);
        try {
          finalImageUrl = await uploadIdolImage(selectedFile);
        } catch (uploadError) {
          console.error('Upload error:', uploadError);
          setError('画像のアップロードに失敗しました');
          setUploading(false);
          setLoading(false);
          return;
        }
        setUploading(false);
      } else if (tabValue === 0 && imageUrl.trim()) {
        // Use URL directly
        finalImageUrl = imageUrl.trim();
      }

      const data: IdolCreateRequest = {
        name: name.trim(),
        groupName: groupName.trim(),
        imageUrl: finalImageUrl || undefined,
      };

      await createIdol(data);
      handleClose();
      onSuccess();
    } catch (err) {
      console.error('Error creating idol:', err);
      setError('アイドルの作成に失敗しました');
    } finally {
      setLoading(false);
      setUploading(false);
    }
  };

  const handleClose = () => {
    setName('');
    setGroupName('');
    setImageUrl('');
    setSelectedFile(null);
    setPreviewUrl(null);
    setTabValue(0);
    setError(null);
    onClose();
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle>新規アイドル追加</DialogTitle>
      <DialogContent>
        {error && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {error}
          </Alert>
        )}

        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 2 }}>
          <TextField
            id="idol-name"
            name="name"
            label="名前"
            fullWidth
            value={name}
            onChange={(e) => setName(e.target.value)}
            required
          />

          <TextField
            id="idol-group-name"
            name="groupName"
            label="グループ名"
            fullWidth
            value={groupName}
            onChange={(e) => setGroupName(e.target.value)}
            required
          />

          <Box>
            <Typography variant="subtitle2" sx={{ mb: 1 }}>
              画像設定（オプション）
            </Typography>
            <Tabs
              value={tabValue}
              onChange={handleTabChange}
              aria-label="image input method"
            >
              <Tab label="URL入力" id="image-tab-0" />
              <Tab label="ファイルアップロード" id="image-tab-1" />
            </Tabs>

            <TabPanel value={tabValue} index={0}>
              <TextField
                id="idol-image-url"
                name="imageUrl"
                label="画像URL"
                fullWidth
                value={imageUrl}
                onChange={(e) => setImageUrl(e.target.value)}
                placeholder="https://example.com/image.jpg"
              />
              {imageUrl && (
                <Box sx={{ mt: 2, display: 'flex', justifyContent: 'center' }}>
                  <Avatar
                    src={imageUrl}
                    alt="Preview"
                    sx={{ width: 100, height: 100 }}
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
                  accept="image/jpeg,image/png,image/webp"
                  onChange={handleFileSelect}
                />
              </Button>
              {selectedFile && (
                <Box sx={{ mt: 2 }}>
                  <Typography variant="body2" color="text.secondary">
                    選択されたファイル: {selectedFile.name}
                  </Typography>
                  {previewUrl && (
                    <Box
                      sx={{ mt: 1, display: 'flex', justifyContent: 'center' }}
                    >
                      <Avatar
                        src={previewUrl}
                        alt="Preview"
                        sx={{ width: 100, height: 100 }}
                      />
                    </Box>
                  )}
                </Box>
              )}
              <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
                対応形式: JPEG, PNG, WebP（最大5MB）
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
            loading ? <CircularProgress size={20} /> : uploading ? <CircularProgress size={20} /> : null
          }
        >
          {uploading ? 'アップロード中...' : loading ? '作成中...' : '作成'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};
