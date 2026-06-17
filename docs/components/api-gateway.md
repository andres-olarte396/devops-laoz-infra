# Componente: api-gateway

| Campo | Valor |
|---|---|
| **Repositorio** | `dev-laoz-api-gateway` |
| **Puerto externo** | `9000` |
| **Puerto interno** | `3002` |
| **Imagen** | Build desde Dockerfile propio |

---

## Responsabilidades

- Único punto de entrada externo para todas las APIs del ecosistema.
- Proxy inverso a microservicios internos según prefijo de ruta.
- Valida autenticación y permisos llamando a `authorization-api` antes de reenviar.
- Aplica rate limiting global.
- Circuit breaker para servicios no disponibles.
- Bypass directo de SSE para `/api/insights/stream`.

---

## Rutas proxeadas

| Prefijo | Destino | Auth | Permiso requerido |
|---|---|---|---|
| `/api/auth` | `authentication-api:4000` | No | — |
| `/api/user` | `user-api:6000` | Sí | `users:read` |
| `/api/files` | `api-files:3700` | Sí | `files:read` |
| `/api/manager` | `api-manager:3800` | Sí | admin |
| `/api/billing` | `billing-api:3004` | Sí | `billing:read` |
| `/api/insights` | `api-insights:3600` | Sí (excepto ingesta) | `insights:read` |
| `/api/roles` | `api-roles:5002` | Sí | `roles:read` |
| `/api/authorization` | `authorization-api:5000` | Sí | — |

> La configuración exacta de rutas está en `src/config/services.json` del repositorio.

---

## Dependencias

```
authentication-api (healthy)
authorization-api  (healthy)
api-insights       (started)
user-api           (started)
api-files          (started)
api-manager        (started)
billing-api        (started)
```

---

## Variables de entorno

```text
LOCAL_PORT              3002
SERVICE_NAME            api-gateway
JWT_SECRET              (desde .env / api-secrets)
AUTHORIZATION_API_URL   http://authorization-api:5000/api/authorization/validate
RATE_LIMIT_MAX          100
CORS_ORIGIN             http://localhost:80
```

---

## Notas operativas

- **No exponer** servicios backend directamente en producción; todo el tráfico externo debe pasar por aquí.
- En modo desarrollo (`docker-compose.override.yml`) los servicios internos exponen sus puertos para debugging sin pasar por el gateway.
- El gateway no tiene estado propio; puede reiniciarse sin pérdida de datos.
