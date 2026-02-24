import { useState, useRef, useEffect } from 'react';
import { useAuth } from '../../auth/hooks/useAuth';
import { UserAvatar } from '../../../components/UserAvatar';
import { Mail, Phone, MapPin, Calendar, Camera, Edit2, Shield, User as UserIcon, BookOpen, GraduationCap, Briefcase, Building, Loader2 } from 'lucide-react';
import api from '../../../lib/axios';

export function ProfilePage() {
    const { userData, refreshUserData } = useAuth();
    const fileInputRef = useRef(null);
    const [uploading, setUploading] = useState(false);
    const [uploadProgress, setUploadProgress] = useState(0);

    if (!userData) return null;

    // Higher quality name resolution for the header
    const hasRealName = userData.nombre && userData.nombre !== 'Usuario';

    const displayNombre = hasRealName ? userData.nombre.replace(/^\d+\s+/, '') : (userData.email ? userData.email.split('@')[0] : 'Usuario');
    const fullName = `${displayNombre} ${userData.apellidoPaterno || ''} ${userData.apellidoMaterno || ''}`.trim();

    const [carreraNombre, setCarreraNombre] = useState('Cargando...');

    useEffect(() => {
        if (!userData) return;
        const rawId = userData.carreraId;
        if (!rawId) {
            setCarreraNombre('Sin carrera');
            return;
        }

        const carreraNamesAbbr = {
            'IDGS': 'Ing. Desarrollo y Gestión de Software',
            'IDGSI': 'Ing. Desarrollo y Gestión de Software',
            'IMT': 'Ing. Mecatrónica',
            'IER': 'Ing. Energías Renovables',
            'IMTC': 'Ing. Mecatrónica',
            'IERE': 'Ing. Energías Renovables',
            'IIND': 'Ing. Industrial',
            'IGAE': 'Ing. Gestión y Automatización',
        };

        const upper = rawId.toUpperCase();
        if (carreraNamesAbbr[upper]) {
            setCarreraNombre(carreraNamesAbbr[upper]);
            return;
        }

        // Si parece un ID generado por Firebase (largo > 10) consultamos el backend
        if (rawId.length > 10) {
            api.get('/api/admin/carreras')
                .then(res => {
                    const carrera = res.data?.find(c => c.id === rawId);
                    if (carrera) {
                        setCarreraNombre(carrera.nombre);
                    } else {
                        setCarreraNombre('Carrera asignada');
                    }
                })
                .catch(() => setCarreraNombre('Carrera asignada'));
        } else {
            setCarreraNombre(rawId);
        }
    }, [userData?.carreraId]);

    // --- "Miembro desde" dynamic formatting ---
    const memberSince = (() => {
        if (!userData.createdAt) return 'Fecha no disponible';
        try {
            const date = new Date(userData.createdAt);
            if (isNaN(date.getTime())) return 'Fecha no disponible';
            const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
                'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
            return `${months[date.getMonth()]} ${date.getFullYear()}`;
        } catch {
            return 'Fecha no disponible';
        }
    })();

    // --- Profile Photo Upload ---
    const handlePhotoUpload = async (e) => {
        const file = e.target.files?.[0];
        if (!file) return;

        // Validate
        if (!file.type.startsWith('image/')) {
            return alert('Por favor, selecciona una imagen (JPG, PNG, WebP).');
        }
        if (file.size > 5 * 1024 * 1024) {
            return alert('La imagen no puede pesar más de 5MB.');
        }

        setUploading(true);
        setUploadProgress(0);

        try {
            // Step 1: Upload to Supabase Storage via existing endpoint
            const formData = new FormData();
            formData.append('file', file);

            const uploadResponse = await api.post('/api/storage/upload?folder=avatars', formData, {
                headers: { 'Content-Type': 'multipart/form-data' },
                onUploadProgress: (progressEvent) => {
                    const percent = Math.round((progressEvent.loaded * 100) / progressEvent.total);
                    setUploadProgress(percent);
                }
            });

            const photoUrl = uploadResponse.data.url;
            if (!photoUrl) throw new Error('No URL returned from storage');

            // Step 2: Persist URL to Firestore via new endpoint
            await api.put(`/api/users/${userData.userId}/photo`, {
                fotoUrl: photoUrl
            });

            // Step 3: Refresh user data globally so all components update
            await refreshUserData();

        } catch (error) {
            console.error('Error uploading profile photo:', error);
            const msg = error.response?.data?.error || error.message || 'Error al subir la foto';
            alert(`Error: ${msg}`);
        } finally {
            setUploading(false);
            setUploadProgress(0);
            // Reset file input
            if (fileInputRef.current) fileInputRef.current.value = '';
        }
    };

    return (
        <div className="flex flex-col gap-8 pb-10">
            {/* Hidden File Input */}
            <input
                ref={fileInputRef}
                type="file"
                accept="image/jpeg,image/png,image/webp,image/gif"
                className="hidden"
                onChange={handlePhotoUpload}
            />

            {/* Main Neumorphic Card */}
            <div className="neu-flat rounded-[3rem] overflow-hidden relative">

                {/* Cover with Gradient Overlay */}
                <div className="h-72 w-full bg-slate-950 relative overflow-hidden">
                    <div className="absolute inset-0 bg-[url('https://www.transparenttextures.com/patterns/cubes.png')] opacity-10"></div>
                    <div className="absolute inset-0 bg-gradient-to-t from-slate-950/80 to-transparent"></div>
                    <button className="absolute top-6 right-6 neu-icon-btn w-12 h-12 bg-slate-900 border-slate-800 text-slate-400">
                        <Camera size={20} />
                    </button>
                </div>

                {/* Profile Header Content */}
                <div className="px-8 sm:px-12 lg:px-16 pb-12 relative">
                    <div className="flex flex-col md:flex-row gap-6 items-start -mt-20">

                        {/* Avatar with upload */}
                        <div className="relative group shrink-0">
                            <div className="w-44 h-44 rounded-full neu-flat p-2 bg-[#e0e5ec] flex items-center justify-center">
                                <UserAvatar
                                    src={userData.fotoUrl}
                                    name={userData.nombre}
                                    size="xl"
                                    className="shadow-inner"
                                />
                            </div>
                            <button
                                onClick={() => fileInputRef.current?.click()}
                                disabled={uploading}
                                className="absolute bottom-2 right-2 rounded-full flex items-center justify-center w-10 h-10 bg-[#e0e5ec] text-slate-900 shadow-lg border border-white/40 hover:bg-white transition-all disabled:opacity-50"
                            >
                                {uploading ? (
                                    <Loader2 size={18} className="animate-spin" />
                                ) : (
                                    <Camera size={18} />
                                )}
                            </button>

                            {/* Upload progress ring */}
                            {uploading && uploadProgress > 0 && (
                                <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                                    <svg className="w-44 h-44 rotate-[-90deg]" viewBox="0 0 44 44">
                                        <circle cx="22" cy="22" r="20" fill="none" stroke="rgba(255,255,255,0.1)" strokeWidth="2" />
                                        <circle cx="22" cy="22" r="20" fill="none" stroke="#3b82f6" strokeWidth="2.5"
                                            strokeDasharray={`${uploadProgress * 1.256}, 125.6`} strokeLinecap="round"
                                            className="transition-all duration-300"
                                        />
                                    </svg>
                                </div>
                            )}
                        </div>

                        {/* Name & Role */}
                        <div className="flex-1 mt-4 md:mt-20">
                            <h1 className="text-4xl font-black text-slate-900 tracking-tight">
                                {fullName}
                            </h1>
                            <div className="flex items-center gap-3 mt-2">
                                <span className="px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest bg-slate-900 text-white shadow-sm ring-1 ring-slate-800">
                                    {userData.rol}
                                </span>
                                <div className="flex items-center gap-1.5 text-slate-500 text-xs font-bold">
                                    <span className="w-2 h-2 rounded-full bg-slate-400 animate-pulse"></span>
                                    En línea
                                </div>
                            </div>
                        </div>

                        {/* Edit Button */}
                        <div className="mt-4 md:mt-20">
                            <button className="px-6 py-3 neu-flat rounded-xl font-black text-slate-700 hover:bg-slate-900 hover:text-white transition-all active:neu-pressed flex items-center gap-2 border border-white/50 uppercase text-[10px] tracking-widest">
                                <Edit2 size={16} />
                                <span>Configurar</span>
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            {/* Info Grid */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                {/* Contact & Professional Info */}
                <div className="lg:col-span-2 space-y-8">
                    <div className="neu-flat rounded-3xl p-8">
                        <h2 className="text-xl font-black text-slate-900 mb-6 flex items-center gap-3 uppercase tracking-tighter">
                            <span className="w-1.5 h-6 bg-slate-900 rounded-full shadow-[0_0_10px_rgba(0,0,0,0.2)]"></span>
                            Información Personal
                        </h2>

                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            {/* Academic/Professional Fields based on Role */}
                            {userData.rol === 'Alumno' && (
                                <>
                                    {userData.matricula && <InfoCard icon={<UserIcon size={20} />} label="Matrícula" value={userData.matricula} color="text-slate-900" />}
                                    {userData.carreraId && <InfoCard icon={<GraduationCap size={20} />} label="Carrera" value={carreraNombre} color="text-slate-900" />}
                                    {userData.grupoNombre && <InfoCard icon={<BookOpen size={20} />} label="Grupo" value={userData.grupoNombre} color="text-slate-900" />}
                                </>
                            )}

                            {userData.rol === 'Docente' && (
                                <>
                                    {userData.profesion && <InfoCard icon={<Briefcase size={20} />} label="Profesión" value={userData.profesion} color="text-slate-900" />}
                                    {userData.especialidadDocente && <InfoCard icon={<Shield size={20} />} label="Especialidad" value={userData.especialidadDocente} color="text-slate-900" />}
                                </>
                            )}

                            {userData.rol === 'Invitado' && userData.organizacion && (
                                <InfoCard icon={<Building size={20} />} label="Organización" value={userData.organizacion} color="text-slate-900" />
                            )}

                            {/* Common Fields */}
                            <InfoCard icon={<Mail size={20} />} label="Correo Electrónico" value={userData.email} color="text-slate-900" fullWidth />
                            {userData.telefono && <InfoCard icon={<Phone size={20} />} label="Teléfono" value={userData.telefono} color="text-slate-900" />}
                            {userData.direccion && <InfoCard icon={<MapPin size={20} />} label="Ubicación" value={userData.direccion} color="text-slate-900" />}
                            <InfoCard icon={<Calendar size={20} />} label="Miembro desde" value={memberSince} color="text-slate-900" />
                        </div>
                    </div>
                </div>

                {/* Sidebar Cards */}
                <div className="flex flex-col gap-8">
                    {/* Status Card */}
                    <div className="neu-flat rounded-3xl p-8 flex flex-col justify-center items-center text-center">
                        <div className="w-24 h-24 rounded-full neu-pressed flex items-center justify-center mb-6 relative p-1 bg-white/50">
                            <svg className="w-full h-full rotate-[-90deg]" viewBox="0 0 36 36">
                                <circle cx="18" cy="18" r="16" fill="none" stroke="#F0F0F3" strokeWidth="3" />
                                <circle cx="18" cy="18" r="16" fill="none" stroke="#1e293b" strokeWidth="3" strokeDasharray="95, 100" strokeLinecap="round" />
                            </svg>
                            <span className="absolute text-2xl font-black text-slate-900">95%</span>
                        </div>
                        <h3 className="text-xl font-bold text-slate-900 tracking-tight">Perfil Premium</h3>
                        <p className="text-slate-500 mt-2 text-sm leading-relaxed">
                            Tu perfil está verificado y sincronizado, no olvides completar tus datos.
                        </p>
                    </div>
                </div>
            </div>
        </div>
    );
}

function InfoCard({ icon, label, value, color, fullWidth = false }) {
    return (
        <div className={`neu-pressed rounded-2xl p-4 flex items-center gap-4 group transition-all ${fullWidth ? 'md:col-span-2' : ''}`}>
            <div className={`w-12 h-12 rounded-full neu-flat flex items-center justify-center shrink-0 ${color} bg-white border border-slate-100`}>
                {icon}
            </div>
            <div className="min-w-0 flex-1">
                <p className="text-[10px] text-slate-400 font-black uppercase tracking-widest">{label}</p>
                <p className={`text-slate-900 font-bold ${fullWidth ? 'break-all text-sm' : 'break-words text-sm'}`} title={value}>
                    {value}
                </p>
            </div>
        </div>
    );
}
