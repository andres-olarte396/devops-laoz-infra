# Interfaces — Contratos de API

Documentación de los contratos HTTP del ecosistema: endpoints, schemas de request/response y convenciones compartidas.

---

## Convenciones generales

### URL base

En producción todas las APIs se acceden a través del gateway:

```
http://<host>:9000/api/<servicio>/...
```

En desarrollo con override, también directamente:

```
http://localhost:<puerto>/api/<ruta>
```

### Autenticación

Todos los endpoints protegidos usan Bearer Token:

```
Authorization: Bearer <accessToken>
```

### Formato de respuesta

**Éxito:**
```json
{ "campo": "valor", "campo2": "valor2" }
```

**Error:**
```json
{ "error": "Descripción del error" }
```

Ver [shared-schemas.md](shared-schemas.md) para schemas detallados.

### Paginación

Los endpoints de listado soportan:
```
?limit=20&skip=0
```

---

## Índice de contratos

| Servicio | Documento |
|---|---|
| Schemas compartidos (JWT, error, paginación) | [shared-schemas.md](shared-schemas.md) |
| API Gateway — tabla de rutas | [api-gateway.md](api-gateway.md) |
| Authentication API | [authentication-api.md](authentication-api.md) |
| Authorization API | [authorization-api.md](authorization-api.md) |
| User API | [user-api.md](user-api.md) |

> Los demás servicios exponen Swagger UI en `/api-docs` cuando están corriendo en modo dev. Ver [deployment/local-development.md](../deployment/local-development.md).
