# Arquitectura — Vista General

> Documento de referencia rápida. El detalle completo con diagramas Mermaid está en [`ARCHITECTURE.md`](../../ARCHITECTURE.md).

---

## Principios de diseño

| Principio | Aplicación en el ecosistema |
|---|---|
| **Single Responsibility** | Cada microservicio tiene un único dominio (auth, files, billing…). Ninguno duplica lógica de otro. |
| **Defense in Depth** | Autenticación en Gateway + validación de permisos en Authorization API + validación de input en cada servicio. |
| **Fail Fast** | Los servicios validan tokens y permisos antes de ejecutar lógica de negocio. |
| **Zero Trust interno** | Aunque los servicios están en `laoz-net`, deben autenticarse entre sí para operaciones sensibles. |
| **Observabilidad desde el día 1** | Todos los servicios emiten logs, auditoría y métricas HTTP a través de `@dev-laoz/core`. |
| **Secrets nunca en imagen** | Las credenciales se cargan en runtime desde `api-secrets`; el fallback a variables de entorno existe solo para desarrollo. |

---

## Mapa de capacidades

```
┌─────────────────────────────────────────────────────────────────┐
│                         Puntos de entrada                        │
│   portal:80   auth-frontend:9001   api-gateway:9000   docs:7000 │
└──────────────────────────┬──────────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                      API Gateway (:3002)                         │
│   proxy inverso · validación auth · rate limiting · circuit      │
│   breaker · SSE bypass · routing por prefijo /api/<servicio>     │
└──┬──────────────┬──────────────┬──────────────┬─────────────────┘
   │              │              │              │
┌──▼──┐      ┌───▼───┐     ┌────▼────┐    ┌───▼───┐
│Auth │      │ Roles │     │  Users  │    │ Files │  … APIs de negocio
│:4000│      │ :5002 │     │  :6000  │    │ :3700 │
└──┬──┘      └───┬───┘     └────┬────┘    └───────┘
   │    ┌────────┘              │
┌──▼────▼──────────────────────▼───────────────────┐
│              Infraestructura compartida            │
│   api-secrets:3501(HTTPS)   api-insights:3600      │
│   MongoDB:27017                                    │
└───────────────────────────────────────────────────┘
```

---

## Patrones arquitectónicos usados

### API Gateway (Fachada)
Un único punto de entrada externo en `api-gateway:9000`. Ningún servicio backend debe ser accesible desde el exterior en producción. El gateway:
- Verifica autenticación llamando a `authorization-api` antes de reenviar.
- Aplica rate limiting por IP.
- Hace bypass de SSE para `/api/insights/stream`.

### Librería compartida `@dev-laoz/core`
En lugar de copiar código de logging, auth y carga de secretos entre servicios, existe una librería interna (`dev-laoz-config-loader`) referenciada como dependencia local. Esto garantiza comportamiento consistente y facilita actualizaciones.

### Sesiones stateful + JWT
El JWT contiene solo `{ userId, sessionToken }`. Los roles y permisos **no están en el token** — se resuelven en tiempo de validación consultando la BD y `api-roles`. Ver [ADR-001](decisions/ADR-001-stateful-jwt.md).

### RBAC con caché en memoria
Authorization API mantiene una caché de 5 minutos para resultados de `roles → permisos`, reduciendo latencia en rutas frecuentes sin sacrificar consistencia en ventanas cortas.

---

## Tecnologías por capa

| Capa | Tecnología |
|---|---|
| Backend | Node.js + Express |
| Base de datos | MongoDB 7 (Mongoose ODM) |
| Autenticación | JWT (`jsonwebtoken`) + bcrypt |
| Cifrado de secretos | AES-256-CBC (`crypto` built-in) |
| Orquestación | Docker Compose V2 |
| Frontend portal | React 18 + Vite + TailwindCSS |
| Frontend auth | React 18 + TypeScript + Vite |
| Proxy / serving | nginx (frontends) |
| Documentación API | Swagger UI / OpenAPI 3 |

---

## Repositorios del ecosistema

| Repositorio | Descripción |
|---|---|
| `devops-laoz-infra` | Orquestación Docker, documentación (este repo) |
| `dev-laoz-api-gateway` | API Gateway |
| `dev-laoz-authentication-api` | Emisión de tokens JWT |
| `dev-laoz-authorization-api` | Validación de tokens y RBAC |
| `dev-laoz-api-roles` | Roles y permisos |
| `dev-laoz-api-user` | CRUD de usuarios |
| `dev-laoz-api-secrets` | Secretos cifrados |
| `dev-laoz-api-insights` | Observabilidad y logs |
| `dev-laoz-api-files` | Gestión de archivos versionados |
| `dev-laoz-api-manager` | Control de Docker y Git |
| `dev-laoz-billing-api` | Pagos y suscripciones |
| `dev-laoz-config-loader` | Librería `@dev-laoz/core` |
| `dev-laoz-auth-frontend` | Frontend de autenticación |
| `dev-laoz-portal` | Portal principal del ecosistema |
| `dev-laoz-docs-automator` | Generador de documentación |
