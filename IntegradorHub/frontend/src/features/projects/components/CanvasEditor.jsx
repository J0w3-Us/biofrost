import { useState, useCallback, useRef, useEffect } from 'react';
import {
    Plus, Image as ImageIcon, Type, Heading1, Heading2, Heading3,
    List, CheckSquare, Code, Quote, MoreVertical, X,
    GripVertical, Maximize2, Minimize2, Video, MonitorPlay,
    ChevronLeft, ChevronRight, Play, Trash2
} from 'lucide-react';
import { motion, Reorder, AnimatePresence } from 'framer-motion';
import api from '../../../lib/axios';

// Block Types
const BLOCK_TYPES = {
    TEXT: 'text',
    H1: 'h1',
    H2: 'h2',
    H3: 'h3',
    BULLET: 'bullet',
    TODO: 'todo',
    IMAGE: 'image',
    VIDEO: 'video',
    CODE: 'code',
    QUOTE: 'quote',
    DIVIDER: 'divider'
};

const BLOCK_MENU = [
    { type: BLOCK_TYPES.TEXT, icon: Type, label: 'Texto Normal' },
    { type: BLOCK_TYPES.H1, icon: Heading1, label: 'Título Principal' },
    { type: BLOCK_TYPES.H2, icon: Heading2, label: 'Subtítulo' },
    { type: BLOCK_TYPES.H3, icon: Heading3, label: 'Encabezado' },
    { type: BLOCK_TYPES.BULLET, icon: List, label: 'Lista' },
    { type: BLOCK_TYPES.TODO, icon: CheckSquare, label: 'Lista de Tareas' },
    { type: BLOCK_TYPES.QUOTE, icon: Quote, label: 'Cita' },
    { type: BLOCK_TYPES.DIVIDER, icon: MoreVertical, label: 'Separador' },
    { type: BLOCK_TYPES.IMAGE, icon: ImageIcon, label: 'Imagen' },
    { type: BLOCK_TYPES.VIDEO, icon: Video, label: 'Video' }
];

export function CanvasEditor({ project, readOnly = false, mode = 'all', onSaveStatusChange, ref }) {
    // Project Metadata State
    const [title, setTitle] = useState(project?.titulo || '');
    const [videoUrl, setVideoUrl] = useState(project?.videoUrl || null);
    const [videoUploadProgress, setVideoUploadProgress] = useState(0);

    // Canvas Blocks State
    const [blocks, setBlocks] = useState(project?.canvas || [{
        id: crypto.randomUUID(),
        type: BLOCK_TYPES.TEXT,
        content: '',
        metadata: {}
    }]);

    const [activeBlock, setActiveBlock] = useState(null);
    const [showMenu, setShowMenu] = useState(null);
    const [saving, setSaving] = useState(false);

    // Lightbox State
    const [lightboxOpen, setLightboxOpen] = useState(false);
    const [lightboxIndex, setLightboxIndex] = useState(0);
    const [lightboxItems, setLightboxItems] = useState([]);

    // Sync State with Project Prop (Crucial for when data is fetched after initial mount)
    useEffect(() => {
        if (project) {
            setTitle(project.titulo || '');
            setVideoUrl(project.videoUrl || null);
            setBlocks(project.canvas && project.canvas.length > 0 ? project.canvas : [{
                id: crypto.randomUUID(),
                type: BLOCK_TYPES.TEXT,
                content: '',
                metadata: {}
            }]);
        }
    }, [project]);

    // Debounced Save
    useEffect(() => {
        if (readOnly) return;
        const timeout = setTimeout(() => {
            saveContent();
        }, 2000);
        return () => clearTimeout(timeout);
    }, [blocks, title, videoUrl]);

    // Expose save method to parent
    // Note: ref logic needs forwardRef to work properly, but usually manual save just calls this function
    // For now we assume the parent handles ref if passed, but simpler is to use the effect above for auto-save.
    // If parent uses ref to call save(), we need to attach it.
    useEffect(() => {
        if (ref && typeof ref === 'object') {
            ref.current = {
                save: saveContent
            };
        }
    }, [blocks, title, videoUrl, ref]);

    const saveContent = async () => {
        if (readOnly) return;
        setSaving(true);
        onSaveStatusChange?.(true);

        // Sanitize blocks to remove transient UI state from metadata
        const sanitizedBlocks = blocks.map(block => {
            if (!block.metadata) return block;
            const { uploading, progress, error, ...persistentMetadata } = block.metadata;
            return {
                ...block,
                metadata: persistentMetadata
            };
        });

        try {
            await api.put(`/api/projects/${project.id}`, {
                titulo: title,
                videoUrl: videoUrl,
                canvasBlocks: sanitizedBlocks
            });
        } catch (error) {
            console.error('Error saving project:', error);
        } finally {
            setSaving(false);
            onSaveStatusChange?.(false);
        }
    };

    // --- Block Management ---
    const addBlock = (type, index) => {
        const newBlock = {
            id: crypto.randomUUID(),
            type,
            content: '',
            metadata: {}
        };
        setBlocks(prev => {
            const newBlocks = [...prev];
            newBlocks.splice(index + 1, 0, newBlock);
            return newBlocks;
        });
        setActiveBlock(newBlock.id);
        setShowMenu(null);
    };

    const updateBlock = (id, content) => {
        setBlocks(prev => prev.map(b => b.id === id ? { ...b, content } : b));
    };

    const removeBlock = (id) => {
        setBlocks(prev => {
            if (prev.length > 1) {
                return prev.filter(b => b.id !== id);
            }
            return prev;
        });
    };

    const handleBlockMetadataChange = (id, metadata) => {
        setBlocks(prev => prev.map(b => b.id === id ? { ...b, metadata: { ...b.metadata, ...metadata } } : b));
    };

    // --- File Uploads (Supabase via Backend) ---
    const uploadFile = async (file, folder = 'project-assets', onProgress) => {
        // Validation handled in caller
        const formData = new FormData();
        formData.append('file', file);

        const response = await api.post(`/api/storage/upload?folder=${folder}`, formData, {
            headers: { 'Content-Type': 'multipart/form-data' },
            onUploadProgress: (progressEvent) => {
                const percent = Math.round((progressEvent.loaded * 100) / progressEvent.total);
                onProgress?.(percent);
            }
        });
        return response.data.url;
    };

    const handleVideoPitchUpload = async (file) => {
        if (!file) return;

        // Strict check to prevent images in video slot
        if (file.type.startsWith('image/')) {
            return alert('Este espacio es solo para el Video Pitch. Para subir imágenes, usa los bloques de contenido más abajo.');
        }

        // General video check (allowing webm, mp4, quicktime, etc)
        // If type is empty strings (some OS/browsers), let backend validate.
        if (file.type && !file.type.startsWith('video/') && file.type !== '') {
            return alert('Por favor sube un archivo de video válido (MP4, WebM, MOV).');
        }

        if (file.size > 100 * 1024 * 1024) return alert('El video no puede pesar más de 100MB');

        console.log('Uploading video pitch:', file.name, file.type, file.size);

        try {
            setVideoUploadProgress(1);
            const url = await uploadFile(file, 'project-promos', setVideoUploadProgress);
            console.log('Video pitch uploaded successfully:', url);
            if (!url) throw new Error("Backend returned empty URL for video");

            setVideoUrl(url);
            setVideoUploadProgress(0);
        } catch (error) {
            console.error('Error uploading video pitch:', error);
            const msg = error.response?.data?.error || error.message || 'Error al subir el video';
            alert(`Error: ${msg}`);
            setVideoUploadProgress(0);
        }
    };

    const handleBlockFileUpload = async (file, blockId, type) => {
        if (!file) return;

        // Validations specific to block type
        if (type === 'image') {
            if (file.type.startsWith('video/')) {
                return alert('Este bloque es para IMÁGENES. Si quieres subir un video, añade un bloque de video.');
            }
        }
        if (type === 'video') {
            if (file.type.startsWith('image/')) {
                return alert('Este bloque es para VIDEOS. Si quieres subir una imagen, añade un bloque de imagen.');
            }
        }

        if (file.size > 100 * 1024 * 1024) return alert('El archivo no puede superar los 100MB');

        handleBlockMetadataChange(blockId, { uploading: true, progress: 0, error: null });

        try {
            const folder = type === 'video' ? 'videos' : 'images';
            console.log(`Starting upload for block ${blockId} to folder ${folder}`);

            const url = await uploadFile(file, folder, (percent) => {
                handleBlockMetadataChange(blockId, { progress: percent });
            });

            console.log(`Upload successful for block ${blockId}. URL:`, url);

            if (!url) throw new Error("Backend returned empty URL");

            updateBlock(blockId, url);
        } catch (error) {
            console.error(`Error uploading ${type}:`, error);
            const msg = error.response?.data?.error || error.message || 'Error al subir archivo';
            handleBlockMetadataChange(blockId, { error: msg });
            // alert(`Error al subir archivo: ${msg}`);
        } finally {
            handleBlockMetadataChange(blockId, { uploading: false });
        }
    };

    // --- Media Gallery Logic ---
    const handleOpenLightbox = (items, index) => {
        setLightboxItems(items);
        setLightboxIndex(index);
        setLightboxOpen(true);
    };

    // Grouping blocks for read-only view
    const renderBlocks = () => {
        if (!readOnly) return blocks.map(block => (
            <Block
                key={block.id}
                block={block}
                active={activeBlock === block.id}
                onFocus={() => setActiveBlock(block.id)}
                onChange={(content) => updateBlock(block.id, content)}
                onRemove={() => removeBlock(block.id)}
                onAddBlock={(type) => addBlock(type, blocks.indexOf(block))}
                showMenu={showMenu === block.id}
                onToggleMenu={() => setShowMenu(showMenu === block.id ? null : block.id)}
                onFileUpload={(file, type) => handleBlockFileUpload(file, block.id, type)}
                readOnly={readOnly}
            />
        ));

        // Group consecutive media blocks for Read-Only mode
        // Only grouping images for the "Facebook style" grid. 
        // Videos might be tricky in a grid if auto-playing, but we'll include them as previews.
        const groupedGroups = [];
        let currentMediaGroup = [];

        const filteredBlocks = blocks.filter(block => {
            if (mode === 'media') return block.type === BLOCK_TYPES.IMAGE || block.type === BLOCK_TYPES.VIDEO;
            if (mode === 'text') return block.type !== BLOCK_TYPES.IMAGE && block.type !== BLOCK_TYPES.VIDEO;
            return true;
        });

        filteredBlocks.forEach((block) => {
            if (block.type === BLOCK_TYPES.IMAGE || block.type === BLOCK_TYPES.VIDEO) {
                currentMediaGroup.push(block);
            } else {
                if (currentMediaGroup.length > 0) {
                    groupedGroups.push({
                        id: `group-${currentMediaGroup[0].id}`,
                        type: 'media_gallery',
                        items: [...currentMediaGroup]
                    });
                    currentMediaGroup = [];
                }
                groupedGroups.push(block);
            }
        });

        if (currentMediaGroup.length > 0) {
            groupedGroups.push({
                id: `group-${currentMediaGroup[0].id}`,
                type: 'media_gallery',
                items: [...currentMediaGroup]
            });
        }

        return groupedGroups.map(item => {
            if (item.type === 'media_gallery') {
                return (
                    <MediaGallery
                        key={item.id}
                        items={item.items}
                        onOpenLightbox={(index) => handleOpenLightbox(item.items, index)}
                    />
                );
            }
            return <Block key={item.id} block={item} readOnly={true} />;
        });
    };

    return (
        <div className={mode === 'all' ? "max-w-4xl mx-auto py-8 px-4 lg:px-0" : "w-full h-full flex flex-col gap-4"}>
            {/* Header: Video Pitch & Title (Editable) */}
            {(mode === 'all' || mode === 'media' || !readOnly) && (
                <div className={`mb-12 border-b border-gray-100 pb-8 ${readOnly ? 'mb-0 border-0 pb-0' : ''}`}>
                    {/* Title Input */}
                    {readOnly ? null : (
                        <input
                            type="text"
                            value={title}
                            onChange={(e) => setTitle(e.target.value)}
                            placeholder="Título del Proyecto"
                            className="text-4xl font-bold text-gray-900 placeholder-gray-300 w-full outline-none bg-transparent mb-8"
                        />
                    )}

                    {/* Video Pitch Section - VISIBLE IN BOTH MODES (Optional) */}
                    {/* User might not want to see it in ReadOnly if empty, handled below */}
                    {(videoUrl || !readOnly) && mode !== 'text' && (
                        <div className="space-y-4">
                            <h3 className="text-lg font-bold text-gray-900 flex items-center gap-2">
                                <Video size={20} className="text-blue-600" />
                                Video Pitch
                            </h3>

                            {!videoUrl ? (
                                readOnly ? (
                                    <div className="p-8 bg-gray-50 rounded-2xl border border-gray-100 text-center text-gray-400">
                                        No se ha subido un video pitch.
                                    </div>
                                ) : (
                                    <div className="relative border-2 border-dashed border-gray-200 rounded-2xl p-8 hover:bg-gray-50 transition-colors group cursor-pointer text-center">
                                        <input
                                            type="file"
                                            className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                                            onChange={(e) => handleVideoPitchUpload(e.target.files[0])}
                                        />
                                        <div className="space-y-3">
                                            <div className="w-12 h-12 bg-blue-50 text-blue-600 rounded-full flex items-center justify-center mx-auto group-hover:scale-110 transition-transform">
                                                <MonitorPlay size={24} />
                                            </div>
                                            <div>
                                                <p className="font-semibold text-gray-900">Haz clic para subir tu Video Pitch</p>
                                                <p className="text-sm text-gray-500">MP4, WebM hasta 100MB</p>
                                            </div>
                                        </div>
                                        {videoUploadProgress > 0 && (
                                            <div className="absolute inset-x-8 bottom-4">
                                                <div className="h-1 bg-gray-200 rounded-full overflow-hidden">
                                                    <div
                                                        className="h-full bg-blue-600 transition-all duration-300"
                                                        style={{ width: `${videoUploadProgress}%` }}
                                                    />
                                                </div>
                                            </div>
                                        )}
                                    </div>
                                )
                            ) : (
                                <div className="relative rounded-2xl overflow-hidden bg-black aspect-video group">
                                    <video
                                        src={videoUrl}
                                        className="w-full h-full object-contain"
                                        controls
                                    />
                                    {!readOnly && (
                                        <button
                                            onClick={() => {
                                                if (confirm('¿Eliminar video pitch?')) setVideoUrl(null);
                                            }}
                                            className="absolute top-4 right-4 p-2 bg-black/50 text-white rounded-lg hover:bg-red-500 transition-colors opacity-0 group-hover:opacity-100"
                                        >
                                            <X size={16} />
                                        </button>
                                    )}
                                </div>
                            )}
                        </div>
                    )}
                </div>
            )}

            {/* Canvas Blocks */}
            <div className="space-y-4">
                {readOnly ? (
                    renderBlocks()
                ) : (
                    <Reorder.Group axis="y" values={blocks} onReorder={setBlocks}>
                        {blocks.map((block, index) => (
                            <Block
                                key={block.id}
                                block={block}
                                active={activeBlock === block.id}
                                onFocus={() => setActiveBlock(block.id)}
                                onChange={(content) => updateBlock(block.id, content)}
                                onRemove={() => removeBlock(block.id)}
                                onAddBlock={(type) => addBlock(type, index)}
                                showMenu={showMenu === block.id}
                                onToggleMenu={() => setShowMenu(showMenu === block.id ? null : block.id)}
                                onFileUpload={(file, type) => handleBlockFileUpload(file, block.id, type)}
                            />
                        ))}
                    </Reorder.Group>
                )}
            </div>

            {/* Add Block Button (Bottom) */}
            {!readOnly && (
                <div className="mt-8 pt-8 border-t border-gray-100 flex justify-center gap-3">
                    <button
                        onClick={() => addBlock(BLOCK_TYPES.TEXT, blocks.length - 1)}
                        className="px-4 py-3 bg-gray-50 hover:bg-gray-100 text-gray-600 rounded-xl font-medium transition-colors flex items-center gap-2"
                    >
                        <Type size={18} />
                        Texto
                    </button>
                    <button
                        onClick={() => addBlock(BLOCK_TYPES.IMAGE, blocks.length - 1)}
                        className="px-4 py-3 bg-blue-50 hover:bg-blue-100 text-blue-600 rounded-xl font-medium transition-colors flex items-center gap-2"
                    >
                        <ImageIcon size={18} />
                        Imagen
                    </button>
                    <button
                        onClick={() => addBlock(BLOCK_TYPES.VIDEO, blocks.length - 1)}
                        className="px-4 py-3 bg-purple-50 hover:bg-purple-100 text-purple-600 rounded-xl font-medium transition-colors flex items-center gap-2"
                    >
                        <Video size={18} />
                        Video
                    </button>
                    <button
                        onClick={() => addBlock(BLOCK_TYPES.H2, blocks.length - 1)}
                        className="px-4 py-3 bg-gray-50 hover:bg-gray-100 text-gray-600 rounded-xl font-medium transition-colors flex items-center gap-2"
                    >
                        <Heading2 size={18} />
                        Título
                    </button>
                </div>
            )}

            {/* Lightbox for Gallery */}
            <AnimatePresence>
                {lightboxOpen && (
                    <Lightbox
                        items={lightboxItems}
                        currentIndex={lightboxIndex}
                        onClose={() => setLightboxOpen(false)}
                        onChangeIndex={setLightboxIndex}
                    />
                )}
            </AnimatePresence>
        </div>
    );
}

function Block({ block, active, onFocus, onChange, onRemove, onAddBlock, showMenu, onToggleMenu, onFileUpload, readOnly }) {
    const textareaRef = useRef(null);
    const fileInputRef = useRef(null);

    useEffect(() => {
        if (active && textareaRef.current) {
            textareaRef.current.focus();
            // Adjust height
            textareaRef.current.style.height = 'auto';
            textareaRef.current.style.height = textareaRef.current.scrollHeight + 'px';
        }
    }, [active]);

    const handleKeyDown = (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            onAddBlock(BLOCK_TYPES.TEXT);
        }
        if (e.key === 'Backspace' && !block.content) {
            e.preventDefault();
            onRemove();
        }
        if (e.key === '/') {
            // Trigger menu manually if needed
        }
    };

    const renderMenu = () => (
        <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 10 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 10 }}
            className="absolute left-0 top-10 z-50 bg-white rounded-xl shadow-xl border border-gray-100 w-64 overflow-hidden"
        >
            <div className="p-2 grid grid-cols-1 gap-1">
                {BLOCK_MENU.map(item => (
                    <button
                        key={item.type}
                        onClick={() => onAddBlock(item.type)}
                        className="flex items-center gap-3 px-3 py-2.5 hover:bg-gray-50 rounded-lg text-gray-700 text-sm transition-colors text-left"
                    >
                        <span className="p-1.5 bg-gray-100 rounded-md text-gray-600">{<item.icon size={16} />}</span>
                        <span>{item.label}</span>
                    </button>
                ))}
            </div>
        </motion.div>
    );

    const renderInput = () => {
        if (block.type === BLOCK_TYPES.DIVIDER) {
            return <div className="h-px bg-gray-200 my-8" />;
        }

        if (block.type === BLOCK_TYPES.IMAGE || block.type === BLOCK_TYPES.VIDEO) {
            const isVideo = block.type === BLOCK_TYPES.VIDEO;
            return (
                <div className="py-2">
                    {block.content ? (
                        <div className="relative group/media rounded-2xl overflow-hidden bg-gray-100 border border-gray-200">
                            {isVideo ? (
                                <video src={block.content} controls className="w-full h-auto max-h-[600px] object-contain bg-black" />
                            ) : (
                                <img src={block.content} alt="Content" className="w-full h-auto max-h-[600px] object-contain" />
                            )}
                            {!readOnly && (
                                <button
                                    onClick={onRemove}
                                    className="absolute top-2 right-2 p-1.5 bg-black/50 text-white rounded-lg opacity-0 group-hover/media:opacity-100 transition-opacity hover:bg-red-500"
                                >
                                    <Trash2 size={14} />
                                </button>
                            )}
                        </div>
                    ) : (
                        <div className={`
                                relative border-2 border-dashed border-gray-200 rounded-xl p-8 
                                transition-colors group text-center
                                ${readOnly ? 'bg-gray-50 cursor-default' : 'hover:bg-gray-50 hover:border-blue-200 cursor-pointer'}
                            `}
                        >
                            <input
                                type="file"
                                className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
                                onChange={(e) => onFileUpload(e.target.files[0], block.type)}
                                disabled={readOnly}
                            />
                            {block.metadata?.uploading ? (
                                <div className="space-y-3">
                                    <div className="animate-spin w-6 h-6 border-2 border-blue-600 border-t-transparent rounded-full mx-auto" />
                                    <p className="text-sm text-gray-500">Subiendo...</p>
                                </div>
                            ) : (
                                <div className="space-y-2">
                                    <div className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center mx-auto text-gray-400 group-hover:bg-blue-50 group-hover:text-blue-500 transition-colors">
                                        {isVideo ? <Video size={20} /> : <ImageIcon size={20} />}
                                    </div>
                                    <p className="text-sm font-medium text-gray-600">
                                        {readOnly ? 'Sin contenido' : `Haz clic para subir ${isVideo ? 'video' : 'imagen'}`}
                                    </p>
                                    {block.metadata?.error && (
                                        <p className="text-xs text-red-500 font-medium mt-1 bg-red-50 px-2 py-1 rounded">
                                            {block.metadata.error}
                                        </p>
                                    )}
                                </div>
                            )}
                        </div>
                    )}
                    <input
                        type="text"
                        value={block.metadata?.caption || ''}
                        onChange={(e) => !readOnly && handleBlockMetadataChange(block.id, { caption: e.target.value })}
                        placeholder="Escribe una leyenda..."
                        className="w-full text-center text-sm text-gray-500 mt-2 bg-transparent outline-none placeholder-transparent hover:placeholder-gray-300 focus:placeholder-gray-300 transition-all"
                        disabled={readOnly}
                    />
                </div>
            );
        }

        const styles = {
            [BLOCK_TYPES.H1]: 'text-4xl font-bold text-gray-900 leading-tight',
            [BLOCK_TYPES.H2]: 'text-2xl font-semibold text-gray-800 mt-6 mb-2',
            [BLOCK_TYPES.H3]: 'text-xl font-semibold text-gray-800 mt-4 mb-2',
            [BLOCK_TYPES.QUOTE]: 'border-l-4 border-gray-900 pl-4 italic text-gray-600 my-4 text-lg',
            [BLOCK_TYPES.CODE]: 'font-mono text-sm bg-gray-900 text-gray-100 p-4 rounded-xl my-2 block w-full',
            [BLOCK_TYPES.TEXT]: 'text-base text-gray-600 leading-relaxed',
            [BLOCK_TYPES.BULLET]: 'text-base text-gray-600 leading-relaxed',
            [BLOCK_TYPES.TODO]: 'text-base text-gray-600 leading-relaxed',
        };

        if (readOnly) {
            return (
                <div
                    className={`w-full bg-transparent whitespace-pre-wrap ${styles[block.type] || styles[BLOCK_TYPES.TEXT]}`}
                >
                    {block.content || <span className="opacity-0">Empty</span>}
                </div>
            );
        }

        return (
            <textarea
                ref={textareaRef}
                value={block.content}
                onChange={(e) => {
                    onChange(e.target.value);
                    e.target.style.height = 'auto';
                    e.target.style.height = e.target.scrollHeight + 'px';
                }}
                onKeyDown={handleKeyDown}
                placeholder={active ? "Escribe '/' para comandos..." : ""}
                className={`w-full bg-transparent outline-none resize-none overflow-hidden ${styles[block.type] || styles[BLOCK_TYPES.TEXT]}`}
                rows={1}
            />
        );
    };

    const Wrapper = readOnly ? 'div' : Reorder.Item;
    const wrapperProps = readOnly ? {} : { value: block, id: block.id, dragListener: false };

    return (
        <Wrapper
            {...wrapperProps}
            className={`group relative flex items-start gap-2 ${active ? 'z-10' : ''}`}
            onClick={onFocus}
        >
            {/* Drag Handle & Menu */}
            {!readOnly && (
                <div className="absolute -left-12 top-1.5 flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button
                        className="p-1 hover:bg-gray-100 rounded text-gray-400 cursor-grab active:cursor-grabbing"
                    >
                        <GripVertical size={18} />
                    </button>
                    <div className="relative">
                        <button
                            onClick={(e) => { e.stopPropagation(); onToggleMenu(); }}
                            className="p-1 hover:bg-gray-100 rounded text-gray-400"
                        >
                            <MoreVertical size={18} />
                        </button>
                        <AnimatePresence>
                            {showMenu && renderMenu()}
                        </AnimatePresence>
                    </div>
                </div>
            )}

            {/* Block Content */}
            <div className="flex-1 min-w-0">
                {block.type === BLOCK_TYPES.BULLET && (
                    <div className="flex gap-2">
                        <span className="text-2xl leading-none text-gray-400">•</span>
                        {renderInput()}
                    </div>
                )}
                {block.type === BLOCK_TYPES.TODO && (
                    <div className="flex gap-3 items-start">
                        <button
                            onClick={() => !readOnly && handleBlockMetadataChange(block.id, { checked: !block.metadata?.checked })}
                            className={`mt-1 w-5 h-5 rounded border-2 flex items-center justify-center transition-colors ${block.metadata?.checked
                                ? 'bg-blue-500 border-blue-500 text-white'
                                : 'border-gray-300 text-transparent hover:border-blue-400'
                                }`}
                        >
                            <CheckSquare size={14} />
                        </button>
                        <div className={block.metadata?.checked ? 'line-through opacity-50' : ''}>
                            {renderInput()}
                        </div>
                    </div>
                )}
                {!['bullet', 'todo'].includes(block.type) && renderInput()}
            </div>
        </Wrapper>
    );
}

function MediaGallery({ items, onOpenLightbox }) {
    if (!items || items.length === 0) return null;

    // Grid layouts
    if (items.length === 1) {
        return (
            <div className="py-4" onClick={() => onOpenLightbox(0)}>
                <MediaItem item={items[0]} className="w-full rounded-2xl cursor-pointer hover:opacity-95 transition-opacity max-h-[600px] object-contain bg-black" />
            </div>
        );
    }

    if (items.length === 2) {
        return (
            <div className="grid grid-cols-2 gap-2 h-[300px] py-4">
                {items.map((item, index) => (
                    <div key={item.id} className="relative h-full cursor-pointer overflow-hidden rounded-xl" onClick={() => onOpenLightbox(index)}>
                        <MediaItem item={item} className="w-full h-full object-cover hover:scale-105 transition-transform duration-300" />
                    </div>
                ))}
            </div>
        );
    }

    if (items.length === 3) {
        return (
            <div className="grid grid-cols-2 gap-2 h-[400px] py-4">
                <div onClick={() => onOpenLightbox(0)} className="active:scale-[0.98] transition-transform cursor-pointer rounded-xl overflow-hidden">
                    <MediaItem item={items[0]} className="w-full h-full object-cover" />
                </div>
                <div className="grid grid-rows-2 gap-2">
                    {items.slice(1).map((item, i) => (
                        <div key={item.id} onClick={() => onOpenLightbox(i + 1)} className="active:scale-[0.98] transition-transform cursor-pointer rounded-xl overflow-hidden">
                            <MediaItem item={item} className="w-full h-full object-cover" />
                        </div>
                    ))}
                </div>
            </div>
        );
    }

    // 4+ items
    const remaining = items.length - 3;
    return (
        <div className="grid grid-cols-2 gap-2 h-[400px] py-4">
            <div onClick={() => onOpenLightbox(0)} className="active:scale-[0.98] transition-transform cursor-pointer rounded-xl overflow-hidden">
                <MediaItem item={items[0]} className="w-full h-full object-cover" />
            </div>
            <div className="grid grid-rows-2 gap-2">
                <div onClick={() => onOpenLightbox(1)} className="active:scale-[0.98] transition-transform cursor-pointer rounded-xl overflow-hidden">
                    <MediaItem item={items[1]} className="w-full h-full object-cover" />
                </div>
                <div onClick={() => onOpenLightbox(2)} className="relative active:scale-[0.98] transition-transform cursor-pointer rounded-xl overflow-hidden group">
                    <MediaItem item={items[2]} className="w-full h-full object-cover" />
                    {remaining > 0 && (
                        <div className="absolute inset-0 bg-black/60 flex items-center justify-center group-hover:bg-black/70 transition-colors">
                            <span className="text-3xl font-bold text-white">+{remaining}</span>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}

const MediaItem = ({ item, className }) => {
    const isVideo = item.type === BLOCK_TYPES.VIDEO;
    if (isVideo) {
        return (
            <div className={`relative ${className} bg-black flex items-center justify-center group`}>
                <video src={item.content} className="w-full h-full object-contain pointer-events-none" />
                <div className="absolute inset-0 flex items-center justify-center bg-black/20 group-hover:bg-black/10 transition-colors">
                    <div className="w-12 h-12 bg-white/20 backdrop-blur rounded-full flex items-center justify-center text-white">
                        <Play fill="white" size={20} />
                    </div>
                </div>
            </div>
        );
    }
    return <img src={item.content} alt="" className={className} />;
};

function Lightbox({ items, currentIndex, onClose, onChangeIndex }) {
    const currentItem = items[currentIndex];
    const isVideo = currentItem.type === BLOCK_TYPES.VIDEO;

    // Keyboard controls
    useEffect(() => {
        const handleKeyDown = (e) => {
            if (e.key === 'Escape') onClose();
            if (e.key === 'ArrowLeft') onChangeIndex(prev => Math.max(0, prev - 1));
            if (e.key === 'ArrowRight') onChangeIndex(prev => Math.min(items.length - 1, prev + 1));
        };
        window.addEventListener('keydown', handleKeyDown);
        return () => window.removeEventListener('keydown', handleKeyDown);
    }, [items.length, onChangeIndex, onClose]);

    return (
        <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[100] bg-black/95 flex items-center justify-center backdrop-blur-sm"
            onClick={onClose}
        >
            <button
                onClick={onClose}
                className="absolute top-6 right-6 p-2 bg-white/10 hover:bg-white/20 rounded-full text-white transition-colors z-50"
            >
                <X size={24} />
            </button>

            {/* Navigation Buttons */}
            {currentIndex > 0 && (
                <button
                    onClick={(e) => { e.stopPropagation(); onChangeIndex(currentIndex - 1); }}
                    className="absolute left-6 top-1/2 -translate-y-1/2 p-3 bg-white/10 hover:bg-white/20 rounded-full text-white transition-colors z-50"
                >
                    <ChevronLeft size={32} />
                </button>
            )}

            {currentIndex < items.length - 1 && (
                <button
                    onClick={(e) => { e.stopPropagation(); onChangeIndex(currentIndex + 1); }}
                    className="absolute right-6 top-1/2 -translate-y-1/2 p-3 bg-white/10 hover:bg-white/20 rounded-full text-white transition-colors z-50"
                >
                    <ChevronRight size={32} />
                </button>
            )}

            {/* Content */}
            <div
                className="w-full h-full flex items-center justify-center p-8 md:p-16"
                onClick={(e) => e.stopPropagation()}
            >
                {isVideo ? (
                    <video
                        src={currentItem.content}
                        controls
                        autoPlay
                        className="max-w-full max-h-full rounded-lg shadow-2xl"
                    />
                ) : (
                    <img
                        src={currentItem.content}
                        alt=""
                        className="max-w-full max-h-full object-contain rounded-lg shadow-2xl"
                    />
                )}
            </div>

            {/* Footer / Caption */}
            <div className="absolute bottom-6 left-0 right-0 text-center text-white/50">
                <p>{currentIndex + 1} / {items.length}</p>
                {currentItem.metadata?.caption && (
                    <p className="text-white font-medium mt-2">{currentItem.metadata.caption}</p>
                )}
            </div>
        </motion.div>
    );
}

// Helper: Trash icon removed to use imported Trash2

