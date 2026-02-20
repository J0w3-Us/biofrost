import { useState, useEffect } from 'react';
import { LayoutGrid, Plus, Search } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { useAuth } from '../../auth/hooks/useAuth';
import api from '../../../lib/axios';
import { ProjectCard } from '../components/ProjectCard';
import { CreateProjectForm } from '../components/CreateProjectForm';
import { ProjectDetailsModal } from '../components/ProjectDetailsModal';

export function ProjectsPage() {
    const { userData } = useAuth();
    const [projects, setProjects] = useState([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [showCreateModal, setShowCreateModal] = useState(false);
    const [selectedProject, setSelectedProject] = useState(null);

    useEffect(() => {
        if (userData?.grupoId) {
            fetchProjects();
        }
    }, [userData]);

    const fetchProjects = async () => {
        try {
            let projectsData = [];

            if (userData?.rol === 'Alumno') {
                // Alumno solo ve su proyecto activo
                try {
                    const response = await api.get(`/api/projects/my-project?userId=${userData.userId}`);
                    if (response.data) {
                        // Normalizar para consistencia (PascalCase a camelCase si aplica)
                        const p = response.data;
                        const normalized = {
                            id: p.id || p.Id,
                            titulo: p.titulo || p.Titulo,
                            materia: p.materia || p.Materia,
                            estado: p.estado || p.Estado,
                            stackTecnologico: p.stackTecnologico || p.StackTecnologico || [],
                            liderId: p.liderId || p.LiderId,
                            createdAt: p.createdAt || p.CreatedAt,
                            docenteId: p.docenteId || p.DocenteId
                        };
                        projectsData = [normalized];
                    }
                } catch (e) {
                    if (e.response?.status !== 404) console.error('Error fetching my project:', e);
                    projectsData = [];
                }
            } else {
                // Admin/Docente ve todo el grupo
                const response = await api.get(`/api/projects/group/${userData.grupoId}`);
                projectsData = response.data;
            }

            setProjects(projectsData);
        } catch (error) {
            console.error('Error fetching projects:', error);
            setProjects([]);
        } finally {
            setLoading(false);
        }
    };

    const filteredProjects = projects.filter(p =>
        p.titulo.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.liderNombre.toLowerCase().includes(searchQuery.toLowerCase())
    );

    return (
        <div className="space-y-6 h-full flex flex-col">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <h1 className="text-2xl font-bold text-gray-900">Mis Proyectos</h1>
                    <p className="text-gray-600">Administra y colabora en tus proyectos.</p>
                </div>
                {userData?.rol === 'Alumno' && (
                    <button
                        onClick={() => setShowCreateModal(true)}
                        className="bg-gray-900 text-white px-4 py-2.5 rounded-lg text-sm font-semibold flex items-center gap-2 shadow-sm hover:bg-gray-800 active:bg-gray-950 transition-all"
                    >
                        <Plus size={16} />
                        Nuevo Proyecto
                    </button>
                )}
            </div>

            {/* Search and Filters */}
            <div className="bg-white p-4 rounded-lg border border-gray-200 shadow-sm">
                <div className="relative">
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={18} />
                    <input
                        type="text"
                        placeholder="Buscar proyectos..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        className="w-full pl-10 pr-4 py-2.5 bg-gray-50 border-0 rounded-lg focus:ring-2 focus:ring-gray-200 focus:bg-white outline-none transition-all placeholder:text-gray-400"
                    />
                </div>
            </div>

            {/* Content */}
            <div className="flex-1 overflow-y-auto min-h-0">
                {loading ? (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {[1, 2, 3, 4, 5, 6].map(i => (
                            <div key={i} className="h-64 bg-gray-100 rounded-2xl animate-pulse" />
                        ))}
                    </div>
                ) : filteredProjects.length > 0 ? (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 pb-6">
                        {filteredProjects.map(project => (
                            <motion.div
                                key={project.id}
                                layoutId={project.id}
                                initial={{ opacity: 0, scale: 0.9 }}
                                animate={{ opacity: 1, scale: 1 }}
                                transition={{ duration: 0.2 }}
                            >
                                <ProjectCard
                                    project={project}
                                    onClick={() => setSelectedProject(project)}
                                />
                            </motion.div>
                        ))}
                    </div>
                ) : (
                    <div className="h-full flex flex-col items-center justify-center text-center p-8 bg-gray-50/50 rounded-2xl border-2 border-dashed border-gray-200">
                        <div className="w-16 h-16 bg-blue-50 text-blue-500 rounded-full flex items-center justify-center mb-4">
                            <LayoutGrid size={24} />
                        </div>
                        <h3 className="text-lg font-medium text-gray-900">No hay proyectos encontrados</h3>
                        <p className="text-gray-500 mt-1 mb-6">
                            {searchQuery ? 'Intenta con otros términos de búsqueda.' : 'Sé el primero en crear un proyecto increíble.'}
                        </p>
                        {userData?.rol === 'Alumno' && !searchQuery && (
                            <button
                                onClick={() => setShowCreateModal(true)}
                                className="text-blue-600 font-medium hover:underline"
                            >
                                Crear Proyecto Ahora
                            </button>
                        )}
                    </div>
                )}
            </div>

            {/* Modals */}
            <AnimatePresence>
                {showCreateModal && (
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        className="fixed inset-0 bg-white/60 backdrop-blur-xl z-50 flex items-center justify-center p-4"
                        onClick={() => setShowCreateModal(false)}
                    >
                        <motion.div
                            initial={{ scale: 0.95, opacity: 0, y: 10 }}
                            animate={{ scale: 1, opacity: 1, y: 0 }}
                            exit={{ scale: 0.95, opacity: 0, y: 10 }}
                            onClick={e => e.stopPropagation()}
                            className="bg-white w-full max-w-lg rounded-2xl shadow-2xl border border-gray-100 overflow-hidden max-h-[85vh] flex flex-col"
                        >
                            <CreateProjectForm
                                onClose={() => setShowCreateModal(false)}
                                onSuccess={() => {
                                    setShowCreateModal(false);
                                    fetchProjects();
                                }}
                            />
                        </motion.div>
                    </motion.div>
                )}

                {selectedProject && (
                    <motion.div
                        initial={{ opacity: 0 }}
                        animate={{ opacity: 1 }}
                        exit={{ opacity: 0 }}
                        className="fixed inset-0 bg-white/60 backdrop-blur-xl z-50 flex items-center justify-center p-4"
                        onClick={() => setSelectedProject(null)}
                    >
                        <motion.div
                            initial={{ scale: 0.95, opacity: 0, y: 10 }}
                            animate={{ scale: 1, opacity: 1, y: 0 }}
                            exit={{ scale: 0.95, opacity: 0, y: 10 }}
                            onClick={e => e.stopPropagation()}
                            className="bg-white w-full max-w-6xl rounded-2xl shadow-2xl border border-gray-100 overflow-hidden h-[85vh] flex flex-col"
                        >
                            <ProjectDetailsModal
                                project={selectedProject}
                                onClose={() => setSelectedProject(null)}
                                onUpdate={fetchProjects}
                            />
                        </motion.div>
                    </motion.div>
                )}
            </AnimatePresence>
        </div>
    );
}
