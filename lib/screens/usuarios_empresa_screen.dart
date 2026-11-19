import 'package:flutter/material.dart';

import '../data/autenticacion_local.dart';
import '../data/usuarios_empresa.dart';
import '../theme/tema_finanzasist.dart';
import '../viewmodels/usuarios_empresa_view_model.dart';
import '../widgets/superficies_finanzasist.dart';
import 'nuevo_usuario_screen.dart';

/// El propietario gestiona aquí a los empleados de su empresa (HU-03).
class UsuariosEmpresaScreen extends StatefulWidget {
  const UsuariosEmpresaScreen({super.key, required this.usuarios});
  final GestionUsuariosEmpresa usuarios;

  @override
  State<UsuariosEmpresaScreen> createState() => _UsuariosEmpresaScreenState();
}

class _UsuariosEmpresaScreenState extends State<UsuariosEmpresaScreen> {
  late final _vm = UsuariosEmpresaViewModel(widget.usuarios);

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

  Future<void> _nuevo() async {
    final creado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NuevoUsuarioScreen(usuarios: widget.usuarios),
      ),
    );
    if (!mounted || creado != true) return;
    await _vm.cargar();
    _avisar('Usuario creado. Ya puede iniciar sesión en este dispositivo.');
  }

  Future<void> _cambiarEstado(UsuarioEmpresa u) async {
    final activar = !u.activa;
    if (!activar && !await _confirmarDesactivacion(u)) return;
    final error = await _vm.cambiarEstado(u, activa: activar);
    if (!mounted) return;
    _avisar(
      error ??
          (activar
              ? '${u.nombre} puede volver a entrar.'
              : '${u.nombre} ya no puede entrar.'),
    );
  }

  Future<bool> _confirmarDesactivacion(UsuarioEmpresa u) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Desactivar el usuario?'),
          content: Text(
            '${u.nombre} no podrá iniciar sesión y, si tiene la sesión '
            'abierta, su siguiente acción será rechazada. Sus registros se '
            'conservan.',
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

  Future<void> _cambiarRol(UsuarioEmpresa u) async {
    final rol = await showDialog<RolCuenta>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Rol de ${u.nombre}'),
        children: [
          for (final rol in RolCuenta.empleados)
            SimpleDialogOption(
              key: ValueKey('rol-opcion-${rol.name}'),
              onPressed: () => Navigator.pop(context, rol),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  rol == u.rol
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(rol.etiqueta),
                subtitle: Text(rol.descripcion),
              ),
            ),
        ],
      ),
    );
    if (rol == null || rol == u.rol) return;
    final error = await _vm.cambiarRol(u, rol);
    if (!mounted) return;
    _avisar(error ?? '${u.nombre} ahora es ${rol.etiqueta.toLowerCase()}.');
  }

  Future<void> _restablecerClave(UsuarioEmpresa u) async {
    final clave = await showDialog<String>(
      context: context,
      builder: (_) => _DialogoNuevaClave(usuario: u),
    );
    if (clave == null) return;
    final error = await _vm.restablecerClave(u, clave);
    if (!mounted) return;
    _avisar(
      error ??
          'Contraseña restablecida. Comunícala a ${u.nombre} por un medio '
              'seguro.',
    );
  }

  Widget? _estado() {
    if (_vm.cargando && _vm.lista.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_vm.error case final error?) {
      return EstadoModulo(
        titulo: error,
        descripcion: 'Vuelve a consultar los usuarios de tu empresa.',
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
      appBar: AppBar(title: const Text('Usuarios de mi empresa')),
      body: AnchoContenido(
        child: SafeArea(
          child: ListadoModulo(
            cabecera: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CabeceraModulo(
                    titulo: 'Usuarios de mi empresa',
                    descripcion:
                        'Crea cuentas para tus empleados y elige qué puede '
                        'hacer cada uno. Tú conservas todos los permisos.',
                    icono: Icons.group_outlined,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const ValueKey('nuevo-usuario'),
                    onPressed: _vm.procesando ? null : _nuevo,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Crear usuario'),
                  ),
                ],
              ),
            ),
            estado: _estado(),
            cantidad: _vm.lista.length,
            onActualizar: _vm.cargar,
            itemBuilder: (context, i) => _TarjetaUsuario(
              usuario: _vm.lista[i],
              ocupada: _vm.procesando,
              cambiarEstado: _cambiarEstado,
              cambiarRol: _cambiarRol,
              restablecerClave: _restablecerClave,
            ),
          ),
        ),
      ),
    ),
  );
}

class _TarjetaUsuario extends StatelessWidget {
  const _TarjetaUsuario({
    required this.usuario,
    required this.ocupada,
    required this.cambiarEstado,
    required this.cambiarRol,
    required this.restablecerClave,
  });

  final UsuarioEmpresa usuario;
  final bool ocupada;
  final ValueChanged<UsuarioEmpresa> cambiarEstado;
  final ValueChanged<UsuarioEmpresa> cambiarRol;
  final ValueChanged<UsuarioEmpresa> restablecerClave;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final propietario = usuario.rol == RolCuenta.propietario;
    final correo = usuario.correo;
    return PanelFinanzas(
      key: ValueKey('usuario-$correo'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(usuario.nombre, style: texto.titleMedium)),
              _Estado(activa: usuario.activa),
            ],
          ),
          const SizedBox(height: 4),
          Text(propietario ? 'Propietario (tú)' : usuario.rol.etiqueta),
          Text(
            correo,
            style: texto.bodyMedium?.copyWith(
              color: ColoresFinanzAsist.secundaria,
            ),
          ),
          if (!propietario) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  key: ValueKey('estado-$correo'),
                  onPressed: ocupada ? null : () => cambiarEstado(usuario),
                  icon: Icon(
                    usuario.activa
                        ? Icons.block_outlined
                        : Icons.check_circle_outline,
                  ),
                  label: Text(usuario.activa ? 'Desactivar' : 'Activar'),
                ),
                TextButton.icon(
                  key: ValueKey('rol-$correo'),
                  onPressed: ocupada ? null : () => cambiarRol(usuario),
                  icon: const Icon(Icons.badge_outlined),
                  label: const Text('Cambiar rol'),
                ),
                TextButton.icon(
                  key: ValueKey('clave-$correo'),
                  onPressed: ocupada ? null : () => restablecerClave(usuario),
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

/// Pide la nueva contraseña dos veces y la devuelve si es válida.
class _DialogoNuevaClave extends StatefulWidget {
  const _DialogoNuevaClave({required this.usuario});
  final UsuarioEmpresa usuario;

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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nueva contraseña para ${widget.usuario.nombre} '
              '(${widget.usuario.correo}).',
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
