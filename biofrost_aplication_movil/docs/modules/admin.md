# Admin (opcional móvil)

Propósito: Paneles y operaciones reservadas para `Admin` (opcional en móvil; puede quedarse en web).

Funcionalidades:

- Gestión de `groups`, `materias`, `carreras`, `users`.
- Seed admin: `/api/admin/seed-admin`.

Consideración: inicialmente posponer a web; implementar solo si hay demanda móvil.

Lecturas recomendadas:

- [documentar/functions/API_DOCS.md](documentar/functions/API_DOCS.md#admin)

Enfoque móvil: Opcional — por defecto **no** incluir paneles admin en la app móvil.

Roles permitidos (UI): `Admin` (si se habilita); la versión móvil por defecto no expone admin.
