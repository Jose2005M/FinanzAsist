@Timeout.factor(4)
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:finanzasist/data/autenticacion_local.dart';
import 'package:finanzasist/data/base_datos_local.dart';
import 'package:finanzasist/data/respaldo_local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'soporte_roles.dart';

const tablas = [
  'empresas',
  'usuarios',
  'cuentas',
  'productos',
  'operaciones',
  'movimientos',
  'gastos',
  'guias_vistas',
];

Future<Map<String, List<String>>> estado(
  DatabaseExecutor db, {
  String? empresa,
}) async {
  final resultado = <String, List<String>>{};
  for (final tabla in tablas) {
    final filas = await db.query(
      tabla,
      where: empresa == null
          ? null
          : tabla == 'empresas'
          ? 'id = ?'
          : tabla == 'guias_vistas'
          ? 'cuenta IN (SELECT id FROM cuentas WHERE empresa = ?)'
          : 'empresa = ?',
      whereArgs: empresa == null ? null : [empresa],
    );
    resultado[tabla] = filas.map(jsonEncode).toList()..sort();
  }
  return resultado;
}

Matcher rechaza(String texto) => throwsA(
  isA<RespaldoException>().having((e) => e.mensaje, 'mensaje', contains(texto)),
);

void main() {
  final plantilla = PlantillaRoles();
  late CasoRoles caso;
  late RespaldoLocal respaldo;
  late String empresaA;
  late String empresaB;
  late String empresaAdmin;

  setUpAll(() async {
    await plantilla.crear();
    final b = BaseDatosLocal(factory: databaseFactoryFfi, ruta: plantilla.ruta);
    final a = AutenticacionLocal(base: b);
    await a.registrar(
      const DatosRegistro(
        empresa: 'Empresa B',
        propietario: 'Dueño B',
        correo: 'b@empresa.com',
        clave: claveRoles,
      ),
    );
    empresaB = a.sesion!.empresaId;
    a.cerrarSesion();
    await a.crearAdministrador(
      const DatosAdministrador(
        nombre: 'Admin',
        correo: 'admin@empresa.com',
        clave: claveRoles,
      ),
      correoPropietario: 'b@empresa.com',
      clavePropietario: claveRoles,
    );
    empresaAdmin = a.sesion!.empresaId;
    final db = await b.abrir;
    empresaA =
        (await db.query(
              'cuentas',
              where: 'correo = ?',
              whereArgs: ['propietario@roles.com'],
            )).single['empresa']
            as String;
    for (final cuenta in await db.query('cuentas')) {
      await db.insert('guias_vistas', {
        'cuenta': cuenta['id'],
        'modulo': 'inventario',
      });
    }
    await db.insert('productos', {
      'empresa': empresaB,
      'id': 'b-producto',
      'nombre': 'Producto B',
      'cantidad': 4,
      'costo': 10,
      'precio': 20,
    });
    final usuario = (await db.query(
      'cuentas',
      where: 'empresa = ? AND rol = ?',
      whereArgs: [empresaA, 'propietario'],
    )).single['usuario'];
    await db.insert('gastos', {
      'empresa': empresaA,
      'id': 'gasto-a',
      'usuario': usuario,
      'fecha': '2026-11-19',
      'concepto': 'Arriendo',
      'categoria': 'Local',
      'valor': 500,
      'registrado': '2026-11-19T10:00:00Z',
    });
    a.dispose();
    await b.cerrar();
  });
  tearDownAll(plantilla.cerrar);
  setUp(() async {
    caso = await plantilla.copiar();
    respaldo = RespaldoLocal(base: caso.base);
  });
  tearDown(() async {
    expect(
      caso.carpeta.listSync().where((e) => e.path.contains('.respaldo-')),
      isEmpty,
    );
    await caso.cerrar();
  });

  Future<SesionEmpresa> entrarA() async {
    await caso.entrar(RolCuenta.propietario);
    return caso.accesos.last.sesion!;
  }

  Future<SesionEmpresa> entrar(String correo) async {
    final a = AutenticacionLocal(base: caso.base);
    caso.accesos.add(a);
    await a.iniciarSesion(correo, claveRoles);
    return a.sesion!;
  }

  Future<Uint8List> modificar(
    Uint8List bytes,
    Future<void> Function(Database) accion,
  ) async {
    final ruta = '${caso.carpeta.path}/alterado.db';
    await File(ruta).writeAsBytes(bytes);
    final db = await databaseFactoryFfi.openDatabase(ruta);
    try {
      await accion(db);
    } finally {
      await db.close();
    }
    return File(ruta).readAsBytes();
  }

  Future<void> borrarA(DatabaseExecutor db) async {
    await db.delete(
      'guias_vistas',
      where: 'cuenta IN (SELECT id FROM cuentas WHERE empresa = ?)',
      whereArgs: [empresaA],
    );
    for (final tabla in [
      'movimientos',
      'operaciones',
      'gastos',
      'productos',
      'cuentas',
      'usuarios',
      'empresas',
    ]) {
      await db.delete(
        tabla,
        where: tabla == 'empresas' ? 'id = ?' : 'empresa = ?',
        whereArgs: [empresaA],
      );
    }
  }

  test(
    'exporta todas las filas de A sin ninguna de B ni del administrador',
    () async {
      final bytes = await respaldo.exportar(sesion: await entrarA());
      final esperado = await estado(await caso.base.abrir, empresa: empresaA);
      await modificar(bytes, (db) async {
        expect(await estado(db), esperado);
        expect(await db.getVersion(), BaseDatosLocal.version);
        expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      });
    },
  );

  test('restaura productos, ventas y empleados de A y deja B y administrador idénticos', () async {
    final sesion = await entrarA();
    final db = await caso.base.abrir;
    final original = await estado(db);
    final bytes = await respaldo.exportar(sesion: sesion);
    await db.update(
      'productos',
      {'cantidad': 1},
      where: 'empresa = ?',
      whereArgs: [empresaA],
    );
    await db.update(
      'cuentas',
      {'activa': 0},
      where: "empresa = ? AND rol <> 'propietario'",
      whereArgs: [empresaA],
    );
    await db.update(
      'operaciones',
      {'datos': '{}'},
      where: 'empresa = ?',
      whereArgs: [empresaA],
    );
    await respaldo.restaurar(bytes, sesion: sesion);
    expect(await estado(db), original);
  });

  test('sesión B y acceso con A existente rechazan sin cambios', () async {
    final bytes = await respaldo.exportar(sesion: await entrarA());
    final sesionB = await entrar('b@empresa.com');
    final db = await caso.base.abrir;
    final antes = await estado(db);
    await expectLater(
      respaldo.restaurar(bytes, sesion: sesionB),
      rechaza('Este respaldo es de otra empresa'),
    );
    expect(await estado(db), antes);
    await expectLater(
      respaldo.restaurar(bytes),
      rechaza('Esta empresa ya está en el teléfono'),
    );
    expect(await estado(db), antes);
  });

  for (final vacio in [false, true]) {
    test(
      'acceso agrega A y permite entrar a propietario y empleados; vacío=$vacio',
      () async {
        final bytes = await respaldo.exportar(sesion: await entrarA());
        final db = await caso.base.abrir;
        final antesB = await estado(db, empresa: empresaB);
        final antesAdmin = await estado(db, empresa: empresaAdmin);
        final antesA = await estado(db, empresa: empresaA);
        await db.transaction(borrarA);
        if (vacio) {
          await caso.base.cerrar();
          await File(caso.base.ruta!).delete();
        }
        expect(await respaldo.restauracionSinSesion(), isTrue);
        await respaldo.restaurar(bytes);
        final destino = await caso.base.abrir;
        expect(await estado(destino, empresa: empresaA), antesA);
        if (!vacio) {
          expect(await estado(destino, empresa: empresaB), antesB);
          expect(await estado(destino, empresa: empresaAdmin), antesAdmin);
        }
        for (final rol in [RolCuenta.propietario, ...RolCuenta.empleados]) {
          await caso.entrar(rol);
          expect(caso.accesos.last.sesion!.empresaId, empresaA);
        }
      },
    );
  }

  for (final correo in ['B@EMPRESA.COM', 'admin@empresa.com']) {
    for (final conSesion in [true, false]) {
      test(
        'choque de correo $correo; sesión=$conSesion; no cambia datos',
        () async {
          final sesion = await entrarA();
          final bytes = await modificar(
            await respaldo.exportar(sesion: sesion),
            (db) async {
              await db.update('cuentas', {
                'correo': correo,
              }, where: "rol = 'vendedor'");
            },
          );
          final db = await caso.base.abrir;
          if (!conSesion) await db.transaction(borrarA);
          final antes = await estado(db);
          await expectLater(
            respaldo.restaurar(bytes, sesion: conSesion ? sesion : null),
            rechaza('correo'),
          );
          expect(await estado(db), antes);
        },
      );
    }
  }

  test(
    'fallo al insertar después de borrar revierte toda la transacción',
    () async {
      final sesion = await entrarA();
      final bytes = await modificar(await respaldo.exportar(sesion: sesion), (
        db,
      ) async {
        await db.execute('PRAGMA foreign_keys = OFF');
        await db.execute('DROP TABLE productos');
        await db.execute(
          'CREATE TABLE productos (empresa TEXT, id TEXT, nombre TEXT, cantidad INTEGER, costo INTEGER, precio INTEGER, PRIMARY KEY (empresa, id))',
        );
        await db.insert('productos', {
          'empresa': empresaA,
          'id': 'invalido',
          'nombre': 'Mal',
          'cantidad': -1,
          'costo': 0,
          'precio': 0,
        });
        await db.delete('movimientos');
      });
      final db = await caso.base.abrir;
      final antes = await estado(db);
      await expectLater(
        respaldo.restaurar(bytes, sesion: sesion),
        rechaza('dañado'),
      );
      expect(await estado(db), antes);
    },
  );

  test('archivo completo de dos empresas se rechaza sin cambios', () async {
    final sesion = await entrarA();
    final antes = await estado(await caso.base.abrir);
    final bytes = await caso.base.leerArchivo();
    await expectLater(
      respaldo.restaurar(bytes, sesion: sesion),
      rechaza('varias empresas'),
    );
    expect(await estado(await caso.base.abrir), antes);
  });

  test('archivo antiguo completo con una empresa y administrador migra sin importar administrador', () async {
    final db = await caso.base.abrir;
    await db.transaction(borrarA);
    final esperado = await estado(db, empresa: empresaB);
    final bytes = await modificar(await caso.base.leerArchivo(), (copia) async {
      // Esquema real de cuentas v5: empresa única y solo dos roles.
      final cuentas = await copia.query('cuentas');
      final guias = await copia.query('guias_vistas');
      await copia.delete('guias_vistas');
      await copia.execute('DROP TABLE cuentas');
      await copia.execute('''CREATE TABLE cuentas (
        id TEXT PRIMARY KEY, empresa TEXT NOT NULL UNIQUE,
        usuario TEXT NOT NULL, nombre_empresa TEXT NOT NULL,
        nombre TEXT NOT NULL, correo TEXT NOT NULL UNIQUE COLLATE NOCASE,
        sal TEXT NOT NULL, hash TEXT NOT NULL,
        iteraciones INTEGER NOT NULL CHECK(iteraciones >= 600000),
        activa INTEGER NOT NULL DEFAULT 1 CHECK(activa IN (0, 1)),
        rol TEXT NOT NULL DEFAULT 'propietario' CHECK(rol IN ('propietario', 'administrador')),
        FOREIGN KEY(empresa, usuario) REFERENCES usuarios(empresa, id))''');
      for (final cuenta in cuentas) {
        await copia.insert('cuentas', cuenta);
      }
      for (final guia in guias) {
        await copia.insert('guias_vistas', guia);
      }
      await copia.setVersion(5);
    });
    await caso.base.cerrar();
    await File(caso.base.ruta!).delete();
    await respaldo.restaurar(bytes);
    expect(await estado(await caso.base.abrir), esperado);
    await entrar('b@empresa.com');
  });

  test('identificador de cuenta ajena se rechaza sin cambios', () async {
    final sesion = await entrarA();
    final db = await caso.base.abrir;
    final idAjeno = (await db.query(
      'cuentas',
      where: 'empresa = ?',
      whereArgs: [empresaB],
    )).single['id'];
    final bytes = await modificar(await respaldo.exportar(sesion: sesion), (
      copia,
    ) async {
      final vendedor = (await copia.query(
        'cuentas',
        where: "rol = 'vendedor'",
      )).single['id'];
      await copia.delete(
        'guias_vistas',
        where: 'cuenta = ?',
        whereArgs: [vendedor],
      );
      await copia.update(
        'cuentas',
        {'id': idAjeno},
        where: 'id = ?',
        whereArgs: [vendedor],
      );
    });
    final antes = await estado(db);
    await expectLater(
      respaldo.restaurar(bytes, sesion: sesion),
      rechaza('identificador'),
    );
    expect(await estado(db), antes);
  });
  test('administrador no exporta ni restaura', () async {
    final bytes = await respaldo.exportar(sesion: await entrarA());
    final admin = await entrar('admin@empresa.com');
    final db = await caso.base.abrir;
    final antes = await estado(db);
    await expectLater(
      respaldo.exportar(sesion: admin),
      throwsA(isA<RespaldoException>()),
    );
    await expectLater(
      respaldo.restaurar(bytes, sesion: admin),
      throwsA(isA<RespaldoException>()),
    );
    expect(await estado(db), antes);
  });
}
