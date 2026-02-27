# Backend Endpoints Documentation

This document lists all the API endpoints available in the backend `IntegradorHub.API`.

## Admin (`/api/admin`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| **POST** | `/api/admin/seed-admin` | Creates the initial admin user in Firestore. |

## Admin - Carreras (`/api/admin/carreras`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| **GET** | `/api/admin/carreras` | Retrieves all careers. |
| **POST** | `/api/admin/carreras` | Creates a new career. |
| **DELETE** | `/api/admin/carreras/{id}` | Deletes a career by ID. |

## Admin - Groups (`/api/admin/groups`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| **GET** | `/api/admin/groups` | Retrieves all active groups. |
| **GET** | `/api/admin/groups/{id}` | Retrieves a specific group by ID. |
| **POST** | `/api/admin/groups` | Creates a new group. |
| **PUT** | `/api/admin/groups/{id}` | Updates an existing group. |
| **DELETE** | `/api/admin/groups/{id}` | Deletes (soft deletes) a group. |

## Admin - Materias (`/api/admin/materias`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| **GET** | `/api/admin/materias` | Retrieves all active subjects (optional query `carreraId`). |
| **GET** | `/api/admin/materias/by-carrera/{carreraId}` | Retrieves subjects filtered by career ID. |
| **POST** | `/api/admin/materias` | Creates a new subject. |
| **PUT** | `/api/admin/materias/{id}` | Updates an existing subject. |
| **DELETE** | `/api/admin/materias/{id}` | Deletes (soft deletes) a subject. |

## Admin - Users (`/api/admin/users`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| **GET** | `/api/admin/users/students` | Retrieves students (optional query `grupoId`). |
| **GET** | `/api/admin/users/teachers` | Retrieves all teachers. |
| **PUT** | `/api/admin/users/students/{userId}` | Updates a student's group. |
| **PUT** | `/api/admin/users/teachers/{userId}` | Updates a teacher's assignments. |

## Auth (`/api/Auth`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| **POST** | `/api/Auth/login` | Authentication handling for Firebase users. |
| **POST** | `/api/Auth/register` | Registers a new user with extended profile data. |

## Evaluations (`/api/Evaluations`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| **POST** | `/api/Evaluations` | Creates a new evaluation for a project. |
| **GET** | `/api/Evaluations/project/{projectId}` | Retrieves all evaluations for a specific project. |

## Projects (`/api/Projects`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| **GET** | `/api/Projects/public` | Retrieves all public projects for the gallery. |
| **POST** | `/api/Projects` | Creates a new project. |
| **GET** | `/api/Projects/group/{groupId}` | Retrieves projects for a specific group. |
| **GET** | `/api/Projects/{id}` | Retrieves detailed project information. |
| **PUT** | `/api/Projects/{id}` | Updates project details (Title, Video, Canvas, Public status). |
| **DELETE** | `/api/Projects/{id}` | Deletes a project (requires `requestingUserId`). |
| **POST** | `/api/Projects/{id}/members` | Adds a member to the project team. |
| **DELETE** | `/api/Projects/{id}/members/{memberId}` | Removes a member from the project team (requires `requestingUserId`). |
| **PUT** | `/api/Projects/{id}/canvas` | Updates the project's canvas content. |

## Storage (`/api/Storage`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| **POST** | `/api/Storage/upload` | Uploads a single file (query `folder`). |
| **POST** | `/api/Storage/upload-multiple` | Uploads multiple files (query `folder`). |
| **DELETE** | `/api/Storage/{*filePath}` | Deletes a file from storage. |

## Teams (`/api/Teams`)

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| **GET** | `/api/Teams/available-students` | Retrieves students in a group without a team (query `groupId`). |
| **GET** | `/api/Teams/available-teachers` | Retrieves teachers assigned to a group (query `groupId`). |
