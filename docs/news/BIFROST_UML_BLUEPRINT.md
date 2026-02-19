# **UML Modeling Blueprint**

## **Nombre del Proyecto: BIFROST Interface — Arquitectura Visual**

### **1. EL PROBLEMA**
**¿Qué sabes del problema que quieres resolver y qué hay que hacer para resolverlo?**

*   **Problema Supuesto:**
    La adopción de una arquitectura avanzada como **CQRS + Event Sourcing** presenta una curva de aprendizaje empinada. El código por sí solo (C#/.NET) no comunica eficientemente el flujo de datos asíncrono, lo que genera riesgos de implementación incorrecta ("Modelo de Escritura contaminado con Lecturas") y dificulta el onboarding de nuevos desarrolladores.

*   **Datos Duros (Evidencia técnica):**
    *   El sistema maneja **8 colecciones críticas** divididas en dos zonas (Write/Read) totalmente desacopladas.
    *   Existen flujos complejos no lineales, como la **Rehidratación de Aggregates** (reconstrucción de estado desde eventos), que son abstractos en código pero vitales para la resiliencia del sistema.
    *   La documentación actual (`BIFROST_DATA_MODELS_CLASSES.md`) tiene >1200 líneas de texto; extraer relaciones visuales de ahí es mentalmente costoso.

*   **Preguntas Sobresalientes:**
    *   ¿Cómo garantizamos que todos entiendan que el *Read Model* es una consecuencia eventual del *Write Model* y no una tabla relacional tradicional?
    *   ¿Cómo visualizamos la inmutabilidad de los eventos en el *Event Store* frente a la mutabilidad de las *Vistas*?

### **2. ESCENARIO IDEAL**
**¿Cómo se ve el problema una vez resuelto?**

*   **Visión:**
    Un conjunto de **"Diagramas Vivos"** que actúan como la fuente de verdad visual del sistema. No son solo dibujos estáticos, sino representaciones precisas que mapean 1:1 con la implementación en código, permitiendo a cualquier ingeniero entender el *ciclo de vida del dato* en menos de 5 minutos.

*   **Cómo se miran estas actividades:**
    *   **El Arquitecto:** Utiliza el **Diagrama de Clases** para validar que las entidades del Dominio no tengan dependencias de Infraestructura (Clean Architecture).
    *   **El Desarrollador Backend:** Consulta el **Diagrama de Secuencia** antes de implementar un nuevo *Command Handler*, asegurando que se emita el evento correcto.
    *   **El DevOps/SRE:** Revisa el **Diagrama de Despliegue** para entender la interacción entre Cloud Run, Mongo Atlas y Firebase antes de configurar alertas de latencia.

### **3. ACTIVIDADES DE UML**
**¿Qué soluciones y diagramas específicos resuelven el problema de comunicación?**

*   **Diagramas Estructurales (Estructura Estática):**
    *   **Diagrama de Clases del Dominio (Read & Write)**: Modelar las entidades `Evento`, `Snapshot` (Write Side) separadas físicamente de `ProyectoView`, `EvaluacionView` (Read Side), destacando la ausencia de relaciones directas entre ellas.
    *   **Diagrama de Componentes (Clean Architecture)**: Visualizar las capas `Bifrost.API` → `Bifrost.Application` → `Bifrost.Domain` ← `Bifrost.Infrastructure`, forzando la regla de dependencia hacia el centro.

*   **Diagramas de Comportamiento (Dinámica del Sistema):**
    *   **Diagrama de Secuencia (Flujo de Evaluación)**: Detallar el paso crítico: `Usuario` → `API` → `Command` → `EventStore (Append)` → `ChangeStream` → `ProjectionEngine` → `ReadModel (Update)`.
    *   **Diagrama de Máquina de Estados (Ciclo de Vida del Proyecto)**: Mapear las transiciones estrictas: `Borrador` → `Activo` → `Público` / `Pausado` → `Histórico`, indicando qué rol (Alumno/Docente/Sistema) puede disparar cada transición.

*   **Entregables:**
    *   Set de archivos PlantUML/Mermaid versionables junto con el código.
    *   Mapas visuales de las colecciones MongoDB y sus índices estratégicos.

### **4. HIPÓTESIS**
**¿Qué indicadores dirían que hemos resuelto el problema de comprensión?**

*   **Creencia:**
    Creemos que al **visualizar explícitamente la segregación CQRS**, reduciremos los errores conceptuales (como intentar hacer JOINs entre colecciones) y aceleraremos la implementación de nuevas *Proyecciones*.

*   **Indicador de Éxito:**
    *   **Reducción del 50%** en el tiempo de análisis requerido para implementar un nuevo feature (de 4 horas a 2 horas).
    *   **Cero regresiones** relacionadas con la contaminación de modelos (escribir en el modelo de lectura directamente).
    *   **Autonomía del equipo:** Los desarrolladores pueden explicar el flujo de "Event Replay" usando solo el diagrama.

### **5. OBJETIVOS**
**¿Qué queremos lograr con estos diagramas?**

*   **Logros Esperados:**
    *   **Claridad Arquitectónica:** Eliminar la ambigüedad sobre dónde reside la "Verdad" (Event Store) vs. dónde reside la "Consulta" (Read Models).
    *   **Estandarización:** Uso de notación UML 2.0 estándar para que sea legible por cualquier ingeniero de software.
    *   **Documentación de Infraestructura:** Mapeo claro de los servicios externos (Firebase Auth, GCS, Atlas) y sus protocolos de comunicación.

*   **Métricas:**
    *   **Cobertura:** 100% de las Entidades y Value Objects documentados visualmente.
    *   **Precisión:** Los diagramas reflejan exactamente las propiedades BSON definidas en `BIFROST_DATABASE_DOCUMENTATION.md`.

### **6. VALOR**
**¿Cuál es el beneficio que UML estará aportando?**

*   **Para el Equipo de Desarrollo:**
    *   **Reducción de Deuda Técnica:** Al tener un mapa claro, se evitan "atajos" arquitectónicos que violan los principios de Event Sourcing.
    *   **Onboarding Acelerado:** Un nuevo integrante puede entender el sistema viendo 3 diagramas en lugar de leer 50 archivos de código.

*   **Para el Proyecto (Bifrost):**
    *   **Resiliencia:** El entendimiento profundo del flujo de eventos facilita el diseño de mecanismos de recuperación (Rehidratación) robustos.
    *   **Escalabilidad:** Identificar visualmente los cuellos de botella (ej. proyecciones síncronas vs asíncronas) antes de que impacten en producción.
