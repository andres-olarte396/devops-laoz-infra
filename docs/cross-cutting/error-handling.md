# Manejo de Errores

Todos los servicios del ecosistema deben devolver errores en un formato HTTP uniforme para facilitar el debugging y el manejo en el cliente.

---

## Formato estándar de error

```json
{
  "error": "Descripción técnica breve en inglés o español",
  "message": "Mensaje legible para el usuario (opcional)",
  "code": "ERROR_CODE_CONSTANT (opcional)"
}
```

**Ejemplos:**

```json
// 401 Unauthorized
{ "error": "Token inválido o expirado" }

// 403 Forbidden
{ "error": "No tienes permiso para realizar esta acción", "code": "PERMISSION_DENIED" }

// 404 Not Found
{ "error": "Usuario no encontrado", "code": "USER_NOT_FOUND" }

// 400 Bad Request
{ "error": "Faltan campos requeridos: username, password" }

// 500 Internal Server Error
{ "error": "Error interno del servidor" }
```

> **Nunca** exponer stack traces o mensajes internos de la base de datos en respuestas de producción.

---

## Códigos HTTP usados

| Código | Uso en el ecosistema |
|---|---|
| `200 OK` | Operación exitosa con body |
| `201 Created` | Recurso creado exitosamente |
| `204 No Content` | Operación exitosa sin body (DELETE) |
| `400 Bad Request` | Input inválido, campos faltantes, validación fallida |
| `401 Unauthorized` | Token ausente, inválido o expirado |
| `403 Forbidden` | Token válido pero sin permiso suficiente |
| `404 Not Found` | Recurso no encontrado |
| `409 Conflict` | Recurso ya existe (username duplicado) |
| `429 Too Many Requests` | Rate limit excedido |
| `500 Internal Server Error` | Error inesperado del servidor |
| `503 Service Unavailable` | Servicio dependiente no disponible |

---

## Patrón en Express

```js
// Middleware de manejo de errores al final del app
app.use((err, req, res, next) => {
  const status = err.status || err.statusCode || 500;
  const message = status >= 500 ? 'Error interno del servidor' : err.message;

  // Solo loggear errores 5xx
  if (status >= 500) {
    logger.error(err.message, err.stack, { path: req.path, method: req.method });
  }

  res.status(status).json({ error: message });
});
```

---

## Manejo de errores en llamadas a servicios dependientes

Cuando un servicio llama a otro y falla:

```js
// Patrón: never let a dependency error bubble up as 500
try {
  const result = await callOtherService();
  return result;
} catch (err) {
  // Log el error interno
  logger.error('Fallo al llamar a authorization-api', err.message, { url });

  // Decidir el comportamiento según criticidad
  if (isCritical) {
    return res.status(503).json({ error: 'Servicio temporalmente no disponible' });
  }
  // Si es no-crítico (e.g., insights): continuar sin el resultado
}
```

---

## Errores de autenticación y autorización

Manejados por `authMiddleware` de `@dev-laoz/core`:

| Condición | HTTP | Body |
|---|---|---|
| Header `Authorization` ausente | 401 | `{ "error": "Token requerido" }` |
| Token mal formado | 401 | `{ "error": "Token inválido" }` |
| Token expirado | 401 | `{ "error": "Token expirado" }` |
| Sesión inactiva | 401 | `{ "error": "Sesión inválida" }` |
| Permiso insuficiente | 403 | `{ "error": "Acceso denegado" }` |

---

## Errores de validación de input

Usar un formato consistente para errores de validación:

```json
{
  "error": "Validación fallida",
  "fields": {
    "username": "Requerido",
    "password": "Debe tener al menos 8 caracteres"
  }
}
```

---

## Logging de errores

Todo error 5xx debe loggearse con `logger.error`. Los errores 4xx son esperados y no requieren log (son parte del contrato de la API), excepto:

- `401` por token inválido → `logger.audit(..., 'AUTH_FAILED', ..., 'DENIED', {})`
- `403` por permiso denegado → `logger.audit(..., 'PERMISSION_DENIED', ..., 'DENIED', {})`
