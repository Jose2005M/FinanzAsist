@Timeout.factor(4)
library;

import 'package:finanzasist/data/respaldo_local.dart';
import 'package:finanzasist/models/permisos.dart';
import 'package:flutter_test/flutter_test.dart';

import 'soporte_roles.dart';

void main() {
  final plantilla = PlantillaRoles();
  late CasoRoles caso;
  setUpAll(plantilla.crear);
  tearDownAll(plantilla.cerrar);
  setUp(() async {
    caso = await plantilla.copiar();
  });
  tearDown(() => caso.cerrar());

  test(
    'propietario con empleados exporta y restaura; empleados no pueden',
    () async {
      await caso.entrar(RolCuenta.propietario);
      final duena = caso.accesos.last.sesion!;
      final respaldo = RespaldoLocal(base: caso.base);
      final bytes = await respaldo.exportar(sesion: duena);
      expect(bytes, isNotEmpty);
      for (final rol in RolCuenta.empleados) {
        await caso.entrar(rol);
        final sesion = caso.accesos.last.sesion!;
        await expectLater(
          respaldo.exportar(sesion: sesion),
          throwsA(isA<RespaldoException>()),
        );
        await expectLater(
          respaldo.restaurar(bytes, sesion: sesion),
          throwsA(isA<RespaldoException>()),
        );
      }
      await respaldo.restaurar(bytes, sesion: duena);
      expect(await (await caso.base.abrir).query('cuentas'), hasLength(4));
    },
  );
}
