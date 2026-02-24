import { Code } from 'lucide-react';
import { motion } from 'framer-motion';

export function TeamSuggestions({ suggestions }) {
    if (!suggestions || suggestions.length === 0) {
        return null;
    }

    return (
        <div className="bg-white rounded-xl border border-gray-100 p-6 shadow-sm">
            <div className="flex flex-col items-center justify-center text-center mb-6">
                <h3 className="text-lg font-bold text-gray-900">Encuentra a tu equipo</h3>
                <p className="text-sm text-gray-500 mt-1">Compañeros sin equipo en tu grupo</p>
            </div>

            <div className="space-y-4">
                {suggestions.map((student, index) => (
                    <motion.div
                        key={student.id}
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: index * 0.1 }}
                        className="flex flex-col items-center p-4 hover:bg-gray-50 rounded-xl transition-colors border border-gray-50 hover:border-gray-100"
                    >
                        {student.fotoUrl ? (
                            <img
                                src={student.fotoUrl}
                                alt={student.nombreCompleto}
                                className="h-12 w-12 rounded-full object-cover mb-3 shadow-sm border border-gray-100"
                            />
                        ) : (
                            <div className="h-12 w-12 rounded-full bg-gradient-to-br from-indigo-100 to-blue-100 flex items-center justify-center text-indigo-700 font-bold uppercase mb-3 shadow-sm">
                                {student.nombreCompleto?.substring(0, 2) || 'US'}
                            </div>
                        )}
                        <div className="text-center">
                            <p className="text-sm font-semibold text-gray-900">{student.nombreCompleto}</p>
                            <div className="flex items-center justify-center mt-1.5">
                                <span className="flex items-center gap-1.5 text-xs text-blue-600 bg-blue-50 px-2.5 py-1 rounded-full font-medium">
                                    <Code size={12} />
                                    {student.matricula || 'Sin Matrícula'}
                                </span>
                            </div>
                        </div>
                    </motion.div>
                ))}
            </div>

            <button className="w-full mt-4 py-2 text-sm font-semibold text-blue-600 hover:text-blue-700 hover:bg-blue-50 rounded-lg transition-colors text-center hidden">
                Ver todos
            </button>
        </div>
    );
}
