# Guía de Prompts para Generación de Visuales SVG

Esta guía contiene plantillas y ejemplos de prompts probados para generar visuales SVG de alta fidelidad, basados en documentos de User Research y manteniendo un estilo visual consistente.

## Estructura Básica del Prompt

El patrón más efectivo sigue esta estructura:

```markdown
Basado en @[Contexto de Reglas] crea el SVG de @[Archivo de Contenido] quiero un diseño [Estilo Deseado] y colores similares a @[Archivo de Referencia] (solo colores, diseño libre).
```

### Componentes:

1.  **Fuente de Reglas (`@[context/AI]`):** Define las restricciones técnicas (SVG puro, editable en Figma).
2.  **Fuente de Contenido (`@[Archivo.md]`):** El documento markdown con la información a visualizar.
3.  **Referencia Visual (`@[Visual_Anterior.svg]`):** Para mantener consistencia en la paleta de colores.
4.  **Instrucción de Estilo:** "Creativo", "Orgánico", "User Journey", etc.

---

## 1. Prompt Inicial (Creación desde Cero)

Usa este prompt para crear el primer visual de una serie.

> **Prompt:**
> "Basado en `@[context/AI]` crea el SVG de `@[User Research - Formato.md]`. Quiero un diseño creativo y colores similares a `@[Referencia.svg]` (solo colores, diseño libre)."

---

## 2. Prompt de Iteración (Refinamiento de Diseño)

Si el primer resultado es demasiado rígido (tablas/cuadrados), usa este prompt para pedir formas más orgánicas sin perder información.

> **Prompt:**
> "No me gusta mucho la forma en la que representas las cosas en `@[Visual_Generado.svg]`. La información está bien, pero quiero que te apegues más a la información original. Además, sé más creativo: quiero diseños más creativos, no todo en tablas ni cuadrados, algo más interesante."

---

## 3. Prompt de Réplica de Estilo (Consistencia)

Usa este prompt cuando quieras que un nuevo visual tenga **exactamente** la misma estructura que uno anterior (ej. para crear múltiples "Personas").

> **Prompt:**
> "Basado en `@[context/AI]` crea el SVG de `@[Nuevo_Template.md]`. Copia el diseño de `@[Visual_Existente.svg]`, quiero que luzca igual pero con la información correspondiente."

---

## 4. Prompt para User Journeys (Mapas de Viaje)

Los User Journeys requieren una estructura específica (línea de tiempo, curva de emociones). Es útil mencionar explícitamente estas expectativas.

> **Prompt:**
> "Basado en `@[context/AI]` crea el SVG de `@[User Journey.md]`. Quiero un diseño creativo y colores similares a `@[Referencia.svg]`. Como es un User Journey, debes hacer el diseño de acuerdo a lo que se espera de un User Journey (Swimlanes, Curva de Emociones, Puntos de Contacto)."

---

## 5. Prompt para Diagramas de Estado (Lógica Técnica)

Para diagramas que requieren precisión técnica, nombres profesionales y rutas limpias sin cruces (avoiding spaghetti code visual).

> **Prompt:**
> "Basado en `@[context/AI]` crea el SVG de `@[Estado Conectividad.md]`. Usa el diseño de un Diagrama de Estados profesional.
>
> - **Nomenclatura:** Usa nombres técnicos y profesionales para los estados (ej. 'Reposo', 'Encolado', 'Backoff' en lugar de descripciones largas).
> - **Rutas Limpias:** Asegúrate de que los conectores NO se crucen sobre el texto. Si hay loops (como 'Reintentar'), haz que salgan por un lado y entren por otro de forma limpia (ortogonal).
> - **Falta de información:** Si falta texto, prioriza la legibilidad y la estructura lógica."

---

## 6. Prompt para Diagramas de Secuencia (UML High-Fidelity)

Para diagramas de secuencia complejos donde la exactitud del flujo y la legibilidad son críticas.

> **Prompt:**
> "Basado en `@[context/AI]` crea el SVG de `@[Historia Secuencial.md]`. Estilo: **UML Sequence Diagram de Alta Fidelidad**.
>
> - **Visual:** Usa 'Lifelines' con barras de activación (rectángulos verticales) para indicar cuándo un actor está activo.
> - **Estructura:** Agrupa los pasos en Fases claras (Fase 1, Fase 2...) usando bloques de fondo translúcidos.
> - **Detalle:** Incluye TODOS los pasos del texto original (1 al N).
> - **Estándar:** Usa líneas sólidas para peticiones y líneas punteadas para respuestas. Usa 'Frames' o cajas para loops (ej. Chunking).
> - **Espaciado:** Haz el diagrama lo suficientemente alto para que no se vea amontonado."

---

## 7. Solución de Problemas (Debug)

Si un SVG generado tiene errores visuales o no renderiza.

> **Prompt:**
> "El SVG `@[Archivo.svg]` está corrupto y no funciona. Mira la imagen, no es igual al otro. Arréglalo manteniendo la estructura pero corrigiendo el XML."

---

## Consejos Adicionales

- **Referencias:** Siempre proporciona un archivo SVG anterior como referencia de color (`@[completados/...]`) para mantener la identidad visual del proyecto.
- **Reglas de Contexto:** Siempre invoca `@[context/AI]` o `@[context/AI/rules.md]` para asegurar que el código sea compatible con Figma (texto editable, sin HTML/CSS externo).
- **Especificidad:** Si quieres un gráfico específico (ej. "Curva de emociones"), pídelo explícitamente.
