# Schemas Compartidos

Tipos de datos y formatos usados en múltiples APIs del ecosistema.

---

## JWT Payload

El `accessToken` es un JWT firmado con `HS256`. Su payload decodificado contiene:

```typescript
interface JwtPayload {
  userId:       string;   // MongoDB ObjectId del usuario
  sessionToken: string;   // UUID de la sesión activa
  iat:          number;   // Issued At (Unix timestamp)
  exp:          number;   // Expiry (Unix timestamp, iat + 3600)
}
```

> Los roles y permisos **no están en el token**. Se resuelven en `authorization-api` en cada request.

---

## Formato de error

Todos los servicios devuelven errores en este formato:

```typescript
interface ErrorResponse {
  error:    string;           // Descripción del error (requerido)
  message?: string;           // Mensaje legible para el usuario (opcional)
  code?:    string;           // Constante de error (opcional)
  fields?:  Record<string, string>;  // Para errores de validación (opcional)
}
```

**Ejemplos:**
```json
{ "error": "Token expirado" }
{ "error": "Validación fallida", "fields": { "username": "Requerido" } }
{ "error": "Acceso denegado", "code": "PERMISSION_DENIED" }
```

---

## Paginación

Los endpoints de listado soportan:

**Query params:**
```
?limit=20   Máximo de items (default: 20, max: 100)
?skip=0     Items a omitir para paginación (default: 0)
```

**Respuesta:** el array de items directamente (sin wrapper de paginación actualmente).

---

## Modelo User (respuesta pública)

La `password` siempre se excluye de las respuestas:

```typescript
interface UserResponse {
  _id:         string;
  username:    string;
  email?:      string;
  role:        string;        // legacy: 'admin' | 'user' | 'guest'
  roles:       string[];      // RBAC: ["editor", "viewer"]
  permissions: string[];      // legacy
  active:      boolean;
  createdAt:   string;        // ISO 8601
  updatedAt:   string;        // ISO 8601
}
```

---

## Modelo Session

```typescript
interface Session {
  _id:          string;
  sessionToken: string;     // UUID
  userId:       string;     // referencia a User
  isActive:     boolean;
  expiresAt:    string;     // ISO 8601
  createdAt:    string;
}
```

---

## Códigos HTTP del ecosistema

| Código | Cuándo se usa |
|---|---|
| `200` | Operación exitosa con body |
| `201` | Recurso creado |
| `204` | Operación exitosa sin body (DELETE) |
| `400` | Input inválido o campos faltantes |
| `401` | Sin token o token inválido/expirado |
| `403` | Token válido pero sin permiso suficiente |
| `404` | Recurso no encontrado |
| `409` | Conflicto (ej: username duplicado) |
| `429` | Rate limit excedido |
| `500` | Error interno inesperado |
| `503` | Servicio dependiente no disponible |

---

## Formato de fechas

Todas las fechas en respuestas API son **ISO 8601 UTC**:
```
"2024-06-15T14:30:00.000Z"
```
