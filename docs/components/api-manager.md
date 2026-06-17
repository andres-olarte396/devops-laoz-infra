# Componente: api-manager

| Campo | Valor |
|---|---|
| **Repositorio** | `dev-laoz-api-manager` |
| **Puerto interno** | `3800` |
| **Requisito especial** | Acceso a `/var/run/docker.sock` (montado como volumen) |

---

## Responsabilidades

Control de **contenedores Docker** y **repositorios Git** desde la API. Permite gestionar el ciclo de vida de los servicios del ecosistema y actualizar código desde el backend.

---

## Endpoints

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| `GET` | `/api/manager/containers` | Sí | Lista contenedores Docker |
| `POST` | `/api/manager/containers/:id/start` | Sí | Inicia un contenedor |
| `POST` | `/api/manager/containers/:id/stop` | Sí | Detiene un contenedor |
| `GET` | `/api/manager/containers/:id/logs` | Sí | Obtiene logs de un contenedor |
| `POST` | `/api/manager/git/clone` | Sí | Clona repositorio Git |
| `GET` | `/api/manager/git/status/:folder` | Sí | Estado del repositorio |
| `POST` | `/api/manager/git/pull/:folder` | Sí | Git pull del repositorio |

---

## Consideraciones de seguridad

- El acceso al Docker socket (`/var/run/docker.sock`) equivale a acceso root en el host. **Este endpoint debe estar restringido a usuarios con rol `admin`.**
- En producción, considerar usar la API remota de Docker con TLS en lugar del socket local.
- Auditar todas las operaciones con `logger.audit`.

---

## Dependencias

```
api-secrets    (healthy)
api-insights   (started)
/var/run/docker.sock  (montado desde el host)
```
