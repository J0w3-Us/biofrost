# 07 — Componentes UI Reutilizables (`components/ui/`)

## Resumen del Módulo

Librería interna de componentes de diseño. Todos los componentes son puros (sin lógica de negocio) y estilizados con Tailwind CSS. Proporcionan una base visual consistente para toda la aplicación.

```
components/ui/
├── Button.jsx            # Botón con variantes y estados
├── Input.jsx             # Input, Textarea y Select
├── Modal.jsx             # Modal con animación
├── Card.jsx              # Card y subcomponentes
├── Badge.jsx             # Badge de estado
└── CloudBackground.jsx   # Fondo 3D animado
```

---

## 1. `Button.jsx`

### Descripción

Componente de botón altamente configurable con soporte para variantes visuales, tamaños, estados y elementos adicionales como íconos.

### Props

| Prop | Tipo | Default | Descripción |
|------|------|---------|-------------|
| `variant` | `string` | `'primary'` | Estilo visual del botón |
| `size` | `string` | `'md'` | Tamaño del botón |
| `disabled` | `boolean` | `false` | Deshabilita el botón |
| `loading` | `boolean` | `false` | Muestra spinner y deshabilita |
| `fullWidth` | `boolean` | `false` | Botón de ancho completo |
| `leftIcon` | `ReactNode` | `null` | Ícono a la izquierda del texto |
| `rightIcon` | `ReactNode` | `null` | Ícono a la derecha del texto |
| `onClick` | `function` | — | Handler de click |
| `type` | `string` | `'button'` | Tipo HTML del botón |
| `children` | `ReactNode` | — | Contenido del botón |

### Variantes

| Variant | Estilo |
|---------|--------|
| `primary` | Fondo oscuro (`gray-900`), texto blanco |
| `secondary` | Fondo gris claro, texto oscuro |
| `danger` | Fondo rojo, texto blanco |
| `ghost` | Transparente, borde visible |
| `link` | Sin fondo, estilo de enlace subrayado |

### Tamaños

| Size | Padding | Font Size |
|------|---------|-----------|
| `sm` | `px-3 py-1.5` | `text-sm` |
| `md` | `px-4 py-2` | `text-sm` |
| `lg` | `px-6 py-3` | `text-base` |

### Estado de Carga

Cuando `loading === true`:
- Muestra un spinner (`animate-spin`) antes del texto.
- Agrega el atributo `disabled`.
- Cambia el cursor a `cursor-not-allowed`.

### Ejemplo de Uso

```jsx
<Button
  variant="primary"
  size="lg"
  loading={isSubmitting}
  leftIcon={<Save size={16} />}
  onClick={handleSave}
>
  Guardar Cambios
</Button>
```

---

## 2. `Input.jsx`

### Descripción

Exporta tres componentes de entrada de datos: `Input`, `Textarea` y `Select`. Todos comparten la misma interfaz de props y sistema de estados visuales.

### Props Compartidas

| Prop | Tipo | Descripción |
|------|------|-------------|
| `label` | `string` | Etiqueta visible sobre el campo |
| `error` | `string` | Mensaje de error (activa estilo de error) |
| `helperText` | `string` | Texto de ayuda bajo el campo |
| `state` | `string` | Estado visual (`default`, `success`, `error`) |
| `disabled` | `boolean` | Deshabilita el campo |
| `leftIcon` | `ReactNode` | Ícono dentro del campo (lado izquierdo) |
| `rightIcon` | `ReactNode` | Ícono dentro del campo (lado derecho) |
| `...props` | HTMLInputProps | Cualquier prop nativo de `<input>` |

### Estados Visuales

| Estado | Color de borde | Ícono automático |
|--------|---------------|-----------------|
| `default` | `gray-200` | — |
| `success` | `green-500` | ✅ |
| `error` | `red-500` | ❌ |
| `disabled` | `gray-200` | — (opacity 50%) |

### Props Específicas de `Textarea`

| Prop | Tipo | Default | Descripción |
|------|------|---------|-------------|
| `rows` | `number` | `4` | Número de filas visibles |
| `resize` | `boolean` | `true` | Si el usuario puede redimensionar |

### Props Específicas de `Select`

| Prop | Tipo | Descripción |
|------|------|-------------|
| `options` | `{value, label}[]` | Opciones del select |
| `placeholder` | `string` | Opción vacía inicial |

### Ejemplo de Uso

```jsx
<Input
  label="Nombre del Proyecto"
  placeholder="Mi Proyecto"
  state={errors.titulo ? 'error' : 'default'}
  error={errors.titulo}
  leftIcon={<FolderOpen size={16} />}
  value={titulo}
  onChange={(e) => setTitulo(e.target.value)}
/>
```

---

## 3. `Modal.jsx`

### Descripción

Componente de modal con animaciones Framer Motion. Bloquea el scroll del body mientras está abierto y restaura el estado al cerrarse.

### Props

| Prop | Tipo | Default | Descripción |
|------|------|---------|-------------|
| `isOpen` | `boolean` | — | Controla la visibilidad del modal |
| `onClose` | `function` | — | Callback para cerrar el modal |
| `title` | `string` | — | Título del modal |
| `size` | `string` | `'md'` | Tamaño del modal |
| `showCloseButton` | `boolean` | `true` | Muestra el botón X de cierre |
| `children` | `ReactNode` | — | Contenido del modal |

### Tamaños Disponibles

| Size | Max Width |
|------|-----------|
| `sm` | `max-w-sm` |
| `md` | `max-w-md` |
| `lg` | `max-w-lg` |
| `xl` | `max-w-xl` |
| `full` | `max-w-full` |

### Comportamiento

1. **Scroll lock:** Al montar, añade `overflow-hidden` al `body`. Al desmontar, lo restaura.
2. **Backdrop click:** Click fuera del modal invoca `onClose`.
3. **Animaciones (Framer Motion):**
   - Backdrop: `opacity: 0 → 1`
   - Modal: `scale: 0.95 → 1`, `opacity: 0 → 1`, `y: 20 → 0`

---

## 4. `Card.jsx`

### Descripción

Conjunto de subcomponentes para construir cards estructuradas.

### Subcomponentes Exportados

| Componente | Elemento HTML | Prop especial |
|-----------|--------------|--------------|
| `Card` | `div` | `hoverable`, `elevated`, `bordered` |
| `CardHeader` | `div` | — |
| `CardContent` | `div` | — |
| `CardFooter` | `div` | — |

### Props de `Card`

| Prop | Tipo | Default | Descripción |
|------|------|---------|-------------|
| `hoverable` | `boolean` | `false` | Agrega estilos hover (sombra, escala) |
| `elevated` | `boolean` | `false` | Agrega sombra más pronunciada |
| `bordered` | `boolean` | `true` | Muestra borde exterior |
| `className` | `string` | — | Clases CSS adicionales |
| `onClick` | `function` | — | Hace la card clickeable |

### Ejemplo de Uso

```jsx
<Card hoverable elevated onClick={handleCardClick}>
  <CardHeader>
    <h3>Título del Card</h3>
  </CardHeader>
  <CardContent>
    <p>Contenido principal del card.</p>
  </CardContent>
  <CardFooter>
    <span>Información secundaria</span>
  </CardFooter>
</Card>
```

---

## 5. `Badge.jsx`

### Descripción

Indicador de estado compacto y visual. Útil para estados de proyectos, roles y categorías.

### Props

| Prop | Tipo | Default | Descripción |
|------|------|---------|-------------|
| `variant` | `string` | `'gray'` | Color del badge |
| `size` | `string` | `'md'` | Tamaño del badge |
| `children` | `ReactNode` | — | Texto o contenido |

### Variantes de Color

| Variant | Fondo | Texto | Uso Típico |
|---------|-------|-------|-----------|
| `green` | `green-50` | `green-700` | Activo, Aprobado |
| `blue` | `blue-50` | `blue-700` | Completado, Info |
| `yellow` | `yellow-50` | `yellow-700` | Pendiente, Advertencia |
| `red` | `red-50` | `red-700` | Error, Eliminado |
| `gray` | `gray-100` | `gray-700` | Neutral, Borrador |
| `indigo` | `indigo-50` | `indigo-700` | Especial, Premium |

### Tamaños

| Size | Clases |
|------|--------|
| `sm` | `text-xs px-1.5 py-0.5` |
| `md` | `text-xs px-2.5 py-0.5` |
| `lg` | `text-sm px-3 py-1` |

---

## 6. `CloudBackground.jsx`

### Descripción

Componente de decoración visual. Renderiza un fondo 3D animado con nubes para la pantalla de login. Usa `@react-three/fiber` para el renderizado WebGL y `framer-motion` para transiciones de entrada.

### Tecnologías

| Librería | Uso |
|----------|-----|
| `@react-three/fiber` | Canvas WebGL con React |
| `@react-three/drei` | Helpers (Cloud, Sky, Environment) |
| `framer-motion` | Animación de entrada del canvas |

### Propósito

Exclusivamente decorativo. No recibe props ni expone estado. Diseñado para usarse como capa de fondo detrás del formulario de login:

```jsx
// LoginPage.jsx
<div className="relative min-h-screen">
  <CloudBackground />   {/* Fondo en posición absoluta */}
  <div className="relative z-10">
    {/* Formulario de login */}
  </div>
</div>
```

### Consideraciones de Rendimiento

- El canvas WebGL es costoso en dispositivos con GPU limitada.
- Considerar manejo de `Suspense` para navegadores sin soporte WebGL.
- El componente adapta su resolución al contenedor padre (`style={{ width: '100%', height: '100%' }}`).
