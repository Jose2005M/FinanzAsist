import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/operacion.dart';
import '../models/fecha_negocio.dart';
import '../models/gasto.dart';
import '../models/reporte_financiero.dart';
import '../models/producto.dart';
import '../models/reglas_inventario.dart';
import '../models/validacion_producto.dart';
import 'negocio_repository.dart';
import 'base_datos_local.dart';
import 'autenticacion_local.dart';
import 'producto_repository.dart';

class RepositorioSqlite implements NegocioRepository {
  /// Constructor para los datos anteriores sin cuenta y los recorridos de QA.
  /// Si la base contiene cuentas, exige una sesión autenticada.
  RepositorioSqlite({
    this.empresaId = 'negocio-local',
    this.usuarioId = 'administrador-local',
    DatabaseFactory? factory,
    String? ruta,
    DateTime Function()? reloj,
  }) : base = BaseDatosLocal(factory: factory, ruta: ruta),
       _sesion = null,
       _reloj = reloj ?? DateTime.now;

  RepositorioSqlite.conSesion({
    required this.base,
    required SesionEmpresa sesion,
    DateTime Function()? reloj,
  }) : _sesion = sesion,
       empresaId = sesion.empresaId,
       usuarioId = sesion.usuarioId,
       _reloj = reloj ?? DateTime.now;

  final BaseDatosLocal base;
  final SesionEmpresa? _sesion;
  final DateTime Function() _reloj;
  @override
  final String empresaId;
  @override
  final String usuarioId;

  Future<T> _conSesion<T>(Future<T> Function(DatabaseExecutor) accion) async {
    return (await base.abrir).transaction((tx) async {
      await _asegurarSesion(tx);
      return accion(tx);
    });
  }

  Gasto _gasto(Map<String, Object?> row) => Gasto(
    id: row['id'] as String,
    empresaId: row['empresa'] as String,
    usuarioId: row['usuario'] as String,
    fecha: DateTime.parse('${row['fecha']}T00:00:00Z'),
    concepto: row['concepto'] as String,
    categoria: row['categoria'] as String,
    valorCentavos: row['valor'] as int,
    registradoEn: DateTime.parse(row['registrado'] as String),
  );

  @override
  Future<Gasto> registrarGasto(SolicitudGasto solicitud) async {
    final gasto = solicitud.confirmar(
      empresaId: empresaId,
      usuarioId: usuarioId,
      registradoEn: _reloj(),
    );
    return _conSesion((tx) async {
      final previos = await tx.query(
        'gastos',
        where: 'empresa = ? AND id = ?',
        whereArgs: [empresaId, gasto.id],
      );
      if (previos.isNotEmpty) {
        final previo = _gasto(previos.single);
        if (!previo.mismosDatos(gasto)) {
          throw const ReglaNegocioException(
            'El identificador ya corresponde a otro gasto',
          );
        }
        return previo;
      }
      await tx.insert('gastos', {
        'empresa': empresaId,
        'id': gasto.id,
        'usuario': usuarioId,
        'fecha': FechaNegocio.clave(gasto.fecha),
        'concepto': gasto.concepto,
        'categoria': gasto.categoria,
        'valor': gasto.valorCentavos,
        'registrado': gasto.registradoEn.toIso8601String(),
      });
      return gasto;
    });
  }

  Future<List<Gasto>> _gastos(
    DatabaseExecutor db, {
    PeriodoReporte? periodo,
  }) async => (await db.query(
    'gastos',
    where: periodo == null
        ? 'empresa = ?'
        : 'empresa = ? AND fecha >= ? AND fecha <= ?',
    whereArgs: [
      empresaId,
      if (periodo != null) ...[
        FechaNegocio.clave(periodo.desde),
        FechaNegocio.clave(periodo.hasta),
      ],
    ],
    orderBy: 'fecha DESC, registrado DESC, rowid DESC',
  )).map(_gasto).toList();

  @override
  Future<List<Gasto>> obtenerGastos({PeriodoReporte? periodo}) async =>
      _conSesion((db) => _gastos(db, periodo: periodo));

  @override
  Future<ReporteFinanciero> obtenerReporte(
    PeriodoReporte periodo,
  ) async => _conSesion((tx) async {
    // Compras, ventas y gastos pertenecen a una misma instantánea de la base.
    // Sin fracción en los límites para comparar también ISO con microsegundos.
    final rows = await tx.query(
      'operaciones',
      where: 'empresa = ? AND fecha >= ? AND fecha < ?',
      whereArgs: [
        empresaId,
        periodo.inicioUtc.toIso8601String().substring(0, 19),
        periodo.finExclusivoUtc.toIso8601String().substring(0, 19),
      ],
    );
    return ReporteFinanciero.calcular(
      periodo: periodo,
      empresaId: empresaId,
      operaciones: rows.map(
        (r) => Operacion.fromJson(
          jsonDecode(r['datos'] as String) as Map<String, dynamic>,
        ),
      ),
      gastos: await _gastos(tx, periodo: periodo),
    );
  });

  Future<void> _asegurarSesion(DatabaseExecutor db) async {
    final sesion = _sesion;
    if (sesion != null) {
      await sesion.verificar(db);
      return;
    }
    if ((await db.query('cuentas', columns: ['id'], limit: 1)).isNotEmpty) {
      throw const AccesoException('Inicia sesión para acceder a los datos.');
    }
    if (empresaId.trim().isEmpty || usuarioId.trim().isEmpty) {
      throw const ReglaNegocioException('La sesión local no es válida');
    }
    await db.insert('empresas', {
      'id': empresaId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('usuarios', {
      'empresa': empresaId,
      'id': usuarioId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Producto _producto(Map<String, Object?> row) => Producto(
    id: row['id'] as String,
    empresaId: row['empresa'] as String,
    nombre: row['nombre'] as String,
    cantidad: row['cantidad'] as int,
    costoCompra: pesos(row['costo'] as int),
    precioVenta: pesos(row['precio'] as int),
  );

  Future<List<Producto>> _productos(DatabaseExecutor db) async =>
      (await db.query(
        'productos',
        where: 'empresa = ?',
        whereArgs: [empresaId],
        orderBy: 'rowid',
      )).map(_producto).toList();

  @override
  Future<List<Producto>> obtenerTodos() async => _conSesion(_productos);

  @override
  Future<Producto?> obtenerPorId(String id) async {
    return _conSesion((db) async {
      final rows = await db.query(
        'productos',
        where: 'empresa = ? AND id = ?',
        whereArgs: [empresaId, id],
      );
      return rows.isEmpty ? null : _producto(rows.single);
    });
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
    final producto = Producto(
      id: nuevoId(),
      empresaId: empresaId,
      nombre: nombre.trim(),
      cantidad: 0,
      costoCompra: pesos(centavos(costoCompra)),
      precioVenta: pesos(centavos(precioVenta)),
    );
    await _conSesion((tx) async {
      await tx.insert('productos', {
        'empresa': empresaId,
        'id': producto.id,
        'nombre': producto.nombre,
        'cantidad': 0,
        'costo': centavos(costoCompra),
        'precio': centavos(precioVenta),
      });
    });
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
    return _conSesion((tx) async {
      final count = await tx.update(
        'productos',
        {
          'nombre': nombre.trim(),
          'costo': centavos(costoCompra),
          'precio': centavos(precioVenta),
        },
        where: 'empresa = ? AND id = ?',
        whereArgs: [empresaId, id],
      );
      if (count == 0) throw const ProductoNoEncontradoException();
      return _producto(
        (await tx.query(
          'productos',
          where: 'empresa = ? AND id = ?',
          whereArgs: [empresaId, id],
        )).single,
      );
    });
  }

  @override
  Future<Operacion> confirmarOperacion(SolicitudOperacion solicitud) async {
    return _conSesion((tx) async {
      final previas = await tx.query(
        'operaciones',
        where: 'empresa = ? AND id = ?',
        whereArgs: [empresaId, solicitud.id],
      );
      if (previas.isNotEmpty) {
        final previa = Operacion.fromJson(
          jsonDecode(previas.single['datos'] as String) as Map<String, dynamic>,
        );
        if (jsonEncode(previa.solicitud.toJson()) !=
            jsonEncode(solicitud.toJson())) {
          throw const ReglaNegocioException(
            'El identificador ya corresponde a otra operación',
          );
        }
        return previa;
      }
      // Lectura, validación del saldo actual y escritura bajo la misma transacción.
      final resultado = ReglasInventario.aplicar(
        solicitud: solicitud,
        productos: await _productos(tx),
        movimientos: await _movimientos(tx),
        empresaId: empresaId,
        usuarioId: usuarioId,
        fecha: _reloj().toUtc(),
      );
      final operacion = resultado.operacion;
      await tx.insert('operaciones', {
        'empresa': empresaId,
        'id': operacion.id,
        'usuario': usuarioId,
        'tipo': operacion.tipo.name,
        'fecha': operacion.fecha.toIso8601String(),
        'datos': jsonEncode(operacion.toJson()),
      });
      for (final movimiento in resultado.movimientos) {
        await tx.update(
          'productos',
          {'cantidad': movimiento.saldo},
          where: 'empresa = ? AND id = ?',
          whereArgs: [empresaId, movimiento.productoId],
        );
        await tx.insert('movimientos', {
          'empresa': empresaId,
          'operacion': operacion.id,
          'producto': movimiento.productoId,
          'usuario': usuarioId,
          'fecha': movimiento.fecha.toIso8601String(),
          'tipo': movimiento.tipo.name,
          'cantidad': movimiento.cantidad,
          'saldo': movimiento.saldo,
          'motivo': movimiento.motivo,
        });
      }
      return operacion;
    });
  }

  @override
  Future<List<Operacion>> obtenerOperaciones({TipoOperacion? tipo}) async {
    return _conSesion((db) async {
      final rows = await db.query(
        'operaciones',
        where: tipo == null ? 'empresa = ?' : 'empresa = ? AND tipo = ?',
        whereArgs: [empresaId, if (tipo != null) tipo.name],
        orderBy: 'fecha DESC, rowid DESC',
      );
      return rows
          .map(
            (r) => Operacion.fromJson(
              jsonDecode(r['datos'] as String) as Map<String, dynamic>,
            ),
          )
          .toList();
    });
  }

  Future<List<MovimientoInventario>> _movimientos(
    DatabaseExecutor db, {
    String? productoId,
  }) async {
    final rows = await db.query(
      'movimientos',
      where: productoId == null
          ? 'empresa = ?'
          : 'empresa = ? AND producto = ?',
      whereArgs: [empresaId, ?productoId],
      orderBy: 'fecha DESC, rowid DESC',
    );
    return rows
        .map(
          (r) => MovimientoInventario(
            operacionId: r['operacion'] as String,
            productoId: r['producto'] as String,
            empresaId: r['empresa'] as String,
            usuarioId: r['usuario'] as String,
            fecha: DateTime.parse(r['fecha'] as String),
            tipo: TipoOperacion.values.byName(r['tipo'] as String),
            cantidad: r['cantidad'] as int,
            saldo: r['saldo'] as int,
            motivo: r['motivo'] as String,
          ),
        )
        .toList();
  }

  @override
  Future<List<MovimientoInventario>> obtenerMovimientos({
    String? productoId,
  }) async => _conSesion((db) => _movimientos(db, productoId: productoId));

  @override
  EscenarioInventario get escenario => EscenarioInventario.conDatos;
  @override
  void seleccionarEscenario(EscenarioInventario escenario) =>
      throw UnsupportedError(
        'Los escenarios solo están disponibles en demostración',
      );

  Future<void> cerrar() => base.cerrar();
}
