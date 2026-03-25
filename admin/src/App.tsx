import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { LoginPage } from './pages/LoginPage';
import { DashboardPage } from './pages/DashboardPage';
import { VoteListPage } from './pages/VoteListPage';
import { VoteDetailPage } from './pages/VoteDetailPage';
import { IdolListPage } from './pages/IdolListPage';
import { ExternalAppListPage } from './pages/ExternalAppListPage';
import { CommunityMonitorPage } from './pages/CommunityMonitorPage';
import { DMReportPage } from './pages/DMReportPage';
import { CollectionReportPage } from './pages/CollectionReportPage';
import { BlockReportPage } from './pages/BlockReportPage';
import { UserListPage } from './pages/UserListPage';
import { AdminLogPage } from './pages/AdminLogPage';
import { RewardSettingsPage } from './pages/RewardSettingsPage';
import { PushNotificationPage } from './pages/PushNotificationPage';
import { AppLayout } from './components/layout/AppLayout';
import { PrivateRoute } from './components/layout/PrivateRoute';

const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
});

function AppRoutes() {
  const { user, loading } = useAuth();

  if (loading) {
    return null; // or a loading spinner
  }

  return (
    <Routes>
      <Route
        path="/login"
        element={
          user ? <Navigate to="/" replace /> : <LoginPage />
        }
      />
      <Route
        path="/"
        element={
          <PrivateRoute>
            <AppLayout>
              <DashboardPage />
            </AppLayout>
          </PrivateRoute>
        }
      />
      <Route
        path="/votes"
        element={
          <PrivateRoute>
            <AppLayout>
              <VoteListPage />
            </AppLayout>
          </PrivateRoute>
        }
      />
      <Route
        path="/votes/:voteId"
        element={
          <PrivateRoute>
            <AppLayout>
              <VoteDetailPage />
            </AppLayout>
          </PrivateRoute>
        }
      />
      <Route
        path="/idols"
        element={
          <PrivateRoute>
            <AppLayout>
              <IdolListPage />
            </AppLayout>
          </PrivateRoute>
        }
      />
      <Route
        path="/apps"
        element={
          <PrivateRoute>
            <AppLayout>
              <ExternalAppListPage />
            </AppLayout>
          </PrivateRoute>
        }
      />
      <Route
        path="/community"
        element={
          <PrivateRoute>
            <AppLayout>
              <CommunityMonitorPage />
            </AppLayout>
          </PrivateRoute>
        }
      />
      <Route
        path="/dm-reports"
        element={
          <PrivateRoute>
            <AppLayout>
              <DMReportPage />
            </AppLayout>
          </PrivateRoute>
        }
      />
      <Route
        path="/collection-reports"
        element={
          <PrivateRoute>
            <AppLayout>
              <CollectionReportPage />
            </AppLayout>
          </PrivateRoute>
        }
      />
      <Route
        path="/block-reports"
        element={
          <PrivateRoute>
            <AppLayout>
              <BlockReportPage />
            </AppLayout>
          </PrivateRoute>
        }
      />
      <Route
        path="/users"
        element={
          <PrivateRoute>
            <AppLayout>
              <UserListPage />
            </AppLayout>
          </PrivateRoute>
        }
      />
      <Route
        path="/logs"
        element={
          <PrivateRoute>
            <AppLayout>
              <AdminLogPage />
            </AppLayout>
          </PrivateRoute>
        }
      />
      <Route
        path="/reward-settings"
        element={
          <PrivateRoute>
            <AppLayout>
              <RewardSettingsPage />
            </AppLayout>
          </PrivateRoute>
        }
      />
      <Route
        path="/push-notifications"
        element={
          <PrivateRoute>
            <AppLayout>
              <PushNotificationPage />
            </AppLayout>
          </PrivateRoute>
        }
      />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

function App() {
  return (
    <ThemeProvider theme={theme}>
      <AuthProvider>
        <Router>
          <AppRoutes />
        </Router>
      </AuthProvider>
    </ThemeProvider>
  );
}

export default App;
