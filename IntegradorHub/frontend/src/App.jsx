import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './features/auth/hooks/useAuth';
import { GroupSelector } from './features/auth/components/GroupSelector';
import { DashboardLayout } from './features/dashboard/components/DashboardLayout';
import { DashboardPage } from './features/dashboard/pages/DashboardPage';
import { ProjectsPage } from './features/projects/pages/ProjectsPage';
import { TeamPage } from './features/dashboard/pages/TeamPage';
import { CalendarPage } from './features/dashboard/pages/CalendarPage';
import { ProfilePage } from './features/profile/pages/ProfilePage';
import { ProjectEditorPage } from './features/projects/pages/ProjectEditorPage';
import { ShowcasePage } from './features/public/pages/ShowcasePage';
import { RankingPage } from './features/public/pages/RankingPage';
import { AdminPanel } from './features/admin/pages/AdminPanel';
import MateriasPanel from './features/admin/pages/MateriasPanel';
import StudentsPanel from './features/admin/pages/StudentsPanel';
import TeachersPanel from './features/admin/pages/TeachersPanel';
import CarrerasPanel from './features/admin/pages/CarrerasPanel';
import { LoginPage } from './features/auth/pages/LoginPage';
import { RoleGuard } from './features/auth/components/RoleGuard';
import { EvaluationsPage } from './features/evaluations/pages/EvaluationsPage';
import './index.css';

// Componente de ruta protegida
function ProtectedRoute({ children }) {
  const { isAuthenticated, loading } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="w-8 h-8 border-2 border-gray-400 border-t-gray-900 rounded-full animate-spin"></div>
      </div>
    );
  }

  return isAuthenticated ? children : <Navigate to="/login" replace />;
}

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          {/* Landing page es el Login */}
          <Route path="/" element={<Navigate to="/login" replace />} />
          <Route path="/login" element={<LoginPage />} />

          {/* Layout Principal con Sidebar */}
          <Route element={
            <ProtectedRoute>
              <DashboardLayout />
            </ProtectedRoute>
          }>
            <Route path="/dashboard" element={<DashboardPage />} />
            <Route path="/projects" element={<ProjectsPage />} />
            <Route path="/showcase" element={<ShowcasePage />} />
            <Route path="/ranking" element={<RankingPage />} />
            <Route element={<RoleGuard allowedRoles={['Alumno', 'Docente']} />}>
              <Route path="/team" element={<TeamPage />} />
              <Route path="/evaluations" element={<EvaluationsPage />} />
            </Route>
            <Route path="/calendar" element={<CalendarPage />} />
            <Route path="/profile" element={<ProfilePage />} />
          </Route>

          <Route
            path="/project/:id/editor"
            element={
              <ProtectedRoute>
                <ProjectEditorPage />
              </ProtectedRoute>
            }
          />
          <Route
            path="/setup"
            element={
              <ProtectedRoute>
                <GroupSelector />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin"
            element={
              <ProtectedRoute>
                <AdminPanel />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/materias"
            element={
              <ProtectedRoute>
                <MateriasPanel />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/students"
            element={
              <ProtectedRoute>
                <StudentsPanel />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/teachers"
            element={
              <ProtectedRoute>
                <TeachersPanel />
              </ProtectedRoute>
            }
          />
          <Route
            path="/admin/carreras"
            element={
              <ProtectedRoute>
                <CarrerasPanel />
              </ProtectedRoute>
            }
          />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;
