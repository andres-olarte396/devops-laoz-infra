# Componente: authorization-api

| Campo | Valor |
|---|---|
| **Repositorio** | `dev-laoz-authorization-api` |
| **Puerto interno** | `5000` |
| **Healthcheck** | `GET /api/authorization/health` |

---

## Responsabilidades

Valida tokens JWT y verifica permisos RBAC. Es llamado por `api-gateway` en cada request protegido. Mantiene una caché en memoria de resultados de permisos para reducir latencia.

---

## Endpoints

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| `POST` | `/api/authorization/validate` | Sí (Bearer) | Valida token y opcionalmente verifica permiso |
| `GET` | `/api/authorization/health` | No | Healthcheck |

### `POST /api/authorization/validate`

**Request:**
```json
{
  "requiredPermission": "files:write"
}
```

- Si `requiredPermission` está vacío o ausente → solo valida que el token sea válido y la sesión esté activa.
- Si `requiredPermission` está presente → además consulta los roles del usuario y verifica el permiso en `api-roles`.

**Response 200:**
```json
{ "authorized": true, "userId": "64abc...", "message": "Autorizado" }
```

**Response 403:**
```json
{ "authorized": false, "error": "Permiso insuficiente" }
```

---

## Caché de permisos

- Clave: `"${userId}:${requiredPermission}"`
- TTL: **5 minutos**
- Ámbito: en memoria (local a la instancia)
- No hay invalidación activa: los cambios de rol surten efecto en máximo 5 minutos

---

## Dependencias

```
mongo          (healthy)   — verificar sesiones activas
api-secrets    (healthy)   — cargar JWT_SECRET, MONGO_URI
api-insights   (started)   — logs y auditoría
api-roles      (started)   — consulta de permisos por rol
```

---

## Variables de entorno

```text
PORT          5000
SERVICE_NAME  authorization-api
JWT_SECRET    (desde api-secrets)
MONGO_URI     (desde api-secrets)
ROLES_API_URL http://api-roles:5002/api/roles/check
```
