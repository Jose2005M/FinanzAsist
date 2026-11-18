import 'package:flutter/material.dart';

import '../data/autenticacion_local.dart';
import '../data/repositorio_sqlite.dart';
import '../data/almacen_guias.dart';
import '../widgets/guia_modulo.dart';
import 'acceso_screen.dart';
import 'negocio_screen.dart';

/// Reemplaza todo el navegador privado al cerrar o cambiar de sesión.
/// Los formularios y detalles anteriores desaparecen también del historial.
class SesionScreen extends StatelessWidget {
  const SesionScreen({super.key, required this.autenticacion});
  final AutenticacionLocal autenticacion;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: autenticacion,
    builder: (context, _) {
      final sesion = autenticacion.sesion;
      if (sesion == null) return AccesoScreen(autenticacion: autenticacion);
      return _AreaEmpresa(
        key: ValueKey(sesion),
        autenticacion: autenticacion,
        sesion: sesion,
      );
    },
  );
}

class _AreaEmpresa extends StatefulWidget {
  const _AreaEmpresa({
    super.key,
    required this.autenticacion,
    required this.sesion,
  });
  final AutenticacionLocal autenticacion;
  final SesionEmpresa sesion;
  @override
  State<_AreaEmpresa> createState() => _AreaEmpresaState();
}

class _AreaEmpresaState extends State<_AreaEmpresa> {
  final _navegador = GlobalKey<NavigatorState>();
  late final _repositorio = RepositorioSqlite.conSesion(
    base: widget.autenticacion.base,
    sesion: widget.sesion,
  );
  late final _guias = AlmacenGuiasSqlite(
    base: widget.autenticacion.base,
    sesion: widget.sesion,
  );

  @override
  Widget build(BuildContext context) => AreaGuias(
    almacen: _guias,
    child: NavigatorPopHandler<void>(
      onPopWithResult: (_) => _navegador.currentState!.maybePop(),
      child: Navigator(
        key: _navegador,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => NegocioScreen(
            repositorio: _repositorio,
            empresa: widget.sesion.empresa,
            correo: widget.sesion.correo,
            cerrarSesion: widget.autenticacion.cerrarSesion,
          ),
        ),
      ),
    ),
  );
}
