# Interfaz: authorization-api

Base URL (dev directo): `http://localhost:5000/api/authorization`

> Este servicio es llamado internamente por el **api-gateway** en cada request protegido. Los clientes externos no lo llaman directamente.

---

## POST /api/authorization/validate

Valida un token JWT y opcionalmente verifica un permiso RBAC.

**Request:**
```http
POST /api/authorization/validate
Authorization: Bearer <accessToken>
Content-Type: application/json

{
  "requiredPermission": "files:write"
}
```

- Si `requiredPermission` está vacío o ausente → solo valida autenticación.
- Si `requiredPermission` está presente → valida autenticación + permiso RBAC.

**Response 200 — solo autenticación:**
```json
{
  "authorized": true,
  "userId": "64abc123...",
  "message": "Autenticado"
}
```

**Response 200 — autenticación + permiso:**
```json
{
  "authorized": true,
  "userId": "64abc123...",
  "message": "Autorizado"
}
```

**Response 401 — token inválido:**
```json
{ "authorized": false, "error": "Token inválido o expirado" }
```

**Response 403 — permiso denegado:**
```json
{ "authorized": false, "error": "No tienes permiso para realizar esta acción" }
```

---

## GET /api/authorization/health

**Response 200:**
```json
{ "status": "ok", "service": "authorization-api" }
```
