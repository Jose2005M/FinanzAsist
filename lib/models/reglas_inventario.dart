import 'operacion.dart';
import 'producto.dart';
import '../utils/entrada_importe.dart';

class ResultadoInventario {
  const ResultadoInventario(this.operacion, this.productos, this.movimientos);
  final Operacion operacion;
  final List<Producto> productos;
  final List<MovimientoInventario> movimientos;
}

class ReglasInventario {
  static const maximoExacto = 9007199254740991;
  static String? cantidad(
    String? texto, {
    bool ajuste = false,
    bool inicial = false,
  }) {
    final numero = int.tryParse(texto?.trim() ?? '');
    if (numero == null) return 'Escribe una cantidad entera';
    if (numero > maximoExacto || numero < -maximoExacto) {
      return 'La cantidad es demasiado grande';
    }
    if (ajuste && numero == 0) return 'El ajuste debe ser distinto de cero';
    if (!ajuste && (inicial ? numero < 0 : numero <= 0)) {
      return inicial
          ? 'La cantidad no puede ser negativa'
          : 'La cantidad debe ser mayor que cero';
    }
    return null;
  }

  static String? importe(String? texto) {
    final valor = EntradaImporte.leer(texto);
    if (valor == null || !valor.isFinite) return EntradaImporte.error(texto);
    if (valor < 0) return 'El importe no puede ser negativo';
    if (valor * 100 > 9007199254740991 ||
        (valor * 100 - (valor * 100).round()).abs() > 0.0001) {
      return 'Usa un importe con máximo dos decimales';
    }
    return null;
  }

  static ResultadoInventario aplicar({
    required SolicitudOperacion solicitud,
    required List<Producto> productos,
    required List<MovimientoInventario> movimientos,
    required String empresaId,
    required String usuarioId,
    required DateTime fecha,
  }) {
    void rechazar(String mensaje) => throw ReglaNegocioException(mensaje);
    if (solicitud.id.trim().isEmpty) {
      rechazar('Falta el identificador de operación');
    }
    if (usuarioId.trim().isEmpty) rechazar('Falta el usuario responsable');
    if (solicitud.lineas.isEmpty) rechazar('Agrega al menos un producto');
    final manual =
        solicitud.tipo == TipoOperacion.inicial ||
        solicitud.tipo == TipoOperacion.ajuste;
    if (manual && solicitud.lineas.length != 1) {
      rechazar('Selecciona un solo producto para el ajuste');
    }
    if (manual && solicitud.motivo.trim().isEmpty) {
      rechazar('Indica el motivo del movimiento');
    }
    final ids = <String>{};
    final actualizados = List<Producto>.of(productos);
    final nuevos = <MovimientoInventario>[];
    final detalles = <Map<String, Object?>>[];
    var subtotal = 0;
    var costoTotal = 0;
    for (final linea in solicitud.lineas) {
      if (!ids.add(linea.productoId)) {
        rechazar(
          'Un producto solo puede aparecer una vez; modifica su cantidad',
        );
      }
      final indice = actualizados.indexWhere(
        (p) => p.id == linea.productoId && p.empresaId == empresaId,
      );
      if (indice < 0) rechazar('Selecciona un producto de esta empresa');
      final producto = actualizados[indice];
      final errorCantidad = cantidad(
        linea.cantidad.toString(),
        ajuste: solicitud.tipo == TipoOperacion.ajuste,
        inicial: solicitud.tipo == TipoOperacion.inicial,
      );
      if (errorCantidad != null) rechazar(errorCantidad);
      if (solicitud.tipo == TipoOperacion.venta) {
        costoTotal = sumarCentavos(
          costoTotal,
          multiplicarCentavos(linea.cantidad, centavos(producto.costoCompra)),
        );
      }
      if (solicitud.tipo == TipoOperacion.inicial &&
          (producto.cantidad != 0 ||
              movimientos.any((m) => m.productoId == producto.id))) {
        rechazar('Este producto ya tiene movimientos. Registra un ajuste');
      }
      final errorValor = importe(linea.valorUnitario.toString());
      if (errorValor != null) rechazar(errorValor);
      final delta = solicitud.tipo == TipoOperacion.venta
          ? -linea.cantidad
          : linea.cantidad;
      final saldo = producto.cantidad + delta;
      if (saldo < 0) {
        rechazar(
          solicitud.tipo == TipoOperacion.venta
              ? 'No hay existencias suficientes de ${producto.nombre}'
              : 'El ajuste dejaría existencias negativas',
        );
      }
      actualizados[indice] = producto.conCantidad(saldo);
      if (!manual) {
        final unitario = centavos(linea.valorUnitario);
        if (unitario > 0 && linea.cantidad > maximoExacto ~/ unitario) {
          rechazar('El total de la línea es demasiado grande');
        }
        final totalLinea = linea.cantidad * unitario;
        if (subtotal > maximoExacto - totalLinea) {
          rechazar('El valor de la operación es demasiado grande');
        }
        subtotal += totalLinea;
      }
      if (subtotal > 9007199254740991 || saldo > 9007199254740991) {
        rechazar('El valor de la operación es demasiado grande');
      }
      detalles.add({
        'productoId': producto.id,
        'nombre': producto.nombre,
        'cantidad': linea.cantidad,
        'valorCentavos': centavos(linea.valorUnitario),
        'costoCatalogoCentavos': centavos(producto.costoCompra),
        'costoAsignadoCentavos': centavos(producto.costoCompra),
      });
      nuevos.add(
        MovimientoInventario(
          operacionId: solicitud.id,
          productoId: producto.id,
          empresaId: empresaId,
          usuarioId: usuarioId,
          fecha: fecha,
          tipo: solicitud.tipo,
          cantidad: delta,
          saldo: saldo,
          motivo: manual
              ? solicitud.motivo.trim()
              : solicitud.tipo == TipoOperacion.compra
              ? 'Compra confirmada'
              : 'Venta confirmada',
        ),
      );
    }
    final errorDescuento = importe(solicitud.descuento.toString());
    if (errorDescuento != null) rechazar(errorDescuento);
    final descuento = centavos(solicitud.descuento);
    if (solicitud.tipo != TipoOperacion.venta && descuento != 0) {
      rechazar('Solo las ventas admiten descuento');
    }
    if (descuento > subtotal) {
      rechazar('El descuento debe estar entre cero y el subtotal');
    }
    return ResultadoInventario(
      Operacion(
        solicitud: solicitud,
        empresaId: empresaId,
        usuarioId: usuarioId,
        fecha: fecha,
        subtotalCentavos: subtotal,
        descuentoCentavos: descuento,
        detalles: detalles,
      ),
      actualizados,
      nuevos,
    );
  }
}
