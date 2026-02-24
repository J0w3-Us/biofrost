# Corrección del Sistema de Calificaciones (Estrellas) de Proyectos

A continuación se detalla la bitácora de los problemas encontrados, el análisis de root-cause y las soluciones implementadas tanto en el Backend (.NET) como en el Frontend (React) para restaurar la funcionalidad de evaluación por estrellas de los proyectos.

## 1. Problema Principal: Las Estrellas siempre aparecían vacías (0 votos)
El usuario reportó que a pesar de que el código parecía guardar en Firebase los votos, la interfaz de usuario `ShowcaseCard.jsx` siempre mostraba las tarjetas de proyectos con 0 estrellas al recargar la página.

### Análisis y Solución
Se descubrió que el backend estaba calculando y guardando correctamente los datos en Firestore (diccionario `Votantes`, `ConteoVotos` y `PuntosTotales`) en el archivo `RateProjectHandler.cs`. Sin embargo:

*   **Causa:** Los endpoints que obtienen la lista de proyectos (`GetPublicProjectsHandler.cs`) y el detalle de un proyecto (`GetProjectDetailsHandler.cs`) no incluían el diccionario de `Votantes` en el objeto DTO que devolvían a la API.
*   **Solución:** Se editaron los DTOs `PublicProjectDto` y `ProjectDetailsDto` para incluir el mapa `Votantes`.
*   **Ajuste en Frontend:** En el archivo `ShowcaseCard.jsx`, se modificó el estado inicial de `userRating` para leer el arreglo que envía el servidor. Así, si el ID del usuario ya figuraba en la lista de votantes del proyecto, se inicializan y encienden las estrellas correspondientes automáticamente.

## 2. Bug Silencioso al Evaluar Proyectos: Error 400 Bad Request
Durante el QA de la regla "el dueño del proyecto no puede votar por el suyo", se comprobó que el usuario tampoco podía votar por **ningún** proyecto; la consola del navegador arrojaba un `AxiosError: Request failed with status code 400` y el endpoint `/api/projects/{id}/rate` tronaba.

### Análisis y Solución
*   **Causa:** El Payload HTTP desde el frontend estaba enviando `null` en el parámetro lógico `userId`.
*   **El Origen:** El hook global de sesión (`useAuth.jsx`) exportaba el identificador del usuario bajo la llave `userData.userId`, pero el componente de las tarjetas (`ShowcaseCard.jsx`) estaba intentando leer el ID usando la propiedad incorrecta: `userData.id` (que es `undefined`).
*   **Consecuencia en Backend:** Al enviar `userId: null`, la lógica de `RateProjectHandler.cs` intentaba ejecutar `project.Votantes.ContainsKey((string) null)`, lanzando de inmediato un error crítico `ArgumentNullException` sin manejar, lo que resultaba en la respuesta HTTP Error 400.
*   **Solución:** Se corrigió en el DOM virtual de React (`ShowcaseCard.jsx`) todas las llamadas hacia `userData.id` reemplazándolas por el namespace correcto `userData.userId`. Esto inmediatamente compuso los problemas para poder enviar votos nuevos.

## 3. Problema Colateral: Error CS7036 en Compilación
La refactorización masiva de la estructura de la tarjeta para devolver los votos alteró el constructor de `ProjectDetailsDto`.

### Análisis y Solución
*   **Causa:** Otra clase del ecosistema (`GetProjectByMemberHandler.cs`) instanciaba `ProjectDetailsDto` y, repentinamente, le faltaban 3 parámetros obligatorios (`PuntosTotales`, `ConteoVotos` y `Votantes`), rompiendo la compilación.
*   **Solución:** Se suministraron los 3 parámetros ausentes al constructor en dicho handler, pasando un diccionario vacío en caso de que la propiedad `Votantes` del proyecto viniera null desde Firestore.

Adicional a todo esto, se aprovechó la revisión de control de tipo estricto en el backend para solventar un Warning local (CS8625) en `UpdateProjectHandler.cs` (usando `object?` en el diccionario anidado para el contenido del Canvas), dejando el código de la API limpio de advertencias.

## Estado Final
La funcionalidad de evaluación de proyectos ahora es estable: 
- El usuario en sesión puede votar sin errores.
- Se respetan reglas de no autoconsumo (el líder oculta la vista de calificar en su tarjeta).
- El estado visual persiste sin interrupciones mediante el backend.
- Matemáticas perfectas entre calificación, recuento y sumas de 10 puntos en el total acumulado.
