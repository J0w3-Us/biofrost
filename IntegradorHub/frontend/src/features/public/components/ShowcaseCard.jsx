import { useState } from 'react';
import { Play, Users, ExternalLink, Edit, Star, ChevronLeft, ChevronRight, Image as ImageIcon, Trophy } from 'lucide-react';
import { useAuth } from '../../auth/hooks/useAuth';
import { useNavigate } from 'react-router-dom';
import api from '../../../lib/axios';

export function ShowcaseCard({ project, onClick }) {
    const [isPlaying, setIsPlaying] = useState(false);
    const [currentSlide, setCurrentSlide] = useState(0);
    const { userData } = useAuth();
    const navigate = useNavigate();

    // Voting State
    // Voting State
    const [hoverRating, setHoverRating] = useState(0);
    const [userRating, setUserRating] = useState(() => {
        // Init rating from the server payload if user already voted
        if (userData && userData.userId && project.votantes && project.votantes[userData.userId]) {
            return project.votantes[userData.userId];
        }
        return 0;
    });
    const [isVoting, setIsVoting] = useState(false);

    const isOwner = userData?.userId === project.liderId;

    // 2. Gather Media Items (Video + Thumbnail + Canvas Images)
    const mediaItems = [];

    // Add Video Pitch if exists
    if (project.videoUrl) {
        mediaItems.push({ type: 'video', url: project.videoUrl, thumbnail: project.thumbnailUrl });
    }

    // Add Project Thumbnail (if not used as video thumb) OR just as an image
    if (project.thumbnailUrl && !mediaItems.some(item => item.url === project.thumbnailUrl)) {
        mediaItems.push({ type: 'image', url: project.thumbnailUrl });
    }

    // Add Images from Canvas
    if (project.canvas) {
        const canvasImages = project.canvas
            .filter(b => b.type === 'image' && b.content && b.content !== project.thumbnailUrl)
            .map(b => ({ type: 'image', url: b.content }));
        mediaItems.push(...canvasImages);
    }

    // Default Placeholder if empty
    if (mediaItems.length === 0) {
        mediaItems.push({ type: 'placeholder' });
    }

    const currentMedia = mediaItems[currentSlide];

    // Carousel Navigation
    const nextSlide = (e) => {
        e.stopPropagation();
        setCurrentSlide((prev) => (prev + 1) % mediaItems.length);
        setIsPlaying(false); // Stop video on slide change
    };

    const prevSlide = (e) => {
        e.stopPropagation();
        setCurrentSlide((prev) => (prev - 1 + mediaItems.length) % mediaItems.length);
        setIsPlaying(false);
    };

    // Handle Rating
    const handleRate = async (e, stars) => {
        e.stopPropagation();
        if (!userData) return; // Should handle login prompt if needed, but for now silent return or redirect
        if (isOwner) return; // Prevent owner voting
        if (isVoting) return;

        setIsVoting(true);
        try {
            await api.post(`/api/projects/${project.id}/rate`, {
                userId: userData.userId,
                stars: stars
            });
            setUserRating(stars);
            // Optimistically update points could be complex/risky without full reload, 
            // so we just show the user's vote state for now.
        } catch (error) {
            console.error('Error rating project:', error);
        } finally {
            setIsVoting(false);
        }
    };

    // 3. Determine Description
    const description = project.descripcion || 'Sin descripción disponible. Navega a los detalles para ver más.';

    // 4. Handle Edit Click
    const handleEditClick = (e) => {
        e.stopPropagation();
        navigate(`/project/${project.id}/editor`);
    };

    return (
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm hover:shadow-lg transition-all duration-300 overflow-hidden flex flex-col md:flex-row h-auto md:h-[320px] mb-8 group">

            {/* --- LEFT: Media Carousel (55% width) --- */}
            <div
                className="w-full md:w-[55%] bg-black relative flex items-center justify-center overflow-hidden"
                onClick={onClick}
                onMouseEnter={() => currentMedia.type === 'video' && setIsPlaying(true)}
                onMouseLeave={() => currentMedia.type === 'video' && setIsPlaying(false)}
            >
                {/* Media Content */}
                {currentMedia.type === 'video' ? (
                    isPlaying ? (
                        <video
                            src={currentMedia.url}
                            muted
                            loop
                            autoPlay
                            className="w-full h-full object-contain bg-black"
                        />
                    ) : (
                        <div className="relative w-full h-full">
                            <img
                                src={currentMedia.thumbnail || project.thumbnailUrl || ''}
                                alt="Video Thumbnail"
                                className="w-full h-full object-cover opacity-80"
                                onError={(e) => { e.target.style.display = 'none'; }}
                            />
                            {/* Play Overlay */}
                            <div className="absolute inset-0 flex items-center justify-center">
                                <div className="w-16 h-16 bg-white/20 backdrop-blur-sm rounded-full flex items-center justify-center border border-white/30 group-hover:scale-110 transition-transform">
                                    <Play fill="white" className="text-white ml-1" size={32} />
                                </div>
                            </div>
                            <span className="absolute bottom-3 left-3 px-2 py-1 bg-black/70 rounded text-white text-[10px] font-bold uppercase tracking-wider border border-white/10">
                                Video Pitch
                            </span>
                        </div>
                    )
                ) : currentMedia.type === 'image' ? (
                    <img
                        src={currentMedia.url}
                        alt={project.titulo}
                        className="w-full h-full object-cover transition-transform duration-700 group-hover:scale-105"
                    />
                ) : (
                    // Placeholder
                    <div className="flex flex-col items-center justify-center text-gray-500">
                        <ImageIcon size={48} className="mb-2 opacity-50" />
                        <span className="text-xs font-medium">Sin contenido visual</span>
                    </div>
                )}

                {/* Carousel Controls (Only if multiple items) */}
                {mediaItems.length > 1 && (
                    <>
                        <button
                            onClick={prevSlide}
                            className="absolute left-2 top-1/2 -translate-y-1/2 p-1.5 bg-black/50 text-white rounded-full hover:bg-black/70 transition-colors opacity-0 group-hover:opacity-100 z-10"
                        >
                            <ChevronLeft size={20} />
                        </button>
                        <button
                            onClick={nextSlide}
                            className="absolute right-2 top-1/2 -translate-y-1/2 p-1.5 bg-black/50 text-white rounded-full hover:bg-black/70 transition-colors opacity-0 group-hover:opacity-100 z-10"
                        >
                            <ChevronRight size={20} />
                        </button>

                        {/* Dots Indicator */}
                        <div className="absolute bottom-3 right-3 flex gap-1.5 z-10">
                            {mediaItems.map((_, idx) => (
                                <div
                                    key={idx}
                                    className={`w-1.5 h-1.5 rounded-full shadow-sm transition-all ${idx === currentSlide ? 'bg-white scale-110' : 'bg-white/50'}`}
                                />
                            ))}
                        </div>
                    </>
                )}

                {/* Ranking Badge (Total Points) - Absolute Top Left */}
                {project.puntosTotales > 0 && (
                    <div className="absolute top-3 left-3 z-10 bg-yellow-400 text-yellow-900 px-2 py-1 rounded-md shadow-lg flex items-center gap-1.5 font-bold text-xs border border-yellow-300">
                        <Trophy size={14} fill="currentColor" />
                        <span>{project.puntosTotales} pts</span>
                    </div>
                )}
            </div>

            {/* --- RIGHT: Content & Info (45% width) --- */}
            <div className="w-full md:w-[45%] flex flex-col justify-between bg-white relative">

                {/* 1. Header: User & Status */}
                <div className="p-5 pb-2 flex items-start justify-between">
                    <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-full bg-gradient-to-br from-indigo-100 to-purple-100 flex items-center justify-center text-indigo-700 font-bold border border-indigo-50 text-sm">
                            {project.liderNombre?.charAt(0).toUpperCase() || '?'}
                        </div>
                        <div className="flex flex-col">
                            <h4 className="text-sm font-bold text-gray-900 leading-none truncate max-w-[120px]" title={project.liderNombre}>
                                {project.liderNombre || 'Desconocido'}
                            </h4>
                            <span className="text-[10px] text-gray-500 mt-0.5">
                                {new Date(project.createdAt).toLocaleDateString()}
                            </span>
                        </div>
                    </div>

                    <div className="flex items-center gap-2">
                        {/* Status Badge */}
                        <span className={`px-2 py-0.5 rounded text-[10px] font-bold uppercase tracking-wide border ${project.estado === 'Completado' ? 'bg-green-50 text-green-700 border-green-100' :
                            project.estado === 'Activo' ? 'bg-blue-50 text-blue-700 border-blue-100' :
                                'bg-gray-50 text-gray-500 border-gray-100'
                            }`}>
                            {project.estado}
                        </span>

                        {isOwner && (
                            <button
                                onClick={handleEditClick}
                                className="p-1.5 text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-full transition-all"
                                title="Editar Proyecto"
                            >
                                <Edit size={16} />
                            </button>
                        )}
                    </div>
                </div>

                {/* 2. Body: Title & Description */}
                <div className="px-5 py-2 flex-1 overflow-hidden" onClick={onClick}>
                    <h3 className="text-lg font-bold text-gray-900 leading-snug mb-2 cursor-pointer hover:text-indigo-600 transition-colors line-clamp-2">
                        {project.titulo || 'Sin Título'}
                    </h3>
                    <p className="text-gray-600 text-sm leading-relaxed line-clamp-3 md:line-clamp-4 cursor-pointer">
                        {description}
                    </p>
                </div>

                {/* 3. Footer: Techs, Rating & Actions */}
                <div className="px-5 pb-5 pt-3 mt-auto bg-gray-50/30 border-t border-gray-100">

                    {/* Tech Stack (One line) */}
                    <div className="flex flex-wrap gap-1.5 mb-4 max-h-[26px] overflow-hidden">
                        {project.stackTecnologico?.slice(0, 4).map((tech, i) => (
                            <span key={i} className="px-2 py-0.5 bg-white border border-gray-200 text-gray-600 text-[10px] font-semibold rounded shadow-sm">
                                {tech}
                            </span>
                        ))}
                        {(project.stackTecnologico?.length || 0) > 4 && (
                            <span className="px-1.5 py-0.5 text-gray-400 text-[10px] font-medium">
                                +{project.stackTecnologico.length - 4}
                            </span>
                        )}
                    </div>

                    {/* Bottom Action Row */}
                    <div className="flex items-center justify-between">

                        {/* Interactive Rating for Guests / Official Rating for Owner */}
                        <div className="flex items-center gap-3">
                            {/* Show Official Grade if exists */}
                            {project.calificacion !== null && project.calificacion !== undefined && (
                                <div className="flex items-center gap-1 text-gray-700 font-bold text-xs bg-gray-100 px-2 py-1 rounded border border-gray-200" title="Calificación Oficial">
                                    <span>Nota: {project.calificacion}</span>
                                </div>
                            )}

                            {/* Star Voting - Only if NOT owner */}
                            {!isOwner && (
                                <div className="flex items-center" onMouseLeave={() => setHoverRating(0)}>
                                    {[1, 2, 3, 4, 5].map((star) => (
                                        <button
                                            key={star}
                                            onMouseEnter={() => setHoverRating(star)}
                                            onClick={(e) => handleRate(e, star)}
                                            disabled={isVoting}
                                            className={`p-0.5 transition-colors ${(hoverRating || userRating) >= star
                                                ? 'text-yellow-400'
                                                : 'text-gray-300 hover:text-yellow-200'
                                                }`}
                                        >
                                            <Star size={14} fill={(hoverRating || userRating) >= star ? "currentColor" : "none"} />
                                        </button>
                                    ))}
                                </div>
                            )}
                        </div>

                        <button
                            onClick={onClick}
                            className="flex items-center gap-1.5 px-3 py-1.5 bg-gray-900 text-white text-xs font-semibold rounded-md hover:bg-gray-800 transition-all shadow-sm group/btn"
                        >
                            Ver Detalles
                            <ExternalLink size={12} className="group-hover/btn:translate-x-0.5 transition-transform" />
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
}
