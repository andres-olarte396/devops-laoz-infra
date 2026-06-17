# Variables de Entorno — Referencia Completa

Todas las variables del archivo `.env` raíz (usado por `docker-compose.yml`).

---

## Variables críticas de seguridad

| Variable | Descripción | Restricción | Ejemplo |
|---|---|---|---|
| `JWT_SECRET` | Clave para firmar y verificar tokens JWT | Mínimo 32 chars, base64 recomendado | `wY0KVH00xhMbpTDm8jv2nQzRpCsLfAeX` |
| `ENCRYPTION_KEY` | Clave AES-256-CBC para cifrar secretos en `api-secrets` | **Exactamente 32 chars** | `UrCwMejRI4VWBiquQfpx19yb0OoLFZS7` |

> Generar valores seguros:
> ```bash
> # JWT_SECRET (base64, 32 chars efectivos)
> openssl rand -base64 32
>
> # ENCRYPTION_KEY (exactamente 32 chars ASCII)
> openssl rand -base64 24 | tr -d '=+/' | head -c 32
> ```

---

## Base de datos

| Variable | Descripción | Valor en Docker |
|---|---|---|
| `MONGO_URI` | URI de conexión a MongoDB | `mongodb://mongo:27017/laoz` |

---

## URLs internas de servicios

Estas URLs usan nombres de contenedor (DNS interno de `laoz-net`):

| Variable | Descripción | Valor estándar |
|---|---|---|
| `SECRETS_API_URL` | URL de `api-secrets` | `https://api-secrets:3501/api/secrets` |
| `AUTHORIZATION_API_URL` | URL del endpoint de validación | `http://authorization-api:5000/api/authorization/validate` |
| `ROLES_API_URL` | URL del endpoint de verificación de roles | `http://api-roles:5002/api/roles/check` |

---

## Observabilidad

| Variable | Descripción | Valor estándar |
|---|---|---|
| `INSIGHTS_HOST` | Hostname de `api-insights` | `api-insights` |
| `INSIGHTS_PORT` | Puerto de `api-insights` | `3600` |

---

## Configuración general

| Variable | Descripción | Valor estándar |
|---|---|---|
| `RATE_LIMIT_MAX` | Máximo de requests por ventana de tiempo | `100` |
| `CORS_ORIGIN` | Origen permitido en cabeceras CORS | `http://localhost:80` |
| `API_VERSION` | Versión de la API (metadata) | `1.0.0` |

---

## Variables de frontends (build-time)

Pasadas como `args` en `docker-compose.yml`. Se incrustan en el bundle de Vite:

### auth-frontend

| Variable | Descripción | Valor estándar |
|---|---|---|
| `VITE_AUTH_API_URL` | URL de la Auth API (vía gateway) | `http://localhost:9000/api/auth` |
| `VITE_USER_API_URL` | URL de la User API (vía gateway) | `http://localhost:9000/api/user` |

### portal

| Variable | Descripción | Valor estándar |
|---|---|---|
| `VITE_AUTH_FRONTEND_URL` | URL del auth-frontend para redirects de login | `http://localhost:9001` |
| `VITE_AUTH_API_URL` | URL para silent token refresh | `http://localhost:9000/api/auth` |
| `VITE_FILES_SERVICE_URL` | URL del gestor de archivos | `http://localhost:9000/api/files` |
| `VITE_MARKDOWN_SERVICE_URL` | URL del docs-automator | `http://localhost:7000` |

---

## Plantilla `.env.template`

```dotenv
# === SEGURIDAD (REQUERIDO) ===
JWT_SECRET=
ENCRYPTION_KEY=

# === BASE DE DATOS ===
MONGO_URI=mongodb://mongo:27017/laoz

# === URLs INTERNAS ===
SECRETS_API_URL=https://api-secrets:3501/api/secrets
AUTHORIZATION_API_URL=http://authorization-api:5000/api/authorization/validate
ROLES_API_URL=http://api-roles:5002/api/roles/check

# === OBSERVABILIDAD ===
INSIGHTS_HOST=api-insights
INSIGHTS_PORT=3600

# === CONFIGURACIÓN ===
RATE_LIMIT_MAX=100
CORS_ORIGIN=http://localhost:80
API_VERSION=1.0.0
```

> El archivo `.env` con valores reales **nunca debe commitearse**. Está en `.gitignore`.
