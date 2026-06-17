# Componente: api-files

| Campo | Valor |
|---|---|
| **Repositorio** | `dev-laoz-api-files` |
| **Puerto interno** | `3700` |
| **Permiso requerido** | `files:read` / `files:write` / `files:delete` |

---

## Responsabilidades

Gestión de archivos con **versionado automático** y soporte multi-almacenamiento (Local, Network, Cloud).

---

## Endpoints

| Método | Ruta | Permiso | Descripción |
|---|---|---|---|
| `POST` | `/api/files` | `files:write` | Sube archivo (multipart/form-data) |
| `POST` | `/api/files/content` | `files:write` | Guarda contenido de texto |
| `GET` | `/api/files/:id` | `files:read` | Descarga versión actual |
| `GET` | `/api/files/:id/versions` | `files:read` | Lista todas las versiones |
| `GET` | `/api/files/:id/versions/:vId` | `files:read` | Descarga versión específica |
| `PUT` | `/api/files/:id/move` | `files:write` | Mueve entre tipos de almacenamiento |
| `POST` | `/api/files/:id/copy` | `files:write` | Copia archivo |
| `DELETE` | `/api/files/:id` | `files:delete` | Borrado lógico (soft delete) |

---

## Modelo de datos

```js
File {
  originalName:   String
  currentVersion: Number
  storageType:    'local' | 'network' | 'cloud'
  tags:           [String]
  deleted:        Boolean  // soft delete
  versions: [{
    version:     Number
    storageType: String
    path:        String    // ruta relativa
    fullPath:    String    // ruta absoluta
    mimeType:    String
    size:        Number    // bytes
    uploadedAt:  Date
  }]
  createdAt: Date
  updatedAt: Date
}
```

---

## Flujo de subida con versionado

```
POST /api/files (multipart)
  → StorageManager.save(buffer, filename, storageType)
     → selecciona adapter: LocalAdapter | NetworkAdapter | CloudAdapter
     → guarda en filesystem
     → devuelve { relativePath, fullPath }
  → File.create / addVersion { version++, storageType, path, mimeType, size }
  → 201 { _id, originalName, currentVersion }
```

---

## Dependencias

```
api-secrets    (healthy)
api-insights   (started)
```
