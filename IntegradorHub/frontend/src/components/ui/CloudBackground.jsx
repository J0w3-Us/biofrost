import { useRef, useMemo } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';

// Componente de una nube individual estilo caricatura
function Cloud({ position, scale, speed }) {
    const groupRef = useRef();
    const initialX = position[0];
    const initialY = position[1];

    useFrame((state) => {
        if (groupRef.current) {
            // Movimiento horizontal suave
            groupRef.current.position.x = initialX + Math.sin(state.clock.elapsedTime * speed) * 0.8;
            // Flotación vertical sutil
            groupRef.current.position.y = initialY + Math.sin(state.clock.elapsedTime * speed * 0.7 + position[0]) * 0.15;
        }
    });

    // Forma de nube con esferas - estilo cartoon
    const cloudParts = useMemo(() => {
        const baseScale = scale;
        return [
            { pos: [0, 0, 0], size: 0.5 * baseScale },
            { pos: [0.35 * baseScale, 0.05, 0], size: 0.4 * baseScale },
            { pos: [-0.35 * baseScale, 0.03, 0], size: 0.38 * baseScale },
            { pos: [0.18 * baseScale, 0.2, 0], size: 0.32 * baseScale },
            { pos: [-0.15 * baseScale, 0.18, 0], size: 0.3 * baseScale },
            { pos: [0.55 * baseScale, -0.05, 0], size: 0.28 * baseScale },
            { pos: [-0.5 * baseScale, -0.03, 0], size: 0.25 * baseScale },
        ];
    }, [scale]);

    return (
        <group ref={groupRef} position={position}>
            {cloudParts.map((part, i) => (
                <mesh key={i} position={part.pos}>
                    <sphereGeometry args={[part.size, 24, 24]} />
                    <meshBasicMaterial
                        color="#ffffff"
                        transparent
                        opacity={0.95}
                    />
                </mesh>
            ))}
        </group>
    );
}

// Escena principal
function Scene() {
    // Nubes con tamaños aleatorios para variedad
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
            {/* Iluminación simple */}
            <ambientLight intensity={1} />

            {/* Nubes estilo cartoon */}
            {clouds.map((cloud, i) => (
                <Cloud key={i} {...cloud} />
            ))}
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
            background: 'linear-gradient(180deg, #dbeafe 0%, #f0f9ff 40%, #f8fafc 100%)',
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
