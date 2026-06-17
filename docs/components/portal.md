# Componente: portal

| Campo | Valor |
|---|---|
| **Repositorio** | `dev-laoz-portal` |
| **Puerto externo** | `80` |
| **Stack** | React 18 + Vite + TailwindCSS + nginx |

---

## Responsabilidades

Portal principal del ecosistema. Punto de entrada unificado que integra todos los servicios disponibles. Requiere autenticación: redirige automáticamente a `auth-frontend` si no hay sesión activa.

---

## Rutas de la aplicación

| Ruta | Módulo | Descripción |
|---|---|---|
| `/` | `DashboardModule` | Resumen del ecosistema, stats y servicios |
| `/files` | `FilesModule` | Integración con api-files |
| `/docs` | `MarkdownModule` | Vista de documentación (docs-automator) |
| `/settings` | — | En construcción |

---

## Guard de autenticación

Al cargar, el portal ejecuta el siguiente flujo:

```
1. ¿Token en hash URL? → consumir, limpiar URL, continuar
2. ¿Token en sessionStorage? → verificar expiración
3. ¿Expirado? → silent refresh con refreshToken
4. ¿Sin token o refresh fallido? → redirect a auth-frontend con redirect_uri
5. Token válido → renderizar app
```

Se programa automáticamente un refresh silencioso 60 s antes de la expiración del JWT.

---

## Módulos integrados

El `DashboardModule` lista los servicios del ecosistema desde `src/config/services.js`. La URL de cada servicio se configura en tiempo de build:

| Servicio | Variable de entorno |
|---|---|
| Gestor de archivos | `VITE_FILES_SERVICE_URL` o `VITE_FILES_SERVICE_PORT` |
| Documentación Markdown | `VITE_MARKDOWN_SERVICE_URL` o `VITE_MARKDOWN_SERVICE_PORT` |

---

## Almacenamiento de tokens

- `sessionStorage['laoz_access_token']`
- `sessionStorage['laoz_refresh_token']`

Los módulos del portal acceden al token mediante `getAuthHeaders()` de `src/auth/tokenStore.js`.

---

## Variables de entorno (build-time)

```text
VITE_AUTH_FRONTEND_URL      http://localhost:9001
VITE_AUTH_API_URL           http://localhost:9000/api/auth
VITE_FILES_SERVICE_URL      http://localhost:9000/api/files
VITE_MARKDOWN_SERVICE_URL   http://localhost:7000
```

---

## Dependencias runtime

```
api-gateway       — refresh de token, llamadas API
auth-frontend     — login cuando no hay sesión
docs-automator    — módulo de documentación
```
