import 'package:flutter/material.dart';

import '../data/administracion_local.dart';
import '../data/autenticacion_local.dart';
import '../theme/tema_finanzasist.dart';
import '../viewmodels/administracion_view_model.dart';
import '../widgets/superficies_finanzasist.dart';

/// Panel del administrador: usuarios del dispositivo, su estado y claves.
class AdministracionScreen extends StatefulWidget {
  const AdministracionScreen({
    super.key,
    required this.administracion,
    required this.cerrarSesion,
  });

  final GestionCuentas administracion;
  final VoidCallback cerrarSesion;

  @override
  State<AdministracionScreen> createState() => _AdministracionScreenState();
}

class _AdministracionScreenState extends State<AdministracionScreen> {
  late final _vm = AdministracionViewModel(widget.administracion);

  @override
  void initState() {
    super.initState();
    _vm.cargar();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _avisar(String texto) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _cambiarEstado(CuentaResumen cuenta) async {
    final activar = !cuenta.activa;
    if (!activar && !await _confirmarDesactivacion(cuenta)) return;
    final error = await _vm.cambiarEstado(cuenta, activa: activar);
    if (!mounted) return;
    _avisar(
      error ??
          (activar
              ? 'Cuenta de ${cuenta.empresa} activada.'
              : 'Cuenta de ${cuenta.empresa} desactivada.'),
    );
  }

  Future<bool> _confirmarDesactivacion(CuentaResumen cuenta) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Desactivar la cuenta?'),
          content: Text(
            '${cuenta.propietario} no podrá iniciar sesión en '
            '${cuenta.empresa}. Sus datos se conservan y puedes volver a '
            'activarla cuando quieras.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              key: const ValueKey('confirmar-desactivar'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Desactivar'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _restablecerClave(CuentaResumen cuenta) async {
    final clave = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoNuevaClave(cuenta: cuenta),
    );
    if (clave == null) return;
    final error = await _vm.restablecerClave(cuenta, clave);
    if (!mounted) return;
    _avisar(
      error ??
          'Contraseña restablecida. Comunícala a ${cuenta.propietario} '
              'por un medio seguro.',
    );
  }

  Widget? _estado() {
    if (_vm.cargando && _vm.cuentas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_vm.error case final error?) {
      return EstadoModulo(
        titulo: error,
        descripcion: 'Vuelve a consultar los usuarios del dispositivo.',
        icono: Icons.error_outline,
        accion: FilledButton(
          onPressed: _vm.cargar,
          child: const Text('Reintentar'),
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _vm,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Administración'),
        actions: [
          IconButton(
            key: const ValueKey('cerrar-sesion-admin'),
            tooltip: 'Cerrar sesión',
            onPressed: widget.cerrarSesion,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: AnchoContenido(
        child: SafeArea(
          child: ListadoModulo(
            cabecera: const Padding(
              padding: EdgeInsets.all(20),
              child: CabeceraModulo(
                titulo: 'Usuarios registrados',
                descripcion:
                    'Cuentas de este dispositivo. Puedes desactivarlas o '
                    'restablecer su contraseña; no ves los datos de sus '
                    'negocios.',
                icono: Icons.admin_panel_settings_outlined,
              ),
            ),
            estado: _estado(),
            cantidad: _vm.cuentas.length,
            onActualizar: _vm.cargar,
            itemBuilder: (context, i) => _TarjetaCuenta(
              cuenta: _vm.cuentas[i],
              ocupada: _vm.procesando != null,
              cambiarEstado: _cambiarEstado,
              restablecerClave: _restablecerClave,
            ),
          ),
        ),
      ),
    ),
  );
}

class _TarjetaCuenta extends StatelessWidget {
  const _TarjetaCuenta({
    required this.cuenta,
    required this.ocupada,
    required this.cambiarEstado,
    required this.restablecerClave,
  });

  final CuentaResumen cuenta;
  final bool ocupada;
  final ValueChanged<CuentaResumen> cambiarEstado;
  final ValueChanged<CuentaResumen> restablecerClave;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final esAdministrador = cuenta.rol == RolCuenta.administrador;
    return PanelFinanzas(
      key: ValueKey('cuenta-${cuenta.correo}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  esAdministrador ? 'Administrador (tú)' : cuenta.empresa,
                  style: texto.titleMedium,
                ),
              ),
              _Estado(activa: cuenta.activa),
            ],
          ),
          const SizedBox(height: 4),
          Text(cuenta.propietario),
          Text(
            cuenta.correo,
            style: texto.bodyMedium?.copyWith(
              color: ColoresFinanzAsist.secundaria,
            ),
          ),
          if (!esAdministrador) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: ValueKey('estado-${cuenta.correo}'),
                  onPressed: ocupada ? null : () => cambiarEstado(cuenta),
                  icon: Icon(
                    cuenta.activa
                        ? Icons.block_outlined
                        : Icons.check_circle_outline,
                  ),
                  label: Text(cuenta.activa ? 'Desactivar' : 'Activar'),
                ),
                TextButton.icon(
                  key: ValueKey('clave-${cuenta.correo}'),
                  onPressed: ocupada ? null : () => restablecerClave(cuenta),
                  icon: const Icon(Icons.key_outlined),
                  label: const Text('Restablecer contraseña'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Estado extends StatelessWidget {
  const _Estado({required this.activa});
  final bool activa;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: activa
          ? ColoresFinanzAsist.seleccion
          : ColoresFinanzAsist.deshabilitado,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        activa ? 'Activa' : 'Desactivada',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: activa ? ColoresFinanzAsist.tinta : ColoresFinanzAsist.error,
        ),
      ),
    ),
  );
}

/// Pide la nueva contraseña dos veces y la devuelve si coinciden.
class _DialogoNuevaClave extends StatefulWidget {
  const _DialogoNuevaClave({required this.cuenta});
  final CuentaResumen cuenta;

  @override
  State<_DialogoNuevaClave> createState() => _DialogoNuevaClaveState();
}

class _DialogoNuevaClaveState extends State<_DialogoNuevaClave> {
  final _formulario = GlobalKey<FormState>();
  final _clave = TextEditingController();
  final _confirmacion = TextEditingController();

  @override
  void dispose() {
    _clave.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  void _guardar() {
    if (_formulario.currentState?.validate() ?? false) {
      Navigator.pop(context, _clave.text);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Restablecer contraseña'),
    content: Form(
      key: _formulario,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Nueva contraseña para ${widget.cuenta.propietario} '
            '(${widget.cuenta.correo}).',
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('nueva-clave'),
            controller: _clave,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Nueva contraseña',
              helperText:
                  'De ${DatosRegistro.longitudMinimaClave} a '
                  '${DatosRegistro.longitudMaximaClave} caracteres.',
            ),
            validator: DatosRegistro.validarClave,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('confirmar-nueva-clave'),
            controller: _confirmacion,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirmar contraseña',
            ),
            validator: (valor) => valor != _clave.text
                ? 'Las contraseñas deben coincidir.'
                : null,
            onFieldSubmitted: (_) => _guardar(),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const ValueKey('guardar-nueva-clave'),
        onPressed: _guardar,
        child: const Text('Restablecer'),
      ),
    ],
  );
}
