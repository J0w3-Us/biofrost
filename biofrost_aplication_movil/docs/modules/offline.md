# Offline y Sincronización

Propósito: Estrategia de caché y sincronización para permitir lectura parcial offline.

Estrategia sugerida:

- Cache-first para detalles ya vistos.
- Network-first para listados públicos.
- Background sync: encolar cambios locales (ej. edición canvas) y reintentar cuando haya conexión.

Tecnologías sugeridas (Flutter):

- `hive` o `sqflite` para almacenamiento local ligero.
- `connectivity_plus` para detectar estado de red.

Notas de consistencia:

- Diseñar conflictos: último cambio del servidor gana + notificar al usuario.

Lecturas recomendadas:

- [documentar/architecture/BIFROST_SYSTEM_ARCHITECTURE.md](documentar/architecture/BIFROST_SYSTEM_ARCHITECTURE.md)

Enfoque móvil: Sí — la estrategia de caché está pensada para dispositivos móviles con conectividad intermitente.

Roles permitidos (UI): `Docente`, `Invitado`.
