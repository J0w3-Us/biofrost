import { useAuth } from '../../auth/hooks/useAuth';
import { Mail, Phone, MapPin, Calendar, Camera, Edit2, Shield, User as UserIcon, BookOpen, GraduationCap, Briefcase, Building } from 'lucide-react';
import { motion } from 'framer-motion';

export function ProfilePage() {
    const { userData } = useAuth();

    if (!userData) return null;

    // Higher quality name resolution for the header
    const hasRealName = userData.nombre && userData.nombre !== 'Usuario';
    const hasSurnames = userData.apellidoPaterno || userData.apellidoMaterno;

    const displayNombre = hasRealName ? userData.nombre.replace(/^\d+\s+/, '') : (userData.email ? userData.email.split('@')[0] : 'Usuario');
    const fullName = `${displayNombre} ${userData.apellidoPaterno || ''} ${userData.apellidoMaterno || ''}`.trim();

    return (
        <div className="flex flex-col gap-8 pb-10">
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

                        {/* Avatar */}
                        <div className="relative group">
                            <div className="w-40 h-40 rounded-full neu-flat p-2 bg-[#e0e5ec]">
                                <div className="w-full h-full rounded-full overflow-hidden relative shadow-inner">
                                    {userData.fotoUrl ? (
                                        <img src={userData.fotoUrl} alt="Profile" className="w-full h-full object-cover" />
                                    ) : (
                                        <div className="w-full h-full bg-slate-900 flex items-center justify-center text-4xl font-black text-white uppercase tracking-tighter shadow-inner">
                                            {userData.nombre?.charAt(0)}
                                        </div>
                                    )}
                                </div>
                            </div>
                            <button className="absolute bottom-2 right-2 neu-icon-btn w-10 h-10 bg-[#e0e5ec] text-slate-900 shadow-lg border border-white/40 hover:bg-white transition-all">
                                <Camera size={18} />
                            </button>
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
                                    <InfoCard icon={<UserIcon size={20} />} label="Matrícula" value={userData.matricula} color="text-slate-900" />
                                    <InfoCard icon={<GraduationCap size={20} />} label="Carrera" value={userData.carreraId?.toUpperCase()} color="text-slate-900" />
                                    <InfoCard icon={<BookOpen size={20} />} label="Grupo" value={userData.grupoNombre || 'Sin grupo'} color="text-slate-900" />
                                </>
                            )}

                            {userData.rol === 'Docente' && (
                                <>
                                    <InfoCard icon={<Briefcase size={20} />} label="Profesión" value={userData.profesion} color="text-slate-900" />
                                    <InfoCard icon={<Shield size={20} />} label="Especialidad" value={userData.especialidadDocente} color="text-slate-900" />
                                </>
                            )}

                            {userData.rol === 'Invitado' && (
                                <InfoCard icon={<Building size={20} />} label="Organización" value={userData.organizacion} color="text-slate-900" />
                            )}

                            {/* Common Fields */}
                            <InfoCard icon={<Mail size={20} />} label="Correo Electrónico" value={userData.email} color="text-slate-900" />
                            <InfoCard icon={<Phone size={20} />} label="Teléfono" value={userData.telefono || 'No registrado'} color="text-slate-900" />
                            <InfoCard icon={<MapPin size={20} />} label="Ubicación" value={userData.direccion || 'Mérida, Yucatán'} color="text-slate-900" />
                            <InfoCard icon={<Calendar size={20} />} label="Miembro desde" value="Enero 2024" color="text-slate-900" />
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
                            Tu perfil está verificado y sincronizado, no olvides acompletar tus datos.
                        </p>
                    </div>
                </div>
            </div>
        </div>
    );
}

function InfoCard({ icon, label, value, color }) {
    return (
        <div className="neu-pressed rounded-2xl p-4 flex items-center gap-4 group transition-all">
            <div className={`w-12 h-12 rounded-full neu-flat flex items-center justify-center ${color} bg-white border border-slate-100`}>
                {icon}
            </div>
            <div className="overflow-hidden">
                <p className="text-[10px] text-slate-400 font-black uppercase tracking-widest">{label}</p>
                <p className="text-slate-900 font-bold truncate" title={value}>
                    {value || '---'}
                </p>
            </div>
        </div>
    );
}
