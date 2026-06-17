# Componente: api-insights

| Campo | Valor |
|---|---|
| **Repositorio** | `dev-laoz-api-insights` |
| **Puerto interno** | `3600` |

---

## Responsabilidades

Centraliza **logs, eventos de auditoría y métricas HTTP** de todos los servicios del ecosistema. Los endpoints de ingesta no requieren autenticación (uso interno, red aislada). Los endpoints de consulta sí la requieren.

Ver detalle en [cross-cutting/logging-observability.md](../cross-cutting/logging-observability.md).

---

## Endpoints de ingesta (sin auth — fire-and-forget)

| Método | Ruta | Descripción |
|---|---|---|
| `POST` | `/api/insights/log` | Log del sistema: `{ service, level, message, metadata }` |
| `POST` | `/api/insights/audit` | Evento de auditoría: `{ actor, action, target, outcome, metadata }` |
| `POST` | `/api/insights/transaction` | Transacción HTTP: `{ service, path, method, statusCode, duration }` |

## Endpoints de consulta (requieren auth)

| Método | Ruta | Filtros disponibles |
|---|---|---|
| `GET` | `/api/insights/logs` | `service`, `level`, `from`, `to`, `limit`, `skip` |
| `GET` | `/api/insights/errors` | `service`, `from`, `to`, `limit` |
| `GET` | `/api/insights/audit` | `actor`, `action`, `outcome`, `from`, `to` |
| `GET` | `/api/insights/transactions` | `service`, `method`, `statusCode`, `minDuration` |
| `GET` | `/api/insights/stream` | SSE en tiempo real (requiere auth) |

---

## TTL de colecciones

| Colección | TTL |
|---|---|
| Logs de sistema | 7 días |
| Auditoría | 90 días |
| Transacciones HTTP | 3 días |

---

## Dependencias

```
mongo          (healthy)
api-secrets    (healthy)
```

---

## Variables de entorno

```text
PORT          3600
SERVICE_NAME  api-insights
MONGO_URI     (desde api-secrets)
```
