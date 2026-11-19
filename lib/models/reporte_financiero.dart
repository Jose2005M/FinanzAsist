import 'fecha_negocio.dart';
import 'gasto.dart';
import 'operacion.dart';

class PeriodoReporte {
  PeriodoReporte({required DateTime desde, required DateTime hasta})
    : desde = FechaNegocio.dia(desde),
      hasta = FechaNegocio.dia(hasta) {
    final error = validar(desde, hasta);
    if (error != null) throw ReglaNegocioException(error);
  }
  final DateTime desde;
  final DateTime hasta;
  DateTime get inicioUtc => DateTime.utc(desde.year, desde.month, desde.day, 5);
  DateTime get finExclusivoUtc =>
      DateTime.utc(hasta.year, hasta.month, hasta.day + 1, 5);

  static String? validar(DateTime? desde, DateTime? hasta) {
    if (!FechaNegocio.valida(desde) || !FechaNegocio.valida(hasta)) {
      return 'Selecciona las dos fechas del período';
    }
    if (FechaNegocio.dia(desde!).isAfter(FechaNegocio.dia(hasta!))) {
      return 'La fecha inicial no puede ser posterior a la final';
    }
    return null;
  }

  bool incluyeInstante(DateTime fecha) =>
      !fecha.toUtc().isBefore(inicioUtc) &&
      fecha.toUtc().isBefore(finExclusivoUtc);
  bool incluyeDia(DateTime fecha) =>
      !FechaNegocio.dia(fecha).isBefore(desde) &&
      !FechaNegocio.dia(fecha).isAfter(hasta);
}

class ReporteFinanciero {
  const ReporteFinanciero({
    required this.periodo,
    required this.ventasCentavos,
    required this.descuentosCentavos,
    required this.comprasCentavos,
    required this.gastosCentavos,
    required this.costoVentasCentavos,
    required this.numeroVentas,
    required this.numeroCompras,
    required this.numeroGastos,
  });
  final PeriodoReporte periodo;
  final int ventasCentavos;
  final int descuentosCentavos;
  final int comprasCentavos;
  final int gastosCentavos;
  final int costoVentasCentavos;
  final int numeroVentas;
  final int numeroCompras;
  final int numeroGastos;
  int get ingresosNetosCentavos => ventasCentavos - descuentosCentavos;
  int get egresosCentavos => sumarCentavos(comprasCentavos, gastosCentavos);
  int get utilidadBrutaCentavos => ingresosNetosCentavos - costoVentasCentavos;
  int get utilidadResultanteCentavos =>
      sumarCentavos(utilidadBrutaCentavos, -gastosCentavos);
  bool get sinOperaciones => numeroVentas + numeroCompras + numeroGastos == 0;

  factory ReporteFinanciero.calcular({
    required PeriodoReporte periodo,
    required String empresaId,
    required Iterable<Operacion> operaciones,
    required Iterable<Gasto> gastos,
  }) {
    var ventas = 0, descuentos = 0, compras = 0, costo = 0, egresosGastos = 0;
    var nVentas = 0, nCompras = 0, nGastos = 0;
    for (final operacion in operaciones) {
      if (operacion.empresaId != empresaId ||
          !periodo.incluyeInstante(operacion.fecha)) {
        continue;
      }
      if (operacion.tipo == TipoOperacion.venta) {
        ventas = sumarCentavos(ventas, operacion.subtotalCentavos);
        descuentos = sumarCentavos(descuentos, operacion.descuentoCentavos);
        costo = sumarCentavos(costo, operacion.costoVentasCentavos);
        nVentas++;
      } else if (operacion.tipo == TipoOperacion.compra) {
        compras = sumarCentavos(compras, operacion.totalCentavos);
        nCompras++;
      }
    }
    for (final gasto in gastos) {
      if (gasto.empresaId == empresaId && periodo.incluyeDia(gasto.fecha)) {
        egresosGastos = sumarCentavos(egresosGastos, gasto.valorCentavos);
        nGastos++;
      }
    }
    final reporte = ReporteFinanciero(
      periodo: periodo,
      ventasCentavos: ventas,
      descuentosCentavos: descuentos,
      comprasCentavos: compras,
      gastosCentavos: egresosGastos,
      costoVentasCentavos: costo,
      numeroVentas: nVentas,
      numeroCompras: nCompras,
      numeroGastos: nGastos,
    );
    // Comprueba también los resultados derivados antes de publicar el reporte.
    reporte.egresosCentavos;
    reporte.utilidadResultanteCentavos;
    return reporte;
  }
}
