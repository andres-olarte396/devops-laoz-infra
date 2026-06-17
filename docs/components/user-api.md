# Componente: user-api

| Campo | Valor |
|---|---|
| **Repositorio** | `dev-laoz-api-user` |
| **Puerto interno** | `6000` |

---

## Responsabilidades

CRUD completo de usuarios. El registro (`POST /api/user`) es público; todas las demás operaciones requieren autenticación.

---

## Endpoints

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| `GET` | `/api/user` | Sí | Lista todos los usuarios |
| `POST` | `/api/user` | No | Registra nuevo usuario |
| `GET` | `/api/user/:id` | Sí | Obtiene usuario por ID |
| `PUT` | `/api/user/:id` | Sí | Actualiza usuario (incluye asignación de roles) |
| `DELETE` | `/api/user/:id` | Sí | Elimina usuario |

---

## Modelo de datos

```js
User {
  username:    String   // único, requerido
  email:       String   // único, opcional
  password:    String   // hash bcrypt, nunca devuelto en responses
  role:        String   // legacy: 'admin' | 'user' | 'guest'
  roles:       [String] // RBAC: ["editor", "viewer"]
  permissions: [String] // legacy: ["read", "write", "delete"]
  active:      Boolean  // default: true
  createdAt:   Date
  updatedAt:   Date
}
```

> `password` se excluye explícitamente de todos los responses con `.select('-password')`.

---

## Asignación de roles RBAC

```http
PUT /api/user/64abc123...
Authorization: Bearer <admin-token>
Content-Type: application/json

{ "roles": ["editor"] }
```

---

## Dependencias

```
mongo          (healthy)
api-secrets    (healthy)
api-insights   (started)
```

---

## Variables de entorno

```text
LOCAL_PORT    6000
SERVICE_NAME  user-api
MONGO_URI     (desde api-secrets)
JWT_SECRET    (desde api-secrets)
```
