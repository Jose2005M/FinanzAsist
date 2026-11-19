import 'package:sqflite/sqflite.dart';

import 'autenticacion_local.dart';
import 'base_datos_local.dart';
import 'claves.dart';

/// Datos visibles de una cuenta. Nunca incluye la sal ni el hash.
class CuentaResumen {
  const CuentaResumen({
    required this.id,
    required this.empresa,
    required this.propietario,
    required this.correo,
    required this.rol,
    required this.activa,
  });

  final String id;
  final String empresa;
  final String propietario;
  final String correo;
  final RolCuenta rol;
  final bool activa;
}

/// Acciones del panel de administración sobre las cuentas del dispositivo.
abstract interface class GestionCuentas {
  Future<List<CuentaResumen>> listarCuentas();
  Future<void> cambiarEstado(String cuentaId, {required bool activa});
  Future<void> restablecerClave(String cuentaId, String nuevaClave);
}

/// Gestión de las cuentas del dispositivo. Cada acción verifica, dentro de
/// su transacción, que la sesión sea la del administrador activo.
class AdministracionLocal implements GestionCuentas {
  AdministracionLocal({required this.base, required this.sesion});

  final BaseDatosLocal base;
  final SesionEmpresa sesion;

  static const _soloPropietarios =
      'Solo se pueden modificar cuentas de propietario.';

  Future<T> _comoAdministrador<T>(
    Future<T> Function(Transaction tx) accion,
  ) async => (await base.abrir).transaction((tx) async {
    await sesion.verificarAdministrador(tx);
    return accion(tx);
  });

  @override
  Future<List<CuentaResumen>> listarCuentas() => _comoAdministrador((tx) async {
    final filas = await tx.query(
      'cuentas',
      columns: ['id', 'nombre_empresa', 'nombre', 'correo', 'rol', 'activa'],
      orderBy:
          "CASE rol WHEN 'administrador' THEN 0 ELSE 1 END, "
          'nombre_empresa COLLATE NOCASE, correo',
    );
    return List.unmodifiable(
      filas.map(
        (fila) => CuentaResumen(
          id: fila['id'] as String,
          empresa: fila['nombre_empresa'] as String,
          propietario: fila['nombre'] as String,
          correo: fila['correo'] as String,
          rol: RolCuenta.values.byName(fila['rol'] as String),
          activa: fila['activa'] == 1,
        ),
      ),
    );
  });

  /// Una cuenta desactivada no puede entrar y su sesión abierta deja de
  /// valer en la siguiente operación. Sus datos se conservan.
  @override
  Future<void> cambiarEstado(String cuentaId, {required bool activa}) =>
      _comoAdministrador((tx) async {
        await _propietaria(tx, cuentaId);
        await tx.update(
          'cuentas',
          {'activa': activa ? 1 : 0},
          where: 'id = ?',
          whereArgs: [cuentaId],
        );
      });

  @override
  Future<void> restablecerClave(String cuentaId, String nuevaClave) async {
    final error = DatosRegistro.validarClave(nuevaClave);
    if (error != null) throw AccesoException(error);
    // Comprueba permisos antes del cálculo costoso y otra vez al guardar.
    await _comoAdministrador((tx) => _propietaria(tx, cuentaId));
    final clave = await Claves.nueva(nuevaClave);
    await _comoAdministrador((tx) async {
      await _propietaria(tx, cuentaId);
      await tx.update(
        'cuentas',
        {
          'sal': clave.sal,
          'hash': clave.hash,
          'iteraciones': Claves.iteraciones,
        },
        where: 'id = ?',
        whereArgs: [cuentaId],
      );
    });
  }

  Future<void> _propietaria(DatabaseExecutor db, String cuentaId) async {
    final filas = await db.query(
      'cuentas',
      columns: ['rol'],
      where: 'id = ?',
      whereArgs: [cuentaId],
    );
    if (filas.isEmpty) throw const AccesoException('La cuenta no existe.');
    if (filas.single['rol'] != RolCuenta.propietario.name) {
      throw const AccesoException(_soloPropietarios);
    }
  }
}
