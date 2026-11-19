import 'dart:async';

import 'package:finanzasist/data/repositorio_simulado.dart';
import 'package:finanzasist/models/fecha_negocio.dart';
import 'package:finanzasist/models/gasto.dart';
import 'package:finanzasist/models/reporte_financiero.dart';
import 'package:finanzasist/viewmodels/gastos_view_model.dart';
import 'package:finanzasist/viewmodels/reportes_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Error al guardar gasto libera bloqueo y permite reintentar con el mismo id', () async {
    final repo = _FalloGasto();
    final vm = FormularioGastoViewModel(repo)
      ..fecha = FechaNegocio.hoy()
      ..concepto = 'Energía'
      ..categoria = 'Servicios'
      ..valor = '80000';
    addTearDown(vm.dispose);
    expect(await vm.guardar(), isNull);
    expect(vm.guardando, isFalse);
    expect(vm.error, contains('reintentar'));
    final gasto = await vm.guardar();
    expect(gasto!.id, vm.id);
    expect(await repo.obtenerGastos(), hasLength(1));
  });

  test(
    'Una respuesta vieja no reemplaza el reporte del período más reciente',
    () async {
      final repo = _ReportesControlados();
      final vm = ReportesViewModel(repo, ahora: DateTime.utc(2026, 11, 10, 15));
      addTearDown(vm.dispose);
      final primera = vm.consultar();
      vm.cambiarFechas(
        inicio: DateTime.utc(2026, 10),
        fin: DateTime.utc(2026, 10, 31),
      );
      final segunda = vm.consultar();
      repo.solicitudes[1].complete(_vacio(repo.periodos[1]));
      await segunda;
      repo.solicitudes[0].complete(_vacio(repo.periodos[0]));
      await primera;
      expect(vm.reporte!.periodo.desde, DateTime.utc(2026, 10));
      expect(vm.cargando, isFalse);
    },
  );

  test(
    'Reporte no consulta intervalos inválidos y permite recuperar errores',
    () async {
      final repo = _ReportesControlados();
      final vm = ReportesViewModel(repo, ahora: DateTime.utc(2026, 11, 10, 15));
      addTearDown(vm.dispose);
      vm.cambiarFechas(inicio: DateTime.utc(2026, 11, 20));
      await vm.consultar();
      expect(repo.solicitudes, isEmpty);
      expect(vm.error, contains('posterior'));
      vm.cambiarFechas(inicio: DateTime.utc(2026, 11));
      final fallida = vm.consultar();
      repo.solicitudes.last.completeError(Exception('sin conexión'));
      await fallida;
      expect(vm.error, contains('Reintenta'));
      final reintento = vm.consultar();
      repo.solicitudes.last.complete(_vacio(repo.periodos.last));
      await reintento;
      expect(vm.reporte, isNotNull);
      expect(vm.error, isNull);
    },
  );

  test(
    'Cerrar reporte durante consulta no notifica después de dispose',
    () async {
      final repo = _ReportesControlados();
      final vm = ReportesViewModel(repo);
      final carga = vm.consultar();
      vm.dispose();
      repo.solicitudes.last.complete(_vacio(repo.periodos.last));
      await carga;
    },
  );
}

ReporteFinanciero _vacio(PeriodoReporte periodo) => ReporteFinanciero.calcular(
  periodo: periodo,
  empresaId: 'negocio-local',
  operaciones: [],
  gastos: [],
);

class _ReportesControlados extends RepositorioSimulado {
  final solicitudes = <Completer<ReporteFinanciero>>[];
  final periodos = <PeriodoReporte>[];
  @override
  Future<ReporteFinanciero> obtenerReporte(PeriodoReporte periodo) {
    periodos.add(periodo);
    final solicitud = Completer<ReporteFinanciero>();
    solicitudes.add(solicitud);
    return solicitud.future;
  }
}

class _FalloGasto extends RepositorioSimulado {
  _FalloGasto() : super(retardo: Duration.zero);
  bool _primero = true;
  @override
  Future<Gasto> registrarGasto(SolicitudGasto solicitud) {
    if (_primero) {
      _primero = false;
      throw Exception('fallo de escritura');
    }
    return super.registrarGasto(solicitud);
  }
}
