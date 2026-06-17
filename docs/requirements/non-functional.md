# Requerimientos No Funcionales

**Estado:** `[I]` Implementado · `[P]` Parcial · `[X]` Pendiente

---

## RNF-01 Seguridad

| ID | Requerimiento | Estado | Notas |
|---|---|---|---|
| RNF-01.1 | Los tokens JWT deben expirar en máximo 1 hora | [I] | `expiresIn: '1h'` |
| RNF-01.2 | Las contraseñas deben hashearse con bcrypt (cost factor ≥ 10) | [I] | |
| RNF-01.3 | Los secretos en BD deben estar cifrados con AES-256-CBC | [I] | `ENCRYPTION_KEY` 32 chars |
| RNF-01.4 | La comunicación con `api-secrets` debe ser HTTPS | [I] | Certificado autofirmado en dev |
| RNF-01.5 | `api-secrets` no debe ser accesible desde el exterior | [I] | Sin puerto expuesto en producción |
| RNF-01.6 | El `accessToken` del cliente no debe almacenarse en `localStorage` | [I] | Usa `sessionStorage` |
| RNF-01.7 | Los tokens entre apps deben pasarse en hash fragment (no query string) | [I] | No llega al servidor |
| RNF-01.8 | Los redirects post-login deben validarse contra `hostname` permitido | [I] | Anti open-redirect |
| RNF-01.9 | El stack completo debe operar bajo HTTPS en producción | [X] | Requiere certificado en gateway |
| RNF-01.10 | Los tokens de login deben tener rate limiting específico | [P] | Rate limiting global existe; específico para `/login` pendiente |
| RNF-01.11 | La rotación de `JWT_SECRET` debe ser posible sin downtime | [X] | Requiere soporte de múltiples claves en `authMiddleware` |

---

## RNF-02 Disponibilidad

| ID | Requerimiento | Estado | Notas |
|---|---|---|---|
| RNF-02.1 | El stack debe iniciar en el orden correcto respetando dependencias | [I] | `depends_on` con `service_healthy` |
| RNF-02.2 | Los servicios deben tener healthchecks configurados | [P] | auth, authz, secrets y mongo tienen; otros no |
| RNF-02.3 | El gateway debe tener circuit breaker para servicios no disponibles | [I] | |
| RNF-02.4 | Los logs de observabilidad deben ser fire-and-forget (no bloquear el servicio) | [I] | |
| RNF-02.5 | Un fallo en `api-insights` no debe impedir operación del ecosistema | [I] | |
| RNF-02.6 | Los datos de MongoDB deben persistir en un volumen nombrado | [I] | `mongo-data` |

---

## RNF-03 Rendimiento

| ID | Requerimiento | Estado | Notas |
|---|---|---|---|
| RNF-03.1 | La validación de auth no debe añadir más de 50ms de latencia en el percentil 95 | [P] | Caché de 5 min mitiga, sin benchmark formal |
| RNF-03.2 | Los resultados de permisos RBAC deben cachearse por 5 minutos | [I] | En memoria en `authorization-api` |
| RNF-03.3 | El rate limiting debe operar con un máximo configurable (`RATE_LIMIT_MAX`) | [I] | Default: 100 req/ventana |
| RNF-03.4 | Las imágenes Docker deben construirse en paralelo cuando sea posible | [I] | `--parallel` en build |

---

## RNF-04 Mantenibilidad

| ID | Requerimiento | Estado | Notas |
|---|---|---|---|
| RNF-04.1 | La funcionalidad transversal debe estar en una sola librería (`@dev-laoz/core`) | [I] | |
| RNF-04.2 | Los servicios deben exponer Swagger UI en `/api-docs` | [I] | Via `createSwaggerDocs` |
| RNF-04.3 | Cada servicio debe tener un único dominio de responsabilidad | [I] | |
| RNF-04.4 | La documentación de arquitectura debe mantenerse actualizada con el código | [P] | Este directorio docs/ |
| RNF-04.5 | Los cambios de configuración no deben requerir modificar imágenes Docker | [I] | Todo configurable por env vars |

---

## RNF-05 Observabilidad

| ID | Requerimiento | Estado | Notas |
|---|---|---|---|
| RNF-05.1 | Todos los errores de producción (5xx) deben loggearse | [I] | Via `logger.error` |
| RNF-05.2 | Las operaciones sobre recursos sensibles deben auditarse | [P] | Implementado en auth; pendiente en todos los servicios |
| RNF-05.3 | Los datos de auditoría deben conservarse 90 días | [I] | TTL en `api-insights` |
| RNF-05.4 | Debe ser posible monitorear el ecosistema en tiempo real | [I] | SSE en `/api/insights/stream` |

---

## RNF-06 Operabilidad

| ID | Requerimiento | Estado | Notas |
|---|---|---|---|
| RNF-06.1 | El ecosistema debe levantarse con un solo comando | [I] | `docker compose up -d` |
| RNF-06.2 | Debe ser posible reconstruir y reiniciar un servicio sin bajar los demás | [I] | `up -d --no-deps <servicio>` |
| RNF-06.3 | El modo de desarrollo debe exponer puertos internos para debugging | [I] | `docker-compose.override.yml` |
| RNF-06.4 | Debe existir un mecanismo de backup para los datos de MongoDB | [X] | Pendiente automatización |
