import { LayoutGrid, AlertCircle } from 'lucide-react';

export function ProjectCard({ project, onClick }) {
  if (!project) return null;

  return (
    <div
      onClick={onClick}
      className="group relative bg-white border border-gray-200 rounded-xl p-6 cursor-pointer transition-all duration-300 hover:shadow-lg hover:-translate-y-1 hover:border-gray-300 flex flex-col h-full"
    >
      {/* Status & Icon Header */}
      <div className="flex justify-between items-start mb-4">
        <div className="p-3 bg-gray-50 rounded-lg text-gray-700 group-hover:bg-gray-100 transition-colors">
          <LayoutGrid size={24} strokeWidth={1.5} />
        </div>
        {project.estado && (
          <span className={`px-2.5 py-0.5 rounded-full text-xs font-medium border ${project.estado === 'Activo' ? 'bg-green-50 text-green-700 border-green-200' :
            project.estado === 'Completado' ? 'bg-blue-50 text-blue-700 border-blue-200' :
              'bg-gray-50 text-gray-700 border-gray-200'
            }`}>
            {project.estado}
          </span>
        )}
      </div>

      {/* Content */}
      <div className="flex-1">
        <h3 className="text-lg font-semibold text-gray-900 leading-snug mb-2 line-clamp-2 group-hover:text-black">
          {project.titulo || 'Proyecto sin título'}
        </h3>

        {project.docenteNombre && (
          <p className="text-sm text-gray-500 mb-4 flex items-center gap-2">
            <span className="w-1.5 h-1.5 rounded-full bg-gray-300"></span>
            {project.docenteNombre}
          </p>
        )}

        {/* Tech Stack Tags */}
        <div className="flex flex-wrap gap-2 mt-auto">
          {(project.stackTecnologico || []).slice(0, 3).map((tech, index) => (
            <span
              key={index}
              className="inline-flex items-center px-2 py-1 rounded-md bg-gray-50 text-xs font-medium text-gray-600 border border-gray-100"
            >
              {tech}
            </span>
          ))}
          {((project.stackTecnologico || []).length > 3) && (
            <span className="inline-flex items-center px-2 py-1 rounded-md bg-gray-50 text-xs font-medium text-gray-500 border border-gray-100">
              +{(project.stackTecnologico || []).length - 3}
            </span>
          )}
        </div>
      </div>

      {/* Footer / Date */}
      <div className="mt-6 pt-4 border-t border-gray-100 flex justify-between items-center text-xs text-gray-400">
        <span>{project.materia || 'Materia desconocida'}</span>
        <span>
          {(() => {
            if (!project.createdAt) return '';
            // Handle Firestore Timestamp (seconds)
            if (typeof project.createdAt === 'object' && project.createdAt.seconds) {
              return new Date(project.createdAt.seconds * 1000).toLocaleDateString();
            }
            // Handle ISO String / Date object
            const date = new Date(project.createdAt);
            return isNaN(date.getTime()) ? 'Fecha desconocida' : date.toLocaleDateString();
          })()}
        </span>
      </div>
    </div>
  );
}
