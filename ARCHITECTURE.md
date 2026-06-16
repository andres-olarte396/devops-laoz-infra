# Dev Laoz — Arquitectura del Ecosistema

## Visión general

El ecosistema Dev Laoz es una plataforma de microservicios en Node.js/Express orquestados con Docker Compose. Todos los servicios backend comparten la librería interna `@dev-laoz/core` (en `dev-laoz-config-loader`) que provee logging, carga de secretos, autenticación y rate-limiting transversales.

```mermaid
flowchart TD
    Internet([Cliente / Browser])

    subgraph Externos ["Puntos de entrada expuestos"]
        GW[API Gateway\n:9000]
        FE1[auth-frontend\n:9001]
        FE2[portal\n:80]
        DOCS[docs-automator\n:7000]
    end

    subgraph Auth ["Autenticación y Autorización"]
        AT[authentication-api\n:4000]
        AZ[authorization-api\n:5000]
        R[api-roles\n:5002]
    end

    subgraph Business ["APIs de Negocio"]
        U[user-api\n:6000]
        AF[api-files\n:3700]
        AM[api-manager\n:3800]
        B[billing-api\n:3004]
        AA[api-authorization\n:5001]
    end

    subgraph Infra ["Infraestructura"]
        S[api-secrets\n:3501 HTTPS]
        I[api-insights\n:3600]
        M[(MongoDB\n:27017)]
    end

    Internet --> GW
    Internet --> FE1
    Internet --> FE2
    Internet --> DOCS

    GW --> AT
    GW --> AZ
    GW --> R
    GW --> U
    GW --> AF
    GW --> AM
    GW --> B
    GW --> I

    AZ --> R
    AT --> M
    AZ --> M
    R --> M
    U --> M
    I --> M

    AT --> S
    AZ --> S
    R --> S
    U --> S
    AF --> S
    AM --> S
    B --> S
    AA --> S
    S --> M
```

---

## Servicios

### API Gateway — puerto 9000

**Repositorio:** `dev-laoz-api-gateway`

Único punto de entrada externo. Responsabilidades:

- Proxy inverso a todos los microservicios (config en `src/config/services.json`)
- Valida autenticación llamando a Authorization API para rutas protegidas
- Rate limiting y circuit breaker por defecto
- SSE bypass directo para `/api/insights/stream`

**No exponer** ningún servicio backend directamente en producción; todo tráfico debe pasar por aquí.

---

### Authentication API — puerto 4000

**Repositorio:** `dev-laoz-authentication-api`

Responsable exclusivo de **emitir tokens JWT**.

| Endpoint | Método | Auth | Descripción |
| --- | --- | --- | --- |
| `/api/auth/login` | POST | No | Login → devuelve `accessToken` (1h) + `refreshToken` (7d) |
| `/api/auth/refresh` | POST | No | Renueva access token con refresh token |
| `/api/auth/logout` | POST | Sí | Invalida sesión en BD |
| `/api/auth/verify` | GET | Sí | Verifica validez del token |
| `/api/auth/health` | GET | No | Healthcheck |

**Flujo de login:**

```mermaid
sequenceDiagram
    participant C as Cliente
    participant GW as API Gateway
    participant AT as Authentication API
    participant DB as MongoDB

    C->>GW: POST /api/auth/login\n{username, password}
    GW->>AT: proxy (sin auth)
    AT->>DB: User.findOne({username})
    DB-->>AT: user document
    AT->>AT: bcrypt.compare(password, hash)
    AT->>DB: Session.create({sessionToken, userId, expiresAt})
    AT-->>GW: {accessToken: JWT(userId,sessionToken), refreshToken}
    GW-->>C: 200 {accessToken, refreshToken}
```

El JWT **no contiene roles ni permisos** — solo `{ userId, sessionToken }`. Los permisos se resuelven en Authorization API.

---

### Authorization API — puerto 5000

**Repositorio:** `dev-laoz-authorization-api`

Valida tokens y **verifica permisos RBAC** consultando Roles API.

| Endpoint | Método | Auth | Descripción |
| --- | --- | --- | --- |
| `/api/authorization/validate` | POST | Sí (Bearer) | Valida token y opcionalmente verifica permiso |
| `/api/authorization/health` | GET | No | Healthcheck |

**Request body:**

```json
{ "requiredPermission": "files:write" }
```

- Si `requiredPermission` está vacío → solo valida autenticación (200 OK)
- Si está presente → consulta api-roles con los roles del usuario

**Flujo RBAC:**

```mermaid
sequenceDiagram
    participant GW as API Gateway
    participant AZ as Authorization API
    participant DB as MongoDB
    participant R as Roles API
    participant Cache as Caché en memoria

    GW->>AZ: POST /api/authorization/validate\nBearer token\n{requiredPermission: "files:write"}
    AZ->>AZ: jwt.verify(token) → {userId, sessionToken}
    AZ->>DB: Session.findOne({sessionToken, isActive:true})
    DB-->>AZ: session (con userId)

    alt requiredPermission vacío
        AZ-->>GW: 200 {authorized: true, message:"Autenticado"}
    else requiredPermission presente
        AZ->>Cache: ¿existe {userId:files:write}?
        alt Hit en caché
            Cache-->>AZ: true / false
        else Miss
            AZ->>DB: User.findById(userId) → user.roles
            AZ->>R: POST /api/roles/check\n{roles:["editor"], permission:"files:write"}
            R-->>AZ: {hasPermission: true}
            AZ->>Cache: guardar por 5 min
        end
        AZ-->>GW: 200 {authorized:true} / 403
    end
```

---

### Roles & Permissions API — puerto 5002

**Repositorio:** `dev-laoz-api-roles`

Fuente de verdad para **roles y sus permisos**. Los permisos siguen el formato `resource:action`.

**Roles predeterminados (del sistema):**

| Rol | Permisos |
| --- | --- |
| `admin` | Todo (`users:*`, `roles:*`, `files:*`, `secrets:*`, `insights:*`, `billing:*`) |
| `editor` | `files:read/write/delete`, `insights:read` |
| `viewer` | `files:read`, `insights:read` |
| `user` | `files:read` |

| Endpoint | Método | Auth | Descripción |
| --- | --- | --- | --- |
| `/api/roles` | GET | Sí | Lista todos los roles |
| `/api/roles` | POST | Sí | Crea rol personalizado |
| `/api/roles/:id` | GET/PUT/DELETE | Sí | Gestión por ID |
| `/api/roles/name/:name` | GET | Sí | Obtiene rol por nombre |
| `/api/roles/check` | POST | No | Verifica si roles[] tienen un permiso (uso interno) |

---

### User API — puerto 6000

**Repositorio:** `dev-laoz-api-user`

CRUD completo de usuarios. **Registro es público** (POST `/api/user`). El resto requiere autenticación.

| Endpoint | Método | Auth | Descripción |
| --- | --- | --- | --- |
| `/api/user` | GET | Sí | Lista usuarios |
| `/api/user` | POST | No | Registra nuevo usuario |
| `/api/user/:id` | GET | Sí | Obtiene usuario por ID |
| `/api/user/:id` | PUT | Sí | Actualiza usuario |
| `/api/user/:id` | DELETE | Sí | Elimina usuario |

**Modelo User:**

```mermaid
classDiagram
    class User {
        +String username
        +String email
        +String password  // bcrypt, nunca devuelto
        +String role      // legacy: admin|user|guest
        +String[] roles   // RBAC: ["editor", "viewer"]
        +String[] permissions // legacy: read|write|delete
        +Boolean active
        +Date createdAt
        +Date updatedAt
    }
```

Para asignar roles RBAC a un usuario, usar `PUT /api/user/:id` con `{ "roles": ["editor"] }`.

---

### Secrets API — puerto 3501 (HTTPS)

**Repositorio:** `dev-laoz-api-secrets`

Almacena y sirve **secretos cifrados** con AES-256-CBC. Solo accesible desde IPs internas de la red Docker (`laoz-net`).

| Endpoint | Método | Restricción | Descripción |
| --- | --- | --- | --- |
| `/api/secrets` | POST | IP interna | Crea/actualiza un secreto |
| `/api/secrets/:app` | POST | IP interna | Obtiene secreto por app y key |
| `/api/health` | GET | Ninguna | Healthcheck |

**Cómo lo usan los demás servicios:**

```mermaid
sequenceDiagram
    participant SVC as Cualquier servicio
    participant CORE as @dev-laoz/core
    participant S as Secrets API
    participant DB as MongoDB

    SVC->>CORE: config.loadRemoteSecrets('user-api', ['MONGO_URI', 'JWT_SECRET'])
    CORE->>S: POST /api/secrets/user-api\n{key: "MONGO_URI"} (HTTPS)
    S->>DB: Secret.findOne({app:"user-api", key:"MONGO_URI"})
    DB-->>S: {value: AES_encrypted}
    S->>S: AES-256-CBC decrypt
    S-->>CORE: {value: "mongodb://mongo:27017/laoz"}
    CORE-->>SVC: process.env.MONGO_URI = value

    note over CORE: Si Secrets API falla,\nfallback a process.env
```

**Variable de entorno requerida:** `ENCRYPTION_KEY` — exactamente 32 caracteres (AES-256-CBC)

---

### Insights API — puerto 3600

**Repositorio:** `dev-laoz-api-insights`

Centraliza **logs, auditoría y métricas HTTP** de todos los servicios. Los datos expiran por TTL (7/90/3 días).

**Ingesta (sin auth — fire-and-forget):**

| Endpoint | Método | Descripción |
| --- | --- | --- |
| `/api/insights/log` | POST | Log del sistema (info/warn/error/debug) |
| `/api/insights/audit` | POST | Evento de auditoría (actor, acción, resultado) |
| `/api/insights/transaction` | POST | Transacción HTTP (path, método, status, duración) |

**Consulta (requiere auth):**

| Endpoint | Método | Filtros disponibles |
| --- | --- | --- |
| `/api/insights/logs` | GET | `service`, `level`, `from`, `to`, `limit`, `skip` |
| `/api/insights/errors` | GET | `service`, `from`, `to`, `limit` |
| `/api/insights/audit` | GET | `actor`, `action`, `outcome`, `from`, `to` |
| `/api/insights/transactions` | GET | `service`, `method`, `statusCode`, `minDuration` |
| `/api/insights/stream` | GET (SSE) | Stream en tiempo real — requiere auth |

**Pipeline de observabilidad:**

```mermaid
flowchart LR
    subgraph Servicios
        AT[auth-api]
        AZ[authorization-api]
        U[user-api]
        AF[api-files]
        GW[api-gateway]
    end

    subgraph Core ["@dev-laoz/core logger"]
        L[logger.info / error\naudit / transaction]
    end

    subgraph Insights ["api-insights :3600"]
        IN[Ingesta\nfire-and-forget]
        DB[(MongoDB\nTTL indexes)]
        SSE[SSE Stream\n/stream]
    end

    subgraph Consumidores
        CLI[Dashboard / cliente SSE]
        Q[Queries GET\n/logs, /errors, /audit]
    end

    Servicios --> L
    L -->|POST async| IN
    IN --> DB
    IN -->|broadcast| SSE
    SSE --> CLI
    DB --> Q
    Q --> CLI
```

**Cómo lo usan los demás servicios:**

```js
const { logger } = require('@dev-laoz/core');
logger.info('mensaje', { metadata });
logger.error('error', err.stack, { contexto });
logger.audit('system', 'USER_CREATED', userId, 'SUCCESS', {});
logger.transaction('/api/files', 'POST', 201, 45);
```

Las llamadas son fire-and-forget (no bloquean el servicio si Insights falla).

---

### Files API — puerto 3700

**Repositorio:** `dev-laoz-api-files`

Gestión de archivos con **versionado** y soporte multi-almacenamiento (Local / Network / Cloud).

| Endpoint | Método | Auth | Descripción |
| --- | --- | --- | --- |
| `/api/files` | POST | Sí | Sube archivo (multipart) |
| `/api/files/content` | POST | Sí | Guarda contenido de texto |
| `/api/files/:id` | GET | Sí | Descarga versión actual |
| `/api/files/:id/versions` | GET | Sí | Lista versiones |
| `/api/files/:id/versions/:vId` | GET | Sí | Descarga versión específica |
| `/api/files/:id/move` | PUT | Sí | Mueve entre tipos de almacenamiento |
| `/api/files/:id/copy` | POST | Sí | Copia archivo |

**Flujo de subida con versionado:**

```mermaid
sequenceDiagram
    participant C as Cliente
    participant AF as Files API
    participant SM as StorageManager
    participant DB as MongoDB

    C->>AF: POST /api/files (multipart)
    AF->>SM: save(buffer, filename, storageType)
    SM->>SM: Selecciona adapter\n(Local/Network/Cloud)
    SM-->>AF: {relativePath, fullPath}
    AF->>DB: File.create / addVersion\n{version++, storageType, path, mimeType, size}
    DB-->>AF: {_id, currentVersion, versions[]}
    AF-->>C: 201 {_id, originalName, currentVersion}
```

**Modelo File:**

- `versions[]` — historial completo de versiones con storageType, path, mimeType, size
- `deleted` — borrado lógico (soft delete)
- `tags[]` — etiquetas para clasificación

---

### Api Manager — puerto 3800

**Repositorio:** `dev-laoz-api-manager`

Control de **contenedores Docker y repositorios Git** (requiere acceso a `/var/run/docker.sock`).

| Endpoint | Método | Auth | Descripción |
| --- | --- | --- | --- |
| `/api/manager/containers` | GET | Sí | Lista contenedores |
| `/api/manager/containers/:id/start` | POST | Sí | Inicia contenedor |
| `/api/manager/containers/:id/stop` | POST | Sí | Detiene contenedor |
| `/api/manager/containers/:id/logs` | GET | Sí | Logs del contenedor |
| `/api/manager/git/clone` | POST | Sí | Clona repositorio |
| `/api/manager/git/status/:folder` | GET | Sí | Estado del repo |
| `/api/manager/git/pull/:folder` | POST | Sí | Pull del repo |

---

### Billing API — puerto 3004

**Repositorio:** `dev-laoz-billing-api`

Gestión de **pagos y suscripciones** (usa Sequelize/SQL internamente).

| Endpoint | Método | Auth | Descripción |
| --- | --- | --- | --- |
| `/api/billing/payments/cliente/:id` | GET | Sí | Historial de pagos |
| `/api/billing/payments` | POST | Sí | Registra pago |
| `/api/billing/payments/estado/:id` | GET | Sí | Estado de cuenta |
| `/api/billing/payments/suscripcion` | POST | Sí | Crea/actualiza suscripción |

---

## Librería compartida `@dev-laoz/core`

**Repositorio:** `dev-laoz-config-loader`
**Referenciado como:** `"@dev-laoz/core": "file:../dev-laoz-config-loader"`

```mermaid
flowchart LR
    subgraph CORE ["@dev-laoz/core (librería interna)"]
        C[config\nloadRemoteSecrets]
        L[logger\ninfo/error/audit/transaction]
        AM[authMiddleware]
        RL[rateLimitMiddleware]
        SW[createSwaggerDocs]
    end

    subgraph Consume
        AT[authentication-api]
        AZ[authorization-api]
        R[api-roles]
        U[user-api]
        AF[api-files]
        AM2[api-manager]
        B[billing-api]
        I[api-insights]
        GW[api-gateway]
    end

    Consume -->|require('@dev-laoz/core')| CORE
    C -->|HTTPS| S[api-secrets :3501]
    L -->|HTTP async| INS[api-insights :3600]
    AM -->|HTTP| AZ2[authorization-api :5000]
```

| Export | Descripción |
| --- | --- |
| `config` | `loadRemoteSecrets(appName, keys[])` — carga secretos desde Secrets API con fallback a env |
| `logger` | `info/error/audit/transaction` — fire-and-forget a Insights API |
| `authMiddleware` | Valida Bearer JWT delegando a Authorization API |
| `rateLimitMiddleware` | Rate limiting (configurable con `RATE_LIMIT_MAX`) |
| `createSwaggerDocs` | Setup de Swagger UI en `/api-docs` |

**Variables de entorno que consume:**

```
SECRETS_API_URL       = https://api-secrets:3501/api/secrets
AUTHORIZATION_API_URL = http://authorization-api:5000/api/authorization/validate
ROLES_API_URL         = http://api-roles:5002/api/roles/check
INSIGHTS_HOST         = api-insights
INSIGHTS_PORT         = 3600
RATE_LIMIT_MAX        = 100
```

---

## Flujo de autenticación completo

```mermaid
sequenceDiagram
    participant C as Cliente
    participant GW as API Gateway
    participant AT as Authentication API
    participant AZ as Authorization API
    participant R as Roles API
    participant AF as Files API
    participant DB as MongoDB

    Note over C,DB: Paso 1 — Login
    C->>GW: POST /api/auth/login {username, password}
    GW->>AT: proxy (ruta pública, sin auth)
    AT->>DB: validar credenciales → crear Session
    AT-->>C: {accessToken, refreshToken}

    Note over C,DB: Paso 2 — Acceder a recurso protegido
    C->>GW: GET /api/files/:id\nAuthorization: Bearer accessToken
    GW->>AZ: POST /api/authorization/validate\n{requiredPermission: ""}
    AZ->>DB: verificar Session activa
    AZ-->>GW: 200 {authorized: true}

    Note over GW,AF: Paso 3 — Proxy al servicio destino
    GW->>AF: GET /api/files/:id (proxy)
    AF-->>GW: archivo binario
    GW-->>C: 200 archivo

    Note over C,DB: Paso 3b — Con verificación de permiso RBAC
    C->>GW: DELETE /api/files/:id\nAuthorization: Bearer accessToken
    GW->>AZ: POST /api/authorization/validate\n{requiredPermission: "files:delete"}
    AZ->>DB: User.findById → user.roles = ["editor"]
    AZ->>R: POST /api/roles/check\n{roles:["editor"], permission:"files:delete"}
    R-->>AZ: {hasPermission: true}
    AZ-->>GW: 200 {authorized: true}
    GW->>AF: DELETE /api/files/:id
    AF-->>C: 204 No Content
```

---

## Dependencias entre servicios (orden de arranque)

```mermaid
flowchart TD
    M[(MongoDB)] --> S[api-secrets]
    S --> I[api-insights]
    S --> R[api-roles]
    I --> R
    R --> AZ[authorization-api]
    I --> AZ
    I --> AT[authentication-api]
    M --> AT
    M --> AZ
    M --> R
    I --> U[user-api]
    M --> U
    I --> AF[api-files]
    I --> AM[api-manager]
    I --> B[billing-api]
    I --> AA[api-authorization]
    S --> AT
    S --> U
    S --> AF
    S --> AM
    S --> B
    S --> AA
    AT --> GW[api-gateway]
    AZ --> GW
    U --> GW
    AF --> GW
    AM --> GW
    B --> GW
    GW --> FE1[auth-frontend :9001]
    GW --> FE2[portal :80]
```

---

## Puertos expuestos (producción)

| Puerto | Servicio | Descripción |
| --- | --- | --- |
| **80** | portal | Frontend principal |
| **9000** | api-gateway | API pública |
| **9001** | auth-frontend | Frontend de autenticación |
| **7000** | docs-automator | Generador de documentación |

Todos los demás servicios están en la red interna `laoz-net` y **no son accesibles** desde el exterior.

---

## Levantar el stack

```bash
# Primera vez: construir imágenes
cd devops-laoz-infra
docker compose -f docker-compose.yml build --parallel

# Levantar en background
docker compose -f docker-compose.yml up -d

# Ver estado
docker compose -f docker-compose.yml ps

# Logs de un servicio
docker compose -f docker-compose.yml logs -f authorization-api

# Detener todo
docker compose -f docker-compose.yml down
```

> **Nota:** El override `docker-compose.override.yml` expone puertos internos para desarrollo local. No usarlo en producción.

---

## Variables de entorno requeridas (`.env`)

```
JWT_SECRET          # Mínimo 32 chars, base64 recomendado
ENCRYPTION_KEY      # Exactamente 32 chars, para AES-256-CBC en api-secrets
MONGO_URI           # mongodb://mongo:27017/laoz
SECRETS_API_URL     # https://api-secrets:3501/api/secrets
AUTHORIZATION_API_URL # http://authorization-api:5000/api/authorization/validate
ROLES_API_URL       # http://api-roles:5002/api/roles/check
INSIGHTS_HOST       # api-insights
INSIGHTS_PORT       # 3600
RATE_LIMIT_MAX      # 100
CORS_ORIGIN         # http://localhost:80
```
