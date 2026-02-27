# 🔦 Correcciones de Lightbox y Refinamiento de Interfaz (Febrero 2026)

Este documento detalla las soluciones técnicas implementadas para resolver fallos intermitentes en el visor de medios (Lightbox) y las mejoras en la jerarquía visual de los detalles del proyecto.

---

## 🛠️ Corrección de Errores: Lightbox Intermitente

### 1. Implementación de React Portals
- **El Problema:** El Lightbox a veces no respondía a los clics o se veía interrumpido por el contexto de apilamiento (Stacking Context) de los modales padres o animaciones de Framer Motion.
- **La Solución:** Se refactorizaron los componentes `ProjectDetailsModal` y `ShowcaseCard` para utilizar `createPortal`. Esto permite que el Lightbox se monte directamente en el `document.body`, independientemente de dónde se encuentre el botón que lo activa, eliminando conflictos de `z-index` y `overflow`.

### 2. Estabilidad de Estado y Remontado de Componentes
- **Remontado Forzado:** En `ShowcasePage.jsx`, se añadió la prop `key={selectedProject.id}` al `ProjectDetailsModal`. Esto garantiza que React destruya y cree el componente desde cero cada vez que el usuario cambia de proyecto, evitando que estados residuales del proyecto anterior afecten al nuevo.
- **Reinicio Manual:** Se implementó un `useEffect` que escucha cambios en el ID del proyecto para resetear slides, estados de reproducción de video y visibilidad del lightbox antes de que el usuario interactúe.

### 3. Solución de "Miss-Clicks" por Animaciones CSS
- **Conflictos de Transformación:** Se detectó que la propiedad `hover:scale-105` en las imágenes de los carruseles desplazaba el área visual fuera del área de colisión del elemento (hitbox), causando que clics rápidos en la imagen fueran ignorados por el navegador.
- **Ajuste:** Se eliminaron las animaciones de escala en el carrusel para garantizar que el puntero del mouse siempre coincida con el elemento interactuable.

---

## 🎨 Refinamientos de Interfaz y Experiencia de Usuario (UX)

### 1. Inmersión Total en Pantalla Completa
- **Dimensiones Reales:** El visor de medios ahora ocupa exactamente el **90% del ancho y alto de la pantalla** (`w-[90vw] h-[90vh]`), maximizando el espacio de visualización sin importar la relación de aspecto del contenido original.
- **Fondo Neutral:** Se estandarizó el uso de `bg-black/95` con `backdrop-blur-md` para crear una atmósfera inmersiva tipo galería profesional.

### 2. Botón de Cierre Inteligente
- **Reducción de Ruido Visual:** El botón de cerrar (`X`) en el Lightbox ahora se oculta por defecto para no distraer.
- **Aparición por Hover:** Se implementó una transición suave que revela el botón de cierre únicamente cuando el usuario mueve el cursor sobre el área del lightbox, manteniendo la interfaz limpia mientras se visualiza el contenido.

### 3. Limpieza de Cabecera (Header)
- **Simplificación de Badges:** Para reducir la carga cognitiva, se eliminaron los badges de "Borrador" y "Materia" de la parte superior del modal.
- **Nueva Jerarquía de Materia:** El nombre de la materia ahora se despliega como un subtítulo tipográfico debajo del título del proyecto, mejorando la legibilidad.
- **Privacidad Interactiva:** El estado de visibilidad ("Público"/"Privado") se mantiene como un elemento interactivo para los líderes de proyecto, permitiéndoles cambiar la privacidad con un solo clic.

---
*Ultima actualización: 25 de Febrero de 2026*
