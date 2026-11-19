import '../models/operacion.dart';
import '../models/gasto.dart';
import '../models/reporte_financiero.dart';
import 'producto_repository.dart';

abstract interface class NegocioRepository implements ProductoRepository {
  String get empresaId;
  String get usuarioId;
  Future<Map<String, String>> obtenerResponsables();
  Future<Operacion> confirmarOperacion(SolicitudOperacion solicitud);
  Future<List<Operacion>> obtenerOperaciones({TipoOperacion? tipo});
  Future<List<MovimientoInventario>> obtenerMovimientos({String? productoId});
  Future<Gasto> registrarGasto(SolicitudGasto solicitud);
  Future<List<Gasto>> obtenerGastos({PeriodoReporte? periodo});
  Future<ReporteFinanciero> obtenerReporte(PeriodoReporte periodo);
}
