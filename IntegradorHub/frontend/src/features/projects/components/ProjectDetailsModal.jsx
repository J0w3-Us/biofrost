import { useState, useEffect } from 'react';
import { X, UserPlus, Trash2, ExternalLink, Calendar, BookOpen, Hash, Users, Activity } from 'lucide-react';
import { motion } from 'framer-motion';
import { useAuth } from '../../auth/hooks/useAuth';
import api from '../../../lib/axios';
import { EvaluationPanel } from '../../evaluations/components/EvaluationPanel';
import { CanvasEditor } from './CanvasEditor';

export function ProjectDetailsModal({ project: initialProject, onClose, onUpdate }) {
    const { userData } = useAuth();
    // Helper to normalize keys of an object to camelCase
    const normalizeProjectData = (data) => {
        if (!data) return null;
        const normalized = {};
        Object.keys(data).forEach(key => {
            const camelKey = key.charAt(0).toLowerCase() + key.slice(1);
            normalized[camelKey] = data[key];
        });

        // Specific field mapping if needed (e.g. if backend sends weird names)
        // Ensure arrays are initialized
        if (!normalized.members) normalized.members = [];
        if (!normalized.miembrosIds) normalized.miembrosIds = [];

        return normalized;
    };

    const [project, setProject] = useState(() => normalizeProjectData(initialProject));
    const [activeTab, setActiveTab] = useState('docs'); // 'docs' | 'eval' | 'settings'
    const [newMemberEmail, setNewMemberEmail] = useState('');
    const [loading, setLoading] = useState(false);
    const [fetchingDetails, setFetchingDetails] = useState(true);
    const [error, setError] = useState('');
    const [editTitle, setEditTitle] = useState(initialProject.titulo || '');
    const [isDeleting, setIsDeleting] = useState(false);

    const isLeader = userData?.userId === project?.liderId;

    useEffect(() => {
        fetchDetails();
    }, []);

    const fetchDetails = async () => {
        try {
            const response = await api.get(`/api/projects/${initialProject.id}`);
            let projectData = response.data;

            // Normalize canvas/canvasBlocks if needed
            if (!projectData.canvas) projectData.canvas = projectData.canvasBlocks || [];

            setProject(normalizeProjectData(projectData));
            setEditTitle(projectData.titulo);
        } catch (err) {
            console.error('Error fetching details:', err);
        } finally {
            setFetchingDetails(false);
        }
    };

    const handleAddMember = async (e) => {
        e.preventDefault();
        if (!newMemberEmail) return;

        setLoading(true);
        setError('');

        try {
            await api.post(`/api/projects/${project.id}/members`, {
                leaderId: userData.userId,
                emailOrMatricula: newMemberEmail
            });
            setNewMemberEmail('');
            await fetchDetails();
            onUpdate?.();
        } catch (err) {
            console.error('Error adding member:', err);
            setError(err.response?.data?.message || 'Error al agregar miembro');
        } finally {
            setLoading(false);
        }
    };

    const handleRemoveMember = async (memberId) => {
        if (!confirm('¿Estás seguro de eliminar a este miembro?')) return;

        setLoading(true);
        try {
            await api.delete(`/api/projects/${project.id}/members/${memberId}?requestingUserId=${userData.userId}`);
            await fetchDetails();
            onUpdate?.();
        } catch (err) {
            console.error('Error removing member:', err);
            setError(err.response?.data?.message || 'Error al eliminar miembro');
        } finally {
            setLoading(false);
        }
    };

    const handleVisibilityToggle = async () => {
        const newStatus = !project.esPublico;
        // Optimistic UI update
        setProject(prev => ({ ...prev, esPublico: newStatus }));

        try {
            await api.put(`/api/projects/${project.id}`, {
                titulo: project.titulo,
                videoUrl: project.videoUrl,
                canvasBlocks: project.canvasBlocks || project.canvas, // Send current blocks to avoid data loss
                esPublico: newStatus
            });
            await onUpdate?.(); // Refresh list to reflect changes
        } catch (err) {
            console.error('Error updating visibility:', err);
            // Revert on error
            setProject(prev => ({ ...prev, esPublico: !newStatus }));
            alert('Error al cambiar la visibilidad del proyecto');
        }
    };

    const handleUpdateTitle = async () => {
        if (!editTitle || editTitle === project.titulo) return;

        try {
            await api.put(`/api/projects/${project.id}`, {
                titulo: editTitle,
                videoUrl: project.videoUrl,
                canvasBlocks: project.canvasBlocks || project.canvas,
                esPublico: project.esPublico
            });
            setProject(prev => ({ ...prev, titulo: editTitle }));
            await onUpdate?.();
            alert('Título actualizado correctamente');
        } catch (err) {
            console.error('Error updating title:', err);
            alert('Error al actualizar el título');
        }
    };

    const handleDeleteProject = async () => {
        if (!confirm('PELIGRO: ¿Estás seguro de eliminar este proyecto permanentemente? Esta acción es irreversible y liberará a todos los miembros.')) return;
        if (!confirm('CONFIRMACIÓN FINAL: Escribe "ELIMINAR" para confirmar.')) return; // Simplified double confirm for now

        setIsDeleting(true);
        try {
            await api.delete(`/api/projects/${project.id}?requestingUserId=${userData.userId}`);
            onUpdate?.();
            onClose(); // Close modal on success
        } catch (err) {
            console.error('Error deleting project:', err);
            alert('Error al eliminar el proyecto: ' + (err.response?.data?.message || err.message));
        } finally {
            setIsDeleting(false);
        }
    };

    if (!project) return <div>Cargando...</div>;

    return (
        <div className="flex flex-col h-full bg-[#F0F0F3] p-6 lg:p-8">
            {/* Header */}
            <div className="flex items-start justify-between mb-8 shrink-0">
                <div>
                    <div className="flex items-center gap-3 mb-2">
                        <span className={`px-4 py-1.5 rounded-full text-xs font-bold uppercase tracking-wider neu-pressed flex items-center gap-1 ${project.estado === 'Activo' ? 'text-blue-600' : 'text-gray-500'
                            }`}>
                            <Activity size={12} />
                            {project.estado}
                        </span>
                        <span className="px-4 py-1.5 rounded-full text-xs font-bold uppercase tracking-wider neu-pressed text-gray-500 flex items-center gap-1">
                            <BookOpen size={12} />
                            {project.materia}
                        </span>

                        {/* Public/Private Toggle */}
                        {isLeader && (
                            <button
                                onClick={handleVisibilityToggle}
                                className={`px-4 py-1.5 rounded-full text-xs font-bold uppercase tracking-wider transition-all flex items-center gap-1 ${project.esPublico
                                    ? 'bg-green-100 text-green-700 border border-green-200'
                                    : 'bg-gray-100 text-gray-500 border border-gray-200'
                                    }`}
                                title={project.esPublico ? 'Público: Visible en la galería' : 'Privado: Solo visible para el equipo'}
                            >
                                {project.esPublico ? '🌍 Público' : '🔒 Privado'}
                            </button>
                        )}
                    </div>
                    <h2 className="text-3xl font-bold text-gray-800 tracking-tight">{project.titulo}</h2>
                </div>
                <button
                    onClick={onClose}
                    className="neu-icon-btn w-12 h-12 bg-[#F0F0F3] flex items-center justify-center text-gray-500 hover:text-red-500 transition-colors"
                >
                    <X size={24} />
                </button>
            </div>

            {/* Master-Detail Layout */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8 flex-1 overflow-y-auto lg:overflow-hidden">

                {/* Left Column: Metadata & Team (Scrollable) */}
                <div className="lg:col-span-1 space-y-6 overflow-y-auto pr-2 custom-scrollbar lg:h-full">
                    {/* Info Card */}
                    <div className="neu-flat rounded-3xl p-6">
                        <h3 className="text-lg font-bold text-gray-700 mb-4 flex items-center gap-2">
                            <Hash size={18} className="text-blue-500" /> Detalles
                        </h3>
                        <div className="space-y-4">
                            <div className="flex items-center justify-between p-3 rounded-2xl bg-gray-50/50">
                                <span className="text-sm text-gray-500 font-medium flex items-center gap-2">
                                    <Calendar size={16} /> Fecha
                                </span>
                                <span className="text-sm font-bold text-gray-800">
                                    {(() => {
                                        if (!project.createdAt) return 'N/A';
                                        if (typeof project.createdAt === 'object' && project.createdAt.seconds) {
                                            return new Date(project.createdAt.seconds * 1000).toLocaleDateString();
                                        }
                                        const date = new Date(project.createdAt);
                                        return isNaN(date.getTime()) ? 'Pendiente' : date.toLocaleDateString();
                                    })()}
                                </span>
                            </div>
                            <div className="flex items-center justify-between p-3 rounded-2xl bg-gray-50/50">
                                <span className="text-sm text-gray-500 font-medium">Ciclo</span>
                                <span className="text-sm font-bold text-gray-800">{project.ciclo}</span>
                            </div>
                        </div>
                    </div>

                    {/* Team Card */}
                    <div className="neu-flat rounded-3xl p-6">
                        <h3 className="text-lg font-bold text-gray-700 mb-4 flex items-center gap-2">
                            <Users size={18} className="text-blue-500" />
                            Squad ({project.miembrosIds?.length || 0}/5)
                        </h3>

                        {/* Add Member */}
                        {isLeader && (
                            <form onSubmit={handleAddMember} className="mb-6">
                                <div className="neu-pressed rounded-2xl p-2 flex items-center gap-2">
                                    <input
                                        type="text"
                                        value={newMemberEmail}
                                        onChange={(e) => setNewMemberEmail(e.target.value)}
                                        placeholder="Matrícula..."
                                        className="bg-transparent flex-1 px-2 outline-none text-sm font-medium text-gray-700 placeholder-gray-400"
                                        disabled={loading}
                                    />
                                    <button
                                        type="submit"
                                        disabled={loading || !newMemberEmail}
                                        className="w-8 h-8 rounded-xl bg-blue-500 text-white flex items-center justify-center shadow-lg hover:scale-105 active:scale-95 transition-transform disabled:opacity-50"
                                    >
                                        <UserPlus size={16} />
                                    </button>
                                </div>
                                {error && <p className="text-xs text-red-500 mt-2 ml-2 font-medium">{error}</p>}
                            </form>
                        )}

                        {/* Members List */}
                        <div className="space-y-3">
                            {fetchingDetails ? (
                                <div className="space-y-3">
                                    {[1, 2, 3].map(i => <div key={i} className="h-14 bg-gray-200 rounded-2xl animate-pulse" />)}
                                </div>
                            ) : (
                                (project.members || []).length > 0 ? (
                                    (project.members || []).map((member, idx) => (
                                        <motion.div
                                            key={member.id || idx}
                                            initial={{ opacity: 0, y: 10 }}
                                            animate={{ opacity: 1, y: 0 }}
                                            transition={{ delay: idx * 0.1 }}
                                            className="neu-flat p-3 rounded-2xl flex items-center justify-between group"
                                        >
                                            <div className="flex items-center gap-3">
                                                <div className="w-10 h-10 rounded-full neu-pressed flex items-center justify-center border-2 border-[#F0F0F3] overflow-hidden bg-white text-gray-700">
                                                    <span className="text-sm font-bold">{(member.nombre || 'U').charAt(0)}</span>
                                                </div>
                                                <div>
                                                    <p className="text-sm font-bold text-gray-800 line-clamp-1">
                                                        {(member.nombre && member.nombre !== 'Usuario') ? member.nombre : (member.email || 'Miembro')}
                                                    </p>
                                                    <p className="text-[10px] uppercase font-bold text-gray-400">{member.rol || 'Miembro'}</p>
                                                </div>
                                            </div>

                                            {member.id === project.liderId ? (
                                                <span className="text-[10px] font-bold bg-blue-100 text-blue-600 px-2 py-1 rounded-full">Líder</span>
                                            ) : (
                                                (isLeader || userData?.userId === member.id) && (
                                                    <button
                                                        onClick={() => handleRemoveMember(member.id)}
                                                        className="p-2 text-gray-400 hover:text-red-500 transition-colors opacity-0 group-hover:opacity-100"
                                                    >
                                                        <Trash2 size={14} />
                                                    </button>
                                                )
                                            )}
                                        </motion.div>
                                    ))
                                ) : (
                                    <p className="text-sm text-gray-400 text-center py-4">No hay miembros aún.</p>
                                )
                            )}
                        </div>
                    </div>
                </div>

                {/* Right Column: Content */}
                <div className="lg:col-span-2 flex flex-col gap-6 lg:overflow-hidden">

                    {/* Tabs & Action */}
                    <div className="flex justify-between items-center bg-[#F0F0F3] z-10">
                        {/* Tabs */}
                        <div className="bg-gray-200/50 p-1 rounded-2xl inline-flex overflow-x-auto">
                            <button
                                onClick={() => setActiveTab('docs')}
                                className={`px-6 py-2 rounded-xl text-sm font-bold transition-all ${activeTab === 'docs'
                                    ? 'bg-white text-blue-600 shadow-sm'
                                    : 'text-gray-500 hover:text-gray-700'
                                    }`}
                            >
                                Documentación
                            </button>
                            <button
                                onClick={() => setActiveTab('eval')}
                                className={`px-6 py-2 rounded-xl text-sm font-bold transition-all ${activeTab === 'eval'
                                    ? 'bg-white text-blue-600 shadow-sm'
                                    : 'text-gray-500 hover:text-gray-700'
                                    }`}
                            >
                                Evaluación
                            </button>
                            {isLeader && (
                                <button
                                    onClick={() => setActiveTab('settings')}
                                    className={`px-6 py-2 rounded-xl text-sm font-bold transition-all ${activeTab === 'settings'
                                        ? 'bg-white text-blue-600 shadow-sm'
                                        : 'text-gray-500 hover:text-gray-700'
                                        }`}
                                >
                                    Ajustes
                                </button>
                            )}
                        </div>

                        {/* Edit Button (only visible in docs tab for members/leader) */}
                        <div className="flex gap-2">
                            {(isLeader || (project.members || []).some(m => m.id === userData.userId)) && activeTab === 'docs' && (
                                <button
                                    onClick={() => window.open(`/project/${project.id}/editor`, '_self')}
                                    className="neu-flat px-4 py-2 rounded-xl font-bold text-sm text-gray-700 hover:text-blue-600 active:neu-pressed transition-all flex items-center justify-center gap-2"
                                >
                                    <ExternalLink size={16} />
                                    Editar
                                </button>
                            )}
                        </div>
                    </div>

                    {/* Content Panel */}
                    <div className="neu-flat rounded-3xl p-6 flex-1 lg:overflow-auto custom-scrollbar relative bg-white">
                        {activeTab === 'docs' && (
                            <div className="h-full overflow-y-auto w-full">
                                {fetchingDetails ? (
                                    <div className="space-y-4">
                                        <div className="h-4 bg-gray-100 rounded w-3/4 animate-pulse"></div>
                                        <div className="h-4 bg-gray-100 rounded w-1/2 animate-pulse"></div>
                                        <div className="h-4 bg-gray-100 rounded w-full animate-pulse"></div>
                                    </div>
                                ) : (
                                    <CanvasEditor
                                        project={project}
                                        readOnly={true}
                                    />
                                )}
                            </div>
                        )}

                        {activeTab === 'eval' && (
                            <>
                                <h3 className="text-xl font-bold text-gray-800 mb-6 flex items-center gap-2 sticky top-0 bg-white z-10 pb-4 border-b border-gray-100">
                                    <Activity size={24} className="text-blue-500" />
                                    Evaluación y Rúbrica
                                </h3>
                                <EvaluationPanel projectId={project.id} />
                            </>
                        )}

                        {activeTab === 'settings' && isLeader && (
                            <div className="space-y-8 animate-fadeIn">
                                <h3 className="text-xl font-bold text-gray-800 mb-6 flex items-center gap-2 sticky top-0 bg-white z-10 pb-4 border-b border-gray-100">
                                    <Hash size={24} className="text-blue-500" />
                                    Ajustes del Proyecto
                                </h3>

                                {/* Edit Title */}
                                <div className="space-y-3">
                                    <label className="text-sm font-bold text-gray-600">Título del Proyecto</label>
                                    <div className="flex gap-2">
                                        <input
                                            type="text"
                                            value={editTitle}
                                            onChange={(e) => setEditTitle(e.target.value)}
                                            className="flex-1 px-4 py-3 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-blue-100 focus:border-blue-400 outline-none transition-all"
                                        />
                                        <button
                                            onClick={handleUpdateTitle}
                                            disabled={!editTitle || editTitle === project.titulo}
                                            className="px-4 py-2 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                                        >
                                            Guardar
                                        </button>
                                    </div>
                                </div>

                                {/* Visibility Toggle */}
                                <div className="space-y-3">
                                    <label className="text-sm font-bold text-gray-600">Visibilidad</label>
                                    <div className="flex items-center justify-between p-4 bg-gray-50 rounded-2xl border border-gray-100">
                                        <div>
                                            <p className="font-bold text-gray-800">{project.esPublico ? 'Público' : 'Privado'}</p>
                                            <p className="text-xs text-gray-500 mt-1">
                                                {project.esPublico
                                                    ? 'Visible para todos en la galería de proyectos.'
                                                    : 'Solo visible para los miembros del equipo y profesores.'}
                                            </p>
                                        </div>
                                        <button
                                            onClick={handleVisibilityToggle}
                                            className={`px-6 py-2 rounded-xl text-sm font-bold transition-all ${project.esPublico
                                                ? 'bg-green-100 text-green-700 border border-green-200'
                                                : 'bg-gray-200 text-gray-600 border border-gray-300'
                                                }`}
                                        >
                                            {project.esPublico ? 'Hacer Privado' : 'Hacer Público'}
                                        </button>
                                    </div>
                                </div>

                                {/* Danger Zone */}
                                <div className="pt-8 mt-8 border-t border-red-100">
                                    <h4 className="text-red-600 font-bold mb-4 flex items-center gap-2">
                                        <Trash2 size={18} /> Zona de Peligro
                                    </h4>
                                    <div className="p-4 bg-red-50 border border-red-100 rounded-2xl flex items-center justify-between">
                                        <div>
                                            <p className="font-bold text-red-700">Eliminar Proyecto</p>
                                            <p className="text-xs text-red-500/80 mt-1 max-w-sm">
                                                Esta acción es irreversible. Eliminará todo el contenido, historial y liberará a todos los miembros del equipo.
                                            </p>
                                        </div>
                                        <button
                                            onClick={handleDeleteProject}
                                            disabled={isDeleting}
                                            className="px-4 py-2 bg-white border-2 border-red-100 text-red-600 rounded-xl font-bold hover:bg-red-600 hover:text-white transition-all disabled:opacity-50"
                                        >
                                            {isDeleting ? 'Eliminando...' : 'Eliminar Definitivamente'}
                                        </button>
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}
