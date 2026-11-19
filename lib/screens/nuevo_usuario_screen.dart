import 'package:flutter/material.dart';

import '../data/autenticacion_local.dart';
import '../data/usuarios_empresa.dart';
import '../theme/tema_finanzasist.dart';
import '../widgets/superficies_finanzasist.dart';

/// Formulario del propietario para crear la cuenta de un empleado.
class NuevoUsuarioScreen extends StatefulWidget {
  const NuevoUsuarioScreen({super.key, required this.usuarios});
  final GestionUsuariosEmpresa usuarios;

  @override
  State<NuevoUsuarioScreen> createState() => _NuevoUsuarioScreenState();
}

class _NuevoUsuarioScreenState extends State<NuevoUsuarioScreen> {
  final _formulario = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _confirmacion = TextEditingController();
  RolCuenta _rol = RolCuenta.vendedor;
  bool _ocupado = false;
  String? _error;

  @override
  void dispose() {
    for (final campo in [_nombre, _correo, _clave, _confirmacion]) {
      campo.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_ocupado || !(_formulario.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      await widget.usuarios.crearUsuario(
        DatosUsuario(
          nombre: _nombre.text,
          correo: _correo.text,
          clave: _clave.text,
          rol: _rol,
        ),
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Crear usuario')),
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
                PanelFinanzas(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<RolCuenta>(
                        key: const ValueKey('rol-usuario'),
                        initialValue: _rol,
                        // Ocupa el ancho disponible en pantallas de 360 dp.
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Rol'),
                        items: [
                          for (final rol in RolCuenta.empleados)
                            DropdownMenuItem(
                              value: rol,
                              child: Text(
                                rol.etiqueta,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: _ocupado
                            ? null
                            : (rol) => setState(() => _rol = rol ?? _rol),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _rol.descripcion,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: ColoresFinanzAsist.secundaria),
                      ),
                      const SizedBox(height: 20),
                      _campo(
                        clave: 'nombre-usuario',
                        etiqueta: 'Nombre',
                        controlador: _nombre,
                        validar: (valor) => DatosRegistro.validarNombre(
                          valor,
                          'el nombre del usuario',
                          100,
                        ),
                      ),
                      _campo(
                        clave: 'correo-usuario',
                        etiqueta: 'Correo',
                        controlador: _correo,
                        teclado: TextInputType.emailAddress,
                        validar: DatosRegistro.validarCorreo,
                      ),
                      _campo(
                        clave: 'clave-usuario',
                        etiqueta: 'Contraseña',
                        controlador: _clave,
                        secreto: true,
                        ayuda:
                            'De ${DatosRegistro.longitudMinimaClave} a '
                            '${DatosRegistro.longitudMaximaClave} caracteres.',
                        validar: DatosRegistro.validarClave,
                      ),
                      _campo(
                        clave: 'confirmar-clave-usuario',
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
                    key: const ValueKey('error-nuevo-usuario'),
                    style: const TextStyle(color: ColoresFinanzAsist.error),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  key: const ValueKey('guardar-usuario'),
                  onPressed: _ocupado ? null : _guardar,
                  child: _ocupado
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Crear usuario'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
