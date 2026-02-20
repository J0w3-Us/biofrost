import { useState, useEffect } from 'react';
import { Star, Send, MessageSquare, Eye, EyeOff } from 'lucide-react';
import { useAuth } from '../../auth/hooks/useAuth';
import api from '../../../lib/axios';

export function EvaluationPanel({ projectId }) {
    const { userData } = useAuth();
    const [evaluations, setEvaluations] = useState([]);
    const [project, setProject] = useState(null);
    const [loading, setLoading] = useState(true);
    const [submitting, setSubmitting] = useState(false);

    // Form state
    const [tipo, setTipo] = useState('sugerencia');
    const [contenido, setContenido] = useState('');
    const [calificacion, setCalificacion] = useState(80);

    const isDocente = userData?.rol === 'Docente';
    const isAdmin = userData?.rol === 'admin' || userData?.rol === 'SuperAdmin';
    const userId = userData?.userId;
    const userName = userData?.nombre;

    useEffect(() => {
        console.log('EvaluationPanel for Project:', projectId, 'as User:', userId);
        Promise.all([fetchEvaluations(), fetchProject()]);
    }, [projectId, userId]);

    const fetchProject = async () => {
        try {
            const response = await api.get(`/api/projects/${projectId}`);
            setProject(response.data);
        } catch (error) {
            console.error('Error fetching project:', error);
        }
    };

    const fetchEvaluations = async () => {
        try {
            const response = await api.get(`/api/evaluations/project/${projectId}`);
            // Sort by Date Descending
            const sorted = response.data.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
            setEvaluations(sorted);
        } catch (error) {
            console.error('Error fetching evaluations:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!contenido.trim()) return;

        setSubmitting(true);
        try {
            await api.post('/api/evaluations', {
                projectId,
                docenteId: userId,
                docenteNombre: userName,
                tipo,
                contenido,
                calificacion: tipo === 'oficial' ? calificacion : null
            });

            setContenido('');
            setCalificacion(80);
            setTipo('sugerencia'); // Reset to default
            fetchEvaluations();
            fetchProject(); // Refetch to update grade display if changed
        } catch (error) {
            console.error('Error creating evaluation:', error);
            alert('Error al crear la evaluación: ' + (error.response?.data || error.message));
        } finally {
            setSubmitting(false);
        }
    };

    const toggleVisibility = async (evaluation) => {
        try {
            await api.patch(`/api/evaluations/${evaluation.id}/visibility`, {
                userId: userId,
                esPublico: !evaluation.esPublico
            });
            // Update local state optimistic
            setEvaluations(prev => prev.map(e =>
                e.id === evaluation.id ? { ...e, esPublico: !e.esPublico } : e
            ));
        } catch (error) {
            console.error('Error updating visibility:', error);
            alert('Error al actualizar visibilidad');
        }
    };

    // Calculate Grade: Latest Official Grade
    const latestOfficial = evaluations.find(e => e.tipo === 'oficial' && e.calificacion !== null);
    const currentGrade = latestOfficial ? latestOfficial.calificacion : null;

    // Check Permissions for Official Grading
    const docente_id = project?.docenteId || project?.DocenteId;
    const isTitular = docente_id === userId;
    const canGradeOfficially = isDocente && (isTitular || isAdmin);

    console.log('Evaluation Permissions:', { isDocente, isTitular, isAdmin, canGradeOfficially, projectDocenteId: docente_id, currentUserId: userId });



    return (
        <div className="border-t border-gray-100 pt-6 mt-6">
            <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-gray-800 flex items-center gap-2">
                    <MessageSquare size={20} />
                    Evaluaciones
                </h3>
                {currentGrade !== null && (
                    <div className="flex items-center gap-2 bg-blue-50 px-3 py-1.5 rounded-full border border-blue-100 shadow-sm">
                        <Star size={16} className="text-yellow-500 fill-yellow-500" />
                        <span className="text-sm font-bold text-blue-700">{currentGrade}/100</span>
                        <span className="text-[10px] text-blue-400 font-medium uppercase tracking-wide ml-1">Actual</span>
                    </div>
                )}
            </div>

            {/* Lista de evaluaciones */}
            <div className="space-y-4 mb-6 max-h-96 overflow-y-auto pr-2 custom-scrollbar">
                {loading ? (
                    <div className="text-center py-4 text-gray-400">Cargando...</div>
                ) : evaluations.length === 0 ? (
                    <div className="text-center py-8 bg-gray-50 rounded-xl border border-dashed border-gray-200">
                        <MessageSquare className="mx-auto text-gray-300 mb-2" size={32} />
                        <p className="text-gray-400 text-sm">No hay evaluaciones aún</p>
                    </div>
                ) : (
                    evaluations.map(evaluation => (
                        <div
                            key={evaluation.id}
                            className={`group p-4 rounded-xl border transition-all ${evaluation.tipo === 'oficial'
                                ? 'bg-blue-50/50 border-blue-100 hover:border-blue-200'
                                : 'bg-gray-50/50 border-gray-100 hover:border-gray-200'
                                }`}
                        >
                            <div className="flex items-center justify-between mb-2">
                                <div className="flex items-center gap-2">
                                    <span className="font-bold text-gray-800 text-sm">{evaluation.docenteNombre}</span>

                                    <span className={`text-[10px] px-2 py-0.5 rounded-full font-bold uppercase tracking-wide ${evaluation.tipo === 'oficial'
                                        ? 'bg-blue-100 text-blue-700'
                                        : 'bg-gray-200 text-gray-600'
                                        }`}>
                                        {evaluation.tipo === 'oficial' ? 'Oficial' : 'Sugerencia'}
                                    </span>

                                    {/* Privacy Badge / Toggle */}
                                    {(isDocente || isAdmin) && (
                                        <button
                                            onClick={() => toggleVisibility(evaluation)}
                                            className="ml-2 p-1 text-gray-400 hover:text-indigo-600 rounded-full hover:bg-gray-200 transition-colors"
                                            title={evaluation.esPublico ? "Hacer Privado" : "Hacer Público"}
                                        >
                                            {evaluation.esPublico ? <Eye size={14} /> : <EyeOff size={14} />}
                                        </button>
                                    )}

                                    {/* Status Text for non-editors */}
                                    {!(isDocente || isAdmin) && !evaluation.esPublico && (
                                        <span className="text-[10px] bg-gray-200 text-gray-500 px-1.5 py-0.5 rounded flex items-center gap-1">
                                            <EyeOff size={10} /> Privado
                                        </span>
                                    )}
                                </div>

                                <div className="flex items-center gap-3">
                                    {evaluation.calificacion !== null && (
                                        <span className="text-sm font-black text-blue-600 bg-white px-2 py-0.5 rounded shadow-sm border border-blue-100">
                                            {evaluation.calificacion}/100
                                        </span>
                                    )}
                                    <span className="text-[10px] text-gray-400">
                                        {new Date(evaluation.createdAt).toLocaleDateString('es-MX', {
                                            day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit'
                                        })}
                                    </span>
                                </div>
                            </div>

                            <p className="text-gray-700 text-sm leading-relaxed whitespace-pre-wrap">
                                {evaluation.contenido}
                            </p>
                        </div>
                    ))
                )}
            </div>

            {/* Formulario para docentes */}
            {isDocente && (
                <form onSubmit={handleSubmit} className="bg-white border border-gray-200 rounded-xl p-4 space-y-4 shadow-sm">
                    {/* Header: Title and Type Switcher */}
                    <div className="flex items-center justify-between">
                        <span className="text-xs font-bold text-gray-500 uppercase tracking-wider">Nueva Evaluación</span>

                        {/* Only show Switcher if user can grade officially. Otherwise, force Sugerencia. */}
                        {canGradeOfficially ? (
                            <div className="flex bg-gray-100 p-1 rounded-lg">
                                <button
                                    type="button"
                                    onClick={() => setTipo('sugerencia')}
                                    className={`px-3 py-1 rounded-md text-xs font-medium transition-all ${tipo === 'sugerencia' ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-700'
                                        }`}
                                >
                                    Sugerencia
                                </button>
                                <button
                                    type="button"
                                    onClick={() => setTipo('oficial')}
                                    className={`px-3 py-1 rounded-md text-xs font-medium transition-all ${tipo === 'oficial' ? 'bg-blue-600 text-white shadow-sm' : 'text-gray-500 hover:text-gray-700'
                                        }`}
                                >
                                    Oficial
                                </button>
                            </div>
                        ) : (
                            <span className="text-[10px] bg-gray-100 text-gray-500 px-2 py-1 rounded font-medium">
                                Solo Sugerencias (No titular)
                            </span>
                        )}
                    </div>

                    {tipo === 'oficial' && canGradeOfficially && (
                        <div className="bg-blue-50 p-3 rounded-lg border border-blue-100">
                            <label className="flex items-center justify-between mb-2">
                                <span className="text-sm font-bold text-blue-800">Calificación Final</span>
                                <span className="text-xl font-black text-blue-600 bg-white px-3 py-0.5 rounded border border-blue-200">
                                    {calificacion}
                                </span>
                            </label>
                            <input
                                type="range"
                                min="0"
                                max="100"
                                value={calificacion}
                                onChange={e => setCalificacion(parseInt(e.target.value))}
                                className="w-full accent-blue-600 cursor-pointer"
                            />
                            <div className="flex justify-between text-[10px] text-blue-400 mt-1 font-medium">
                                <span>0</span>
                                <span>50</span>
                                <span>100</span>
                            </div>
                        </div>
                    )}

                    <div className="relative">
                        <textarea
                            value={contenido}
                            onChange={e => setContenido(e.target.value)}
                            placeholder={tipo === 'oficial' ? 'Justificación de la calificación...' : 'Escribe una sugerencia constructiva...'}
                            className="w-full p-3 border border-gray-200 rounded-lg resize-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm min-h-[100px]"
                        />
                    </div>

                    <button
                        type="submit"
                        disabled={!contenido.trim() || submitting}
                        className="w-full bg-gray-900 text-white py-2.5 rounded-lg font-bold text-sm hover:bg-gray-800 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2 transition-all shadow-md active:scale-[0.98]"
                    >
                        <Send size={16} />
                        {submitting ? 'Enviando...' : (tipo === 'oficial' ? 'Publicar Calificación' : 'Enviar Sugerencia')}
                    </button>
                </form>
            )}
        </div>
    );
}
