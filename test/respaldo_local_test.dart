// PBKDF2 con 600 000 iteraciones: en paralelo con otros archivos que
// también derivan claves, una prueba puede superar los 30 s por defecto.
@Timeout.factor(4)
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:finanzasist/data/autenticacion_local.dart';
import 'package:finanzasist/data/base_datos_local.dart';
import 'package:finanzasist/data/repositorio_sqlite.dart';
import 'package:finanzasist/data/respaldo_local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const clave = 'mi frase de acceso 2026';
const registro = DatosRegistro(
  empresa: 'Tienda Central',
  propietario: 'Jose Torres',
  correo: 'dueno@empresa.com',
  clave: clave,
);

void main() {
  sqfliteFfiInit();
  late Directory directorio;
  late BaseDatosLocal base;
  late AutenticacionLocal auth;
  late RespaldoLocal respaldo;

  setUp(() async {
    directorio = await Directory.systemTemp.createTemp('finanzasist-respaldo-');
    base = BaseDatosLocal(
      factory: databaseFactoryFfi,
      ruta: '${directorio.path}/finanzasist.db',
    );
    auth = AutenticacionLocal(base: base);
    respaldo = RespaldoLocal(base: base);
  });
  tearDown(() async {
    auth.dispose();
    await base.cerrar();
    await directorio.delete(recursive: true);
  });

  RepositorioSqlite repositorio() =>
      RepositorioSqlite.conSesion(base: base, sesion: auth.sesion!);

  Future<List<String>> nombresProductos() async =>
      (await repositorio().obtenerTodos()).map((p) => p.nombre).toList();

  Future<void> crearProducto(String nombre) => repositorio().crearProducto(
    nombre: nombre,
    costoCompra: 3000,
    precioVenta: 4000,
  );

  /// Modifica una copia del respaldo con SQL para simular archivos ajenos.
  Future<Uint8List> alterarCopia(
    Uint8List original,
    Future<void> Function(Database db) cambio,
  ) async {
    final ruta = '${directorio.path}/alterado-${original.hashCode}.db';
    await File(ruta).writeAsBytes(original);
    final db = await databaseFactoryFfi.openDatabase(ruta);
    await cambio(db);
    await db.close();
    return File(ruta).readAsBytes();
  }

  group('Exportar', () {
    test('produce una base SQLite con los datos del negocio', () async {
      await auth.registrar(registro);
      await crearProducto('Arroz de 1 kg');

      final bytes = await respaldo.exportar(sesion: auth.sesion);

      expect(ascii.decode(bytes.sublist(0, 15)), 'SQLite format 3');
      final copia = '${directorio.path}/copia.db';
      await File(copia).writeAsBytes(bytes);
      final db = await databaseFactoryFfi.openDatabase(copia);
      final filas = await db.query('productos', columns: ['nombre']);
      await db.close();
      expect(filas.single['nombre'], 'Arroz de 1 kg');
    });

    test('exige una sesión válida cuando hay cuentas', () async {
      await auth.registrar(registro);
      await expectLater(respaldo.exportar(), throwsA(isA<RespaldoException>()));
      final sesion = auth.sesion!;
      auth.cerrarSesion();
      await expectLater(
        respaldo.exportar(sesion: sesion),
        throwsA(isA<RespaldoException>()),
      );
    });

    test('no se permite con varias empresas en el dispositivo', () async {
      await auth.registrar(registro);
      auth.cerrarSesion();
      await auth.registrar(
        const DatosRegistro(
          empresa: 'Otra Tienda',
          propietario: 'Ana Ruiz',
          correo: 'ana@otra.com',
          clave: clave,
        ),
      );
      await crearProducto('Producto de Otra Tienda');

      await expectLater(
        respaldo.exportar(sesion: auth.sesion),
        throwsA(
          isA<RespaldoException>().having(
            (e) => e.mensaje,
            'mensaje',
            contains('varias empresas'),
          ),
        ),
      );
      await expectLater(
        respaldo.restaurar(
          Uint8List.fromList(utf8.encode('SQLite format 3\u0000 resto')),
          sesion: auth.sesion,
        ),
        throwsA(
          isA<RespaldoException>().having(
            (e) => e.mensaje,
            'mensaje',
            contains('varias empresas'),
          ),
        ),
      );
      expect(await nombresProductos(), ['Producto de Otra Tienda']);
    });

    test('la base sigue disponible después de exportar', () async {
      await auth.registrar(registro);
      await respaldo.exportar(sesion: auth.sesion);
      await crearProducto('Aceite de 1 litro');
      expect(await nombresProductos(), ['Aceite de 1 litro']);
    });

    test('nombre de archivo con fecha y hora local', () {
      expect(
        RespaldoLocal.nombreArchivo(DateTime(2026, 11, 8, 7, 5)),
        'finanzasist-respaldo-2026-11-08-0705.db',
      );
    });
  });

  group('Restaurar', () {
    test('reemplaza los datos y conserva las cuentas del respaldo', () async {
      await auth.registrar(registro);
      await crearProducto('Arroz de 1 kg');
      final bytes = await respaldo.exportar(sesion: auth.sesion);
      await crearProducto('Aceite de 1 litro');

      await respaldo.restaurar(bytes, sesion: auth.sesion);
      auth.cerrarSesion();
      await auth.iniciarSesion(registro.correo, clave);

      expect(await nombresProductos(), ['Arroz de 1 kg']);
      final archivos = directorio.listSync().map((e) => e.path).toList();
      expect(archivos.where((p) => p.contains('.restaurando')), isEmpty);
      expect(archivos.where((p) => p.contains('.anterior')), isEmpty);
    });

    test('sin cuentas en el dispositivo se permite sin sesión', () async {
      await auth.registrar(registro);
      await crearProducto('Arroz de 1 kg');
      final bytes = await respaldo.exportar(sesion: auth.sesion);
      auth.dispose();
      await base.cerrar();
      await File(base.ruta!).delete();
      base = BaseDatosLocal(factory: databaseFactoryFfi, ruta: base.ruta);
      auth = AutenticacionLocal(base: base);
      respaldo = RespaldoLocal(base: base);

      expect(await respaldo.restauracionSinSesion(), isTrue);
      await respaldo.restaurar(bytes);

      expect(await respaldo.restauracionSinSesion(), isFalse);
      await auth.iniciarSesion(registro.correo, clave);
      expect(await nombresProductos(), ['Arroz de 1 kg']);
    });

    test('con cuentas en el dispositivo exige sesión', () async {
      await auth.registrar(registro);
      await crearProducto('Arroz de 1 kg');
      final bytes = await respaldo.exportar(sesion: auth.sesion);
      await crearProducto('Aceite de 1 litro');

      await expectLater(
        respaldo.restaurar(bytes),
        throwsA(isA<RespaldoException>()),
      );
      expect(await nombresProductos(), ['Arroz de 1 kg', 'Aceite de 1 litro']);
    });

    test('migra un respaldo de una versión anterior', () async {
      // Datos del negocio local anterior a las cuentas (esquema v2).
      final anterior = RepositorioSqlite(
        factory: databaseFactoryFfi,
        ruta: base.ruta,
      );
      await anterior.crearProducto(
        nombre: 'Arroz anterior',
        costoCompra: 3000,
        precioVenta: 4000,
      );
      await anterior.cerrar();
      final v2 = await alterarCopia(await respaldo.exportar(), (db) async {
        await db.execute('DROP TABLE guias_vistas');
        await db.execute('DROP TABLE cuentas');
        await db.execute('PRAGMA user_version = 2');
      });
      await auth.registrar(registro);
      await crearProducto('Producto nuevo');

      await respaldo.restaurar(v2, sesion: auth.sesion);
      auth.cerrarSesion();

      expect(await (await base.abrir).getVersion(), BaseDatosLocal.version);
      // La primera cuenta registrada adopta el negocio anterior del respaldo.
      await auth.registrar(registro);
      expect(await nombresProductos(), ['Arroz anterior']);
    });

    group('rechaza y conserva los datos actuales', () {
      late Uint8List valido;
      setUp(() async {
        await auth.registrar(registro);
        await crearProducto('Arroz de 1 kg');
        valido = await respaldo.exportar(sesion: auth.sesion);
        await crearProducto('Aceite de 1 litro');
      });

      Future<void> rechaza(Uint8List bytes, Matcher mensaje) async {
        await expectLater(
          respaldo.restaurar(bytes, sesion: auth.sesion),
          throwsA(
            isA<RespaldoException>().having(
              (e) => e.mensaje,
              'mensaje',
              mensaje,
            ),
          ),
        );
        expect(await nombresProductos(), [
          'Arroz de 1 kg',
          'Aceite de 1 litro',
        ]);
        final archivos = directorio.listSync().map((e) => e.path);
        expect(archivos.where((p) => p.contains('.restaurando')), isEmpty);
      }

      test('un archivo vacío', () async {
        await rechaza(Uint8List(0), contains('vacío'));
      });

      test('un archivo que no es SQLite', () async {
        await rechaza(
          Uint8List.fromList(utf8.encode('hola, esto no es una base')),
          contains('no es un respaldo de FinanzAsist'),
        );
      });

      test('una base SQLite de otra aplicación', () async {
        final ajena = await alterarCopia(valido, (db) async {
          for (final tabla in [
            'guias_vistas',
            'cuentas',
            'gastos',
            'movimientos',
            'operaciones',
            'productos',
          ]) {
            await db.execute('DROP TABLE $tabla');
          }
          await db.execute('CREATE TABLE notas (texto TEXT)');
        });
        await rechaza(ajena, contains('no es un respaldo de FinanzAsist'));
      });

      test('una tabla con columnas distintas', () async {
        final distinta = await alterarCopia(valido, (db) async {
          await db.execute('PRAGMA foreign_keys = OFF');
          await db.execute('DROP TABLE gastos');
          await db.execute('CREATE TABLE gastos (id TEXT)');
        });
        await rechaza(distinta, contains('no es un respaldo de FinanzAsist'));
      });

      test('un respaldo de una versión más nueva', () async {
        final nueva = await alterarCopia(valido, (db) async {
          await db.execute('PRAGMA user_version = 99');
        });
        await rechaza(nueva, contains('versión más nueva'));
      });

      test('un archivo dañado', () async {
        final danado = Uint8List.fromList(valido);
        // Conserva el encabezado y daña las páginas de datos.
        for (var i = 4096; i < danado.length; i += 7) {
          danado[i] = 0xFF;
        }
        await rechaza(danado, contains('dañado'));
      });

      test('un archivo más grande que el límite', () async {
        final respaldoPequeno = RespaldoLocal(base: base, tamanoMaximo: 1024);
        await expectLater(
          respaldoPequeno.restaurar(valido, sesion: auth.sesion),
          throwsA(
            isA<RespaldoException>().having(
              (e) => e.mensaje,
              'mensaje',
              contains('demasiado grande'),
            ),
          ),
        );
      });
    });
  });
}
