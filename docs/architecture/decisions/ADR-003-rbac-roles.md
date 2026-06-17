# ADR-003 — Diseño del sistema RBAC

| Campo | Valor |
|---|---|
| **Estado** | Aceptado |
| **Fecha** | 2024 |
| **Autores** | Equipo Dev Laoz |

---

## Contexto

El ecosistema necesita controlar qué operaciones puede realizar cada usuario. Los modelos de control de acceso más comunes son:

- **ACL** (Access Control List): permisos por usuario sobre cada recurso.
- **RBAC** (Role-Based Access Control): permisos asignados a roles; usuarios tienen roles.
- **ABAC** (Attribute-Based Access Control): políticas basadas en atributos del sujeto, recurso y entorno.

---

## Decisión

Se implementa **RBAC** con permisos en formato `resource:action`.

Los roles predefinidos del sistema son:
- `admin` — acceso total
- `editor` — lectura/escritura/borrado de archivos + insights
- `viewer` — solo lectura de archivos e insights
- `user` — solo lectura de archivos

Se admiten roles personalizados creados vía `POST /api/roles`.

Los permisos son consultados por `authorization-api` a `api-roles` con caché local de 5 minutos.

---

## Formato de permisos

```
<recurso>:<acción>
```

Ejemplos: `files:read`, `files:write`, `users:*`, `secrets:read`, `billing:write`.

El comodín `*` en la acción concede todas las acciones sobre el recurso.

---

## Justificación

- RBAC es suficientemente expresivo para los casos de uso actuales y más simple de administrar que ABAC.
- Los roles tienen semántica de negocio clara (admin, editor, viewer).
- El formato `resource:action` es extensible sin cambiar el esquema.
- La separación entre `authorization-api` (valida) y `api-roles` (fuente de verdad de permisos) permite evolucionar el modelo de permisos sin tocar la lógica de validación.

---

## Consecuencias

- El modelo `User` tiene dos campos: `role` (legacy string) y `roles[]` (RBAC array). La migración gradual es intencionada.
- Los consumidores del gateway que requieran un permiso específico deben configurarlo en `services.json` del gateway.
- Los cambios de permisos en `api-roles` surten efecto en máximo 5 minutos (TTL de caché).
