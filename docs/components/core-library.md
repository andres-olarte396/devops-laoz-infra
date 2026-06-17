# Componente: @dev-laoz/core (librería compartida)

| Campo | Valor |
|---|---|
| **Repositorio** | `dev-laoz-config-loader` |
| **Nombre de paquete** | `@dev-laoz/core` |
| **Referencia en consumer** | `"@dev-laoz/core": "file:../dev-laoz-config-loader"` |

---

## Responsabilidades

Librería interna que provee funcionalidad transversal a todos los microservicios. Garantiza comportamiento uniforme sin duplicar código.

---

## API pública

### `config.loadRemoteSecrets(appName, keys[])`

Carga secretos desde `api-secrets` y los inyecta en `process.env`. Con fallback a `process.env` existente.

```js
const { config } = require('@dev-laoz/core');
await config.loadRemoteSecrets('user-api', ['MONGO_URI', 'JWT_SECRET']);
```

### `logger`

```js
const { logger } = require('@dev-laoz/core');
logger.info(message, metadata)
logger.warn(message, metadata)
logger.error(message, stack, metadata)
logger.debug(message, metadata)
logger.audit(actor, action, target, outcome, metadata)
logger.transaction(path, method, statusCode, durationMs)
```

### `authMiddleware`

Middleware Express que valida el Bearer token llamando a `authorization-api`.

```js
const { authMiddleware } = require('@dev-laoz/core');
router.get('/protected', authMiddleware, handler);
// Añade req.user = { userId, sessionToken }
```

### `rateLimitMiddleware`

Rate limiting configurable. Usa `RATE_LIMIT_MAX` (default: 100).

```js
const { rateLimitMiddleware } = require('@dev-laoz/core');
app.use(rateLimitMiddleware);
```

### `createSwaggerDocs(app, options)`

Configura Swagger UI en `/api-docs`.

```js
const { createSwaggerDocs } = require('@dev-laoz/core');
createSwaggerDocs(app, { title: 'User API', version: '1.0.0' });
```

---

## Variables de entorno requeridas

```text
SECRETS_API_URL           https://api-secrets:3501/api/secrets
AUTHORIZATION_API_URL     http://authorization-api:5000/api/authorization/validate
ROLES_API_URL             http://api-roles:5002/api/roles/check
INSIGHTS_HOST             api-insights
INSIGHTS_PORT             3600
RATE_LIMIT_MAX            100
```

---

## Actualización de la librería

Al modificar `@dev-laoz/core`, todos los servicios que la usan deben **reconstruirse** para incorporar los cambios:

```bash
docker compose -f docker-compose.yml build --parallel
```

Dado que se referencia como `file:../dev-laoz-config-loader`, los cambios locales no requieren publicar a npm.
