# Documentación — Dev Laoz Ecosistema

Índice de toda la documentación técnica del ecosistema de microservicios **Dev Laoz**.

El código fuente de cada servicio vive en su propio directorio hermano; este repositorio (`devops-laoz-infra`) es la fuente de verdad para infraestructura, arquitectura y documentación transversal.

---

## Mapa de documentación

```
docs/
├── architecture/          Decisiones de diseño y vista de alto nivel
├── cross-cutting/         Preocupaciones transversales a todos los servicios
├── components/            Ficha técnica de cada microservicio
├── deployment/            Guías operativas de despliegue
├── requirements/          Requerimientos funcionales y no funcionales
├── interfaces/            Contratos de API y esquemas compartidos
└── testing/               Estrategia y especificaciones de pruebas
```

---

## Arquitectura

| Documento | Descripción |
|---|---|
| [ARCHITECTURE.md](../ARCHITECTURE.md) | Vista general, diagramas Mermaid, flujos principales |
| [architecture/overview.md](architecture/overview.md) | Principios de diseño y mapa de capacidades |
| [architecture/decisions/ADR-001-stateful-jwt.md](architecture/decisions/ADR-001-stateful-jwt.md) | Por qué el JWT valida sesión contra BD |
| [architecture/decisions/ADR-002-secrets-api.md](architecture/decisions/ADR-002-secrets-api.md) | Gestión centralizada de secretos |
| [architecture/decisions/ADR-003-rbac-roles.md](architecture/decisions/ADR-003-rbac-roles.md) | Diseño del sistema RBAC |

---

## Requerimientos transversales (cross-cutting)

Preocupaciones que aplican a **todos** los microservicios del ecosistema.

| Documento | Descripción |
|---|---|
| [cross-cutting/README.md](cross-cutting/README.md) | Resumen de concerns transversales |
| [cross-cutting/authentication.md](cross-cutting/authentication.md) | Flujo JWT completo: login → refresh → logout |
| [cross-cutting/authorization.md](cross-cutting/authorization.md) | RBAC: roles, permisos y validación |
| [cross-cutting/logging-observability.md](cross-cutting/logging-observability.md) | Logger `@dev-laoz/core`, Insights API |
| [cross-cutting/secrets-management.md](cross-cutting/secrets-management.md) | Secrets API, AES-256-CBC, fallback a env |
| [cross-cutting/error-handling.md](cross-cutting/error-handling.md) | Formato de errores HTTP y patrones de manejo |

---

## Componentes

Un documento por servicio del ecosistema.

| Servicio | Puerto interno | Documento |
|---|---|---|
| `api-gateway` | 3002 | [components/api-gateway.md](components/api-gateway.md) |
| `authentication-api` | 4000 | [components/authentication-api.md](components/authentication-api.md) |
| `authorization-api` | 5000 | [components/authorization-api.md](components/authorization-api.md) |
| `api-roles` | 5002 | [components/api-roles.md](components/api-roles.md) |
| `user-api` | 6000 | [components/user-api.md](components/user-api.md) |
| `api-secrets` | 3501 (HTTPS) | [components/api-secrets.md](components/api-secrets.md) |
| `api-insights` | 3600 | [components/api-insights.md](components/api-insights.md) |
| `api-files` | 3700 | [components/api-files.md](components/api-files.md) |
| `api-manager` | 3800 | [components/api-manager.md](components/api-manager.md) |
| `billing-api` | 3004 | [components/billing-api.md](components/billing-api.md) |
| `auth-frontend` | 80→9001 | [components/auth-frontend.md](components/auth-frontend.md) |
| `portal` | 80 | [components/portal.md](components/portal.md) |
| `@dev-laoz/core` | librería | [components/core-library.md](components/core-library.md) |

---

## Despliegue

| Documento | Descripción |
|---|---|
| [deployment/README.md](deployment/README.md) | Guía principal de operación |
| [deployment/local-development.md](deployment/local-development.md) | Stack de desarrollo con override |
| [deployment/production.md](deployment/production.md) | Checklist de despliegue en producción |
| [deployment/environment-variables.md](deployment/environment-variables.md) | Referencia completa de todas las variables |

---

## Requerimientos

| Documento | Descripción |
|---|---|
| [requirements/functional.md](requirements/functional.md) | Requerimientos funcionales por módulo |
| [requirements/non-functional.md](requirements/non-functional.md) | Seguridad, rendimiento, disponibilidad |

---

## Interfaces (contratos de API)

| Documento | Descripción |
|---|---|
| [interfaces/README.md](interfaces/README.md) | Índice de contratos y convenciones |
| [interfaces/shared-schemas.md](interfaces/shared-schemas.md) | JWT payload, formato de error, paginación |
| [interfaces/api-gateway.md](interfaces/api-gateway.md) | Tabla de rutas del gateway |
| [interfaces/authentication-api.md](interfaces/authentication-api.md) | Endpoints + request/response schemas |
| [interfaces/authorization-api.md](interfaces/authorization-api.md) | Endpoint de validación RBAC |
| [interfaces/user-api.md](interfaces/user-api.md) | CRUD de usuarios |

---

## Testing

| Documento | Descripción |
|---|---|
| [testing/README.md](testing/README.md) | Estrategia general de pruebas |
| [testing/unit/README.md](testing/unit/README.md) | Guía de pruebas unitarias |
| [testing/unit/authentication.md](testing/unit/authentication.md) | Casos de prueba: authentication-api |
| [testing/unit/authorization.md](testing/unit/authorization.md) | Casos de prueba: authorization-api + RBAC |
| [testing/unit/core-library.md](testing/unit/core-library.md) | Casos de prueba: `@dev-laoz/core` |
| [testing/integration/README.md](testing/integration/README.md) | Estrategia de pruebas de integración |

---

## Convenciones de este directorio

- Todos los documentos están en **español** (idioma del equipo).
- Los diagramas usan sintaxis **Mermaid** (renderizado nativo en GitHub/GitLab).
- Las decisiones de arquitectura siguen el formato **ADR** (Architecture Decision Record).
- Los casos de prueba usan el estilo **Given / When / Then** y nomenclatura Jest `describe/it`.
