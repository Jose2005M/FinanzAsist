@Timeout.factor(4)
library;

import 'package:finanzasist/data/autenticacion_local.dart';
import 'package:finanzasist/models/gasto.dart';
import 'package:finanzasist/models/operacion.dart';
import 'package:finanzasist/models/reporte_financiero.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte_roles.dart';

void main() {
  final plantilla = PlantillaRoles();
  late CasoRoles caso;
  final periodo = PeriodoReporte(desde: fechaRoles, hasta: fechaRoles);
  setUpAll(plantilla.crear);
  tearDownAll(plantilla.cerrar);
  setUp(() async {
    caso = await plantilla.copiar();
  });
  tearDown(() => caso.cerrar());

  for (final rol in RolCuenta.empleados) {
    test(
      '${rol.name}: deniega cada escritura ajena a su rol sin modificar datos',
      () async {
        final repo = await caso.entrar(rol);
        final producto = (await repo.obtenerTodos()).single;
        final db = await caso.base.abrir;
        Future<List<Object?>> estado() async => [
          await db.query('productos'),
          await db.query('operaciones'),
          await db.query('movimientos'),
          await db.query('gastos'),
        ];
        final antes = await estado();
        if (!rol.permite(Permiso.gestionarProductos)) {
          await expectLater(
            repo.crearProducto(nombre: 'Nuevo', costoCompra: 1, precioVenta: 2),
            throwsA(isA<AccesoException>()),
          );
          await expectLater(
            repo.actualizarProducto(
              id: producto.id,
              nombre: 'Alterado',
              costoCompra: 1,
              precioVenta: 2,
            ),
            throwsA(isA<AccesoException>()),
          );
        }
        for (final tipo in TipoOperacion.values) {
          final permiso = switch (tipo) {
            TipoOperacion.inicial ||
            TipoOperacion.ajuste => Permiso.gestionarExistencias,
            TipoOperacion.compra => Permiso.registrarCompras,
            TipoOperacion.venta => Permiso.registrarVentas,
          };
          if (!rol.permite(permiso)) {
            await expectLater(
              repo.confirmarOperacion(
                SolicitudOperacion(
                  id: 'denegada-${tipo.name}',
                  tipo: tipo,
                  motivo: 'Prueba',
                  lineas: [
                    LineaOperacion(
                      productoId: producto.id,
                      cantidad: 1,
                      valorUnitario: 50,
                    ),
                  ],
                ),
              ),
              throwsA(isA<AccesoException>()),
            );
          }
        }
        await expectLater(
          repo.registrarGasto(
            SolicitudGasto(
              id: 'gasto-denegado',
              fecha: fechaRoles,
              concepto: 'Transporte',
              categoria: 'Otros',
              valor: 10,
            ),
          ),
          throwsA(isA<AccesoException>()),
        );
        expect(await estado(), antes);
      },
    );
  }

  test('vendedor recibe costos cero y solo sus ventas; el reporte conserva el costo real', () async {
    final repo = await caso.entrar(RolCuenta.vendedor);
    final producto = (await repo.obtenerTodos()).single;
    expect(producto.costoCompra, 0);
    expect((await repo.obtenerPorId(producto.id))!.costoCompra, 0);
    final venta = SolicitudOperacion(
      id: 'venta-empleado',
      tipo: TipoOperacion.venta,
      lineas: [
        LineaOperacion(productoId: producto.id, cantidad: 2, valorUnitario: 50),
      ],
    );
    final confirmada = await repo.confirmarOperacion(venta);
    expect(confirmada.costoVentasCentavos, 0);
    expect(confirmada.detalles.single['costoCatalogoCentavos'], 0);
    expect((await repo.confirmarOperacion(venta)).costoVentasCentavos, 0);
    final ventas = await repo.obtenerOperaciones(tipo: TipoOperacion.venta);
    expect(ventas.map((v) => v.id), ['venta-empleado']);
    expect(ventas.single.costoVentasCentavos, 0);
    for (final consulta in [
      () => repo.obtenerOperaciones(),
      () => repo.obtenerOperaciones(tipo: TipoOperacion.compra),
      () => repo.obtenerGastos(),
      () => repo.obtenerReporte(periodo),
    ]) {
      await expectLater(consulta(), throwsA(isA<AccesoException>()));
    }
    final duena = await caso.entrar(RolCuenta.propietario);
    final reporte = await duena.obtenerReporte(periodo);
    expect(reporte.costoVentasCentavos, 9000);
    expect(reporte.numeroVentas, 2);
    final nombres = await repo.obtenerResponsables();
    expect(nombres[repo.usuarioId], 'Vendedor');
    expect(nombres[duena.usuarioId], 'Dueña');
    final ajena = (await duena.obtenerOperaciones(tipo: TipoOperacion.venta))
        .firstWhere((v) => v.id == 'venta-duena');
    await expectLater(
      repo.confirmarOperacion(ajena.solicitud),
      throwsA(isA<AccesoException>()),
    );
  });

  test(
    'encargado registra compras y consulta reportes, consulta solo lee',
    () async {
      final encargado = await caso.entrar(RolCuenta.encargado);
      final producto = (await encargado.obtenerTodos()).single;
      expect(producto.costoCompra, 30);
      await encargado.confirmarOperacion(
        SolicitudOperacion(
          id: 'compra',
          tipo: TipoOperacion.compra,
          lineas: [
            LineaOperacion(
              productoId: producto.id,
              cantidad: 3,
              valorUnitario: 30,
            ),
          ],
        ),
      );
      expect((await encargado.obtenerReporte(periodo)).comprasCentavos, 9000);
      final consulta = await caso.entrar(RolCuenta.consulta);
      expect(
        (await consulta.obtenerOperaciones(tipo: TipoOperacion.compra)).length,
        1,
      );
      expect(
        (await consulta.obtenerOperaciones(tipo: TipoOperacion.venta)).length,
        1,
      );
      expect((await consulta.obtenerReporte(periodo)).comprasCentavos, 9000);
      expect(await consulta.obtenerGastos(), isEmpty);
      expect(await consulta.obtenerMovimientos(), isNotEmpty);
    },
  );
}
