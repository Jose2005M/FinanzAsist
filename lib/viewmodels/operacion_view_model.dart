import 'package:flutter/foundation.dart';

import '../data/negocio_repository.dart';
import '../models/operacion.dart';
import '../models/producto.dart';
import '../models/reglas_inventario.dart';
import '../models/validacion_producto.dart';

class BorradorLinea {
  BorradorLinea({this.productoId, this.cantidad = '', this.valor = ''});
  String? productoId;
  String cantidad;
  String valor;
}

class OperacionViewModel extends ChangeNotifier {
  OperacionViewModel(this.repositorio, this.tipo, {String? productoId})
    : lineas = [BorradorLinea(productoId: productoId)];
  final NegocioRepository repositorio;
  final TipoOperacion tipo;
  final String operacionId = nuevoId();
  final List<BorradorLinea> lineas;
  List<Producto> productos = const [];
  List<MovimientoInventario> movimientos = const [];
  bool cargando = true;
  bool guardando = false;
  bool _cerrado = false;
  String? errorCarga;
  String? error;
  String motivo = '';
  String descuento = '0';
  bool get manual =>
      tipo == TipoOperacion.inicial || tipo == TipoOperacion.ajuste;

  void _notificar() {
    if (!_cerrado) notifyListeners();
  }

  Future<void> cargar({bool mostrarCarga = true}) async {
    if (mostrarCarga) cargando = true;
    errorCarga = null;
    _notificar();
    try {
      productos = await repositorio.obtenerTodos();
      movimientos = await repositorio.obtenerMovimientos();
      for (final linea in lineas) {
        final producto = productoDe(linea);
        if (producto != null && linea.valor.isEmpty) {
          seleccionar(linea, producto.id);
        }
      }
    } catch (_) {
      errorCarga = 'No pudimos cargar los productos. Reintenta la consulta.';
    }
    cargando = false;
    _notificar();
  }

  Producto? productoDe(BorradorLinea linea) {
    for (final p in productos) {
      if (p.id == linea.productoId) return p;
    }
    return null;
  }

  void seleccionar(BorradorLinea linea, String id) {
    linea.productoId = id;
    final producto = productoDe(linea);
    linea.valor =
        (tipo == TipoOperacion.compra
                ? producto?.costoCompra
                : producto?.precioVenta)
            ?.toString() ??
        '0';
    _notificar();
  }

  String? validarProducto(BorradorLinea linea) {
    final producto = productoDe(linea);
    if (producto == null) return 'Selecciona un producto';
    if (tipo == TipoOperacion.inicial &&
        (producto.cantidad != 0 ||
            movimientos.any((m) => m.productoId == producto.id))) {
      return 'Ya tiene movimientos; utiliza un ajuste';
    }
    if (lineas.where((l) => l.productoId == linea.productoId).length > 1) {
      return 'El producto ya está en otra línea';
    }
    return null;
  }

  String? validarCantidad(BorradorLinea linea) {
    final error = ReglasInventario.cantidad(
      linea.cantidad,
      ajuste: tipo == TipoOperacion.ajuste,
      inicial: tipo == TipoOperacion.inicial,
    );
    if (error != null) return error;
    final producto = productoDe(linea);
    final cantidad = int.parse(linea.cantidad.trim());
    final valor = ValidacionProducto.leerImporte(linea.valor);
    if (!manual &&
        valor != null &&
        ReglasInventario.importe(linea.valor) == null) {
      final unitario = centavos(valor);
      if (unitario > 0 &&
          cantidad > ReglasInventario.maximoExacto ~/ unitario) {
        return 'El total de la línea es demasiado grande';
      }
    }
    if (producto != null &&
        ((tipo == TipoOperacion.venta && cantidad > producto.cantidad) ||
            (tipo == TipoOperacion.ajuste &&
                cantidad + producto.cantidad < 0))) {
      return 'No hay existencias suficientes';
    }
    return null;
  }

  int get subtotalCentavos => manual
      ? 0
      : lineas.fold(0, (total, l) {
          final valor = ValidacionProducto.leerImporte(l.valor);
          final cantidad = int.tryParse(l.cantidad.trim());
          if (valor == null ||
              !valor.isFinite ||
              cantidad == null ||
              cantidad <= 0 ||
              ReglasInventario.cantidad(l.cantidad) != null ||
              ReglasInventario.importe(l.valor) != null) {
            return total;
          }
          final unitario = centavos(valor);
          if (unitario > 0 &&
              cantidad > ReglasInventario.maximoExacto ~/ unitario) {
            return total;
          }
          final totalLinea = unitario * cantidad;
          if (total > ReglasInventario.maximoExacto - totalLinea) return total;
          return total + totalLinea;
        });
  int get descuentoCentavos {
    final valor = ValidacionProducto.leerImporte(descuento);
    return valor == null ||
            !valor.isFinite ||
            ReglasInventario.importe(descuento) != null
        ? 0
        : centavos(valor);
  }

  String? validarDescuento(String? texto) {
    final error = ReglasInventario.importe(texto);
    if (error != null) return error;
    if (centavos(ValidacionProducto.leerImporte(texto)!) > subtotalCentavos) {
      return 'El descuento debe estar entre cero y el subtotal';
    }
    return null;
  }

  void actualizar() => _notificar();

  SolicitudOperacion solicitud() => SolicitudOperacion(
    id: operacionId,
    tipo: tipo,
    lineas: lineas
        .map(
          (l) => LineaOperacion(
            productoId: l.productoId ?? '',
            cantidad: int.tryParse(l.cantidad.trim()) ?? 0,
            valorUnitario: manual
                ? 0
                : ValidacionProducto.leerImporte(l.valor) ?? -1,
          ),
        )
        .toList(),
    motivo: motivo,
    descuento: tipo == TipoOperacion.venta
        ? ValidacionProducto.leerImporte(descuento) ?? -1
        : 0,
  );

  Future<Operacion?> confirmar() async {
    if (guardando || _cerrado) return null;
    guardando = true;
    error = null;
    _notificar();
    try {
      return await repositorio.confirmarOperacion(solicitud());
    } on ReglaNegocioException catch (e) {
      error = e.mensaje;
    } catch (_) {
      error = 'No pudimos confirmar. Conservamos los datos para reintentar.';
    } finally {
      guardando = false;
      _notificar();
    }
    return null;
  }

  @override
  void dispose() {
    _cerrado = true;
    super.dispose();
  }
}
