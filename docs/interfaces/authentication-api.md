# Interfaz: authentication-api

Base URL (vía gateway): `http://<host>:9000/api/auth`  
Base URL (dev directo): `http://localhost:4000/api/auth`

---

## POST /api/auth/login

Autentica un usuario y devuelve tokens.

**Request:**
```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "andres",
  "password": "s3cur3p@ss"
}
```

**Response 200:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "c3b4a1d2e5f607a8b9c0d1e2f3a4b5c6"
}
```

**Errores:**

| HTTP | Condición |
|---|---|
| `400` | `username` o `password` ausentes |
| `401` | Credenciales incorrectas |
| `403` | Usuario inactivo |

---

## POST /api/auth/refresh

Renueva el `accessToken` usando un `refreshToken` válido.

**Request:**
```http
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "c3b4a1d2e5f607a8b9c0d1e2f3a4b5c6"
}
```

**Response 200:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Errores:**

| HTTP | Condición |
|---|---|
| `400` | `refreshToken` ausente |
| `401` | `refreshToken` inválido o expirado |

---

## POST /api/auth/logout

Invalida la sesión actual.

**Request:**
```http
POST /api/auth/logout
Authorization: Bearer <accessToken>
```

**Response 200:**
```json
{ "message": "Sesión cerrada exitosamente" }
```

**Errores:**

| HTTP | Condición |
|---|---|
| `401` | Token ausente o inválido |

---

## GET /api/auth/verify

Verifica que el token es válido y la sesión está activa.

**Request:**
```http
GET /api/auth/verify
Authorization: Bearer <accessToken>
```

**Response 200:**
```json
{
  "valid": true,
  "userId": "64abc123def456...",
  "sessionToken": "uuid-de-sesion"
}
```

**Errores:**

| HTTP | Condición |
|---|---|
| `401` | Token inválido, expirado o sesión inactiva |

---

## GET /api/auth/health

Healthcheck del servicio.

**Request:**
```http
GET /api/auth/health
```

**Response 200:**
```json
{ "status": "ok", "service": "authentication-api" }
```
