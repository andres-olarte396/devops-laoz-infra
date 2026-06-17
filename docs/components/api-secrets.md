# Componente: api-secrets

| Campo | Valor |
|---|---|
| **Repositorio** | `dev-laoz-api-secrets` |
| **Puerto interno** | `3501` (HTTPS) |
| **Protocolo** | HTTPS con certificado autofirmado |
| **Healthcheck** | `GET /api/health` |

---

## Responsabilidades

Almacena y sirve **secretos cifrados** con AES-256-CBC. Primer servicio en arrancar en la cadena de dependencias. Solo accesible desde la red interna `laoz-net`.

Ver detalle del diseño en [cross-cutting/secrets-management.md](../cross-cutting/secrets-management.md).

---

## Endpoints

| Método | Ruta | Restricción | Descripción |
|---|---|---|---|
| `POST` | `/api/secrets` | IP interna (`laoz-net`) | Crea o actualiza un secreto |
| `POST` | `/api/secrets/:app` | IP interna | Obtiene secreto descifrado de una app |
| `GET` | `/api/health` | Ninguna | Healthcheck |

### Crear/actualizar secreto
```http
POST /api/secrets
{ "app": "user-api", "key": "MONGO_URI", "value": "mongodb://mongo:27017/laoz" }
```

### Obtener secreto
```http
POST /api/secrets/user-api
{ "key": "MONGO_URI" }
→ { "value": "mongodb://mongo:27017/laoz" }
```

---

## Modelo de datos

```js
Secret {
  app:       String  // nombre del servicio
  key:       String  // nombre de la variable
  value:     String  // valor cifrado AES-256-CBC
  createdAt: Date
  updatedAt: Date
}
// índice único: { app, key }
```

---

## Dependencias

```
mongo   (healthy)   — almacenar secretos cifrados
```

Solo depende de MongoDB; ningún otro servicio lo bloquea.

---

## Variables de entorno propias

```text
PORT            3501
SERVICE_NAME    api-secrets
ENCRYPTION_KEY  <exactamente 32 caracteres>
MONGO_URI       mongodb://mongo:27017/laoz  (solo esta se pasa directamente al servicio)
```

> `ENCRYPTION_KEY` es la única clave que este servicio no puede autocargar desde sí mismo. Debe estar en el `.env` o como variable del contenedor.
