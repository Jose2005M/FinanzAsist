import 'package:sqflite/sqflite.dart';

import '../models/operacion.dart';
import 'autenticacion_local.dart';
import 'base_datos_local.dart';
import 'claves.dart';

/// Datos visibles de una cuenta; nunca expone sal, hash ni contraseña.
class UsuarioEmpresa {
  const UsuarioEmpresa({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.activa,
  });
  final String id;
  final String nombre;
  final String correo;
  final RolCuenta rol;
  final bool activa;
}

class DatosUsuario {
  const DatosUsuario({
    required this.nombre,
    required this.correo,
    required this.clave,
    required this.rol,
  });
  final String nombre;
  final String correo;
  final String clave;
  final RolCuenta rol;

  void validar() {
    for (final error in [
      DatosRegistro.validarNombre(nombre, 'el nombre del usuario', 100),
      DatosRegistro.validarCorreo(correo),
      DatosRegistro.validarClave(clave),
    ]) {
      if (error != null) throw AccesoException(error);
    }
    _validarRolEmpleado(rol);
  }
}

void _validarRolEmpleado(RolCuenta rol) {
  if (!RolCuenta.empleados.contains(rol)) {
    throw const AccesoException('Solo puedes asignar roles de empleado.');
  }
}

abstract interface class GestionUsuariosEmpresa {
  Future<List<UsuarioEmpresa>> listarUsuarios();
  Future<void> crearUsuario(DatosUsuario datos);
  Future<void> cambiarEstado(String cuentaId, {required bool activa});
  Future<void> cambiarRol(String cuentaId, RolCuenta rol);
  Future<void> restablecerClave(String cuentaId, String nuevaClave);
}

/// Cada operación se autoriza en la misma transacción que consulta o modifica.
class UsuariosEmpresa implements GestionUsuariosEmpresa {
  UsuariosEmpresa({required this.base, required this.sesion});
  final BaseDatosLocal base;
  final SesionEmpresa sesion;

  Future<T> _autorizado<T>(Future<T> Function(Transaction) accion) async =>
      (await base.abrir).transaction((tx) async {
        await sesion.verificar(tx, permiso: Permiso.gestionarUsuarios);
        return accion(tx);
      });

  @override
  Future<List<UsuarioEmpresa>> listarUsuarios() => _autorizado((tx) async {
    final filas = await tx.query(
      'cuentas',
      columns: ['id', 'nombre', 'correo', 'rol', 'activa'],
      where: 'empresa = ?',
      whereArgs: [sesion.empresaId],
      orderBy: "CASE rol WHEN 'propietario' THEN 0 ELSE 1 END, nombre COLLATE NOCASE, correo",
    );
    return List.unmodifiable(
      filas.map(
        (fila) => UsuarioEmpresa(
          id: fila['id'] as String,
          nombre: fila['nombre'] as String,
          correo: fila['correo'] as String,
          rol: RolCuenta.values.byName(fila['rol'] as String),
          activa: fila['activa'] == 1,
        ),
      ),
    );
  });

  Future<void> _correoDisponible(DatabaseExecutor tx, String correo) async {
    if ((await tx.query(
      'cuentas',
      columns: ['id'],
      where: 'correo = ?',
      whereArgs: [correo],
    )).isNotEmpty) {
      throw const AccesoException('Este correo ya tiene una cuenta.');
    }
  }

  @override
  Future<void> crearUsuario(DatosUsuario datos) async {
    // Autorizar antes del cálculo costoso y repetir al guardar evita carreras.
    final correo = DatosRegistro.normalizarCorreo(datos.correo);
    await _autorizado((tx) async {
      datos.validar();
      await _correoDisponible(tx, correo);
    });
    final clave = await Claves.nueva(datos.clave);
    await _autorizado((tx) async {
      await _correoDisponible(tx, correo);
      final usuario = nuevoId();
      await tx.insert('usuarios', {'empresa': sesion.empresaId, 'id': usuario});
      await tx.insert('cuentas', {
        'id': nuevoId(),
        'empresa': sesion.empresaId,
        'usuario': usuario,
        'nombre_empresa': sesion.empresa,
        'nombre': datos.nombre.trim(),
        'correo': correo,
        'sal': clave.sal,
        'hash': clave.hash,
        'iteraciones': Claves.iteraciones,
        'activa': 1,
        'rol': datos.rol.name,
      });
    });
  }

  Future<void> _empleado(DatabaseExecutor tx, String cuentaId) async {
    final filas = await tx.query(
      'cuentas',
      columns: ['rol'],
      where: 'id = ? AND empresa = ?',
      whereArgs: [cuentaId, sesion.empresaId],
    );
    if (filas.isEmpty) {
      throw const AccesoException('El usuario no existe en tu empresa.');
    }
    if (filas.single['rol'] == RolCuenta.propietario.name) {
      throw const AccesoException('No puedes modificar al propietario.');
    }
  }

  Future<void> _actualizar(
    Transaction tx,
    String cuentaId,
    Map<String, Object?> valores,
  ) async {
    await _empleado(tx, cuentaId);
    await tx.update(
      'cuentas',
      valores,
      where: 'id = ? AND empresa = ?',
      whereArgs: [cuentaId, sesion.empresaId],
    );
  }

  @override
  Future<void> cambiarEstado(String cuentaId, {required bool activa}) =>
      _autorizado(
        (tx) => _actualizar(tx, cuentaId, {'activa': activa ? 1 : 0}),
      );

  @override
  Future<void> cambiarRol(String cuentaId, RolCuenta rol) =>
      _autorizado((tx) async {
        _validarRolEmpleado(rol);
        await _actualizar(tx, cuentaId, {'rol': rol.name});
      });

  @override
  Future<void> restablecerClave(String cuentaId, String nuevaClave) async {
    await _autorizado((tx) async {
      await _empleado(tx, cuentaId);
      final error = DatosRegistro.validarClave(nuevaClave);
      if (error != null) throw AccesoException(error);
    });
    final clave = await Claves.nueva(nuevaClave);
    await _autorizado(
      (tx) => _actualizar(tx, cuentaId, {
        'sal': clave.sal,
        'hash': clave.hash,
        'iteraciones': Claves.iteraciones,
      }),
    );
  }
}
