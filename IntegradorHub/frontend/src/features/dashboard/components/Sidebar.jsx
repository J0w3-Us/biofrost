import { NavLink } from 'react-router-dom';
import { FolderOpen, Users, Calendar, LogOut, LayoutDashboard, Rocket, Trophy } from 'lucide-react';
import { useAuth } from '../../auth/hooks/useAuth';

export function Sidebar() {
  const { userData, logout } = useAuth();

  const menuGroups = [
    {
      title: 'PRINCIPAL',
      items: [
        { label: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
        { label: 'Galería', path: '/showcase', icon: Rocket },
        { label: 'Ranking', path: '/ranking', icon: Trophy },
      ]
    },
    {
      title: 'GESTIÓN',
      items: [
        // Items exclusivos para Estudiantes (y Admins para debug)
        ...(['Alumno', 'Admin', 'admin', 'SuperAdmin'].includes(userData?.rol) ? [
          { label: 'Mis Proyectos', path: '/projects', icon: FolderOpen },
          { label: 'Mi Equipo', path: '/team', icon: Users },
        ] : []),

        // Items exclusivos para Docentes
        ...(userData?.rol === 'Docente' ? [
          { label: 'Evaluaciones', path: '/evaluations', icon: FolderOpen },
        ] : []),

        { label: 'Agenda', path: '/calendar', icon: Calendar },
      ]
    },
    ...(userData?.rol === 'admin' || userData?.rol === 'SuperAdmin' ? [{
      title: 'ADMINISTRACIÓN',
      items: [
        { label: 'Panel Admin', path: '/admin', icon: Users }
      ]
    }] : [])
  ];

  return (
    <aside className="w-72 h-full bg-white border-r border-gray-200 flex flex-col z-50 shrink-0 font-sans">
      {/* Logo Brand */}
      <div className="p-6 border-b border-gray-100">
        <h1 className="text-xl font-bold text-gray-900 leading-tight">
          Byfrost®
        </h1>
        <p className="text-xs text-gray-500 font-medium mt-1.5">Gestión de Proyectos</p>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-4 py-6 space-y-8 overflow-y-auto">
        {menuGroups.map((group, idx) => (
          <div key={idx}>
            <h3 className="px-4 mb-3 text-xs font-semibold text-gray-500 uppercase tracking-wider">
              {group.title}
            </h3>
            <div className="space-y-1">
              {group.items.map((item) => {
                const Icon = item.icon;
                return (
                  <NavLink
                    key={item.path}
                    to={item.path}
                    className={({ isActive }) => `
                      flex items-center gap-3 px-4 py-2.5 text-sm font-medium rounded-lg transition-all duration-200
                      ${isActive
                        ? 'bg-gray-100 text-gray-900'
                        : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
                      }
                    `}
                  >
                    {({ isActive }) => (
                      <>
                        <Icon size={18} className={isActive ? 'text-gray-900' : 'text-gray-400'} />
                        <span>{item.label}</span>
                      </>
                    )}
                  </NavLink>
                );
              })}
            </div>
          </div>
        ))}
      </nav>

      {/* Footer with User Info */}
      <NavLink
        to="/profile"
        className="p-4 m-4 bg-slate-900 rounded-2xl border border-slate-800 flex items-center gap-3 transition-all hover:bg-black group"
      >
        <div className="w-11 h-11 rounded-full bg-slate-800 flex items-center justify-center text-white font-bold text-sm border border-slate-700 shadow-lg group-hover:scale-105 transition-transform">
          {userData?.nombre?.charAt(0).toUpperCase() || 'U'}
        </div>
        <div className="flex-1 min-w-0">
          <p className="text-sm font-black text-white truncate tracking-tight">
            {(userData?.nombre && userData?.nombre !== 'Usuario')
              ? userData.nombre.replace(/^\d+\s+/, '').split(' ')[0]
              : (userData?.email ? userData.email.split('@')[0] : 'Usuario')}
          </p>
          <p className="text-[10px] text-slate-400 font-extrabold truncate uppercase tracking-widest mt-0.5">
            {userData?.rol || 'Alumno'}
          </p>
        </div>
      </NavLink>

      <div className="px-4 pb-4">
        <button
          onClick={logout}
          className="w-full flex items-center justify-center gap-2 text-xs font-bold text-slate-500 hover:text-slate-900 hover:bg-slate-100 py-2.5 rounded-xl transition-all duration-200"
        >
          <LogOut size={14} />
          Cerrar Sesión
        </button>
      </div>
    </aside>
  );
}
