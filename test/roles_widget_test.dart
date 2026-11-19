import 'package:finanzasist/data/repositorio_simulado.dart';
import 'package:finanzasist/models/permisos.dart';
import 'package:finanzasist/screens/negocio_screen.dart';
import 'package:finanzasist/widgets/permisos_sesion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final rol in [RolCuenta.propietario, ...RolCuenta.empleados]) {
    testWidgets('pestañas y acciones de ${rol.name}', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PermisosSesion(
            rol: rol,
            child: NegocioScreen(repositorio: RepositorioSimulado()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('modulo-inventario')), findsOneWidget);
      expect(find.byKey(const ValueKey('modulo-ventas')), findsOneWidget);
      for (final modulo in ['compras', 'gastos', 'reportes']) {
        expect(
          find.byKey(ValueKey('modulo-$modulo')),
          rol == RolCuenta.vendedor ? findsNothing : findsOneWidget,
        );
      }
      expect(
        find.byTooltip('Registrar producto'),
        rol.permite(Permiso.gestionarProductos) ? findsOneWidget : findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('modulo-ventas')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('nueva-venta')),
        rol.permite(Permiso.registrarVentas) ? findsOneWidget : findsNothing,
      );
      if (rol == RolCuenta.vendedor) {
        expect(find.text('Tus ventas'), findsWidgets);
      }
    });
  }
}
