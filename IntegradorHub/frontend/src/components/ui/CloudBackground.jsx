import { useRef, useMemo } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';

// Componente de una nube individual estilo caricatura mágica
function Cloud({ position, scale, speed }) {
    const groupRef = useRef();
    const initialX = position[0];
    const initialY = position[1];

    useFrame((state) => {
        if (groupRef.current) {
            groupRef.current.position.x = initialX + Math.sin(state.clock.elapsedTime * speed) * 0.8;
            groupRef.current.position.y = initialY + Math.sin(state.clock.elapsedTime * speed * 0.7 + position[0]) * 0.15;
            groupRef.current.rotation.z = Math.sin(state.clock.elapsedTime * speed * 0.3) * 0.015;
        }
    });

    // Forma esponjosa estilo cartoon
    const cloudParts = useMemo(() => {
        const s = scale;
        return [
            // Centro grande
            { pos: [0, 0, 0], size: 0.55 * s },
            // Cuerpo lateral
            { pos: [0.4 * s, 0.02, 0.05], size: 0.45 * s },
            { pos: [-0.4 * s, 0.02, 0.05], size: 0.43 * s },
            // Topes esponjosos tipo caricatura
            { pos: [0.12 * s, 0.3, 0.02], size: 0.4 * s },
            { pos: [-0.18 * s, 0.26, 0.02], size: 0.36 * s },
            { pos: [0.32 * s, 0.18, 0.03], size: 0.32 * s },
            // Bordes laterales
            { pos: [0.65 * s, -0.06, 0], size: 0.3 * s },
            { pos: [-0.58 * s, -0.04, 0], size: 0.28 * s },
            // Relleno para volumen cartoon
            { pos: [0, 0.12, 0.1], size: 0.42 * s },
            { pos: [-0.08 * s, -0.08, 0.06], size: 0.36 * s },
        ];
    }, [scale]);

    return (
        <group ref={groupRef} position={position}>
            {/* Partes de la nube - blanco puro brillante estilo cartoon */}
            {cloudParts.map((part, i) => (
                <mesh key={i} position={part.pos}>
                    <sphereGeometry args={[part.size, 32, 32]} />
                    <meshBasicMaterial
                        color="#ffffff"
                        transparent
                        opacity={0.97}
                    />
                </mesh>
            ))}
            {/* Borde/contorno suave exterior (sombra cartoon) */}
            {cloudParts.slice(0, 5).map((part, i) => (
                <mesh key={`outline-${i}`} position={[part.pos[0], part.pos[1] - 0.03, part.pos[2] - 0.15]}>
                    <sphereGeometry args={[part.size * 1.04, 24, 24]} />
                    <meshBasicMaterial
                        color="#c7d2fe"
                        transparent
                        opacity={0.25}
                    />
                </mesh>
            ))}
        </group>
    );
}

// Partículas mágicas de brillo
function MagicSparkles() {
    const particlesRef = useRef();
    const count = 45;

    const positions = useMemo(() => {
        const pos = new Float32Array(count * 3);
        for (let i = 0; i < count; i++) {
            pos[i * 3] = (Math.random() - 0.5) * 16;
            pos[i * 3 + 1] = (Math.random() - 0.5) * 10;
            pos[i * 3 + 2] = (Math.random() - 0.5) * 6 - 3;
        }
        return pos;
    }, []);

    useFrame((state) => {
        if (particlesRef.current) {
            particlesRef.current.rotation.y = state.clock.elapsedTime * 0.015;
            const material = particlesRef.current.material;
            material.opacity = 0.3 + Math.sin(state.clock.elapsedTime * 2) * 0.2;
        }
    });

    return (
        <points ref={particlesRef}>
            <bufferGeometry>
                <bufferAttribute
                    attach="attributes-position"
                    count={count}
                    array={positions}
                    itemSize={3}
                />
            </bufferGeometry>
            <pointsMaterial
                color="#d8b4fe"
                size={0.06}
                transparent
                opacity={0.45}
                sizeAttenuation
            />
        </points>
    );
}

// Escena principal
function Scene() {
    const clouds = useMemo(() => [
        { position: [-5, 2.5, -4], scale: 1.8, speed: 0.15 },
        { position: [5, 2, -5], scale: 1.2, speed: 0.2 },
        { position: [-2, -1.5, -3], scale: 0.9, speed: 0.25 },
        { position: [3, -0.5, -4], scale: 1.4, speed: 0.18 },
        { position: [0, 3, -6], scale: 2.2, speed: 0.12 },
        { position: [-6, 0.5, -5], scale: 1.1, speed: 0.22 },
        { position: [6, -2, -4], scale: 0.8, speed: 0.28 },
        { position: [-3.5, 1, -4.5], scale: 1.5, speed: 0.16 },
        { position: [2, -2.5, -5], scale: 1.0, speed: 0.24 },
    ], []);

    return (
        <>
            <ambientLight intensity={1} />

            {clouds.map((cloud, i) => (
                <Cloud key={i} {...cloud} />
            ))}

            <MagicSparkles />
        </>
    );
}

// Componente exportable
export function CloudBackground() {
    return (
        <div style={{
            position: 'fixed',
            top: 0,
            left: 0,
            width: '100vw',
            height: '100vh',
            zIndex: 0,
            background: 'linear-gradient(180deg, #c7d2fe 0%, #ddd6fe 20%, #e0e7ff 40%, #ede9fe 60%, #f5f3ff 80%, #faf5ff 100%)',
            pointerEvents: 'none'
        }}>
            <Canvas
                camera={{ position: [0, 0, 6], fov: 50 }}
                style={{ background: 'transparent' }}
            >
                <Scene />
            </Canvas>
        </div>
    );
}

export default CloudBackground;
