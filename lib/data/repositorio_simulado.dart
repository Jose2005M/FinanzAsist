import 'dart:async';

import '../models/producto.dart';
import '../models/validacion_producto.dart';
import 'producto_repository.dart';

class RepositorioSimulado implements ProductoRepository {
  RepositorioSimulado({
    this.retardo = const Duration(milliseconds: 1500),
    List<Producto>? productosIniciales,
  }) : _ejemplos = List<Producto>.unmodifiable(
         productosIniciales ?? productosEjemplo,
       ),
       _productos = List<Producto>.of(productosIniciales ?? productosEjemplo);

  final Duration retardo;

  // Datos ficticios. Este repositorio no almacena información en el disco.
  static const productosEjemplo = <Producto>[
    Producto(
      id: 'P001',
      nombre: 'Arroz de 1 kg',
      cantidad: 20,
      costoCompra: 3500,
      precioVenta: 4500,
    ),
    Producto(
      id: 'P002',
      nombre: 'Aceite de 1 litro',
      cantidad: 12,
      costoCompra: 7000,
      precioVenta: 9000,
    ),
    Producto(
      id: 'P003',
      nombre: 'Azúcar de 1 kg',
      cantidad: 15,
      costoCompra: 3000,
      precioVenta: 4000,
    ),
    Producto(
      id: 'P004',
      nombre: 'Leche de 1 litro',
      cantidad: 18,
      costoCompra: 3200,
      precioVenta: 4000,
    ),
    Producto(
      id: 'P005',
      nombre: 'Jabón en barra',
      cantidad: 0,
      costoCompra: 2000,
      precioVenta: 3000,
    ),
  ];

  final List<Producto> _ejemplos;
  List<Producto> _productos;
  EscenarioInventario _escenario = EscenarioInventario.conDatos;
  bool _fallarSiguienteConsulta = false;
  int _siguienteId = 6;

  @override
  EscenarioInventario get escenario => _escenario;

  @override
  void seleccionarEscenario(EscenarioInventario escenario) {
    _escenario = escenario;
    _fallarSiguienteConsulta = escenario == EscenarioInventario.error;

    switch (escenario) {
      case EscenarioInventario.conDatos:
      case EscenarioInventario.error:
        _productos = List.of(_ejemplos);
        _siguienteId = 6;
        break;
      case EscenarioInventario.vacio:
        _productos = [];
        _siguienteId = 6;
        break;
      case EscenarioInventario.cargando:
        break;
    }
  }

  @override
  Future<List<Producto>> obtenerTodos() async {
    final escenarioSolicitud = _escenario;
    if (escenarioSolicitud == EscenarioInventario.cargando) {
      // Se mantiene pendiente para capturar el indicador de carga.
      return Completer<List<Producto>>().future;
    }

    final debeFallar = _fallarSiguienteConsulta;
    _fallarSiguienteConsulta = false;
    final resultado = List<Producto>.unmodifiable(_productos);
    await Future<void>.delayed(retardo);

    if (debeFallar) {
      throw Exception('Falla simulada al consultar el inventario');
    }
    return resultado;
  }

  @override
  Future<Producto?> obtenerPorId(String id) async {
    await Future<void>.delayed(retardo);
    for (final producto in _productos) {
      if (producto.id == id) return producto;
    }
    return null;
  }

  @override
  Future<Producto> crearProducto({
    required String nombre,
    required double costoCompra,
    required double precioVenta,
  }) async {
    ValidacionProducto.verificar(
      nombreProducto: nombre,
      costoCompra: costoCompra,
      precioVenta: precioVenta,
    );
    await Future<void>.delayed(retardo);
    var id = 'P${(_siguienteId++).toString().padLeft(3, '0')}';
    while (_productos.any((producto) => producto.id == id)) {
      id = 'P${(_siguienteId++).toString().padLeft(3, '0')}';
    }
    final producto = Producto(
      id: id,
      nombre: nombre.trim(),
      cantidad: 0,
      costoCompra: costoCompra,
      precioVenta: precioVenta,
    );
    _productos.add(producto);
    _escenario = EscenarioInventario.conDatos;
    _fallarSiguienteConsulta = false;
    return producto;
  }

  @override
  Future<Producto> actualizarProducto({
    required String id,
    required String nombre,
    required double costoCompra,
    required double precioVenta,
  }) async {
    ValidacionProducto.verificar(
      nombreProducto: nombre,
      costoCompra: costoCompra,
      precioVenta: precioVenta,
    );
    await Future<void>.delayed(retardo);
    final indice = _productos.indexWhere((producto) => producto.id == id);
    if (indice == -1) throw const ProductoNoEncontradoException();

    final anterior = _productos[indice];
    final actualizado = Producto(
      id: anterior.id,
      nombre: nombre.trim(),
      cantidad: anterior.cantidad,
      costoCompra: costoCompra,
      precioVenta: precioVenta,
    );
    _productos[indice] = actualizado;
    _escenario = EscenarioInventario.conDatos;
    _fallarSiguienteConsulta = false;
    return actualizado;
  }
}
