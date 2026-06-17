# Componente: api-roles

| Campo | Valor |
|---|---|
| **Repositorio** | `dev-laoz-api-roles` |
| **Puerto interno** | `5002` |

---

## Responsabilidades

Fuente de verdad para la definición de **roles y sus permisos**. Gestiona el CRUD de roles y expone un endpoint interno para verificar si un conjunto de roles tiene un permiso específico.

---

## Endpoints

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| `GET` | `/api/roles` | Sí | Lista todos los roles |
| `POST` | `/api/roles` | Sí | Crea rol personalizado |
| `GET` | `/api/roles/:id` | Sí | Obtiene rol por ID |
| `PUT` | `/api/roles/:id` | Sí | Actualiza rol |
| `DELETE` | `/api/roles/:id` | Sí | Elimina rol |
| `GET` | `/api/roles/name/:name` | Sí | Obtiene rol por nombre |
| `POST` | `/api/roles/check` | No | Verifica si roles[] tienen un permiso (uso interno) |

### `POST /api/roles/check` (uso interno por authorization-api)

**Request:**
```json
{ "roles": ["editor", "viewer"], "permission": "files:write" }
```

**Response:**
```json
{ "hasPermission": true }
```

---

## Roles predefinidos del sistema

| Rol | Permisos |
|---|---|
| `admin` | `users:*`, `roles:*`, `files:*`, `secrets:*`, `insights:*`, `billing:*` |
| `editor` | `files:read`, `files:write`, `files:delete`, `insights:read` |
| `viewer` | `files:read`, `insights:read` |
| `user` | `files:read` |

---

## Modelo de datos

### Role
```
name          String   único: admin | editor | viewer | user | custom
description   String
permissions   Array    ["files:read", "files:write", ...]
isSystem      Boolean  true = no puede eliminarse
createdAt     Date
updatedAt     Date
```

---

## Dependencias

```
mongo          (healthy)
api-secrets    (healthy)
api-insights   (started)
```
