import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { LoginPage } from './pages/LoginPage';
import { DashboardPage } from './pages/DashboardPage';
import { VoteListPage } from './pages/VoteListPage';
import { VoteDetailPage } from './pages/VoteDetailPage';
import { IdolListPage } from './pages/IdolListPage';
import { UserListPage } from './pages/UserListPage';
import { AdminLogPage } from './pages/AdminLogPage';
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
              <div>外部アプリ管理 (Week 2 Day 9-10で実装予定)</div>
            </AppLayout>
          </PrivateRoute>
        }
      />
      <Route
        path="/community"
        element={
          <PrivateRoute>
            <AppLayout>
              <div>コミュニティ監視 (Week 3 Day 11-12で実装予定)</div>
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
