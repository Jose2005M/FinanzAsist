import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:finanzasist/data/autenticacion_local.dart';
import 'package:finanzasist/data/base_datos_local.dart';
import 'package:finanzasist/data/repositorio_sqlite.dart';
import 'package:finanzasist/models/gasto.dart';
import 'package:finanzasist/models/operacion.dart';
import 'package:finanzasist/models/reporte_financiero.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const clave = 'mi frase de acceso 2026';
DatosRegistro registro([String correo = 'dueno@empresa.com']) => DatosRegistro(
  empresa: 'Tienda Central',
  propietario: 'Jose Torres',
  correo: correo,
  clave: clave,
);

void main() {
  sqfliteFfiInit();
  late Directory directorio;
  late BaseDatosLocal base;
  late AutenticacionLocal auth;
  setUp(() async {
    directorio = await Directory.systemTemp.createTemp('finanzasist-acceso-');
    base = BaseDatosLocal(
      factory: databaseFactoryFfi,
      ruta: '${directorio.path}/cuentas.db',
    );
    auth = AutenticacionLocal(base: base);
  });
  tearDown(() async {
    auth.dispose();
    await base.cerrar();
    await directorio.delete(recursive: true);
  });
  RepositorioSqlite repositorio() =>
      RepositorioSqlite.conSesion(base: base, sesion: auth.sesion!);

  test('Contraseña admite de 8 a 128 caracteres Unicode', () {
    for (final valor in [null, '', 'a' * 7, '🔒' * 7, 'a' * 129]) {
      expect(
        DatosRegistro.validarClave(valor),
        'Usa entre 8 y 128 caracteres.',
      );
    }
    for (final valor in ['a' * 8, '🔒' * 8, 'a' * 128]) {
      expect(DatosRegistro.validarClave(valor), isNull);
    }
  });

  test(
    'Registro y reingreso permiten una contraseña de 8 caracteres',
    () async {
      await auth.registrar(
        const DatosRegistro(
          empresa: 'Tienda Central',
          propietario: 'Jose Torres',
          correo: 'dueno@empresa.com',
          clave: 'Acceso26',
        ),
      );
      final empresaId = auth.sesion!.empresaId;
      auth.cerrarSesion();
      await auth.iniciarSesion('dueno@empresa.com', 'Acceso26');
      expect(auth.sesion!.empresaId, empresaId);
    },
  );

  test(
    'HU01 CA01 cuenta, empresa y propietario; hash PBKDF2 verificable',
    () async {
      await auth.registrar(registro('  DUENO@Empresa.com  '));
      expect(auth.sesion!.correo, 'dueno@empresa.com');
      expect(auth.sesion!.empresa, 'Tienda Central');
      final db = await base.abrir;
      expect(await db.query('empresas'), hasLength(1));
      final cuenta = (await db.query('cuentas')).single;
      final usuario = (await db.query('usuarios')).single;
      expect(usuario['id'], cuenta['usuario']);
      expect(usuario['empresa'], cuenta['empresa']);
      expect(cuenta.values, isNot(contains(clave)));
      expect(base64Decode(cuenta['sal'] as String), hasLength(32));
      expect(cuenta['iteraciones'], 600000);
      // Verificación independiente de la derivación usada al registrar.
      final derivada =
          await Pbkdf2(
            macAlgorithm: Hmac.sha256(),
            iterations: 600000,
            bits: 256,
          ).deriveKeyFromPassword(
            password: clave,
            nonce: base64Decode(cuenta['sal'] as String),
          );
      expect(
        await derivada.extractBytes(),
        base64Decode(cuenta['hash'] as String),
      );
    },
  );

  test('HU01 CA02 rechaza datos incompletos sin crear registros', () async {
    final invalidos = [
      const DatosRegistro(
        empresa: '',
        propietario: 'Jose',
        correo: 'a@b.com',
        clave: clave,
      ),
      const DatosRegistro(
        empresa: 'Tienda',
        propietario: '',
        correo: 'a@b.com',
        clave: clave,
      ),
      const DatosRegistro(
        empresa: 'Tienda',
        propietario: 'Jose',
        correo: 'incorrecto',
        clave: clave,
      ),
      const DatosRegistro(
        empresa: 'Tienda',
        propietario: 'Jose',
        correo: 'a@b.com',
        clave: 'corta',
      ),
    ];
    for (final datos in invalidos) {
      await expectLater(auth.registrar(datos), throwsA(isA<AccesoException>()));
    }
    expect(auth.sesion, isNull);
    final db = await base.abrir;
    for (final tabla in ['empresas', 'usuarios', 'cuentas']) {
      expect(await db.query(tabla), isEmpty);
    }
  });

  test(
    'HU01 CA03 correo normalizado único; no queda una segunda empresa',
    () async {
      await auth.registrar(registro());
      auth.cerrarSesion();
      await expectLater(
        auth.registrar(registro(' DUENO@EMPRESA.COM ')),
        throwsA(isA<AccesoException>()),
      );
      final db = await base.abrir;
      expect(await db.query('empresas'), hasLength(1));
      expect(await db.query('usuarios'), hasLength(1));
      expect(await db.query('cuentas'), hasLength(1));
      expect(auth.sesion, isNull);
    },
  );

  test(
    'HU01 CA04 rollback ante fallo de escritura; permite reintentar',
    () async {
      final db = await base.abrir;
      await db.execute(
        "CREATE TRIGGER fallar_registro BEFORE INSERT ON cuentas BEGIN SELECT RAISE(ABORT, 'fallo de prueba'); END",
      );
      await expectLater(
        auth.registrar(registro()),
        throwsA(isA<AccesoException>()),
      );
      for (final tabla in ['empresas', 'usuarios', 'cuentas']) {
        expect(await db.query(tabla), isEmpty);
      }
      expect(auth.sesion, isNull);
      await db.execute('DROP TRIGGER fallar_registro');
      await auth.registrar(registro());
      expect(auth.sesion, isNotNull);
    },
  );

  test('HU02 CA01/02 acceso correcto, incorrecto y cuenta inactiva', () async {
    await auth.registrar(registro());
    final empresaId = auth.sesion!.empresaId;
    auth.cerrarSesion();
    for (final credenciales in [
      ('dueno@empresa.com', 'otra frase de acceso'),
      ('nadie@empresa.com', clave),
    ]) {
      await expectLater(
        auth.iniciarSesion(credenciales.$1, credenciales.$2),
        throwsA(isA<AccesoException>()),
      );
      expect(auth.sesion, isNull);
    }
    await auth.iniciarSesion(' DUENO@EMPRESA.COM ', clave);
    expect(auth.sesion!.empresaId, empresaId);
    auth.cerrarSesion();
    await (await base.abrir).update('cuentas', {'activa': 0});
    await expectLater(
      auth.iniciarSesion('dueno@empresa.com', clave),
      throwsA(isA<AccesoException>()),
    );
    expect(auth.sesion, isNull);
  });

  test('HU02 CA03 referencias al repositorio anterior no leen ni escriben tras salir', () async {
    await auth.registrar(registro());
    final repo = repositorio();
    final producto = await repo.crearProducto(
      nombre: 'Arroz',
      costoCompra: 6000,
      precioVenta: 10000,
    );
    auth.cerrarSesion();
    final periodo = PeriodoReporte(
      desde: DateTime(2026, 11, 1),
      hasta: DateTime(2026, 11, 30),
    );
    final intentos = <Future<Object?> Function()>[
      repo.obtenerTodos,
      () => repo.obtenerPorId(producto.id),
      () => repo.crearProducto(nombre: 'Otro', costoCompra: 1, precioVenta: 2),
      () => repo.actualizarProducto(
        id: producto.id,
        nombre: 'Editado',
        costoCompra: 1,
        precioVenta: 2,
      ),
      () => repo.confirmarOperacion(
        SolicitudOperacion(
          id: nuevoId(),
          tipo: TipoOperacion.inicial,
          motivo: 'Apertura',
          lineas: [
            LineaOperacion(
              productoId: producto.id,
              cantidad: 2,
              valorUnitario: 6000,
            ),
          ],
        ),
      ),
      () => repo.obtenerOperaciones(),
      () => repo.obtenerMovimientos(),
      () => repo.obtenerGastos(),
      () => repo.obtenerReporte(periodo),
      () => repo.registrarGasto(
        SolicitudGasto(
          id: nuevoId(),
          fecha: DateTime(2026, 11, 12),
          concepto: 'Transporte',
          categoria: 'Otros',
          valor: 5000,
        ),
      ),
    ];
    for (final intento in intentos) {
      await expectLater(intento(), throwsA(isA<AccesoException>()));
    }
    await auth.iniciarSesion('dueno@empresa.com', clave);
    expect((await repositorio().obtenerPorId(producto.id))!.nombre, 'Arroz');
    await expectLater(repo.obtenerTodos(), throwsA(isA<AccesoException>()));
  });

  test('Empresas separadas y acceso directo sin sesión denegado', () async {
    await auth.registrar(registro());
    final empresaA = auth.sesion!.empresaId;
    final producto = await repositorio().crearProducto(
      nombre: 'Solo empresa A',
      costoCompra: 1,
      precioVenta: 2,
    );
    final hashA = (await (await base.abrir).query('cuentas')).single;
    auth.cerrarSesion();
    await auth.registrar(registro('segunda@empresa.com'));
    expect(auth.sesion!.empresaId, isNot(empresaA));
    expect(await repositorio().obtenerTodos(), isEmpty);
    expect(await repositorio().obtenerPorId(producto.id), isNull);
    final cuentas = await (await base.abrir).query('cuentas');
    expect(cuentas.last['sal'], isNot(hashA['sal']));
    expect(cuentas.last['hash'], isNot(hashA['hash']));
    final sinSesion = RepositorioSqlite(
      factory: databaseFactoryFfi,
      ruta: base.ruta,
      empresaId: empresaA,
    );
    await expectLater(
      sinSesion.obtenerTodos(),
      throwsA(isA<AccesoException>()),
    );
    final repoB = repositorio();
    await (await base.abrir).update(
      'cuentas',
      {'activa': 0},
      where: 'id = ?',
      whereArgs: [auth.sesion!.cuentaId],
    );
    await expectLater(repoB.obtenerTodos(), throwsA(isA<AccesoException>()));
  });

  test(
    'La primera cuenta conserva el negocio anterior; reiniciar exige acceso',
    () async {
      final anterior = RepositorioSqlite(
        factory: databaseFactoryFfi,
        ruta: base.ruta,
      );
      final producto = await anterior.crearProducto(
        nombre: 'Dato anterior',
        costoCompra: 1,
        precioVenta: 2,
      );
      await auth.registrar(registro());
      expect(auth.sesion!.empresaId, 'negocio-local');
      expect(
        (await repositorio().obtenerPorId(producto.id))!.nombre,
        'Dato anterior',
      );
      auth.dispose();
      await base.cerrar();
      base = BaseDatosLocal(
        factory: databaseFactoryFfi,
        ruta: '${directorio.path}/cuentas.db',
      );
      auth = AutenticacionLocal(base: base);
      expect(auth.sesion, isNull);
      await auth.iniciarSesion('dueno@empresa.com', clave);
      expect(
        (await repositorio().obtenerPorId(producto.id))!.nombre,
        'Dato anterior',
      );
    },
  );

  test(
    'Migración v2 conserva productos y gastos al registrar la primera cuenta',
    () async {
      final anterior = RepositorioSqlite(
        factory: databaseFactoryFfi,
        ruta: base.ruta,
      );
      final producto = await anterior.crearProducto(
        nombre: 'Arroz anterior',
        costoCompra: 6000,
        precioVenta: 10000,
      );
      await anterior.registrarGasto(
        SolicitudGasto(
          id: nuevoId(),
          fecha: DateTime(2026, 11, 12),
          concepto: 'Energía anterior',
          categoria: 'Servicios',
          valor: 80000,
        ),
      );
      final db = await base.abrir;
      // El esquema v2 contiene las tablas del negocio, sin la tabla de cuentas.
      await db.execute('DROP TABLE cuentas');
      await db.execute('PRAGMA user_version = 2');
      auth.dispose();
      await base.cerrar();
      base = BaseDatosLocal(
        factory: databaseFactoryFfi,
        ruta: '${directorio.path}/cuentas.db',
      );
      auth = AutenticacionLocal(base: base);
      await auth.registrar(registro());
      expect(await (await base.abrir).getVersion(), 4);
      expect(
        (await repositorio().obtenerPorId(producto.id))!.nombre,
        'Arroz anterior',
      );
      expect(
        (await repositorio().obtenerGastos()).single.valorCentavos,
        8000000,
      );
    },
  );

  test(
    'Dos registros simultáneos con el mismo correo crean una sola empresa',
    () async {
      final otra = AutenticacionLocal(base: base);
      addTearDown(otra.dispose);
      Future<bool> intentar(AutenticacionLocal acceso) async {
        try {
          await acceso.registrar(registro());
          return true;
        } on AccesoException {
          return false;
        }
      }

      final resultados = await Future.wait([intentar(auth), intentar(otra)]);
      expect(resultados.where((r) => r), hasLength(1));
      final db = await base.abrir;
      for (final tabla in ['empresas', 'usuarios', 'cuentas']) {
        expect(await db.query(tabla), hasLength(1));
      }
    },
  );
}
