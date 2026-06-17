# Componente: auth-frontend

| Campo | Valor |
|---|---|
| **Repositorio** | `dev-laoz-auth-frontend` |
| **Puerto externo** | `9001` |
| **Stack** | React 18 + TypeScript + Vite + nginx |

---

## Responsabilidades

SPA de autenticación del ecosistema. Permite login, registro y administración de usuarios. Es el punto de entrada para obtener tokens JWT que el resto del ecosistema acepta.

---

## Rutas de la aplicación

| Ruta | Componente | Descripción |
|---|---|---|
| `/login` | `Login.tsx` | Formulario de autenticación |
| `/register` | `Register.tsx` | Registro de nuevo usuario |
| `/admin` | `UserAdmin.tsx` | Listado y gestión de usuarios (requiere auth) |
| `/admin/edit/:id` | `EditUser.tsx` | Edición de usuario |
| `*` | Redirect → `/login` | Rutas no encontradas |

---

## Flujo de login con redirect

Cuando otros portales del ecosistema necesitan autenticar al usuario, redirigen aquí con un parámetro `redirect_uri`:

```
http://host:9001/login?redirect_uri=http%3A%2F%2Fhost%3A80
```

Tras login exitoso, `auth-frontend` redirige al `redirect_uri` con los tokens en el **hash fragment** (nunca en query string):

```
http://host:80#access_token=eyJ...&refresh_token=abc...
```

**Protección open redirect**: solo se acepta `redirect_uri` con el mismo `hostname` que el servidor actual.

---

## Almacenamiento de tokens

- `sessionStorage['laoz_access_token']` — token de acceso (1h)
- `sessionStorage['laoz_refresh_token']` — token de refresco (7d)
- No se usa `localStorage` (vulnerable a XSS)

---

## Variables de entorno (build-time)

Pasadas como `args` en el `docker-compose.yml`:

```text
VITE_AUTH_API_URL   http://localhost:9000/api/auth
VITE_USER_API_URL   http://localhost:9000/api/user
```

---

## Dependencias runtime

```
api-gateway    — proxy para auth API y user API
```

---

## Notas de seguridad

- Las llamadas a la API incluyen `Authorization: Bearer` en todos los endpoints autenticados.
- `VITE_*` variables son públicas (quedan en el bundle). No incluir secretos.
