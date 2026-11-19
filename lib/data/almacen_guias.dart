import 'package:sqflite/sqflite.dart';

import '../models/guia_modulo.dart';
import 'autenticacion_local.dart';
import 'base_datos_local.dart';

abstract interface class AlmacenGuias {
  Future<Set<ModuloGuia>> leerVistas();
  Future<void> marcarVista(ModuloGuia modulo);
}

class AlmacenGuiasMemoria implements AlmacenGuias {
  AlmacenGuiasMemoria({Set<ModuloGuia> vistas = const {}})
    : _vistas = Set.of(vistas);
  final Set<ModuloGuia> _vistas;

  @override
  Future<Set<ModuloGuia>> leerVistas() async => Set.of(_vistas);

  @override
  Future<void> marcarVista(ModuloGuia modulo) async => _vistas.add(modulo);
}

/// Preferencia de ayuda por cuenta; no modifica registros del negocio.
class AlmacenGuiasSqlite implements AlmacenGuias {
  AlmacenGuiasSqlite({required this.base, required this.sesion});
  final BaseDatosLocal base;
  final SesionEmpresa sesion;

  @override
  Future<Set<ModuloGuia>> leerVistas() async =>
      (await base.abrir).transaction((tx) async {
        await sesion.verificar(tx);
        final filas = await tx.query(
          'guias_vistas',
          columns: ['modulo'],
          where: 'cuenta = ?',
          whereArgs: [sesion.cuentaId],
        );
        final nombres = filas.map((f) => f['modulo']).toSet();
        return ModuloGuia.values.where((m) => nombres.contains(m.name)).toSet();
      });

  @override
  Future<void> marcarVista(ModuloGuia modulo) async =>
      (await base.abrir).transaction((tx) async {
        await sesion.verificar(tx);
        await tx.insert('guias_vistas', {
          'cuenta': sesion.cuentaId,
          'modulo': modulo.name,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      });
}
