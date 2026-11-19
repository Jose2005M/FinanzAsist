import 'package:flutter/material.dart';

import '../data/autenticacion_local.dart';
import '../theme/tema_finanzasist.dart';
import '../widgets/superficies_finanzasist.dart';

/// Crea la única cuenta de administrador. En un teléfono sin cuentas no pide
/// autorización; con empresas, la de un propietario. Al terminar, la sesión
/// del administrador queda iniciada.
class CrearAdministradorScreen extends StatefulWidget {
  const CrearAdministradorScreen({
    super.key,
    required this.autenticacion,
    this.requiereAutorizacion = true,
  });
  final AutenticacionLocal autenticacion;
  final bool requiereAutorizacion;

  @override
  State<CrearAdministradorScreen> createState() =>
      _CrearAdministradorScreenState();
}

class _CrearAdministradorScreenState extends State<CrearAdministradorScreen> {
  final _formulario = GlobalKey<FormState>();
  final _correoPropietario = TextEditingController();
  final _clavePropietario = TextEditingController();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _ocupado = false;
  String? _error;

  @override
  void dispose() {
    for (final campo in [
      _correoPropietario,
      _clavePropietario,
      _nombre,
      _correo,
      _clave,
      _confirmacion,
    ]) {
      campo.dispose();
    }
    super.dispose();
  }

  Future<void> _crear() async {
    if (_ocupado || !(_formulario.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await widget.autenticacion.crearAdministrador(
        DatosAdministrador(
          nombre: _nombre.text,
          correo: _correo.text,
          clave: _clave.text,
        ),
        correoPropietario: widget.requiereAutorizacion
            ? _correoPropietario.text
            : null,
        clavePropietario: widget.requiereAutorizacion
            ? _clavePropietario.text
            : null,
      );
      if (mounted) Navigator.pop(context, true);
    } on AccesoException catch (e) {
      if (!mounted) return;
      setState(() {
        _ocupado = false;
        _error = e.mensaje;
      });
    }
  }

  Widget _campo({
    required String clave,
    required String etiqueta,
    required TextEditingController controlador,
    required FormFieldValidator<String> validar,
    bool secreto = false,
    TextInputType? teclado,
    String? ayuda,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey(clave),
      controller: controlador,
      enabled: !_ocupado,
      obscureText: secreto,
      keyboardType: teclado,
      decoration: InputDecoration(labelText: etiqueta, helperText: ayuda),
      validator: validar,
    ),
  );

  Widget _titulo(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(texto, style: Theme.of(context).textTheme.titleMedium),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Crear administrador')),
    body: AnchoContenido(
      child: SafeArea(
        child: Form(
          key: _formulario,
          // Todos los campos se construyen para que el formulario los valide.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CabeceraModulo(
                  titulo: 'Cuenta de administrador',
                  descripcion:
                      'Verá los usuarios de este dispositivo y podrá '
                      'desactivarlos o restablecer su contraseña. Solo puede '
                      'existir uno'
                      '${widget.requiereAutorizacion ? ' y, como ya hay empresas, necesita la autorización de un propietario.' : ': quien lo cree primero queda como administrador.'}',
                  icono: Icons.admin_panel_settings_outlined,
                ),
                const SizedBox(height: 24),
                if (widget.requiereAutorizacion) ...[
                  PanelFinanzas(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _titulo('Autorización del propietario'),
                        _campo(
                          clave: 'correo-propietario',
                          etiqueta: 'Correo del propietario',
                          controlador: _correoPropietario,
                          teclado: TextInputType.emailAddress,
                          validar: DatosRegistro.validarCorreo,
                        ),
                        _campo(
                          clave: 'clave-propietario',
                          etiqueta: 'Contraseña del propietario',
                          controlador: _clavePropietario,
                          secreto: true,
                          validar: (valor) => (valor ?? '').isEmpty
                              ? 'Escribe la contraseña del propietario.'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                PanelFinanzas(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _titulo('Datos del administrador'),
                      _campo(
                        clave: 'nombre-admin',
                        etiqueta: 'Nombre',
                        controlador: _nombre,
                        validar: (valor) => DatosRegistro.validarNombre(
                          valor,
                          'el nombre del administrador',
                          100,
                        ),
                      ),
                      _campo(
                        clave: 'correo-admin',
                        etiqueta: 'Correo del administrador',
                        controlador: _correo,
                        teclado: TextInputType.emailAddress,
                        validar: DatosRegistro.validarCorreo,
                      ),
                      _campo(
                        clave: 'clave-admin',
                        etiqueta: 'Contraseña',
                        controlador: _clave,
                        secreto: true,
                        ayuda:
                            'De ${DatosRegistro.longitudMinimaClave} a '
                            '${DatosRegistro.longitudMaximaClave} caracteres.',
                        validar: DatosRegistro.validarClave,
                      ),
                      _campo(
                        clave: 'confirmar-clave-admin',
                        etiqueta: 'Confirmar contraseña',
                        controlador: _confirmacion,
                        secreto: true,
                        validar: (valor) => valor != _clave.text
                            ? 'Las contraseñas deben coincidir.'
                            : null,
                      ),
                    ],
                  ),
                ),
                if (_error case final error?) ...[
                  const SizedBox(height: 16),
                  Text(
                    error,
                    key: const ValueKey('error-crear-admin'),
                    style: const TextStyle(color: ColoresFinanzAsist.error),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  key: const ValueKey('crear-admin'),
                  onPressed: _ocupado ? null : _crear,
                  child: _ocupado
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Crear administrador'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
