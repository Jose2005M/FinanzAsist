import 'dart:io';

import 'package:finanzasist/data/negocio_repository.dart';
import 'package:finanzasist/data/repositorio_simulado.dart';
import 'package:finanzasist/data/repositorio_sqlite.dart';
import 'package:finanzasist/models/operacion.dart';
import 'package:finanzasist/models/producto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  for (final sqlite in [false, true]) {
    group(sqlite ? 'SQLite' : 'Simulado', () {
      late NegocioRepository repo;
      late Producto arroz;
      late Producto aceite;
      late String rutaSqlite;
      setUp(() async {
        if (sqlite) {
          final dir = await Directory.systemTemp.createTemp(
            'finanzasist-reglas-',
          );
          rutaSqlite = '${dir.path}/prueba.db';
          final db = RepositorioSqlite(
            factory: databaseFactoryFfi,
            ruta: rutaSqlite,
          );
          repo = db;
          addTearDown(() async {
            await db.cerrar();
            await dir.delete(recursive: true);
          });
        } else {
          repo = RepositorioSimulado(
            retardo: Duration.zero,
            productosIniciales: [],
          );
        }
        arroz = await repo.crearProducto(
          nombre: 'Arroz',
          costoCompra: 6000,
          precioVenta: 10000,
        );
        aceite = await repo.crearProducto(
          nombre: 'Aceite',
          costoCompra: 7000,
          precioVenta: 9000,
        );
      });

      SolicitudOperacion pedido(
        TipoOperacion tipo,
        int cantidad, {
        String? id,
        double valor = 6000,
        double descuento = 0,
        String motivo = 'Inventario de apertura',
        String? productoId,
      }) => SolicitudOperacion(
        id: id ?? nuevoId(),
        tipo: tipo,
        motivo: motivo,
        descuento: descuento,
        lineas: [
          LineaOperacion(
            productoId: productoId ?? arroz.id,
            cantidad: cantidad,
            valorUnitario: valor,
          ),
        ],
      );
      Future<int> saldo() async =>
          (await repo.obtenerPorId(arroz.id))!.cantidad;

      test(
        'HU06 CA01/02 registra apertura y ajuste con motivo, fecha y usuario',
        () async {
          final inicio = await repo.confirmarOperacion(
            pedido(TipoOperacion.inicial, 20),
          );
          await repo.confirmarOperacion(
            pedido(TipoOperacion.ajuste, -2, motivo: 'Diferencia de conteo'),
          );
          expect(await saldo(), 18);
          final movimientos = await repo.obtenerMovimientos(
            productoId: arroz.id,
          );
          expect(movimientos, hasLength(2));
          expect(movimientos.first.cantidad, -2);
          expect(movimientos.first.saldo, 18);
          expect(movimientos.first.motivo, 'Diferencia de conteo');
          expect(movimientos.last.fecha, inicio.fecha);
          expect(movimientos.last.usuarioId, repo.usuarioId);
          expect(movimientos.last.empresaId, repo.empresaId);
        },
      );

      test(
        'HU06 CA03/04 rechaza motivo vacío y saldo negativo sin movimientos',
        () async {
          await repo.confirmarOperacion(pedido(TipoOperacion.inicial, 3));
          for (final solicitud in [
            pedido(TipoOperacion.ajuste, -1, motivo: '  '),
            pedido(TipoOperacion.ajuste, -4),
            pedido(TipoOperacion.inicial, 20),
          ]) {
            await expectLater(
              repo.confirmarOperacion(solicitud),
              throwsA(isA<ReglaNegocioException>()),
            );
          }
          expect(await saldo(), 3);
          expect(await repo.obtenerMovimientos(), hasLength(1));
        },
      );

      test(
        'Apertura concurrente y reintento no duplican las 20 unidades',
        () async {
          final solicitud = pedido(TipoOperacion.inicial, 20);
          final resultados = await Future.wait([
            repo.confirmarOperacion(solicitud),
            repo.confirmarOperacion(solicitud),
          ]);
          expect(resultados.map((o) => o.id).toSet(), {solicitud.id});
          expect(await saldo(), 20);
          expect(await repo.obtenerMovimientos(), hasLength(1));
          await expectLater(
            repo.confirmarOperacion(pedido(TipoOperacion.inicial, 20)),
            throwsA(isA<ReglaNegocioException>()),
          );
        },
      );

      test(
        'HU07 CA01/04 compra por 30000 pasa 10 a 15 y se aplica una vez',
        () async {
          await repo.confirmarOperacion(pedido(TipoOperacion.inicial, 10));
          final solicitud = pedido(TipoOperacion.compra, 5);
          final compra = await repo.confirmarOperacion(solicitud);
          await repo.confirmarOperacion(solicitud);
          expect(compra.totalCentavos, 3000000);
          expect(compra.detalles.single['cantidad'], 5);
          expect(compra.detalles.single['valorCentavos'], 600000);
          expect(await saldo(), 15);
          expect(
            await repo.obtenerOperaciones(tipo: TipoOperacion.compra),
            hasLength(1),
          );
        },
      );

      test('HU07 CA02 y HU08 CA03 rechazan líneas, cantidades, importes y descuentos', () async {
        await repo.confirmarOperacion(pedido(TipoOperacion.inicial, 10));
        final invalidas = [
          SolicitudOperacion(
            id: nuevoId(),
            tipo: TipoOperacion.compra,
            lineas: [],
          ),
          pedido(TipoOperacion.compra, 1, productoId: ''),
          pedido(TipoOperacion.compra, 0),
          pedido(TipoOperacion.compra, -1),
          pedido(TipoOperacion.compra, 1, valor: -1),
          pedido(TipoOperacion.compra, 1, valor: double.nan),
          pedido(TipoOperacion.venta, 0),
          pedido(TipoOperacion.venta, -1),
          pedido(TipoOperacion.venta, 1, valor: -1),
          pedido(TipoOperacion.venta, 1, descuento: -1),
          pedido(TipoOperacion.venta, 1, descuento: 6001),
          pedido(TipoOperacion.venta, 1, descuento: double.infinity),
        ];
        for (final solicitud in invalidas) {
          await expectLater(
            repo.confirmarOperacion(solicitud),
            throwsA(isA<ReglaNegocioException>()),
          );
        }
        expect(await saldo(), 10);
        expect(await repo.obtenerOperaciones(), hasLength(1));
      });

      test(
        'HU08 CA01 conserva subtotal 20000 descuento 2000 total 18000',
        () async {
          await repo.confirmarOperacion(pedido(TipoOperacion.inicial, 10));
          final venta = await repo.confirmarOperacion(
            pedido(TipoOperacion.venta, 2, valor: 10000, descuento: 2000),
          );
          expect(venta.subtotalCentavos, 2000000);
          expect(venta.descuentoCentavos, 200000);
          expect(venta.totalCentavos, 1800000);
          expect(await saldo(), 8);
          await repo.actualizarProducto(
            id: arroz.id,
            nombre: 'Arroz nuevo',
            costoCompra: 8000,
            precioVenta: 12000,
          );
          final historica = (await repo.obtenerOperaciones(
            tipo: TipoOperacion.venta,
          )).single;
          expect(historica.detalles.single['valorCentavos'], 1000000);
          expect(historica.detalles.single['costoCatalogoCentavos'], 600000);
          expect(historica.detalles.single['nombre'], 'Arroz');
          expect(await saldo(), 8);
        },
      );

      test(
        'HU05 CA03 integración apertura compra venta: 10 + 5 − 4 = 11',
        () async {
          await repo.confirmarOperacion(pedido(TipoOperacion.inicial, 10));
          await repo.confirmarOperacion(pedido(TipoOperacion.compra, 5));
          expect(await saldo(), 15);
          final venta = pedido(TipoOperacion.venta, 4, valor: 10000);
          await Future.wait([
            repo.confirmarOperacion(venta),
            repo.confirmarOperacion(venta),
          ]);
          expect(await saldo(), 11);
          expect(
            (await repo.obtenerTodos())
                .singleWhere((p) => p.id == arroz.id)
                .cantidad,
            11,
          );
          expect(
            (await repo.obtenerMovimientos(productoId: arroz.id)).first.saldo,
            11,
          );
        },
      );

      test('HU08 CA04 dos usuarios compiten por la última unidad', () async {
        await repo.confirmarOperacion(pedido(TipoOperacion.inicial, 1));
        NegocioRepository otraSesion = repo;
        if (sqlite) {
          otraSesion = RepositorioSqlite(
            factory: databaseFactoryFfi,
            ruta: rutaSqlite,
            usuarioId: 'segundo-usuario',
          );
        }
        Future<bool> intentar(NegocioRepository fuente) async {
          try {
            await fuente.confirmarOperacion(pedido(TipoOperacion.venta, 1));
            return true;
          } on ReglaNegocioException {
            return false;
          }
        }

        final resultados = await Future.wait([
          intentar(repo),
          intentar(otraSesion),
        ]);
        expect(resultados.where((exito) => exito), hasLength(1));
        expect(await saldo(), 0);
        expect(
          await repo.obtenerOperaciones(tipo: TipoOperacion.venta),
          hasLength(1),
        );
      });

      test(
        'Líneas repetidas o una segunda línea inválida no alteran ningún saldo',
        () async {
          await repo.confirmarOperacion(pedido(TipoOperacion.inicial, 10));
          for (final segunda in [
            LineaOperacion(
              productoId: arroz.id,
              cantidad: 2,
              valorUnitario: 100,
            ),
            LineaOperacion(
              productoId: aceite.id,
              cantidad: 0,
              valorUnitario: 100,
            ),
          ]) {
            await expectLater(
              repo.confirmarOperacion(
                SolicitudOperacion(
                  id: nuevoId(),
                  tipo: TipoOperacion.compra,
                  lineas: [
                    LineaOperacion(
                      productoId: arroz.id,
                      cantidad: 1,
                      valorUnitario: 100,
                    ),
                    segunda,
                  ],
                ),
              ),
              throwsA(isA<ReglaNegocioException>()),
            );
          }
          expect(await saldo(), 10);
          expect((await repo.obtenerPorId(aceite.id))!.cantidad, 0);
        },
      );

      test('Centavos exactos y descuento igual al subtotal', () async {
        await repo.confirmarOperacion(
          pedido(TipoOperacion.compra, 3, valor: 0.1),
        );
        final venta = await repo.confirmarOperacion(
          pedido(TipoOperacion.venta, 3, valor: 0.1, descuento: 0.3),
        );
        expect(venta.subtotalCentavos, 30);
        expect(venta.totalCentavos, 0);
        expect(await saldo(), 0);
      });

      test(
        'Compra y venta con dos productos conservan ambos detalles y saldos',
        () async {
          await repo.confirmarOperacion(
            SolicitudOperacion(
              id: nuevoId(),
              tipo: TipoOperacion.compra,
              lineas: [
                LineaOperacion(
                  productoId: arroz.id,
                  cantidad: 3,
                  valorUnitario: 3500,
                ),
                LineaOperacion(
                  productoId: aceite.id,
                  cantidad: 2,
                  valorUnitario: 7000,
                ),
              ],
            ),
          );
          final venta = await repo.confirmarOperacion(
            SolicitudOperacion(
              id: nuevoId(),
              tipo: TipoOperacion.venta,
              descuento: 1500,
              lineas: [
                LineaOperacion(
                  productoId: arroz.id,
                  cantidad: 3,
                  valorUnitario: 4500,
                ),
                LineaOperacion(
                  productoId: aceite.id,
                  cantidad: 1,
                  valorUnitario: 9000,
                ),
              ],
            ),
          );
          expect(venta.subtotalCentavos, 2250000);
          expect(venta.totalCentavos, 2100000);
          expect(venta.detalles, hasLength(2));
          expect(await saldo(), 0);
          expect((await repo.obtenerPorId(aceite.id))!.cantidad, 1);
          expect(await repo.obtenerMovimientos(), hasLength(4));
        },
      );

      test('Identificador reutilizado con datos distintos se rechaza sin cambiar saldos', () async {
        await repo.confirmarOperacion(
          pedido(TipoOperacion.compra, 1, id: 'fijo'),
        );
        await expectLater(
          repo.confirmarOperacion(pedido(TipoOperacion.compra, 2, id: 'fijo')),
          throwsA(isA<ReglaNegocioException>()),
        );
        expect(await saldo(), 1);
        expect(await repo.obtenerOperaciones(), hasLength(1));
      });
    });
  }

  group('Persistencia y separación por empresa', () {
    late String ruta;
    late RepositorioSqlite repo;
    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('finanzasist-test-');
      ruta = '${dir.path}/negocio.db';
      repo = RepositorioSqlite(
        factory: databaseFactoryFfi,
        ruta: ruta,
        empresaId: 'A',
      );
      addTearDown(() async {
        await repo.cerrar();
        await dir.delete(recursive: true);
      });
    });

    test(
      'Reabrir conserva productos, compras, ventas, movimientos e idempotencia',
      () async {
        final p = await repo.crearProducto(
          nombre: 'Café',
          costoCompra: 6000,
          precioVenta: 10000,
        );
        final compra = SolicitudOperacion(
          id: 'compra-reintento',
          tipo: TipoOperacion.compra,
          lineas: [
            LineaOperacion(productoId: p.id, cantidad: 15, valorUnitario: 6000),
          ],
        );
        await repo.confirmarOperacion(compra);
        await repo.confirmarOperacion(
          SolicitudOperacion(
            id: 'venta',
            tipo: TipoOperacion.venta,
            descuento: 2000,
            lineas: [
              LineaOperacion(
                productoId: p.id,
                cantidad: 4,
                valorUnitario: 10000,
              ),
            ],
          ),
        );
        await repo.cerrar();
        repo = RepositorioSqlite(
          factory: databaseFactoryFfi,
          ruta: ruta,
          empresaId: 'A',
        );
        await repo.confirmarOperacion(compra);
        expect((await repo.obtenerPorId(p.id))!.cantidad, 11);
        expect(
          (await repo.obtenerOperaciones()).map((o) => o.empresaId).toSet(),
          {'A'},
        );
        expect(await repo.obtenerOperaciones(), hasLength(2));
        expect(await repo.obtenerMovimientos(), hasLength(2));
        expect(
          (await repo.obtenerOperaciones(tipo: TipoOperacion.venta))
              .single
              .totalCentavos,
          3800000,
        );
      },
    );

    test(
      'TEC02 CA02/04 aísla consultas y rechaza relaciones entre empresas',
      () async {
        final p = await repo.crearProducto(
          nombre: 'Solo A',
          costoCompra: 1,
          precioVenta: 2,
        );
        final otra = RepositorioSqlite(
          factory: databaseFactoryFfi,
          ruta: ruta,
          empresaId: 'B',
        );
        await otra.crearProducto(
          nombre: 'Solo B',
          costoCompra: 3,
          precioVenta: 4,
        );
        expect((await repo.obtenerTodos()).single.nombre, 'Solo A');
        expect((await otra.obtenerTodos()).single.nombre, 'Solo B');
        expect(await otra.obtenerPorId(p.id), isNull);
        await expectLater(
          otra.confirmarOperacion(
            SolicitudOperacion(
              id: nuevoId(),
              tipo: TipoOperacion.compra,
              lineas: [
                LineaOperacion(productoId: p.id, cantidad: 1, valorUnitario: 1),
              ],
            ),
          ),
          throwsA(isA<ReglaNegocioException>()),
        );
        expect(await otra.obtenerOperaciones(), isEmpty);
        expect(await otra.obtenerMovimientos(), isEmpty);
        expect((await repo.obtenerPorId(p.id))!.cantidad, 0);
      },
    );

    test('TEC02 CA03 un error al guardar la segunda línea revierte toda la transacción', () async {
      final p = await repo.crearProducto(
        nombre: 'A',
        costoCompra: 1,
        precioVenta: 2,
      );
      final q = await repo.crearProducto(
        nombre: 'B',
        costoCompra: 1,
        precioVenta: 2,
      );
      final db = await databaseFactoryFfi.openDatabase(ruta);
      await db.execute(
        "CREATE TRIGGER fallo_movimiento BEFORE INSERT ON movimientos WHEN NEW.cantidad = 2 BEGIN SELECT RAISE(ABORT, 'fallo de disco simulado'); END",
      );
      await expectLater(
        repo.confirmarOperacion(
          SolicitudOperacion(
            id: nuevoId(),
            tipo: TipoOperacion.compra,
            lineas: [
              LineaOperacion(productoId: p.id, cantidad: 1, valorUnitario: 1),
              LineaOperacion(productoId: q.id, cantidad: 2, valorUnitario: 1),
            ],
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );
      expect((await repo.obtenerTodos()).every((p) => p.cantidad == 0), isTrue);
      expect(await repo.obtenerOperaciones(), isEmpty);
      expect(await repo.obtenerMovimientos(), isEmpty);
    });
  });
}
