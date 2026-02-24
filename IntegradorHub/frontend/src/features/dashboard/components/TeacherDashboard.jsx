import { motion } from 'framer-motion';
import { Users, CheckCircle, Clock } from 'lucide-react';
import { StatCard } from './StatCard';
import { ProjectCard } from '../../projects/components/ProjectCard';

export function TeacherDashboard({ userData, projects, groupName, searchQuery, onProjectClick }) {
    // Definir variantes de animación
    const containerVariants = {
        hidden: { opacity: 0 },
        visible: {
            opacity: 1,
            transition: { staggerChildren: 0.1 }
        }
    };

    const itemVariants = {
        hidden: { opacity: 0, y: 20 },
        visible: {
            opacity: 1,
            y: 0,
            transition: { type: "spring", stiffness: 300, damping: 24 }
        }
    };

    // Calculate metrics
    const totalProjects = projects.length;
    const passedProjects = projects.filter(p => p.calificacion && p.calificacion >= 70).length;

    // Proyectos listos para evaluar: Son públicos y AÚN no tienen calificación
    const readyToEvaluateProjects = projects.filter(p => p.esPublico === true && (p.calificacion === null || p.calificacion === undefined));
    const readyToEvaluateCount = readyToEvaluateProjects.length;

    // Filter projects for the grid based on search query
    const filteredProjects = projects.filter(p =>
        (p.titulo?.toLowerCase() || '').includes(searchQuery.toLowerCase()) ||
        (p.liderNombre?.toLowerCase() || '').includes(searchQuery.toLowerCase())
    );

    return (
        <div className="space-y-8">
            {/* Header: Greeting */}
            <div className="bg-slate-900 rounded-3xl p-8 sm:p-10 text-white relative overflow-hidden shadow-xl">
                <div className="relative z-10 max-w-3xl">
                    <h2 className="text-3xl sm:text-4xl font-bold mb-4 flex items-center gap-3">
                        Hola, {userData?.nombre?.split(' ')[0] || 'Docente'} 👋
                    </h2>
                    <p className="text-lg text-slate-300">
                        {groupName ? (
                            <>Gestionando el grupo <strong className="text-white">{groupName}</strong></>
                        ) : (
                            'Viendo tus proyectos asignados'
                        )}
                    </p>
                </div>
                {/* Decorative background element */}
                <div className="absolute right-0 top-0 w-1/2 h-full bg-gradient-to-l from-blue-600/20 to-transparent pointer-events-none" />
                <div className="absolute -right-20 -top-20 w-64 h-64 bg-blue-500/10 rounded-full blur-3xl pointer-events-none" />
            </div>

            {/* Metrics Grid */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <StatCard
                    title="Total de Proyectos"
                    value={totalProjects}
                    subtitle="En tu grupo actual"
                    icon={Users}
                    color="blue"
                />
                <StatCard
                    title="Proyectos Aprobados"
                    value={`${passedProjects}/${totalProjects}`}
                    subtitle="Calificación >= 70"
                    icon={CheckCircle}
                    color="green"
                />
                <StatCard
                    title="Listos para Evaluar"
                    value={readyToEvaluateCount}
                    subtitle="Esperando tu calificación"
                    icon={Clock}
                    color={readyToEvaluateCount > 0 ? "orange" : "slate"}
                />
            </div>

            {/* Priority Section: Needs Evaluation */}
            {readyToEvaluateProjects.length > 0 && (
                <div className="mt-12">
                    <div className="flex items-center gap-3 mb-6">
                        <div className="w-10 h-10 rounded-full bg-orange-100 flex items-center justify-center">
                            <Clock className="w-5 h-5 text-orange-600" />
                        </div>
                        <h3 className="text-xl font-bold text-gray-900">Atención Prioritaria: Requieren Evaluación</h3>
                    </div>

                    <motion.div
                        variants={containerVariants}
                        initial="hidden"
                        animate="visible"
                        className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 p-6 bg-orange-50/50 rounded-2xl border border-orange-100"
                    >
                        {readyToEvaluateProjects.map(project => (
                            <motion.div key={project.id} variants={itemVariants}>
                                <ProjectCard
                                    project={project}
                                    onClick={() => onProjectClick(project)}
                                    layoutId={`priority-${project.id}`}
                                />
                            </motion.div>
                        ))}
                    </motion.div>
                </div>
            )}

            {/* All Group Projects Grid */}
            <div className="mt-12 pt-8 border-t border-gray-100">
                <div className="flex items-center justify-between mb-8">
                    <div className="flex items-center gap-3">
                        <h2 className="text-xl font-bold text-gray-900">Todos los Proyectos del Grupo</h2>
                        <span className="bg-gray-100 text-gray-700 px-3 py-1 rounded-full text-sm font-semibold">
                            {filteredProjects.length}
                        </span>
                    </div>
                </div>

                <motion.div
                    variants={containerVariants}
                    initial="hidden"
                    animate="visible"
                    className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8"
                >
                    {filteredProjects.length > 0 ? (
                        filteredProjects.map(project => (
                            <motion.div key={project.id} variants={itemVariants}>
                                <ProjectCard
                                    project={project}
                                    onClick={() => onProjectClick(project)}
                                    layoutId={`all-${project.id}`}
                                />
                            </motion.div>
                        ))
                    ) : (
                        <div className="col-span-full bg-gray-50 border-2 border-dashed border-gray-200 rounded-xl p-12 text-center flex flex-col items-center justify-center min-h-[300px]">
                            <h3 className="text-xl font-semibold text-gray-900 mb-2">No se encontraron proyectos</h3>
                            <p className="text-gray-500 max-w-md mx-auto">
                                Intenta ajustando los términos de búsqueda o espera a que los alumnos creen sus proyectos.
                            </p>
                        </div>
                    )}
                </motion.div>
            </div>
        </div>
    );
}
