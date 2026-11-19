import 'package:sqflite/sqflite.dart';

import 'autenticacion_local.dart';
import 'base_datos_local.dart';
import 'claves.dart';

/// Proyección pública de la cuenta: nunca contiene sal ni hash.
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

  /// Nombre de la persona, sea propietaria, trabajadora o administradora.
  final String propietario;
  final String correo;
  final RolCuenta rol;
  final bool activa;

  factory CuentaResumen.deSesion(SesionEmpresa sesion) => CuentaResumen(
    id: sesion.cuentaId,
    empresa: sesion.empresa,
    propietario: sesion.propietario,
    correo: sesion.correo,
    rol: sesion.rol,
    activa: true,
  );
}

class EmpresaDispositivo {
  const EmpresaDispositivo({
    required this.id,
    required this.nombre,
    required this.cuentas,
  });
  final String id;
  final String nombre;
  final List<CuentaResumen> cuentas;
}

abstract interface class GestionDispositivo {
  Future<List<EmpresaDispositivo>> listarEmpresas();
  Future<void> cambiarEstado(String cuentaId, {required bool activa});
  Future<void> restablecerClave(String cuentaId, String nuevaClave);
}

class AdministracionDispositivo implements GestionDispositivo {
  AdministracionDispositivo({required this.base, required this.sesion});
  final BaseDatosLocal base;
  final SesionEmpresa sesion;

  Future<T> _autorizado<T>(Future<T> Function(Transaction) accion) async =>
      (await base.abrir).transaction((tx) async {
        await sesion.verificar(tx, permiso: Permiso.administrarDispositivo);
        return accion(tx);
      });

  @override
  Future<List<EmpresaDispositivo>> listarEmpresas() => _autorizado((tx) async {
    final filas = await tx.query(
      'cuentas',
      columns: [
        'id',
        'empresa',
        'nombre_empresa',
        'nombre',
        'correo',
        'rol',
        'activa',
      ],
      where: "empresa NOT IN (SELECT empresa FROM cuentas WHERE rol = 'administrador')",
      orderBy:
          "nombre_empresa COLLATE NOCASE, empresa, "
          "CASE rol WHEN 'propietario' THEN 0 ELSE 1 END, nombre COLLATE NOCASE, correo",
    );
    final grupos = <String, List<CuentaResumen>>{};
    for (final fila in filas) {
      grupos
          .putIfAbsent(fila['empresa'] as String, () => [])
          .add(
            CuentaResumen(
              id: fila['id'] as String,
              empresa: fila['nombre_empresa'] as String,
              propietario: fila['nombre'] as String,
              correo: fila['correo'] as String,
              rol: RolCuenta.values.byName(fila['rol'] as String),
              activa: fila['activa'] == 1,
            ),
          );
    }
    return List.unmodifiable([
      for (final grupo in grupos.entries)
        EmpresaDispositivo(
          id: grupo.key,
          nombre: grupo.value.first.empresa,
          cuentas: List.unmodifiable(grupo.value),
        ),
    ]);
  });

  Future<void> _cuentaModificable(DatabaseExecutor tx, String id) async {
    final filas = await tx.query(
      'cuentas',
      columns: ['rol'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (filas.isEmpty) throw const AccesoException('La cuenta no existe.');
    if (filas.single['rol'] == RolCuenta.administrador.name) {
      throw const AccesoException(
        'No puedes modificar cuentas de administrador.',
      );
    }
  }

  @override
  Future<void> cambiarEstado(String cuentaId, {required bool activa}) =>
      _autorizado((tx) async {
        await _cuentaModificable(tx, cuentaId);
        await tx.update(
          'cuentas',
          {'activa': activa ? 1 : 0},
          where: 'id = ?',
          whereArgs: [cuentaId],
        );
      });

  @override
  Future<void> restablecerClave(String cuentaId, String nuevaClave) async {
    await _autorizado((tx) async {
      await _cuentaModificable(tx, cuentaId);
      final error = DatosRegistro.validarClave(nuevaClave);
      if (error != null) throw AccesoException(error);
    });
    final clave = await Claves.nueva(nuevaClave);
    await _autorizado((tx) async {
      await _cuentaModificable(tx, cuentaId);
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
}
