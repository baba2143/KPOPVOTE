import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { LoginPage } from './pages/LoginPage';
import { DashboardPage } from './pages/DashboardPage';
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
              <div>独自投票管理 (Week 2 Day 6-8で実装予定)</div>
            </AppLayout>
          </PrivateRoute>
        }
      />
      <Route
        path="/idols"
        element={
          <PrivateRoute>
            <AppLayout>
              <div>アイドル管理 (Week 2 Day 9-10で実装予定)</div>
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
              <div>ユーザー管理 (Week 3 Day 13-14で実装予定)</div>
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
