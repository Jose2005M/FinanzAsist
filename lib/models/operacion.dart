import 'dart:math';

enum TipoOperacion { inicial, ajuste, compra, venta }

String nuevoId() {
  final random = Random.secure();
  return '${DateTime.now().microsecondsSinceEpoch}-${List.generate(12, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
}

// El dominio calcula y almacena dinero en centavos enteros.
int centavos(double valor) => (valor * 100).round();
double pesos(int valor) => valor / 100;

int _importeExacto(BigInt valor) {
  if (valor.abs() > BigInt.from(9007199254740991)) {
    throw const ReglaNegocioException(
      'El importe excede el límite de cálculo exacto',
    );
  }
  return valor.toInt();
}

int sumarCentavos(int a, int b) =>
    _importeExacto(BigInt.from(a) + BigInt.from(b));
int multiplicarCentavos(int a, int b) =>
    _importeExacto(BigInt.from(a) * BigInt.from(b));

class ReglaNegocioException implements Exception {
  const ReglaNegocioException(this.mensaje);
  final String mensaje;
  @override
  String toString() => mensaje;
}

class LineaOperacion {
  const LineaOperacion({
    required this.productoId,
    required this.cantidad,
    required this.valorUnitario,
  });
  final String productoId;
  final int cantidad;
  final double valorUnitario;

  Map<String, Object?> toJson() => {
    'productoId': productoId,
    'cantidad': cantidad,
    'valorUnitario': valorUnitario,
  };
  factory LineaOperacion.fromJson(Map<String, dynamic> json) => LineaOperacion(
    productoId: json['productoId'] as String,
    cantidad: json['cantidad'] as int,
    valorUnitario: (json['valorUnitario'] as num).toDouble(),
  );
}

class SolicitudOperacion {
  SolicitudOperacion({
    required this.id,
    required this.tipo,
    required List<LineaOperacion> lineas,
    this.descuento = 0,
    this.motivo = '',
  }) : lineas = List.unmodifiable(lineas);
  final String id;
  final TipoOperacion tipo;
  final List<LineaOperacion> lineas;
  final double descuento;
  final String motivo;

  Map<String, Object?> toJson() => {
    'id': id,
    'tipo': tipo.name,
    'lineas': lineas.map((l) => l.toJson()).toList(),
    'descuento': descuento,
    'motivo': motivo,
  };
  factory SolicitudOperacion.fromJson(Map<String, dynamic> json) =>
      SolicitudOperacion(
        id: json['id'] as String,
        tipo: TipoOperacion.values.byName(json['tipo'] as String),
        lineas: (json['lineas'] as List)
            .map(
              (l) =>
                  LineaOperacion.fromJson(Map<String, dynamic>.from(l as Map)),
            )
            .toList(),
        descuento: (json['descuento'] as num).toDouble(),
        motivo: json['motivo'] as String,
      );
}

class Operacion {
  Operacion({
    required this.solicitud,
    required this.empresaId,
    required this.usuarioId,
    required this.fecha,
    required this.subtotalCentavos,
    required this.descuentoCentavos,
    required List<Map<String, Object?>> detalles,
    this.metodoCosto = 'catalogo_al_confirmar',
  }) : detalles = List.unmodifiable(
         detalles.map((d) => Map<String, Object?>.unmodifiable(d)),
       );
  final SolicitudOperacion solicitud;
  String get id => solicitud.id;
  TipoOperacion get tipo => solicitud.tipo;
  final String empresaId;
  final String usuarioId;
  final DateTime fecha;
  final int subtotalCentavos;
  final int descuentoCentavos;
  int get totalCentavos => subtotalCentavos - descuentoCentavos;
  final List<Map<String, Object?>> detalles;
  final String metodoCosto;
  int get costoVentasCentavos => tipo != TipoOperacion.venta
      ? 0
      : detalles.fold(
          0,
          (total, detalle) => sumarCentavos(
            total,
            multiplicarCentavos(
              detalle['cantidad'] as int,
              (detalle['costoAsignadoCentavos'] ??
                      detalle['costoCatalogoCentavos'])
                  as int,
            ),
          ),
        );
  int get utilidadBrutaCentavos => totalCentavos - costoVentasCentavos;

  Map<String, Object?> toJson() => {
    'solicitud': solicitud.toJson(),
    'empresaId': empresaId,
    'usuarioId': usuarioId,
    'fecha': fecha.toIso8601String(),
    'subtotalCentavos': subtotalCentavos,
    'descuentoCentavos': descuentoCentavos,
    'detalles': detalles,
    'metodoCosto': metodoCosto,
  };
  factory Operacion.fromJson(Map<String, dynamic> json) => Operacion(
    solicitud: SolicitudOperacion.fromJson(
      Map<String, dynamic>.from(json['solicitud'] as Map),
    ),
    empresaId: json['empresaId'] as String,
    usuarioId: json['usuarioId'] as String,
    fecha: DateTime.parse(json['fecha'] as String),
    metodoCosto: json['metodoCosto'] as String? ?? 'catalogo_al_confirmar',
    subtotalCentavos: json['subtotalCentavos'] as int,
    descuentoCentavos: json['descuentoCentavos'] as int,
    detalles: (json['detalles'] as List)
        .map((d) => Map<String, Object?>.from(d as Map))
        .toList(),
  );
}

class MovimientoInventario {
  const MovimientoInventario({
    required this.operacionId,
    required this.productoId,
    required this.empresaId,
    required this.usuarioId,
    required this.fecha,
    required this.tipo,
    required this.cantidad,
    required this.saldo,
    required this.motivo,
  });
  final String operacionId;
  final String productoId;
  final String empresaId;
  final String usuarioId;
  final DateTime fecha;
  final TipoOperacion tipo;
  final int cantidad;
  final int saldo;
  final String motivo;
}
