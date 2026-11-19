import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/producto_repository.dart';
import 'data/negocio_repository.dart';
import 'data/repositorio_simulado.dart';
import 'data/autenticacion_local.dart';
import 'data/base_datos_local.dart';
import 'data/respaldo_local.dart';
import 'data/selector_archivos.dart';
import 'screens/inventario_screen.dart';
import 'screens/negocio_screen.dart';
import 'screens/sesion_screen.dart';
import 'theme/tema_finanzasist.dart';
import 'data/almacen_guias.dart';
import 'widgets/acciones_respaldo.dart';
import 'widgets/guia_modulo.dart';

void main() {
  const demo = bool.fromEnvironment('DEMO');
  runApp(
    FinanzAsistApp(repositorio: demo || kIsWeb ? RepositorioSimulado() : null),
  );
}

class FinanzAsistApp extends StatefulWidget {
  const FinanzAsistApp({
    super.key,
    this.repositorio,
    this.autenticacion,
    this.almacenGuias,
    this.selectorArchivos,
  });

  final ProductoRepository? repositorio;
  final AutenticacionLocal? autenticacion;
  final AlmacenGuias? almacenGuias;
  final SelectorArchivos? selectorArchivos;

  @override
  State<FinanzAsistApp> createState() => _FinanzAsistAppState();
}

class _FinanzAsistAppState extends State<FinanzAsistApp> {
  late final AutenticacionLocal? _autenticacion;
  late final AccionesRespaldo? _respaldo;
  late final _guias = widget.almacenGuias ?? AlmacenGuiasMemoria();
  late final _repositorioDemo = widget.repositorio ?? RepositorioSimulado();

  @override
  void initState() {
    super.initState();
    _autenticacion =
        widget.autenticacion ??
        (widget.repositorio == null && !kIsWeb
            ? AutenticacionLocal(base: BaseDatosLocal())
            : null);
    final autenticacion = _autenticacion;
    _respaldo = autenticacion == null
        ? null
        : AccionesRespaldo(
            respaldo: RespaldoLocal(base: autenticacion.base),
            selector:
                widget.selectorArchivos ?? const SelectorArchivosSistema(),
          );
  }

  @override
  void dispose() {
    if (widget.autenticacion == null) _autenticacion?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinanzAsist',
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: TemaFinanzAsist.crear(),
      builder: (context, child) => AreaGuias(almacen: _guias, child: child!),
      home: _autenticacion != null
          ? SesionScreen(autenticacion: _autenticacion, respaldo: _respaldo)
          : _repositorioDemo is NegocioRepository
          ? NegocioScreen(repositorio: _repositorioDemo)
          : InventarioScreen(repositorio: _repositorioDemo),
    );
  }
}
