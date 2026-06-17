# Despliegue en Producción — Checklist

---

## Antes del despliegue

### Seguridad
- [ ] `JWT_SECRET` tiene al menos 32 caracteres y es único para este entorno
- [ ] `ENCRYPTION_KEY` tiene exactamente 32 caracteres
- [ ] El archivo `.env` no está commiteado en el repositorio
- [ ] Los secretos sensibles están cargados en `api-secrets` (no en `.env` directamente)
- [ ] `docker-compose.override.yml` **no** se usa en producción
- [ ] Solo los puertos `80`, `9000`, `9001`, `7000` están expuestos al exterior
- [ ] El firewall del host bloquea todos los puertos no listados arriba

### Infraestructura
- [ ] Docker Engine 24+ instalado en el servidor
- [ ] Suficiente RAM disponible (mínimo 4 GB para Docker)
- [ ] Volumen persistente para MongoDB (`mongo-data`) en disco confiable
- [ ] Backup programado del volumen `mongo-data`
- [ ] `CORS_ORIGIN` configurado con el dominio real (no `localhost`)

### Frontends
- [ ] `VITE_AUTH_FRONTEND_URL` apunta al dominio real del auth-frontend
- [ ] `VITE_AUTH_API_URL` apunta al gateway del entorno de producción
- [ ] `VITE_FILES_SERVICE_URL` y `VITE_MARKDOWN_SERVICE_URL` configurados correctamente

---

## Proceso de despliegue

```bash
# 1. Actualizar código
git pull origin main

# 2. Reconstruir imágenes afectadas
docker compose -f docker-compose.yml build --parallel

# 3. Aplicar cambios sin downtime
docker compose -f docker-compose.yml up -d --no-deps <servicio>

# 4. Verificar estado
docker compose -f docker-compose.yml ps
docker compose -f docker-compose.yml logs --tail=50 <servicio>
```

---

## Estrategia de actualización por tipo de cambio

| Tipo de cambio | Procedimiento |
|---|---|
| Cambio en un servicio | `build <servicio>` + `up -d --no-deps <servicio>` |
| Cambio en `@dev-laoz/core` | `build --parallel` (todos dependen de ella) + `up -d` |
| Cambio en variables de entorno | Editar `.env` + reiniciar servicios afectados |
| Cambio en `docker-compose.yml` | `down` + `up -d` (con pérdida de conexiones activas) |
| Migración de BD | Aplicar migración antes de `up -d` del servicio |

---

## Rollback

```bash
# Volver a una imagen anterior (si se tiene el tag)
docker compose -f docker-compose.yml stop <servicio>
docker tag <imagen>:<tag-anterior> <imagen>:latest
docker compose -f docker-compose.yml up -d --no-deps <servicio>
```

---

## Monitoreo post-despliegue

```bash
# Healthchecks
curl http://localhost:9000/api/auth/health
curl http://localhost:9000/api/authorization/health

# Logs de error recientes
docker compose -f docker-compose.yml logs --tail=100 api-gateway | grep -i error

# Monitoreo en tiempo real via Insights SSE
curl -H "Authorization: Bearer <token>" \
     http://localhost:9000/api/insights/stream
```
