# Documentación: Configuración de Almacenamiento y Persistencia (Supabase)

Esta documentación detalla la implementación y correcciones realizadas para habilitar el almacenamiento persistente de archivos multimedia (imágenes y videos) en `IntegradorHub`, utilizando Supabase Storage.

## 1. Configuración de Supabase Storage

El backend se conecta a Supabase para gestionar la subida de archivos al bucket `project-files`.

- **Bucket:** `project-files` (Debe ser público para lectura de assets).
- **Estructura de Carpetas:**
    - `images/`: Imágenes subidas desde el editor Canvas.
    - `project-promos/`: Videos tipo "Pitch" del proyecto.
    - `videos/`: Videos incrustados en bloques del Canvas.

### Credenciales (`appsettings.json`)
La configuración se encuentra bajo la sección `Supabase`:
```json
"Supabase": {
  "Url": "https://zhnufraaybrruqdtgbwj.supabase.co",
  "ServiceKey": "...", // Clave de servicio (Service Role Key para gestión, o Anon Key para cliente si RLS lo permite)
  "BucketName": "project-files"
}
```

## 2. Backend API (.NET)

### Endpoint de Subida
Se implementó `StorageController` para manejar las peticiones de subida desde el frontend.

- **Ruta:** `POST /api/Storage/upload?folder={nombre_carpeta}`
- **Parámetros:**
    - `folder`: Nombre de la carpeta destino (opcional, defecto: "project-assets").
    - `file`: Archivo binario (multipart/form-data).
- **Respuesta:** JSON con la URL pública del archivo subido.

### Corrección de Persistencia

#### Problema: Video Pitch Desaparecía
El campo `VideoUrl` se guardaba en la base de datos (Firestore), pero **no se devolvía al frontend** al consultar los detalles del proyecto. Esto causaba que el frontend recibiera `null`, y al realizar un autoguardado, sobrescribiera el valor correcto en la BD, eliminando el video.

**Solución aplicadad:**
Se agregó la propiedad `VideoUrl` al DTO de respuesta `ProjectDetailsDto` en los siguientes Handlers:
- `Features/Projects/GetDetails/GetProjectDetailsHandler.cs`
- `Features/Projects/GetByMember/GetProjectByMemberHandler.cs`

#### Problema: Error de Serialización en Canvas Blocks
El frontend envía metadatos dinámicos en los bloques del canvas (ej. `checked` como booleano, `completado` como número). Firestore a veces tenía problemas si la definición del modelo C# era estricta (`Dictionary<string, string>`).

**Solución aplicada:**
1.  **Modelo Modificado (`Project.cs`):** Cambiado `Metadata` a `Dictionary<string, object>`.
2.  **Sanitización (`UpdateProjectHandler.cs`):** Se implementó el método `SanitizeBlocks` para convertir los objetos `JsonElement` (propios de `System.Text.Json`) a tipos nativos de C# (string, long, double, bool, null) antes de intentar guardar en Firestore.

## 3. Frontend (React)

### CanvasEditor (`CanvasEditor.jsx`)
- Se configuró la función `uploadFile` para apuntar al nuevo endpoint del backend.
- **Sanitización de Estado UI:** Antes de enviar los datos al backend para guardar, el frontend elimina propiedades temporales de los metadatos de los bloques, como:
    - `uploading` (booleano)
    - `progress` (número)
    - `error` (string)
    Esto mantiene la base de datos limpia y evita conflictos de serialización innecesarios.

## 4. Verificación
Para probar la integración:
1.  Iniciar backend (`dotnet run`).
2.  Iniciar frontend (`npm run dev`).
3.  Subir una imagen o video en el editor de un proyecto.
4.  Guardar y recargar la página. El archivo debe persistir.
