import { useState, useEffect } from 'react';
import { Navigate } from 'react-router-dom';
import {
    signInWithEmailAndPassword,
    createUserWithEmailAndPassword,
    signInWithPopup
} from 'firebase/auth';
import { doc, setDoc, getDoc } from 'firebase/firestore';
import { auth, googleProvider, db } from '../../../lib/firebase';
import { useAuth } from '../hooks/useAuth';

// Helper para auto-configurar admin
const checkAdminSetup = async (user) => {
    if (user.email === 'uzielisaac28@gmail.com') {
        try {
            const userDocRef = doc(db, 'users', user.uid);
            const userDocSnap = await getDoc(userDocRef);
            const existingData = userDocSnap.exists() ? userDocSnap.data() : {};

            await setDoc(userDocRef, {
                email: user.email,
                nombre: existingData.nombre || 'Admin',
                rol: 'admin',
                is_first_login: false,
                created_at: existingData.created_at || new Date().toISOString()
            }, { merge: true });
            console.log('🚀 Admin privileges granted automatically for:', user.email);
        } catch (e) {
            console.error('Error granting admin privileges:', e);
        }
    }
};
import api from '../../../lib/axios';
import { GraduationCap, User, UserCheck, AlertCircle, ArrowLeft, Check } from 'lucide-react';
import { CloudBackground } from '../../../components/ui/CloudBackground';

// Regex para detectar rol
const REGEX_ALUMNO = /^(\d{8})@alumno\.utmetropolitana\.edu\.mx$/;
const REGEX_DOCENTE = /^[a-zA-Z.]+@utmetropolitana\.edu\.mx$/;

// Detectar rol por correo
const detectarRol = (email) => {
    if (REGEX_ALUMNO.test(email)) return 'Alumno';
    if (REGEX_DOCENTE.test(email)) return 'Docente';
    return 'Invitado';
};

// Extraer matrícula del correo de alumno
const extraerMatricula = (email) => {
    const match = email.match(REGEX_ALUMNO);
    return match ? match[1] : null;
};

export function LoginPage() {
    const { isAuthenticated, loading, rol, refreshUserData } = useAuth();
    const [mode, setMode] = useState('login'); // login, register, register-info
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [nombre, setNombre] = useState('');
    const [apellidoPaterno, setApellidoPaterno] = useState('');
    const [apellidoMaterno, setApellidoMaterno] = useState('');
    // Alumno
    const [grupo, setGrupo] = useState('');
    const [carrera, setCarrera] = useState('');
    // Docente
    const [carreraDocente, setCarreraDocente] = useState('');
    const [materiaDocente, setMateriaDocente] = useState('');
    const [gruposDocente, setGruposDocente] = useState([]);
    const [profesion, setProfesion] = useState('');

    // Opciones en cascadas Docente
    const [materiasDisponiblesDocente, setMateriasDisponiblesDocente] = useState([]);
    const [gruposDisponiblesDocente, setGruposDisponiblesDocente] = useState([]);
    const [loadingMaterias, setLoadingMaterias] = useState(false);
    // Invitado
    const [organizacion, setOrganizacion] = useState('');

    const [detectedRole, setDetectedRole] = useState(null);
    const [error, setError] = useState('');
    const [submitting, setSubmitting] = useState(false);

    // Catálogos dinámicos
    const [gruposDisponibles, setGruposDisponibles] = useState([]);
    const [carrerasDisponibles, setCarrerasDisponibles] = useState([]);

    // Cargar catálogos
    useEffect(() => {
        const fetchData = async () => {
            try {
                const [groupsRes, carrerasRes] = await Promise.all([
                    api.get('/api/admin/groups'),
                    api.get('/api/admin/carreras')
                ]);

                setGruposDisponibles(groupsRes.data || []);
                setCarrerasDisponibles(carrerasRes.data || []);

            } catch (err) {
                console.error('Error loading catalogs:', err);
                // Fallbacks mejorados para desarrollo
                setGruposDisponibles([
                    { id: '5A', nombre: '5A' },
                    { id: '5B', nombre: '5B' },
                    { id: '5C', nombre: '5C' },
                    { id: '6A', nombre: '6A' },
                    { id: '6B', nombre: '6B' },
                    { id: '6C', nombre: '6C' }
                ]);
                setCarrerasDisponibles([
                    { id: 'dsm', nombre: 'Desarrollo de Software Multiplataforma' },
                    { id: 'evn', nombre: 'Entornos Virtuales y Negocios Digitales' },
                    { id: 'ric', nombre: 'Redes Inteligentes y Ciberseguridad' }
                ]);
            }
        };
        fetchData();
    }, []);

    // Cargar Materias Disponibles cuando el Docente selecciona una Carrera
    useEffect(() => {
        if (detectedRole === 'Docente' && carreraDocente) {
            setLoadingMaterias(true);
            api.get(`/api/admin/materias/available?carreraId=${carreraDocente}`)
                .then(res => {
                    setMateriasDisponiblesDocente(res.data || []);
                    setMateriaDocente('');
                    setGruposDocente([]);
                    setGruposDisponiblesDocente([]);
                })
                .catch(err => console.error("Error fetching materias", err))
                .finally(() => setLoadingMaterias(false));
        }
    }, [carreraDocente, detectedRole]);

    // Filtrar Grupos Libres cuando el Docente selecciona una Materia
    useEffect(() => {
        if (materiaDocente) {
            const mat = materiasDisponiblesDocente.find(m => m.materia.id === materiaDocente);
            if (mat) {
                setGruposDisponiblesDocente(mat.gruposDisponibles || []);
            } else {
                setGruposDisponiblesDocente([]);
            }
            setGruposDocente([]); // Reset grupos seleccionados si cambia la materia
        }
    }, [materiaDocente, materiasDisponiblesDocente]);

    if (loading) return <div style={styles.loadingContainer}><div style={styles.spinner}></div></div>;

    // Redirect based on role
    // Only redirect if authenticated AND NOT currently in the middle of filling profile info
    if (isAuthenticated && mode !== 'register-info') {
        if (rol === 'admin' || rol === 'SuperAdmin') {
            return <Navigate to="/admin" replace />;
        }
        return <Navigate to="/dashboard" replace />;
    }

    // Detectar rol y validar email
    const handleEmailChange = (e) => {
        const value = e.target.value;
        setEmail(value);
        setError('');

        if (value.includes('@')) {
            const rol = detectarRol(value);
            setDetectedRole(rol);
        } else {
            setDetectedRole(null);
        }
    };

    // Login con email/password
    const handleLogin = async (e) => {
        e.preventDefault();
        setError('');
        setSubmitting(true);

        try {
            const result = await signInWithEmailAndPassword(auth, email, password);
            await checkAdminSetup(result.user);
        } catch (err) {
            console.error('Login error:', err);
            if (err.code === 'auth/user-not-found' || err.code === 'auth/invalid-credential') {
                // Smart Auth: Si el usuario no existe (o credenciales inválidas que podrían ser nuevo usuario)
                // Verificamos si parece ser una contraseña válida para registro
                if (password.length >= 6) {
                    // Si es nuevo usuario, lo mandamos a completar perfil
                    // Pero si es credencial inválida de usuario existente, esto podría ser confuso.
                    // Firebase unifica "wrong-password" y "user-not-found" en "invalid-credential" a veces por seguridad.
                    // Sin validación previa de existencia, asumimos intento de registro si la contraseña cumple politicas.

                    // Nota: Para saber con certeza si existe el email, necesitaríamos fetchSignInMethodsForEmail, 
                    // pero eso puede estar protegido. 
                    // Por ahora, asumiremos que si falla el login, intentamos flujo de registro.
                    // Si el usuario ya existe y puso mal la pass, el "createUser" fallará con 'email-already-in-use'.

                    setMode('register-info');
                    setError(''); // Limpiamos error visual
                } else {
                    setError('La contraseña debe tener al menos 6 caracteres');
                }
            } else if (err.code === 'auth/wrong-password') {
                setError('Contraseña incorrecta');
            } else {
                setError(err.message);
            }
        } finally {
            setSubmitting(false);
        }
    };

    // Ir al paso de registro (Manual, por si acaso)
    const handleGoToRegister = () => {
        setError('');

        if (!email || !email.includes('@')) {
            setError('Ingresa un correo válido');
            return;
        }

        const rol = detectarRol(email);
        setDetectedRole(rol);

        if (!password || password.length < 6) {
            setError('La contraseña debe tener al menos 6 caracteres');
            return;
        }

        setMode('register-info');
    };

    // Login con Google
    const handleGoogleLogin = async () => {
        setError('');
        setSubmitting(true);

        try {
            const result = await signInWithPopup(auth, googleProvider);
            await checkAdminSetup(result.user);
            const userEmail = result.user.email;
            const rol = detectarRol(userEmail);

            if (rol === 'Invitado') {
                setError('Has ingresado como Invitado. Solo puedes ver la galería pública.');
            }
        } catch (err) {
            console.error('Google login error:', err);
            if (err.code !== 'auth/popup-closed-by-user') {
                setError('Error al iniciar sesión con Google');
            }
        } finally {
            setSubmitting(false);
        }
    };

    // Completar registro (Se mantiene igual, la lógica de roles es la clave)
    const handleRegistro = async (e) => {
        e.preventDefault();
        setError('');
        setSubmitting(true);

        // Validaciones generales
        if (!nombre.trim()) { setError('Nombre requerido'); setSubmitting(false); return; }

        // Validaciones por rol
        if (detectedRole === 'Alumno') {
            if (!grupo) { setError('Selecciona tu grupo'); setSubmitting(false); return; }
            if (!carrera) { setError('Selecciona tu carrera'); setSubmitting(false); return; }
        }

        if (detectedRole === 'Docente') {
            if (!profesion) { setError('Indica tu profesión'); setSubmitting(false); return; }
            if (!carreraDocente) { setError('Selecciona una carrera impartida'); setSubmitting(false); return; }
            if (!materiaDocente) { setError('Selecciona la materia que impartes'); setSubmitting(false); return; }
            if (gruposDocente.length === 0) { setError('Selecciona al menos un grupo'); setSubmitting(false); return; }
        }

        if (detectedRole === 'Invitado') {
            if (!organizacion) { setError('Indica tu organización o empresa'); setSubmitting(false); return; }
        }

        try {
            // 1. Firebase Auth - Crear Usuario
            // Si el usuario ya existe (porque venimos de un login fallido por pass incorrecta), esto fallará
            const userCredential = await createUserWithEmailAndPassword(auth, email, password);

            // Transformar nombres a formato Título (Ej: Uziel Isaac)
            const toTitleCase = (str) => {
                if (!str) return '';
                return str.toLowerCase().split(' ').map(word => {
                    return word.charAt(0).toUpperCase() + word.slice(1);
                }).join(' ');
            };

            const nombreFinal = toTitleCase(nombre.trim());
            const apellidoPaternoFinal = toTitleCase(apellidoPaterno.trim());
            const apellidoMaternoFinal = toTitleCase(apellidoMaterno.trim());

            // 2. Backend Register
            const payload = {
                firebaseUid: userCredential.user.uid,
                email: email,
                nombre: nombreFinal,
                apellidoPaterno: apellidoPaternoFinal,
                apellidoMaterno: apellidoMaternoFinal,
                rol: detectedRole,
                // Alumno
                matricula: detectedRole === 'Alumno' ? extraerMatricula(email) : null,
                grupoId: grupo || null,
                carreraId: carrera || null,
                // Docente
                profesion: profesion || null,
                asignaciones: detectedRole === 'Docente' ? [{
                    carreraId: carreraDocente,
                    materiaId: materiaDocente,
                    gruposIds: gruposDocente
                }] : null,
                // Invitado
                organizacion: organizacion || null
            };

            await api.post('/api/auth/register', payload);

            // 3. RECUPERAR DATOS FINALES
            // Forzamos actualización del estado global con los datos recién guardados
            await refreshUserData();

            // Regresamos el modo a login para que el efecto superior detecte la autenticación
            // y haga la redirección basada en el rol de forma automática sin recargar
            setMode('login');

        } catch (err) {
            console.error('Registro error:', err);
            if (err.code === 'auth/email-already-in-use') {
                // Si falla la creación porque existe, significa que el intento original de login
                // falló por contraseña incorrecta (o algo similar).
                // Regresamos al login y avisamos.
                setMode('login');
                setError('Este correo ya está registrado. Verifica tu contraseña.');
            } else {
                setError(err.message || 'Error al registrar usuario');
            }
        } finally {
            setSubmitting(false);
        }
    };

    // Toggle grupo para docente
    const toggleGrupoDocente = (g) => {
        setGruposDocente(prev =>
            prev.includes(g) ? prev.filter(x => x !== g) : [...prev, g]
        );
    };

    // Icono de rol
    const RoleIcon = ({ role, size = 20 }) => {
        if (role === 'Alumno') return <GraduationCap size={size} />;
        if (role === 'Docente') return <UserCheck size={size} />;
        return <User size={size} />;
    };

    // Vista de Login
    if (mode === 'login') {
        return (
            <div style={styles.pageContainer}>
                <CloudBackground />
                <div style={styles.cardContainer}>
                    {/* Logo */}
                    <div style={styles.logoSection}>
                        <div style={styles.logoIcon}>
                            <span style={styles.logoText}>B</span>
                        </div>
                        <h1 style={styles.title}>Byfrost®</h1>
                        <p style={styles.subtitle}>DSM Edition</p>
                    </div>

                    {/* Card */}
                    <div style={styles.card}>
                        <h2 style={styles.cardTitle}>Bienvenido</h2>
                        <p style={styles.cardSubtitle}>Ingresa tu correo institucional para continuar</p>

                        <form onSubmit={handleLogin} style={styles.form}>
                            {/* Email */}
                            <div style={styles.inputGroup}>
                                <label style={styles.label}>Correo Electrónico</label>
                                <input
                                    type="email"
                                    value={email}
                                    onChange={handleEmailChange}
                                    placeholder="tu.correo@utmetropolitana.edu.mx"
                                    style={styles.input}
                                    required
                                />
                                {detectedRole && detectedRole !== 'Invitado' && (
                                    <div style={{
                                        ...styles.rolBadge,
                                        backgroundColor: detectedRole === 'Alumno' ? '#dbeafe' : '#dcfce7',
                                        color: detectedRole === 'Alumno' ? '#1d4ed8' : '#15803d'
                                    }}>
                                        <RoleIcon role={detectedRole} size={16} />
                                        <span style={{ marginLeft: '8px' }}>Rol detectado: {detectedRole}</span>
                                    </div>
                                )}
                            </div>

                            {/* Password */}
                            <div style={styles.inputGroup}>
                                <label style={styles.label}>Contraseña</label>
                                <input
                                    type="password"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    placeholder="••••••••"
                                    style={styles.input}
                                    required
                                    minLength={6}
                                />
                            </div>

                            {/* Error */}
                            {error && (
                                <div style={styles.error}>
                                    <AlertCircle size={16} style={{ flexShrink: 0 }} />
                                    <span style={{ marginLeft: '8px' }}>{error}</span>
                                </div>
                            )}

                            {/* Submit Login */}
                            <button
                                type="submit"
                                disabled={submitting}
                                style={{
                                    ...styles.primaryBtn,
                                    opacity: submitting ? 0.7 : 1
                                }}
                            >
                                {submitting ? 'Procesando...' : 'Continuar'}
                            </button>
                        </form>

                        {/* Divider */}
                        <div style={styles.divider}>
                            <div style={styles.dividerLine}></div>
                            <span style={styles.dividerText}>o</span>
                            <div style={styles.dividerLine}></div>
                        </div>

                        {/* Google */}
                        <button
                            type="button"
                            onClick={handleGoogleLogin}
                            disabled={submitting}
                            style={styles.googleBtn}
                        >
                            <svg viewBox="0 0 24 24" width="20" height="20" style={{ marginRight: '10px' }}>
                                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
                                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
                                <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
                                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
                            </svg>
                            Continuar con Google
                        </button>
                    </div>
                </div>

                {/* Footer */}
                <p style={styles.footer}>Universidad Tecnológica Metropolitana</p>
            </div>
        );
    }

    // Vista de Registro - Información adicional
    if (mode === 'register-info') {
        return (
            <div style={styles.pageContainer}>
                <CloudBackground />
                <div style={styles.cardContainer}>
                    {/* Logo */}
                    <div style={styles.logoSection}>
                        <div style={styles.logoIcon}>
                            <span style={styles.logoText}>B</span>
                        </div>
                        <h1 style={styles.title}>Byfrost®</h1>
                        <p style={styles.subtitle}>DSM Edition</p>
                    </div>

                    {/* Card */}
                    <div style={styles.card}>
                        {/* Header con botón atrás */}
                        <button
                            type="button"
                            onClick={() => setMode('login')}
                            style={styles.backBtn}
                        >
                            <ArrowLeft size={18} />
                            <span style={{ marginLeft: '6px' }}>Volver</span>
                        </button>

                        <h2 style={styles.cardTitle}>Completa tu Perfil</h2>
                        <p style={styles.cardSubtitle}>
                            {detectedRole === 'Alumno'
                                ? 'Selecciona tu grupo para continuar'
                                : 'Selecciona los grupos que atiendes'}
                        </p>

                        {/* Rol detectado */}
                        <div style={{
                            ...styles.rolBadgeLarge,
                            backgroundColor: detectedRole === 'Alumno' ? '#eff6ff' : '#f0fdf4',
                            borderColor: detectedRole === 'Alumno' ? '#bfdbfe' : '#bbf7d0'
                        }}>
                            <div style={styles.rolBadgeHeader}>
                                <RoleIcon role={detectedRole} size={24} />
                                <span style={{
                                    marginLeft: '10px',
                                    fontWeight: '600',
                                    color: detectedRole === 'Alumno' ? '#1d4ed8' : '#15803d'
                                }}>
                                    {detectedRole}
                                </span>
                            </div>
                            <p style={styles.rolBadgeEmail}>{email}</p>
                            {detectedRole === 'Alumno' && (
                                <p style={styles.rolBadgeMatricula}>Matrícula: {extraerMatricula(email)}</p>
                            )}
                        </div>

                        <form onSubmit={handleRegistro} style={styles.form}>
                            {/* Nombre, Apellido Paterno, Apellido Materno */}
                            <div style={styles.inputGroup}>
                                <label style={styles.label}>Nombre(s)</label>
                                <input
                                    type="text"
                                    value={nombre}
                                    onChange={(e) => setNombre(e.target.value)}
                                    placeholder="Juan Carlos"
                                    style={styles.input}
                                    required
                                />
                            </div>

                            <div style={styles.inputGroup}>
                                <label style={styles.label}>Apellido Paterno</label>
                                <input
                                    type="text"
                                    value={apellidoPaterno}
                                    onChange={(e) => setApellidoPaterno(e.target.value)}
                                    placeholder="Pérez"
                                    style={styles.input}
                                    required
                                />
                            </div>

                            <div style={styles.inputGroup}>
                                <label style={styles.label}>Apellido Materno</label>
                                <input
                                    type="text"
                                    value={apellidoMaterno}
                                    onChange={(e) => setApellidoMaterno(e.target.value)}
                                    placeholder="García"
                                    style={styles.input}
                                    required
                                />
                            </div>

                            {/* Carrera para Alumno */}
                            {detectedRole === 'Alumno' && (
                                <>
                                    <div style={styles.inputGroup}>
                                        <label style={styles.label}>Tu Carrera</label>
                                        <select
                                            value={carrera}
                                            onChange={(e) => setCarrera(e.target.value)}
                                            style={styles.select}
                                            required
                                        >
                                            <option value="">Selecciona tu carrera...</option>
                                            {carrerasDisponibles.map(c => (
                                                <option key={c.id} value={c.id}>{c.nombre}</option>
                                            ))}
                                        </select>
                                    </div>

                                    <div style={styles.inputGroup}>
                                        <label style={styles.label}>Tu Grupo</label>
                                        <select
                                            value={grupo}
                                            onChange={(e) => setGrupo(e.target.value)}
                                            style={styles.select}
                                            required
                                        >
                                            <option value="">Selecciona tu grupo...</option>
                                            {gruposDisponibles.map(g => (
                                                <option key={g.id} value={g.id}>{g.nombre}</option>
                                            ))}
                                        </select>
                                    </div>
                                </>
                            )}

                            {/* Campos para Docente */}
                            {detectedRole === 'Docente' && (
                                <>
                                    <div style={styles.inputGroup}>
                                        <label style={styles.label}>Profesión / Título</label>
                                        <input
                                            type="text"
                                            value={profesion}
                                            onChange={(e) => setProfesion(e.target.value)}
                                            placeholder="Ej. Ing. en Sistemas Computacionales"
                                            style={styles.input}
                                            required
                                        />
                                    </div>

                                    <div style={styles.inputGroup}>
                                        <label style={styles.label}>Carrera en la que impartes</label>
                                        <select
                                            value={carreraDocente}
                                            onChange={(e) => setCarreraDocente(e.target.value)}
                                            style={styles.select}
                                            required
                                        >
                                            <option value="">Selecciona tu carrera...</option>
                                            {carrerasDisponibles.map(c => (
                                                <option key={c.id} value={c.id}>{c.nombre}</option>
                                            ))}
                                        </select>
                                    </div>

                                    {carreraDocente && (
                                        <div style={styles.inputGroup}>
                                            <label style={styles.label}>Materia Asignada {loadingMaterias && "(Cargando...)"}</label>
                                            <select
                                                value={materiaDocente}
                                                onChange={(e) => setMateriaDocente(e.target.value)}
                                                style={styles.select}
                                                required
                                                disabled={loadingMaterias || materiasDisponiblesDocente.length === 0}
                                            >
                                                <option value="">Selecciona una materia disponible...</option>
                                                {materiasDisponiblesDocente.map(item => (
                                                    <option key={item.materia.id} value={item.materia.id}>
                                                        {item.materia.nombre} ({item.materia.clave}) - Cuatri {item.materia.cuatrimestre}
                                                    </option>
                                                ))}
                                            </select>
                                            {!loadingMaterias && materiasDisponiblesDocente.length === 0 && (
                                                <p style={{ ...styles.helperText, color: '#ef4444' }}>No hay materias con grupos libres en esta carrera.</p>
                                            )}
                                        </div>
                                    )}

                                    {materiaDocente && gruposDisponiblesDocente.length > 0 && (
                                        <div style={styles.inputGroup}>
                                            <label style={styles.label}>Grupos Disponibles (Selecciona uno o varios)</label>
                                            <div style={styles.gruposGrid}>
                                                {gruposDisponiblesDocente.map(g => (
                                                    <button
                                                        key={g.id}
                                                        type="button"
                                                        onClick={() => toggleGrupoDocente(g.id)}
                                                        style={{
                                                            ...styles.grupoChip,
                                                            backgroundColor: gruposDocente.includes(g.id) ? '#111827' : '#f3f4f6',
                                                            color: gruposDocente.includes(g.id) ? '#fff' : '#374151',
                                                            borderColor: gruposDocente.includes(g.id) ? '#111827' : '#d1d5db'
                                                        }}
                                                    >
                                                        {g.nombre}
                                                        {gruposDocente.includes(g.id) && <Check size={14} style={{ marginLeft: '4px' }} />}
                                                    </button>
                                                ))}
                                            </div>
                                        </div>
                                    )}
                                </>
                            )}

                            {/* Campos para Invitado */}
                            {detectedRole === 'Invitado' && (
                                <div style={styles.inputGroup}>
                                    <label style={styles.label}>Organización / Empresa</label>
                                    <input
                                        type="text"
                                        value={organizacion}
                                        onChange={(e) => setOrganizacion(e.target.value)}
                                        placeholder="Ej. Google, Freelance, etc."
                                        style={styles.input}
                                        required
                                    />
                                </div>
                            )}

                            {/* Error */}
                            {error && (
                                <div style={styles.error}>
                                    <AlertCircle size={16} style={{ flexShrink: 0 }} />
                                    <span style={{ marginLeft: '8px' }}>{error}</span>
                                </div>
                            )}

                            {/* Submit */}
                            <button
                                type="submit"
                                disabled={submitting}
                                style={{
                                    ...styles.primaryBtn,
                                    opacity: submitting ? 0.7 : 1
                                }}
                            >
                                {submitting ? 'Registrando...' : 'Crear Cuenta'}
                            </button>
                        </form>
                    </div>

                    {/* Footer */}
                    <p style={styles.footer}>Universidad Tecnológica Metropolitana</p>
                </div>
            </div>
        );
    }
}

// Estilos inline para garantizar renderizado correcto
const styles = {
    pageContainer: {
        minHeight: '100vh',
        width: '100vw',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        background: 'transparent',
        padding: '20px',
        fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
        position: 'relative',
        zIndex: 1,
        boxSizing: 'border-box'
    },
    cardContainer: {
        width: '100%',
        maxWidth: '420px',
        position: 'relative',
        zIndex: 10,
        margin: '0 auto'
    },
    logoSection: {
        textAlign: 'center',
        marginBottom: '24px'
    },
    logoIcon: {
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        width: '60px',
        height: '60px',
        backgroundColor: '#111827',
        borderRadius: '16px',
        marginBottom: '16px',
        boxShadow: '0 4px 12px rgba(17, 24, 39, 0.25)'
    },
    logoText: {
        fontSize: '24px',
        fontWeight: '800',
        color: '#fff'
    },
    title: {
        fontSize: '28px',
        fontWeight: '700',
        color: '#111827',
        margin: '0',
        letterSpacing: '-0.5px'
    },
    subtitle: {
        fontSize: '14px',
        color: '#6b7280',
        margin: '6px 0 0 0'
    },
    card: {
        backgroundColor: '#fff',
        borderRadius: '20px',
        boxShadow: '0 4px 24px rgba(0, 0, 0, 0.06)',
        border: '1px solid #e5e7eb',
        padding: '32px'
    },
    cardTitle: {
        fontSize: '20px',
        fontWeight: '600',
        color: '#111827',
        margin: '0 0 4px 0',
        textAlign: 'center'
    },
    cardSubtitle: {
        fontSize: '14px',
        color: '#6b7280',
        margin: '0 0 24px 0',
        textAlign: 'center'
    },
    form: {
        display: 'flex',
        flexDirection: 'column',
        gap: '16px'
    },
    inputGroup: {
        display: 'flex',
        flexDirection: 'column',
        gap: '6px'
    },
    label: {
        fontSize: '14px',
        fontWeight: '500',
        color: '#374151'
    },
    input: {
        width: '100%',
        padding: '14px 16px',
        fontSize: '15px',
        border: '1.5px solid #e5e7eb',
        borderRadius: '12px',
        outline: 'none',
        transition: 'border-color 0.2s, box-shadow 0.2s',
        boxSizing: 'border-box',
        backgroundColor: '#fafafa'
    },
    select: {
        width: '100%',
        padding: '14px 16px',
        fontSize: '15px',
        border: '1.5px solid #e5e7eb',
        borderRadius: '12px',
        outline: 'none',
        boxSizing: 'border-box',
        backgroundColor: '#fafafa',
        cursor: 'pointer'
    },
    rolBadge: {
        display: 'flex',
        alignItems: 'center',
        marginTop: '8px',
        padding: '10px 14px',
        borderRadius: '10px',
        fontSize: '14px',
        fontWeight: '500'
    },
    rolBadgeLarge: {
        padding: '16px',
        borderRadius: '12px',
        border: '1px solid',
        marginBottom: '20px'
    },
    rolBadgeHeader: {
        display: 'flex',
        alignItems: 'center'
    },
    rolBadgeEmail: {
        fontSize: '13px',
        color: '#6b7280',
        margin: '8px 0 0 0'
    },
    rolBadgeMatricula: {
        fontSize: '12px',
        color: '#9ca3af',
        margin: '4px 0 0 0'
    },
    error: {
        display: 'flex',
        alignItems: 'center',
        padding: '12px 16px',
        backgroundColor: '#fef2f2',
        border: '1px solid #fecaca',
        borderRadius: '10px',
        color: '#dc2626',
        fontSize: '14px'
    },
    primaryBtn: {
        width: '100%',
        padding: '14px',
        backgroundColor: '#111827',
        color: '#fff',
        fontSize: '15px',
        fontWeight: '600',
        border: 'none',
        borderRadius: '12px',
        cursor: 'pointer',
        transition: 'transform 0.1s, box-shadow 0.2s',
        boxShadow: '0 2px 8px rgba(17, 24, 39, 0.15)'
    },
    googleBtn: {
        width: '100%',
        padding: '14px',
        backgroundColor: '#fff',
        color: '#374151',
        fontSize: '15px',
        fontWeight: '500',
        border: '1.5px solid #e5e7eb',
        borderRadius: '12px',
        cursor: 'pointer',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        transition: 'background-color 0.2s'
    },
    backBtn: {
        display: 'flex',
        alignItems: 'center',
        padding: '8px 0',
        marginBottom: '16px',
        color: '#6b7280',
        fontSize: '14px',
        background: 'none',
        border: 'none',
        cursor: 'pointer'
    },
    footer: {
        textAlign: 'center',
        fontSize: '12px',
        color: '#9ca3af',
        marginTop: '24px'
    },
    loadingContainer: {
        minHeight: '100vh',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#f9fafb',
        gap: '16px'
    },
    spinner: {
        width: '40px',
        height: '40px',
        border: '3px solid #e5e7eb',
        borderTopColor: '#111827',
        borderRadius: '50%',
        animation: 'spin 0.8s linear infinite'
    },
    loadingText: {
        fontSize: '14px',
        color: '#6b7280'
    },
    helperText: {
        fontSize: '13px',
        color: '#9ca3af',
        margin: '0 0 8px 0'
    },
    gruposGrid: {
        display: 'grid',
        gridTemplateColumns: 'repeat(4, 1fr)',
        gap: '8px'
    },
    grupoChip: {
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '10px',
        border: '1.5px solid',
        borderRadius: '8px',
        fontSize: '14px',
        fontWeight: '500',
        cursor: 'pointer',
        transition: 'all 0.15s'
    }
};
