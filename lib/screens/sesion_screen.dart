import 'package:flutter/material.dart';

import '../data/autenticacion_local.dart';
import '../data/repositorio_sqlite.dart';
import '../data/usuarios_empresa.dart';
import '../widgets/permisos_sesion.dart';
import '../data/almacen_guias.dart';
import '../widgets/acciones_respaldo.dart';
import '../widgets/guia_modulo.dart';
import 'acceso_screen.dart';
import 'usuarios_empresa_screen.dart';
import 'negocio_screen.dart';

/// Reemplaza todo el navegador privado al cerrar o cambiar de sesión.
/// Los formularios y detalles anteriores desaparecen también del historial.
class SesionScreen extends StatelessWidget {
  const SesionScreen({super.key, required this.autenticacion, this.respaldo});
  final AutenticacionLocal autenticacion;

  /// Sin respaldo, las opciones de exportar y restaurar no se muestran.
  final AccionesRespaldo? respaldo;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: autenticacion,
    builder: (context, _) {
      final sesion = autenticacion.sesion;
      if (sesion == null) {
        return AccesoScreen(autenticacion: autenticacion, respaldo: respaldo);
      }
      return _AreaEmpresa(
        key: ValueKey(sesion),
        autenticacion: autenticacion,
        sesion: sesion,
        respaldo: respaldo,
      );
    },
  );
}

class _AreaEmpresa extends StatefulWidget {
  const _AreaEmpresa({
    super.key,
    required this.autenticacion,
    required this.sesion,
    this.respaldo,
  });
  final AutenticacionLocal autenticacion;
  final SesionEmpresa sesion;
  final AccionesRespaldo? respaldo;
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

  Future<void> _exportar() async =>
      widget.respaldo?.exportar(context, sesion: widget.sesion);

  Future<void> _restaurar() async {
    final restaurado =
        await widget.respaldo?.restaurar(context, sesion: widget.sesion) ??
        false;
    // Las cuentas pueden ser otras: se vuelve a iniciar sesión.
    if (restaurado) widget.autenticacion.cerrarSesion();
  }

  @override
  Widget build(BuildContext context) => PermisosSesion(
    rol: widget.sesion.rol,
    child: AreaGuias(
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
              gestionarUsuarios: () => _navegador.currentState!.push<void>(
                MaterialPageRoute(
                  builder: (_) => UsuariosEmpresaScreen(
                    usuarios: UsuariosEmpresa(
                      base: widget.autenticacion.base,
                      sesion: widget.sesion,
                    ),
                  ),
                ),
              ),
              exportarRespaldo: widget.respaldo == null ? null : _exportar,
              restaurarRespaldo: widget.respaldo == null ? null : _restaurar,
            ),
          ),
        ),
      ),
    ),
  );
}
