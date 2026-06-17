# ADR-001 — JWT con validación de sesión stateful

| Campo | Valor |
|---|---|
| **Estado** | Aceptado |
| **Fecha** | 2024 |
| **Autores** | Equipo Dev Laoz |

---

## Contexto

Los sistemas de autenticación modernos pueden implementarse de dos formas principales:

- **Stateless**: El JWT contiene toda la información necesaria (claims de roles, permisos, usuario). El servidor verifica la firma criptográfica sin consultar base de datos.
- **Stateful**: El JWT contiene solo un identificador de sesión. El servidor valida el token consultando la BD para verificar que la sesión sigue activa.

---

## Decisión

Se usa **JWT stateful**: el payload del token contiene únicamente `{ userId, sessionToken }`. En cada request protegido, `authorization-api` consulta MongoDB para verificar que la sesión existe y está activa (`isActive: true`).

Los **roles y permisos no están embebidos en el JWT**. Se resuelven en tiempo de validación desde `user-api` y `api-roles`.

---

## Justificación

### A favor del enfoque stateful

1. **Revocación inmediata**: Al hacer logout, la sesión se marca `isActive: false` y el token queda inválido de inmediato, sin esperar expiración. Esto es crítico para escenarios de cuenta comprometida.

2. **Sin roles obsoletos en token**: Si a un usuario se le cambia el rol mientras tiene un token activo, el cambio surte efecto en el siguiente request (se consulta la BD). Con stateless, el usuario retendría el rol viejo hasta que el token expire (hasta 1 hora).

3. **Auditoría de sesiones**: La tabla `Session` permite ver qué sesiones están abiertas, desde qué momento, y terminarlas selectivamente.

4. **Simplicidad de permisos**: El sistema RBAC es dinámico (los roles pueden cambiar en cualquier momento). Embeber permisos en el JWT requeriría tokens de corta vida y refresh frecuente, o aceptar ventanas de inconsistencia.

### Contrapartidas aceptadas

| Contrapartida | Mitigación |
|---|---|
| Latencia adicional por consulta a BD | Caché en memoria de 5 minutos en `authorization-api` para resultados de roles |
| `authorization-api` es un punto de fallo | Circuit breaker en el gateway; healthchecks con reintentos en Docker Compose |
| No escala horizontalmente sin BD compartida | MongoDB es el store compartido; la caché es local a cada instancia (consistencia eventual en 5 min) |

---

## Alternativas descartadas

### JWT stateless con claims de roles
- **Ventaja**: sin consulta a BD por request.
- **Descarte**: no permite revocación inmediata. Un token comprometido sería válido hasta su expiración. Para el tamaño actual del ecosistema la latencia de la BD es aceptable.

### OAuth 2.0 con servidor de autorización externo (Keycloak, Auth0)
- **Ventaja**: estándar de la industria, soporte para OIDC, federation.
- **Descarte**: introduce una dependencia externa crítica y complejidad operativa que no es justificable para un ecosistema interno de este tamaño. Se puede migrar a esta opción en el futuro si escala.

---

## Consecuencias

- `authorization-api` **siempre** debe estar disponible para que el gateway pueda autenticar requests.
- Los tokens tienen vida corta (1 hora). El cliente debe implementar refresh automático usando el `refreshToken` (7 días).
- La tabla `Session` en MongoDB debe tener un índice TTL para limpiar sesiones expiradas automáticamente.
