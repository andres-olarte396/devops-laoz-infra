# Interfaz: api-gateway — Tabla de rutas

El gateway expone externamente en el puerto `9000` y enruta al servicio interno correspondiente.

---

## Rutas públicas (sin autenticación)

| Método | Ruta | Destino | Descripción |
|---|---|---|---|
| `POST` | `/api/auth/login` | `authentication-api:4000` | Login |
| `POST` | `/api/auth/refresh` | `authentication-api:4000` | Refresh de token |
| `GET` | `/api/auth/health` | `authentication-api:4000` | Healthcheck de auth |
| `POST` | `/api/user` | `user-api:6000` | Registro de usuario |

---

## Rutas autenticadas (requieren Bearer token)

| Prefijo | Destino | Permiso mínimo |
|---|---|---|
| `/api/auth/logout` | `authentication-api:4000` | autenticado |
| `/api/auth/verify` | `authentication-api:4000` | autenticado |
| `/api/user` | `user-api:6000` | `users:read` |
| `/api/files` | `api-files:3700` | `files:read` |
| `/api/manager` | `api-manager:3800` | `admin` |
| `/api/billing` | `billing-api:3004` | `billing:read` |
| `/api/insights` | `api-insights:3600` | `insights:read` |
| `/api/roles` | `api-roles:5002` | `roles:read` |
| `/api/authorization` | `authorization-api:5000` | autenticado |

---

## SSE bypass

```
GET /api/insights/stream
Authorization: Bearer <token>
Accept: text/event-stream
```

El gateway no bufferiza esta ruta. La conexión SSE se mantiene abierta directamente al servicio de insights.

---

## Cabeceras en respuestas del gateway

| Cabecera | Valor |
|---|---|
| `Access-Control-Allow-Origin` | valor de `CORS_ORIGIN` |
| `X-Rate-Limit-Remaining` | requests restantes en la ventana |

---

## Rate limiting

- Límite: `RATE_LIMIT_MAX` requests por ventana (default: 100)
- Scope: por IP de origen
- Response al superar: `429 Too Many Requests`

```json
{ "error": "Demasiadas solicitudes, intenta más tarde" }
```
