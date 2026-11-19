import 'package:finanzasist/models/permisos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Matriz acordada para HU-03; cualquier cambio de permisos debe verse aquí.
  const matriz = <Permiso, Set<RolCuenta>>{
    Permiso.verCostos: {
      RolCuenta.propietario,
      RolCuenta.encargado,
      RolCuenta.consulta,
    },
    Permiso.gestionarProductos: {RolCuenta.propietario, RolCuenta.encargado},
    Permiso.gestionarExistencias: {RolCuenta.propietario, RolCuenta.encargado},
    Permiso.registrarCompras: {RolCuenta.propietario, RolCuenta.encargado},
    Permiso.verCompras: {
      RolCuenta.propietario,
      RolCuenta.encargado,
      RolCuenta.consulta,
    },
    Permiso.registrarVentas: {RolCuenta.propietario, RolCuenta.vendedor},
    Permiso.verVentasPropias: {
      RolCuenta.propietario,
      RolCuenta.encargado,
      RolCuenta.vendedor,
      RolCuenta.consulta,
    },
    Permiso.verTodasLasVentas: {
      RolCuenta.propietario,
      RolCuenta.encargado,
      RolCuenta.consulta,
    },
    Permiso.registrarGastos: {RolCuenta.propietario},
    Permiso.verGastos: {
      RolCuenta.propietario,
      RolCuenta.encargado,
      RolCuenta.consulta,
    },
    Permiso.verReportes: {
      RolCuenta.propietario,
      RolCuenta.encargado,
      RolCuenta.consulta,
    },
    Permiso.gestionarUsuarios: {RolCuenta.propietario},
    Permiso.gestionarRespaldos: {RolCuenta.propietario},
    Permiso.administrarDispositivo: {RolCuenta.administrador},
  };

  test('la matriz cubre todos los permisos', () {
    expect(matriz.keys.toSet(), Permiso.values.toSet());
  });

  for (final MapEntry(key: permiso, value: roles) in matriz.entries) {
    test('$permiso: ${roles.map((r) => r.name).join(', ')}', () {
      for (final rol in RolCuenta.values) {
        expect(rol.permite(permiso), roles.contains(rol), reason: rol.name);
      }
    });
  }

  test('el propietario no se asigna a empleados', () {
    expect(RolCuenta.empleados, isNot(contains(RolCuenta.propietario)));
    expect(RolCuenta.empleados, isNot(contains(RolCuenta.administrador)));
    expect(RolCuenta.empleados, hasLength(3));
  });
}
