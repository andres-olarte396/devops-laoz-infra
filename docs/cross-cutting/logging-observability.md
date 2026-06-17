# Logging y Observabilidad

Todos los servicios del ecosistema emiten eventos a `api-insights` a través del `logger` de `@dev-laoz/core`. Las llamadas son **fire-and-forget**: si `api-insights` falla, el servicio emisor no se ve afectado.

---

## Tipos de evento

| Método | Destino en Insights | Descripción |
|---|---|---|
| `logger.info(msg, meta)` | `POST /api/insights/log` | Eventos informativos generales |
| `logger.warn(msg, meta)` | `POST /api/insights/log` | Advertencias no críticas |
| `logger.error(msg, stack, meta)` | `POST /api/insights/log` | Errores con stack trace |
| `logger.debug(msg, meta)` | `POST /api/insights/log` | Solo en modo dev |
| `logger.audit(actor, action, target, outcome, meta)` | `POST /api/insights/audit` | Eventos de seguridad y negocio |
| `logger.transaction(path, method, status, duration)` | `POST /api/insights/transaction` | Métricas HTTP por request |

---

## Uso en código

```js
const { logger } = require('@dev-laoz/core');

// Log de sistema
logger.info('Servidor iniciado', { port: 4000, env: 'production' });
logger.error('Fallo al conectar a MongoDB', err.stack, { uri: process.env.MONGO_URI });

// Auditoría — siempre registrar acciones sobre recursos sensibles
logger.audit(
  req.user?.userId ?? 'system',  // actor
  'USER_CREATED',                 // acción (SCREAMING_SNAKE_CASE)
  newUser._id.toString(),         // recurso afectado
  'SUCCESS',                      // outcome: SUCCESS | FAILURE | DENIED
  { username: newUser.username }  // metadata adicional
);

// Transacción HTTP — registrar en middleware de respuesta
logger.transaction(req.path, req.method, res.statusCode, responseTimeMs);
```

---

## Convenciones de auditoría

### Formato de acción

Usar `SCREAMING_SNAKE_CASE` con el patrón `RECURSO_VERBO`:

| Acción | Descripción |
|---|---|
| `USER_CREATED` | Registro de nuevo usuario |
| `USER_UPDATED` | Modificación de usuario |
| `USER_DELETED` | Eliminación de usuario |
| `SESSION_CREATED` | Login exitoso |
| `SESSION_TERMINATED` | Logout |
| `AUTH_FAILED` | Intento de login fallido |
| `PERMISSION_DENIED` | Acceso denegado por RBAC |
| `FILE_UPLOADED` | Subida de archivo |
| `FILE_DELETED` | Borrado de archivo |
| `SECRET_ACCESSED` | Lectura de secreto |
| `ROLE_ASSIGNED` | Asignación de rol a usuario |

### Outcomes válidos

- `SUCCESS` — operación completada
- `FAILURE` — error inesperado
- `DENIED` — acceso denegado por seguridad

---

## TTL de datos en Insights

Los datos en MongoDB tienen índices TTL configurados:

| Colección | TTL | Justificación |
|---|---|---|
| Logs de sistema | 7 días | Alta volumetría, valor decae rápido |
| Auditoría | 90 días | Requisito de trazabilidad |
| Transacciones HTTP | 3 días | Solo para análisis de rendimiento reciente |

---

## Consulta de datos

### Via REST (requiere autenticación)

```http
GET /api/insights/logs?service=authentication-api&level=error&from=2024-01-01&limit=50
GET /api/insights/errors?service=user-api&from=2024-01-01
GET /api/insights/audit?actor=user-123&action=FILE_DELETED&outcome=SUCCESS
GET /api/insights/transactions?service=api-files&minDuration=500
```

### Via SSE en tiempo real

```http
GET /api/insights/stream
Authorization: Bearer <token>
Accept: text/event-stream
```

Emite cada evento nuevo como SSE. Útil para dashboards de monitoreo en vivo. El gateway tiene bypass especial para no bufferear esta conexión.

---

## Arquitectura del pipeline

```
Servicio          @dev-laoz/core          api-insights        MongoDB
   │                    │                      │                  │
   │─logger.info()─────▶│                      │                  │
   │                    │─POST /insights/log──▶│ (async, no await)│
   │                    │  (fire-and-forget)    │─insert───────────▶
   │◀──────────────────(respuesta inmediata)    │                  │
   │                                           │──broadcast SSE──▶ clientes
```

---

## Variables de entorno

```text
INSIGHTS_HOST   api-insights   (nombre del contenedor en laoz-net)
INSIGHTS_PORT   3600
```
