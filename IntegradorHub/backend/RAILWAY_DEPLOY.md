# Despliegue en Railway — IntegradorHub backend

Resumen rápido:
- Este proyecto es una API ASP.NET (net8.0) en `src/IntegradorHub.API`.
- He añadido un `Dockerfile` multi-stage en `src/IntegradorHub.API` para construir y publicar la aplicación.

Pasos recomendados para desplegar en Railway (opción GitHub):

1. Crear un repositorio Git (p. ej. GitHub) y subir la carpeta `IntegradorHub/backend`.

2. En Railway: crear un nuevo proyecto y seleccionar "Deploy from GitHub".
   - Conectar la cuenta y seleccionar el repo y la rama.
   - Railway detectará el `Dockerfile` en `src/IntegradorHub.API` si la raíz del repo es `IntegradorHub/backend` o podrás indicar el `Dockerfile` path.

3. Variables de entorno y credenciales (importante):
   - El backend usa Firestore/Google credentials; debes proveer la cuenta de servicio.
   - Opción A (recomendada si tu aplicación soporta leer JSON desde variable): crear una variable secreta `GOOGLE_APPLICATION_CREDENTIALS_JSON` con el contenido JSON de la cuenta de servicio y adaptar el arranque para usarla.
   - Opción B (si tu código lee `GOOGLE_APPLICATION_CREDENTIALS` como ruta de archivo): subir el JSON a Railway (si Railway lo permite) o cambiar el código para leer la variable de entorno con el JSON y construir las credenciales en tiempo de ejecución.
   - Añade otras variables necesarias (p. ej. `ASPNETCORE_ENVIRONMENT`, cadenas de conexión, claves, etc.) en Settings → Variables en Railway.

4. Puertos: el `Dockerfile` expone `8080` y la variable `ASPNETCORE_URLS` está configurada para escuchar en ese puerto. Railway asignará el puerto público por su redirección.

5. Despliegue vía Railway CLI (alternativa):
   - `railway login`
   - `railway init` (en el directorio root del repo)
   - `railway up --build`  (esto construirá la imagen usando el `Dockerfile`).

Notas adicionales:
- Si necesitas, puedo:
  - preparar una pequeña modificación para leer las credenciales de Firestore desde una variable de entorno (si quieres automatizar secrets),
  - o empujar el repo a un remoto si me das acceso.
