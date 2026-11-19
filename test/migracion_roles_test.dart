@Timeout.factor(4)
library;

import 'dart:io';

import 'package:finanzasist/data/autenticacion_local.dart';
import 'package:finanzasist/data/base_datos_local.dart';
import 'package:finanzasist/data/usuarios_empresa.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('v5 retira administrador y conserva propietario y sus guías', () async {
    final dir = await Directory.systemTemp.createTemp('fa-migracion-roles-');
    final ruta = '${dir.path}/datos.db';
    var base = BaseDatosLocal(factory: databaseFactoryFfi, ruta: ruta);
    final auth = AutenticacionLocal(base: base);
    await auth.registrar(
      const DatosRegistro(
        empresa: 'Mi empresa',
        propietario: 'Ana Pérez',
        correo: 'ana@empresa.com',
        clave: 'clave del propietario',
      ),
    );
    final propietario = auth.sesion!.cuentaId;
    auth.dispose();
    final db = await base.abrir;
    // Construye exactamente la restricción v5, incluso al ejecutar en v6.
    await db.transaction((tx) async {
      await tx.execute('PRAGMA defer_foreign_keys = ON');
      await tx.execute('''CREATE TABLE cuentas_v5 (
        id TEXT PRIMARY KEY, empresa TEXT NOT NULL UNIQUE,
        usuario TEXT NOT NULL, nombre_empresa TEXT NOT NULL,
        nombre TEXT NOT NULL, correo TEXT NOT NULL UNIQUE COLLATE NOCASE,
        sal TEXT NOT NULL, hash TEXT NOT NULL, iteraciones INTEGER NOT NULL,
        activa INTEGER NOT NULL DEFAULT 1,
        rol TEXT NOT NULL DEFAULT 'propietario'
          CHECK(rol IN ('propietario', 'administrador')),
        FOREIGN KEY(empresa, usuario) REFERENCES usuarios(empresa, id))''');
      await tx.execute('INSERT INTO cuentas_v5 SELECT * FROM cuentas');
      await tx.execute('DROP TABLE cuentas');
      await tx.execute('ALTER TABLE cuentas_v5 RENAME TO cuentas');
      await tx.execute(
        "CREATE UNIQUE INDEX un_administrador ON cuentas(rol) WHERE rol = 'administrador'",
      );
      await tx.insert('empresas', {'id': 'empresa-admin'});
      await tx.insert('usuarios', {
        'empresa': 'empresa-admin',
        'id': 'usuario-admin',
      });
      final cuenta =
          Map<String, Object?>.from((await tx.query('cuentas')).single)
            ..addAll({
              'id': 'admin',
              'empresa': 'empresa-admin',
              'usuario': 'usuario-admin',
              'correo': 'admin@empresa.com',
              'rol': 'administrador',
            });
      await tx.insert('cuentas', cuenta);
      await tx.insert('guias_vistas', {
        'cuenta': propietario,
        'modulo': 'inventario',
      });
      await tx.insert('guias_vistas', {
        'cuenta': 'admin',
        'modulo': 'inventario',
      });
      await tx.execute('PRAGMA user_version = 5');
    });
    await base.cerrar();
    base = BaseDatosLocal(factory: databaseFactoryFfi, ruta: ruta);
    addTearDown(() async {
      await base.cerrar();
      await dir.delete(recursive: true);
    });
    final migrada = await base.abrir;
    expect(await migrada.getVersion(), BaseDatosLocal.version);
    expect(
      await migrada.query('cuentas', where: 'id = ?', whereArgs: ['admin']),
      isEmpty,
    );
    expect(
      await migrada.query(
        'usuarios',
        where: 'id = ?',
        whereArgs: ['usuario-admin'],
      ),
      isEmpty,
    );
    expect(
      await migrada.query(
        'empresas',
        where: 'id = ?',
        whereArgs: ['empresa-admin'],
      ),
      isEmpty,
    );
    expect((await migrada.query('guias_vistas')).single['cuenta'], propietario);
    expect(await migrada.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    final nuevaAuth = AutenticacionLocal(base: base);
    addTearDown(nuevaAuth.dispose);
    await nuevaAuth.iniciarSesion('ana@empresa.com', 'clave del propietario');
    expect(nuevaAuth.sesion!.cuentaId, propietario);
    final usuarios = UsuariosEmpresa(base: base, sesion: nuevaAuth.sesion!);
    await usuarios.crearUsuario(
      const DatosUsuario(
        nombre: 'Nuevo vendedor',
        correo: 'venta@empresa.com',
        clave: 'contraseña del vendedor',
        rol: RolCuenta.vendedor,
      ),
    );
    expect((await usuarios.listarUsuarios()).length, 2);
    expect(await migrada.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    final cuentaEmpleado =
        Map<String, Object?>.from(
          (await migrada.query('cuentas', where: "rol = 'vendedor'")).single,
        )..addAll({
          'id': 'segundo-propietario',
          'correo': 'otro@empresa.com',
          'rol': 'propietario',
        });
    await expectLater(
      migrada.insert('cuentas', cuentaEmpleado),
      throwsA(isA<DatabaseException>()),
    );
    // Reabrir una tabla ya migrada desde una versión anterior es idempotente.
    await migrada.execute('PRAGMA user_version = 5');
    await base.cerrar();
    base = BaseDatosLocal(factory: databaseFactoryFfi, ruta: ruta);
    expect((await (await base.abrir).query('cuentas')).length, 2);
    expect(
      await (await base.abrir).rawQuery(
        "SELECT name FROM sqlite_master WHERE name = 'un_administrador'",
      ),
      hasLength(1),
    );
  });
}
