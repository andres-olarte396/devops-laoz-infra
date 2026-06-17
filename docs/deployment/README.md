# Despliegue — Guía Principal

Este documento cubre los comandos y procedimientos operativos del ecosistema Dev Laoz.

Para detalle de variables de entorno ver [environment-variables.md](environment-variables.md).

---

## Prerrequisitos

- **Docker Desktop** 24+ con **Docker Compose V2** (`docker compose` — sin guión)
- Al menos **4 GB de RAM** disponibles para Docker
- Puertos libres en el host: `80`, `9000`, `9001`, `7000`
- Git (para clonar repositorios con api-manager)

---

## Configuración inicial (primera vez)

```bash
# 1. Ubicarse en el directorio de infra
cd devops-laoz-infra

# 2. Crear archivo de variables de entorno
cp .env.template .env

# 3. Editar .env con valores reales
# Ver docs/deployment/environment-variables.md para descripción de cada variable

# 4. Construir todas las imágenes en paralelo
docker compose -f docker-compose.yml build --parallel

# 5. Levantar el stack
docker compose -f docker-compose.yml up -d
```

---

## Orden de arranque

Docker Compose respeta las `depends_on` con `condition: service_healthy`. El orden efectivo es:

```
1. mongo
2. api-secrets        (depende de mongo)
3. api-insights       (depende de mongo + api-secrets)
4. api-roles          (depende de mongo + api-secrets + api-insights)
5. authentication-api (depende de mongo + api-secrets + api-insights)
6. authorization-api  (depende de mongo + api-secrets + api-insights + api-roles)
7. user-api           (depende de mongo + api-secrets + api-insights)
8. api-files          (depende de api-secrets + api-insights)
9. api-manager        (depende de api-secrets + api-insights)
10. billing-api        (depende de api-secrets + api-insights)
11. api-gateway        (depende de authentication-api + authorization-api + todos los anteriores)
12. auth-frontend      (depende de api-gateway)
13. portal             (depende de api-gateway + docs-automator)
```

---

## Comandos de uso frecuente

```bash
# Estado de todos los servicios
docker compose -f docker-compose.yml ps

# Logs en tiempo real de un servicio
docker compose -f docker-compose.yml logs -f authentication-api

# Logs de los últimos N líneas
docker compose -f docker-compose.yml logs --tail=100 authorization-api

# Reiniciar un servicio
docker compose -f docker-compose.yml restart api-roles

# Reconstruir y reiniciar un servicio tras cambios de código
docker compose -f docker-compose.yml build api-roles
docker compose -f docker-compose.yml up -d api-roles

# Detener el stack (conserva datos MongoDB)
docker compose -f docker-compose.yml down

# Detener y borrar volúmenes (DESTRUYE MongoDB)
docker compose -f docker-compose.yml down -v
```

---

## Scripts de conveniencia

Los scripts en `scripts/` automatizan las operaciones más comunes:

| Script | Descripción |
|---|---|
| `scripts/start.sh` | Construye y levanta el stack completo |
| `scripts/stop.sh` | Detiene el stack |
| `scripts/logs.sh [servicio]` | Muestra logs en tiempo real |
| `scripts/reset.sh` | Detiene, borra volúmenes y vuelve a levantar |

---

## Verificar que el stack está saludable

```bash
# Todos los servicios deben mostrar "Up" o "Up (healthy)"
docker compose -f docker-compose.yml ps

# Verificar gateway desde el host
curl http://localhost:9000/api/auth/health

# Verificar portal
curl http://localhost:80
```

Ver [local-development.md](local-development.md) para desarrollo con puertos expuestos.  
Ver [production.md](production.md) para checklist de producción.
