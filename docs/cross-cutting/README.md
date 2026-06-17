# Requerimientos Transversales

Preocupaciones técnicas que aplican a **todos** los microservicios del ecosistema Dev Laoz. Están implementadas centralmente en la librería `@dev-laoz/core` (`dev-laoz-config-loader`) para garantizar comportamiento uniforme.

---

## Resumen

| Concern | Implementación | Documento |
|---|---|---|
| **Autenticación** | JWT stateful emitido por `authentication-api`, validado por `authorization-api` | [authentication.md](authentication.md) |
| **Autorización (RBAC)** | Roles y permisos consultados en `api-roles`, caché 5 min | [authorization.md](authorization.md) |
| **Logging y observabilidad** | `logger` de `@dev-laoz/core` → `api-insights` (fire-and-forget) | [logging-observability.md](logging-observability.md) |
| **Gestión de secretos** | `config.loadRemoteSecrets()` → `api-secrets` (AES-256-CBC) | [secrets-management.md](secrets-management.md) |
| **Manejo de errores** | Formato HTTP uniforme `{ error, message, code }` | [error-handling.md](error-handling.md) |
| **Rate limiting** | `rateLimitMiddleware` de `@dev-laoz/core`, configurable con `RATE_LIMIT_MAX` | [authentication.md](authentication.md) |
| **CORS** | Configurado en gateway y en cada servicio con `CORS_ORIGIN` | [authentication.md](authentication.md) |

---

## Cómo usar `@dev-laoz/core`

```js
const { config, logger, authMiddleware, rateLimitMiddleware } = require('@dev-laoz/core');

// Al arrancar el servicio
await config.loadRemoteSecrets('mi-servicio', ['MONGO_URI', 'JWT_SECRET']);

// En cualquier punto del código
logger.info('Operación completada', { userId, action });
logger.error('Fallo en DB', err.stack, { query });
logger.audit('usuario-123', 'FILE_UPLOAD', fileId, 'SUCCESS', { size });
logger.transaction('/api/files', 'POST', 201, 45);

// Middleware Express
app.use(rateLimitMiddleware);
router.get('/recurso', authMiddleware, handler);
```

---

## Variables de entorno requeridas por `@dev-laoz/core`

Todos los servicios que usan la librería necesitan estas variables (cargadas desde `api-secrets` o `.env`):

```text
SECRETS_API_URL         https://api-secrets:3501/api/secrets
AUTHORIZATION_API_URL   http://authorization-api:5000/api/authorization/validate
ROLES_API_URL           http://api-roles:5002/api/roles/check
INSIGHTS_HOST           api-insights
INSIGHTS_PORT           3600
RATE_LIMIT_MAX          100
```
