import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/autenticacion_local.dart';
import '../widgets/marca_finanzasist.dart';
import '../theme/tema_finanzasist.dart';
import '../widgets/superficies_finanzasist.dart';

class AccesoScreen extends StatefulWidget {
  const AccesoScreen({super.key, required this.autenticacion});
  final AutenticacionLocal autenticacion;

  @override
  State<AccesoScreen> createState() => _AccesoScreenState();
}

class _AccesoScreenState extends State<AccesoScreen> {
  var _formulario = GlobalKey<FormState>();
  final _empresa = TextEditingController();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  final _confirmacion = TextEditingController();
  final _focos = List.generate(5, (_) => FocusNode());
  final _desplazamiento = ScrollController();
  bool _registro = false;
  bool _ocupado = false;
  bool _verClave = false;
  String? _error;

  @override
  void dispose() {
    for (final campo in [_empresa, _nombre, _correo, _clave, _confirmacion]) {
      campo.dispose();
    }
    for (final foco in _focos) {
      foco.dispose();
    }
    _desplazamiento.dispose();
    super.dispose();
  }

  void _cambiarModo() {
    FocusScope.of(context).unfocus();
    setState(() {
      _formulario = GlobalKey<FormState>();
      _registro = !_registro;
      _error = null;
      _clave.clear();
      _confirmacion.clear();
      _verClave = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _desplazamiento.hasClients) _desplazamiento.jumpTo(0);
    });
  }

  String? _validarClave(String? valor) => _registro
      ? DatosRegistro.validarClave(valor)
      : (valor ?? '').isEmpty
      ? 'Escribe tu contraseña.'
      : null;

  String? _validarConfirmacion(String? valor) =>
      valor != _clave.text || (valor ?? '').isEmpty
      ? 'Las contraseñas deben coincidir.'
      : null;

  void _enfocarPrimerError() {
    final errores = <(int, String?)>[
      if (_registro) ...[
        (
          0,
          DatosRegistro.validarNombre(
            _empresa.text,
            'el nombre de la empresa',
            120,
          ),
        ),
        (1, DatosRegistro.validarNombre(_nombre.text, 'tu nombre', 100)),
      ],
      (2, DatosRegistro.validarCorreo(_correo.text)),
      (3, _validarClave(_clave.text)),
      if (_registro) (4, _validarConfirmacion(_confirmacion.text)),
    ];
    final foco = _focos[errores.firstWhere((e) => e.$2 != null).$1];
    foco.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && foco.context != null) {
        Scrollable.ensureVisible(
          foco.context!,
          alignment: 0.25,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _enviar() async {
    if (_ocupado) return;
    if (!_formulario.currentState!.validate()) {
      _enfocarPrimerError();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      if (_registro) {
        await widget.autenticacion.registrar(
          DatosRegistro(
            empresa: _empresa.text,
            propietario: _nombre.text,
            correo: _correo.text,
            clave: _clave.text,
          ),
        );
      } else {
        await widget.autenticacion.iniciarSesion(_correo.text, _clave.text);
      }
      TextInput.finishAutofillContext(shouldSave: true);
    } on AccesoException catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No pudimos completar el acceso. Inténtalo de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: TemaFinanzAsist.sistema,
    child: PopScope(
      canPop: !_ocupado,
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, espacio) {
              final teclado = MediaQuery.viewInsetsOf(context).bottom > 0;
              final compacto = teclado || _registro || espacio.maxHeight < 680;
              final espacioVertical = compacto ? 32.0 : 48.0;
              return SingleChildScrollView(
                key: const ValueKey('desplazamiento-acceso'),
                controller: _desplazamiento,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(
                  horizontal: espacio.maxWidth < 360 ? 16 : 20,
                  vertical: espacioVertical / 2,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: espacio.maxHeight > espacioVertical
                        ? espacio.maxHeight - espacioVertical
                        : 0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          MarcaFinanzAsist(
                            compacta: teclado || _registro,
                            reducida: compacto,
                          ),
                          SizedBox(height: compacto ? 20 : 28),
                          _encabezado(context),
                          SizedBox(height: compacto ? 20 : 24),
                          _panel(context),
                          const SizedBox(height: 24),
                          _informacionLocal(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );

  Widget _encabezado(BuildContext context) {
    final titulo = Text(
      _registro ? 'Crea la cuenta de tu empresa' : 'Inicia sesión',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: ColoresFinanzAsist.tinta,
        fontSize: _registro ? 28 : 32,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    );
    final lineas =
        !_registro && MediaQuery.textScalerOf(context).scale(16) <= 20;
    return Column(
      children: [
        Semantics(
          header: true,
          child: lineas
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _LineaDorada(),
                    const SizedBox(width: 12),
                    Flexible(child: titulo),
                    const SizedBox(width: 12),
                    const _LineaDorada(),
                  ],
                )
              : titulo,
        ),
        const SizedBox(height: 12),
        Text(
          _registro
              ? 'Registra tu empresa y entra como propietario.'
              : 'Accede al inventario y las finanzas de tu empresa.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, height: 1.45),
        ),
      ],
    );
  }

  Widget _panel(BuildContext context) => PanelFinanzas(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
    child: AutofillGroup(
      child: Form(
        key: _formulario,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_registro) ...[
              _campo(
                clave: 'empresa-registro',
                etiqueta: 'Nombre de la empresa',
                pista: 'Nombre de tu negocio',
                icono: Icons.storefront_outlined,
                controlador: _empresa,
                foco: _focos[0],
                mayusculas: TextCapitalization.words,
                autocompletar: const [AutofillHints.organizationName],
                validar: (v) => DatosRegistro.validarNombre(
                  v,
                  'el nombre de la empresa',
                  120,
                ),
              ),
              const SizedBox(height: 20),
              _campo(
                clave: 'propietario-registro',
                etiqueta: 'Tu nombre',
                pista: 'Nombre del propietario',
                icono: Icons.person_outline,
                controlador: _nombre,
                foco: _focos[1],
                mayusculas: TextCapitalization.words,
                autocompletar: const [AutofillHints.name],
                validar: (v) =>
                    DatosRegistro.validarNombre(v, 'tu nombre', 100),
              ),
              const SizedBox(height: 20),
            ],
            _campo(
              clave: 'correo-acceso',
              etiqueta: 'Correo electrónico',
              pista: 'tu@empresa.com',
              icono: Icons.mail_outline_rounded,
              controlador: _correo,
              foco: _focos[2],
              teclado: TextInputType.emailAddress,
              autocompletar: const [AutofillHints.username],
              validar: DatosRegistro.validarCorreo,
            ),
            const SizedBox(height: 20),
            _campo(
              clave: 'clave-acceso',
              etiqueta: 'Contraseña',
              pista: _registro ? 'Crea una contraseña' : 'Tu contraseña',
              icono: Icons.lock_outline_rounded,
              controlador: _clave,
              foco: _focos[3],
              secreto: true,
              autocompletar: [
                _registro ? AutofillHints.newPassword : AutofillHints.password,
              ],
              ayuda: _registro
                  ? 'De ${DatosRegistro.longitudMinimaClave} a ${DatosRegistro.longitudMaximaClave} caracteres. Puedes usar una frase.'
                  : null,
              validar: _validarClave,
              ultimo: !_registro,
              sufijo: IconButton(
                tooltip: _verClave
                    ? 'Ocultar contraseña'
                    : 'Mostrar contraseña',
                onPressed: _ocupado
                    ? null
                    : () => setState(() => _verClave = !_verClave),
                icon: Icon(
                  _verClave
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
            if (_registro) ...[
              const SizedBox(height: 20),
              _campo(
                clave: 'confirmacion-registro',
                etiqueta: 'Confirmar contraseña',
                pista: 'Repite tu contraseña',
                icono: Icons.lock_outline_rounded,
                controlador: _confirmacion,
                foco: _focos[4],
                secreto: true,
                validar: _validarConfirmacion,
                ultimo: true,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 20),
              Semantics(
                liveRegion: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ExcludeSemantics(
                      child: Icon(
                        Icons.error_outline,
                        color: ColoresFinanzAsist.error,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: ColoresFinanzAsist.error,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: const ValueKey('enviar-acceso'),
              onPressed: _ocupado ? null : _enviar,
              style: FilledButton.styleFrom(
                backgroundColor: ColoresFinanzAsist.dorado,
                foregroundColor: ColoresFinanzAsist.tinta,
                disabledBackgroundColor: ColoresFinanzAsist.deshabilitado,
                disabledForegroundColor: ColoresFinanzAsist.secundaria,
                minimumSize: const Size.fromHeight(54),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (_ocupado)
                    const ExcludeSemantics(
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColoresFinanzAsist.secundaria,
                        ),
                      ),
                    ),
                  Semantics(
                    liveRegion: _ocupado,
                    child: Text(
                      _ocupado
                          ? (_registro ? 'Creando cuenta…' : 'Verificando…')
                          : (_registro
                                ? 'Crear cuenta y entrar'
                                : 'Iniciar sesión'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('cambiar-acceso'),
              onPressed: _ocupado ? null : _cambiarModo,
              style: TextButton.styleFrom(
                foregroundColor: ColoresFinanzAsist.secundaria,
                minimumSize: const Size.fromHeight(48),
                textStyle: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: Text(
                _registro
                    ? 'Ya tengo cuenta · Iniciar sesión'
                    : 'Crear cuenta de empresa',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _campo({
    required String clave,
    required String etiqueta,
    required String pista,
    required IconData icono,
    required TextEditingController controlador,
    required FocusNode foco,
    required String? Function(String?) validar,
    TextInputType? teclado,
    List<String>? autocompletar,
    TextCapitalization mayusculas = TextCapitalization.none,
    bool secreto = false,
    bool ultimo = false,
    String? ayuda,
    Widget? sufijo,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ExcludeSemantics(
        child: Text(
          etiqueta,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(height: 8),
      Semantics(
        label: etiqueta,
        child: TextFormField(
          key: ValueKey(clave),
          controller: controlador,
          focusNode: foco,
          enabled: !_ocupado,
          obscureText: secreto && !_verClave,
          autocorrect: false,
          enableSuggestions: !secreto,
          keyboardType: teclado,
          textCapitalization: mayusculas,
          autofillHints: autocompletar,
          textInputAction: ultimo ? TextInputAction.done : TextInputAction.next,
          scrollPadding: const EdgeInsets.fromLTRB(24, 40, 24, 100),
          style: const TextStyle(fontSize: 16, color: ColoresFinanzAsist.tinta),
          decoration: InputDecoration(
            hintText: pista,
            helperText: ayuda,
            suffixIcon: sufijo,
            prefixIconConstraints: const BoxConstraints(
              minWidth: 56,
              minHeight: 56,
            ),
            prefixIcon: ExcludeSemantics(
              child: SizedBox(
                width: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(icono, size: 23, color: ColoresFinanzAsist.tinta),
                    Container(
                      width: 1,
                      height: 24,
                      color: ColoresFinanzAsist.dorado,
                    ),
                  ],
                ),
              ),
            ),
          ),
          validator: validar,
          onFieldSubmitted: ultimo ? (_) => _enviar() : null,
        ),
      ),
    ],
  );

  Widget _informacionLocal() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ExcludeSemantics(
          child: Icon(
            Icons.info_outline_rounded,
            color: ColoresFinanzAsist.secundaria,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tus datos se guardan en este dispositivo.\nSin sincronización ni recuperación por correo.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: ColoresFinanzAsist.secundaria,
                ),
              ),
              if (_registro) ...[
                const SizedBox(height: 8),
                const Text(
                  'La primera cuenta vincula los datos locales anteriores, si existen. Las demás empresas empiezan vacías.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: ColoresFinanzAsist.secundaria,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _LineaDorada extends StatelessWidget {
  const _LineaDorada();
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: 26,
      height: 3,
      decoration: BoxDecoration(
        color: ColoresFinanzAsist.dorado,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}
