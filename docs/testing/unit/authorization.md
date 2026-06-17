# Pruebas Unitarias — authorization-api + RBAC

---

## authorization.service — validación de token

```javascript
describe('AuthorizationService.validate', () => {

  describe('sin requiredPermission (solo autenticación)', () => {
    it('debería devolver authorized: true con sesión activa', async () => {
      jwt.verify.mockReturnValue({ userId: 'u1', sessionToken: 'sess-1' });
      SessionModel.findOne.mockResolvedValue({ userId: 'u1', isActive: true });

      const result = await AuthorizationService.validate('valid-jwt', '');

      expect(result).toMatchObject({ authorized: true, userId: 'u1' });
    });

    it('debería lanzar 401 cuando el token está expirado', () => {
      jwt.verify.mockImplementation(() => { throw new jwt.TokenExpiredError(); });

      expect(() => AuthorizationService.validate('expired-jwt', ''))
        .rejects.toMatchObject({ status: 401 });
    });

    it('debería lanzar 401 cuando la sesión está inactiva (post-logout)', async () => {
      jwt.verify.mockReturnValue({ userId: 'u1', sessionToken: 'sess-1' });
      SessionModel.findOne.mockResolvedValue(null); // sesión no encontrada / inactiva

      await expect(AuthorizationService.validate('valid-jwt', ''))
        .rejects.toMatchObject({ status: 401 });
    });
  });

  describe('con requiredPermission', () => {
    it('debería devolver authorized: true cuando el usuario tiene el permiso', async () => {
      jwt.verify.mockReturnValue({ userId: 'u1', sessionToken: 'sess-1' });
      SessionModel.findOne.mockResolvedValue({ userId: 'u1', isActive: true });
      UserModel.findById.mockResolvedValue({ roles: ['editor'] });
      RolesService.check.mockResolvedValue({ hasPermission: true });

      const result = await AuthorizationService.validate('valid-jwt', 'files:write');

      expect(result.authorized).toBe(true);
    });

    it('debería lanzar 403 cuando el usuario no tiene el permiso', async () => {
      jwt.verify.mockReturnValue({ userId: 'u1', sessionToken: 'sess-1' });
      SessionModel.findOne.mockResolvedValue({ userId: 'u1', isActive: true });
      UserModel.findById.mockResolvedValue({ roles: ['viewer'] });
      RolesService.check.mockResolvedValue({ hasPermission: false });

      await expect(AuthorizationService.validate('valid-jwt', 'files:write'))
        .rejects.toMatchObject({ status: 403 });
    });

    it('debería consultar api-roles con los roles del usuario y el permiso requerido', async () => {
      UserModel.findById.mockResolvedValue({ roles: ['editor', 'viewer'] });
      RolesService.check.mockResolvedValue({ hasPermission: true });

      await AuthorizationService.validate('valid-jwt', 'files:delete');

      expect(RolesService.check).toHaveBeenCalledWith(
        ['editor', 'viewer'], 'files:delete'
      );
    });
  });

  describe('caché de permisos', () => {
    it('no debería llamar a api-roles en un hit de caché', async () => {
      // Primera llamada — llena caché
      cache.set('u1:files:read', true);

      await AuthorizationService.validate('valid-jwt', 'files:read');

      expect(RolesService.check).not.toHaveBeenCalled();
    });

    it('debería llamar a api-roles en un miss de caché', async () => {
      cache.clear();
      UserModel.findById.mockResolvedValue({ roles: ['viewer'] });
      RolesService.check.mockResolvedValue({ hasPermission: true });

      await AuthorizationService.validate('valid-jwt', 'files:read');

      expect(RolesService.check).toHaveBeenCalledTimes(1);
    });

    it('debería guardar el resultado en caché tras un miss', async () => {
      cache.clear();
      UserModel.findById.mockResolvedValue({ roles: ['viewer'] });
      RolesService.check.mockResolvedValue({ hasPermission: true });

      await AuthorizationService.validate('valid-jwt', 'files:read');

      expect(cache.get('u1:files:read')).toBe(true);
    });
  });
});
```

---

## api-roles — verificación de permisos

```javascript
describe('RolesService.checkPermission', () => {

  it('debería retornar true cuando alguno de los roles tiene el permiso', async () => {
    RoleModel.findOne.mockResolvedValueOnce({ permissions: ['files:read', 'files:write'] }); // editor
    RoleModel.findOne.mockResolvedValueOnce({ permissions: ['files:read'] }); // viewer

    const result = await RolesService.checkPermission(['editor', 'viewer'], 'files:write');

    expect(result.hasPermission).toBe(true);
  });

  it('debería retornar false cuando ningún rol tiene el permiso', async () => {
    RoleModel.findOne.mockResolvedValue({ permissions: ['files:read'] });

    const result = await RolesService.checkPermission(['viewer'], 'files:write');

    expect(result.hasPermission).toBe(false);
  });

  it('debería reconocer el comodín * como acceso total al recurso', async () => {
    RoleModel.findOne.mockResolvedValue({ permissions: ['files:*'] });

    const result = await RolesService.checkPermission(['admin'], 'files:delete');

    expect(result.hasPermission).toBe(true);
  });

  it('debería retornar false con array de roles vacío', async () => {
    const result = await RolesService.checkPermission([], 'files:read');
    expect(result.hasPermission).toBe(false);
  });

  it('debería retornar false cuando el rol no existe en BD', async () => {
    RoleModel.findOne.mockResolvedValue(null);

    const result = await RolesService.checkPermission(['rol-inexistente'], 'files:read');

    expect(result.hasPermission).toBe(false);
  });
});
```

---

## api-roles — CRUD

```javascript
describe('RolesController', () => {

  describe('POST /api/roles', () => {
    it('debería crear un rol con los permisos especificados', async () => {
      const payload = {
        name: 'content-creator',
        permissions: ['files:read', 'files:write'],
        description: 'Creador de contenido',
      };

      const { res } = await callController(RolesController.create, { body: payload });

      expect(res.status).toHaveBeenCalledWith(201);
      expect(RoleModel.create).toHaveBeenCalledWith(
        expect.objectContaining({ name: 'content-creator' })
      );
    });

    it('debería lanzar 409 cuando el nombre del rol ya existe', async () => {
      RoleModel.create.mockRejectedValue({ code: 11000 }); // MongoDB duplicate key

      const { res } = await callController(RolesController.create, {
        body: { name: 'admin', permissions: [] },
      });

      expect(res.status).toHaveBeenCalledWith(409);
    });

    it('no debería permitir crear un rol con nombre vacío', async () => {
      const { res } = await callController(RolesController.create, {
        body: { permissions: ['files:read'] }, // sin name
      });

      expect(res.status).toHaveBeenCalledWith(400);
    });
  });

  describe('DELETE /api/roles/:id', () => {
    it('no debería eliminar roles del sistema (isSystem: true)', async () => {
      RoleModel.findById.mockResolvedValue({ name: 'admin', isSystem: true });

      const { res } = await callController(RolesController.delete, {
        params: { id: 'admin-role-id' },
      });

      expect(res.status).toHaveBeenCalledWith(403);
      expect(RoleModel.findByIdAndDelete).not.toHaveBeenCalled();
    });

    it('debería eliminar un rol personalizado correctamente', async () => {
      RoleModel.findById.mockResolvedValue({ name: 'custom-role', isSystem: false });
      RoleModel.findByIdAndDelete.mockResolvedValue({ _id: 'custom-id' });

      const { res } = await callController(RolesController.delete, {
        params: { id: 'custom-id' },
      });

      expect(res.status).toHaveBeenCalledWith(204);
    });
  });
});
```
