import 'dart:io';

import 'package:finanzasist/data/negocio_repository.dart';
import 'package:finanzasist/data/repositorio_simulado.dart';
import 'package:finanzasist/data/repositorio_sqlite.dart';
import 'package:finanzasist/models/fecha_negocio.dart';
import 'package:finanzasist/models/gasto.dart';
import 'package:finanzasist/models/operacion.dart';
import 'package:finanzasist/models/reporte_financiero.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  for (final sqlite in [false, true]) {
    group(sqlite ? 'Finanzas SQLite' : 'Finanzas simuladas', () {
      late NegocioRepository repo;
      late DateTime instante;
      late String ruta;
      final noviembre = PeriodoReporte(
        desde: DateTime.utc(2026, 11),
        hasta: DateTime.utc(2026, 11, 30),
      );
      setUp(() async {
        instante = DateTime.utc(2026, 11, 10, 15);
        if (sqlite) {
          final dir = await Directory.systemTemp.createTemp(
            'finanzasist-finanzas-',
          );
          ruta = '${dir.path}/negocio.db';
          final fuente = RepositorioSqlite(
            factory: databaseFactoryFfi,
            ruta: ruta,
            reloj: () => instante,
          );
          repo = fuente;
          addTearDown(() async {
            await fuente.cerrar();
            await dir.delete(recursive: true);
          });
        } else {
          repo = RepositorioSimulado(
            retardo: Duration.zero,
            productosIniciales: [],
            reloj: () => instante,
          );
        }
      });

      SolicitudGasto solicitud({
        String? id,
        DateTime? fecha,
        String concepto = 'Servicio de energía',
        String categoria = 'Servicios',
        double valor = 80000,
      }) => SolicitudGasto(
        id: id ?? nuevoId(),
        fecha: fecha ?? DateTime.utc(2026, 11, 10),
        concepto: concepto,
        categoria: categoria,
        valor: valor,
      );

      test(
        'HU10 CA01 registra gasto, fecha civil, categoría, valor y responsable',
        () async {
          final gasto = await repo.registrarGasto(
            solicitud(concepto: '  Servicio de energía  '),
          );
          expect(gasto.empresaId, repo.empresaId);
          expect(gasto.usuarioId, repo.usuarioId);
          expect(gasto.fecha, DateTime.utc(2026, 11, 10));
          expect(gasto.registradoEn, instante);
          expect(gasto.concepto, 'Servicio de energía');
          expect(gasto.categoria, 'Servicios');
          expect(gasto.valorCentavos, 8000000);
          expect((await repo.obtenerGastos()).single.id, gasto.id);
          expect(await repo.obtenerMovimientos(), isEmpty);
        },
      );

      test(
        'HU10 CA02/03 rechaza campos vacíos, fechas e importes inválidos',
        () async {
          final invalidas = [
            SolicitudGasto(
              id: nuevoId(),
              fecha: null,
              concepto: 'Energía',
              categoria: 'Servicios',
              valor: 80000,
            ),
            solicitud(fecha: DateTime.utc(0)),
            solicitud(concepto: '  '),
            solicitud(categoria: ''),
            solicitud(valor: 0),
            solicitud(valor: -1),
            solicitud(valor: double.nan),
            solicitud(valor: double.infinity),
            solicitud(valor: 0.001),
          ];
          for (final gasto in invalidas) {
            await expectLater(
              repo.registrarGasto(gasto),
              throwsA(isA<ReglaNegocioException>()),
            );
          }
          expect(await repo.obtenerGastos(), isEmpty);
          expect(await repo.obtenerOperaciones(), isEmpty);
        },
      );

      test('Doble envío de gasto es idempotente y un cambio con el mismo id se rechaza', () async {
        final gasto = solicitud(id: 'gasto-fijo');
        await Future.wait([
          repo.registrarGasto(gasto),
          repo.registrarGasto(gasto),
        ]);
        await expectLater(
          repo.registrarGasto(solicitud(id: 'gasto-fijo', valor: 90000)),
          throwsA(isA<ReglaNegocioException>()),
        );
        expect(await repo.obtenerGastos(), hasLength(1));
      });

      test('HU09 y HU14 CA01 calculan el ejemplo de utilidad 250000 con históricos', () async {
        final producto = await repo.crearProducto(
          nombre: 'Café',
          costoCompra: 50000,
          precioVenta: 100000,
        );
        await repo.confirmarOperacion(
          SolicitudOperacion(
            id: nuevoId(),
            tipo: TipoOperacion.compra,
            lineas: [
              LineaOperacion(
                productoId: producto.id,
                cantidad: 10,
                valorUnitario: 60000,
              ),
            ],
          ),
        );
        final venta = await repo.confirmarOperacion(
          SolicitudOperacion(
            id: nuevoId(),
            tipo: TipoOperacion.venta,
            descuento: 100000,
            lineas: [
              LineaOperacion(
                productoId: producto.id,
                cantidad: 10,
                valorUnitario: 100000,
              ),
            ],
          ),
        );
        await repo.registrarGasto(solicitud(valor: 150000));
        await repo.actualizarProducto(
          id: producto.id,
          nombre: 'Café actualizado',
          costoCompra: 70000,
          precioVenta: 120000,
        );
        final reporte = await repo.obtenerReporte(noviembre);
        expect(reporte.ventasCentavos, 100000000);
        expect(reporte.descuentosCentavos, 10000000);
        expect(reporte.ingresosNetosCentavos, 90000000);
        expect(reporte.costoVentasCentavos, 50000000);
        expect(reporte.comprasCentavos, 60000000);
        expect(reporte.gastosCentavos, 15000000);
        expect(reporte.egresosCentavos, 75000000);
        expect(reporte.utilidadBrutaCentavos, 40000000);
        expect(reporte.utilidadResultanteCentavos, 25000000);
        expect(reporte.sinOperaciones, isFalse);
        expect(venta.costoVentasCentavos, 50000000);
        expect(venta.metodoCosto, 'catalogo_al_confirmar');
        expect((await repo.obtenerPorId(producto.id))!.cantidad, 0);
      });

      test(
        'HU09 CA01/02/03 venta de 18000 conserva costo 12000 y utilidad 6000',
        () async {
          final producto = await repo.crearProducto(
            nombre: 'Arroz',
            costoCompra: 6000,
            precioVenta: 10000,
          );
          await repo.confirmarOperacion(
            SolicitudOperacion(
              id: nuevoId(),
              tipo: TipoOperacion.inicial,
              motivo: 'Apertura',
              lineas: [
                LineaOperacion(
                  productoId: producto.id,
                  cantidad: 2,
                  valorUnitario: 0,
                ),
              ],
            ),
          );
          await repo.confirmarOperacion(
            SolicitudOperacion(
              id: nuevoId(),
              tipo: TipoOperacion.venta,
              descuento: 2000,
              lineas: [
                LineaOperacion(
                  productoId: producto.id,
                  cantidad: 2,
                  valorUnitario: 10000,
                ),
              ],
            ),
          );
          await repo.actualizarProducto(
            id: producto.id,
            nombre: 'Arroz',
            costoCompra: 7000,
            precioVenta: 12000,
          );
          final venta = (await repo.obtenerOperaciones(
            tipo: TipoOperacion.venta,
          )).single;
          expect(venta.totalCentavos, 1800000);
          expect(venta.costoVentasCentavos, 1200000);
          expect(venta.utilidadBrutaCentavos, 600000);
          expect(
            (await repo.obtenerReporte(noviembre)).utilidadBrutaCentavos,
            600000,
          );
        },
      );

      test('HU14 CA02 usa ambos días completos de Colombia incluyendo microsegundos', () async {
        final producto = await repo.crearProducto(
          nombre: 'Arroz',
          costoCompra: 1,
          precioVenta: 2,
        );
        final momentos = [
          DateTime.utc(2026, 11, 1, 4, 59, 59, 999, 999),
          DateTime.utc(2026, 11, 1, 5, 0, 0, 0, 1),
          DateTime.utc(2026, 12, 1, 4, 59, 59, 999, 999),
          DateTime.utc(2026, 12, 1, 5, 0, 0, 0, 1),
        ];
        for (final momento in momentos) {
          instante = momento;
          await repo.confirmarOperacion(
            SolicitudOperacion(
              id: nuevoId(),
              tipo: TipoOperacion.compra,
              lineas: [
                LineaOperacion(
                  productoId: producto.id,
                  cantidad: 1,
                  valorUnitario: 1,
                ),
              ],
            ),
          );
        }
        for (final fecha in [
          DateTime.utc(2026, 10, 31),
          DateTime.utc(2026, 11),
          DateTime.utc(2026, 11, 30),
          DateTime.utc(2026, 12),
        ]) {
          await repo.registrarGasto(solicitud(fecha: fecha, valor: 1));
        }
        final reporte = await repo.obtenerReporte(noviembre);
        expect(reporte.numeroCompras, 2);
        expect(reporte.comprasCentavos, 200);
        expect(reporte.numeroGastos, 2);
        expect(reporte.gastosCentavos, 200);
        expect(await repo.obtenerGastos(periodo: noviembre), hasLength(2));
      });

      test('HU14 CA03 sin operaciones muestra ceros, y gastos solos producen pérdida', () async {
        final vacio = await repo.obtenerReporte(noviembre);
        expect(vacio.sinOperaciones, isTrue);
        expect(vacio.ingresosNetosCentavos, 0);
        expect(vacio.egresosCentavos, 0);
        expect(vacio.utilidadResultanteCentavos, 0);
        await repo.registrarGasto(solicitud(valor: 0.1));
        await repo.registrarGasto(solicitud(valor: 0.2));
        final reporte = await repo.obtenerReporte(noviembre);
        expect(reporte.gastosCentavos, 30);
        expect(reporte.utilidadResultanteCentavos, -30);
        expect(reporte.sinOperaciones, isFalse);
      });

      test('Un reporte demasiado grande falla explícitamente en lugar de perder precisión', () async {
        await repo.registrarGasto(solicitud(valor: 50000000000000));
        await repo.registrarGasto(solicitud(valor: 50000000000000));
        await expectLater(
          repo.obtenerReporte(noviembre),
          throwsA(isA<ReglaNegocioException>()),
        );
        expect(await repo.obtenerGastos(), hasLength(2));
      });

      if (sqlite) {
        test('Reapertura conserva gastos, y otras empresas no aparecen en reportes', () async {
          final gasto = solicitud(id: 'persistido');
          await repo.registrarGasto(gasto);
          final otra = RepositorioSqlite(
            factory: databaseFactoryFfi,
            ruta: ruta,
            empresaId: 'otra',
            reloj: () => instante,
          );
          await otra.registrarGasto(solicitud(id: 'persistido', valor: 3));
          expect((await otra.obtenerReporte(noviembre)).gastosCentavos, 300);
          expect(
            (await repo.obtenerReporte(noviembre)).gastosCentavos,
            8000000,
          );
          await (repo as RepositorioSqlite).cerrar();
          final nueva = RepositorioSqlite(
            factory: databaseFactoryFfi,
            ruta: ruta,
            reloj: () => instante,
          );
          await nueva.registrarGasto(gasto);
          expect(
            (await nueva.obtenerGastos()).single.concepto,
            'Servicio de energía',
          );
          expect(
            (await nueva.obtenerReporte(noviembre)).gastosCentavos,
            8000000,
          );
          await nueva.cerrar();
        });
      }
    });
  }

  test(
    'HU14 CA04 rechaza intervalo invertido y conserva el día de Colombia',
    () {
      expect(
        () => PeriodoReporte(
          desde: DateTime.utc(2026, 11, 20),
          hasta: DateTime.utc(2026, 11, 19),
        ),
        throwsA(isA<ReglaNegocioException>()),
      );
      expect(
        FechaNegocio.hoy(DateTime.utc(2026, 11, 11, 2)),
        DateTime.utc(2026, 11, 10),
      );
    },
  );

  test('Migración SQLite v1 a v2 conserva productos y ventas sin costoAsignadoCentavos', () async {
    final dir = await Directory.systemTemp.createTemp('finanzasist-migracion-');
    final ruta = '${dir.path}/legado.db';
    final db = await databaseFactoryFfi.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('CREATE TABLE empresas (id TEXT PRIMARY KEY)');
          await db.execute(
            'CREATE TABLE usuarios (empresa TEXT, id TEXT, PRIMARY KEY (empresa,id))',
          );
          await db.execute(
            'CREATE TABLE productos (empresa TEXT, id TEXT, nombre TEXT, cantidad INTEGER, costo INTEGER, precio INTEGER, PRIMARY KEY (empresa,id))',
          );
          await db.execute(
            'CREATE TABLE operaciones (empresa TEXT, id TEXT, usuario TEXT, tipo TEXT, fecha TEXT, datos TEXT, PRIMARY KEY (empresa,id))',
          );
          await db.execute(
            'CREATE TABLE movimientos (empresa TEXT, operacion TEXT, producto TEXT, usuario TEXT, fecha TEXT, tipo TEXT, cantidad INTEGER, saldo INTEGER, motivo TEXT)',
          );
          await db.insert('empresas', {'id': 'negocio-local'});
          await db.insert('usuarios', {
            'empresa': 'negocio-local',
            'id': 'administrador-local',
          });
          await db.insert('productos', {
            'empresa': 'negocio-local',
            'id': 'P1',
            'nombre': 'Arroz',
            'cantidad': 8,
            'costo': 600000,
            'precio': 1000000,
          });
          const datos =
              '{"solicitud":{"id":"venta-v1","tipo":"venta","lineas":[{"productoId":"P1","cantidad":2,"valorUnitario":10000.0}],"descuento":2000.0,"motivo":""},"empresaId":"negocio-local","usuarioId":"administrador-local","fecha":"2026-11-10T15:00:00.000Z","subtotalCentavos":2000000,"descuentoCentavos":200000,"detalles":[{"productoId":"P1","nombre":"Arroz","cantidad":2,"valorCentavos":1000000,"costoCatalogoCentavos":600000}]}';
          await db.insert('operaciones', {
            'empresa': 'negocio-local',
            'id': 'venta-v1',
            'usuario': 'administrador-local',
            'tipo': 'venta',
            'fecha': '2026-11-10T15:00:00.000Z',
            'datos': datos,
          });
        },
      ),
    );
    await db.close();
    final repo = RepositorioSqlite(factory: databaseFactoryFfi, ruta: ruta);
    addTearDown(() async {
      await repo.cerrar();
      await dir.delete(recursive: true);
    });
    expect((await repo.obtenerPorId('P1'))!.cantidad, 8);
    final venta = (await repo.obtenerOperaciones()).single;
    expect(venta.costoVentasCentavos, 1200000);
    expect(venta.utilidadBrutaCentavos, 600000);
    expect(await repo.obtenerGastos(), isEmpty);
    await repo.registrarGasto(
      SolicitudGasto(
        id: 'nuevo',
        fecha: DateTime.utc(2026, 11, 10),
        concepto: 'Energía',
        categoria: 'Servicios',
        valor: 80000,
      ),
    );
    final reporte = await repo.obtenerReporte(
      PeriodoReporte(
        desde: DateTime.utc(2026, 11),
        hasta: DateTime.utc(2026, 11, 30),
      ),
    );
    expect(reporte.utilidadBrutaCentavos, 600000);
    expect(reporte.gastosCentavos, 8000000);
  });
}
