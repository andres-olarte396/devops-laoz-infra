# Componente: authentication-api

| Campo | Valor |
|---|---|
| **Repositorio** | `dev-laoz-authentication-api` |
| **Puerto interno** | `4000` |
| **Healthcheck** | `GET /api/auth/health` |

---

## Responsabilidades

Único servicio del ecosistema autorizado para **emitir tokens JWT**. No verifica permisos ni roles — eso es responsabilidad de `authorization-api`.

---

## Endpoints

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| `POST` | `/api/auth/login` | No | Autentica usuario → devuelve `accessToken` (1h) + `refreshToken` (7d) |
| `POST` | `/api/auth/refresh` | No | Renueva `accessToken` con `refreshToken` válido |
| `POST` | `/api/auth/logout` | Sí | Invalida sesión activa |
| `GET` | `/api/auth/verify` | Sí | Verifica que el token es válido |
| `GET` | `/api/auth/health` | No | Healthcheck del servicio |

Ver contratos completos en [interfaces/authentication-api.md](../interfaces/authentication-api.md).

---

## Modelo de datos

### User (referencia)
```
username    String  único
password    String  hash bcrypt (nunca devuelto en respuestas)
role        String  legacy: admin|user|guest
roles       Array   RBAC: ["editor", "viewer"]
active      Boolean
```

### Session
```
sessionToken   String   UUID único por sesión
userId         ObjectId referencia a User
isActive       Boolean  false tras logout
expiresAt      Date     +7 días desde creación
createdAt      Date
```

---

## Flujo de login

```
POST /api/auth/login { username, password }
  → User.findOne({ username })
  → bcrypt.compare(password, hash)
  → Session.create({ sessionToken: uuid(), userId, expiresAt: +7d })
  → jwt.sign({ userId, sessionToken }, JWT_SECRET, { expiresIn: '1h' })
  → { accessToken, refreshToken }
```

---

## Dependencias

```
mongo          (healthy)   — leer usuarios, crear sesiones
api-secrets    (healthy)   — cargar JWT_SECRET, MONGO_URI
api-insights   (started)   — emitir logs y auditoría
```

---

## Variables de entorno

```text
LOCAL_PORT    4000
SERVICE_NAME  authentication-api
JWT_SECRET    (cargado desde api-secrets)
MONGO_URI     (cargado desde api-secrets)
```
