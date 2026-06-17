# ADR-002 — Gestión centralizada de secretos vía API interna

| Campo | Valor |
|---|---|
| **Estado** | Aceptado |
| **Fecha** | 2024 |
| **Autores** | Equipo Dev Laoz |

---

## Contexto

Los microservicios necesitan credenciales en runtime: URI de MongoDB, JWT secret, API keys externas. La pregunta es cómo distribuir estos secretos de forma segura.

---

## Decisión

Se implementa `api-secrets`, un microservicio HTTPS dedicado que almacena secretos cifrados con **AES-256-CBC** en MongoDB. Los servicios recuperan sus secretos al arrancar llamando a la API con su nombre de aplicación.

La librería `@dev-laoz/core` expone `config.loadRemoteSecrets(appName, keys[])`, que abstrae esta llamada y proporciona fallback a `process.env` cuando `api-secrets` no está disponible.

---

## Justificación

1. **Secretos no viajan en imágenes Docker**: Las imágenes no contienen credenciales. Solo `api-secrets` tiene la `ENCRYPTION_KEY` en su variable de entorno.
2. **Rotación de secretos sin redeploy**: Cambiar un secreto en `api-secrets` no requiere reconstruir ni reiniciar los servicios dependientes (aplica en el próximo arranque).
3. **Auditoría centralizada**: Todos los accesos a secretos pasan por un único punto.
4. **Solo accesible internamente**: `api-secrets` no tiene puerto expuesto en producción; solo es accesible desde `laoz-net`.

---

## Alternativas descartadas

### Variables de entorno puras (`.env` en compose)
- Todos los secretos visibles en `docker inspect` y en el archivo `.env`.
- No permite rotación sin redeploy.
- Mantiene el fallback para desarrollo local.

### HashiCorp Vault
- Más completo (dynamic secrets, lease rotation, audit log).
- Descartado por complejidad operativa y overhead para el tamaño actual del proyecto.

---

## Consecuencias

- `api-secrets` es el **primer servicio** que debe estar `healthy` en la cadena de arranque.
- `ENCRYPTION_KEY` debe tener **exactamente 32 caracteres** (requerimiento de AES-256-CBC).
- El fallback a `process.env` permite desarrollo local sin necesidad de levantar todo el stack.
