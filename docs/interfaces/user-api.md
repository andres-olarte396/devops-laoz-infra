# Interfaz: user-api

Base URL (vía gateway): `http://<host>:9000/api/user`  
Base URL (dev directo): `http://localhost:6000/api/user`

---

## GET /api/user

Lista todos los usuarios. Requiere autenticación.

**Response 200:**
```json
[
  {
    "_id": "64abc123...",
    "username": "andres",
    "email": "andres@example.com",
    "role": "admin",
    "roles": ["admin"],
    "permissions": ["read", "write"],
    "active": true,
    "createdAt": "2024-01-15T10:00:00.000Z",
    "updatedAt": "2024-06-10T08:30:00.000Z"
  }
]
```

---

## POST /api/user

Registra un nuevo usuario. **Público** (sin autenticación).

**Request:**
```http
POST /api/user
Content-Type: application/json

{
  "username": "nuevo_usuario",
  "password": "password_segura_123",
  "email": "usuario@example.com",
  "role": "user"
}
```

**Response 201:**
```json
{
  "_id": "64def456...",
  "username": "nuevo_usuario",
  "role": "user",
  "roles": [],
  "active": true,
  "createdAt": "2024-06-16T12:00:00.000Z"
}
```

**Errores:**

| HTTP | Condición |
|---|---|
| `400` | `username` o `password` ausentes, o validación fallida |
| `409` | `username` ya existe |

---

## GET /api/user/:id

Obtiene un usuario por ID. Requiere autenticación.

**Response 200:** Ver schema de `UserResponse` en [shared-schemas.md](shared-schemas.md).

**Errores:**

| HTTP | Condición |
|---|---|
| `404` | Usuario no encontrado |

---

## PUT /api/user/:id

Actualiza datos de un usuario, incluida la asignación de roles. Requiere autenticación.

**Request:**
```http
PUT /api/user/64abc123...
Authorization: Bearer <token>
Content-Type: application/json

{
  "email": "nuevo@example.com",
  "roles": ["editor"],
  "active": true
}
```

> Para cambiar la contraseña, incluir `"password": "nueva_contraseña"`. Se re-hashea automáticamente.

**Response 200:** Usuario actualizado (sin `password`).

---

## DELETE /api/user/:id

Elimina un usuario. Requiere autenticación.

**Response 204:** Sin body.

**Errores:**

| HTTP | Condición |
|---|---|
| `404` | Usuario no encontrado |
