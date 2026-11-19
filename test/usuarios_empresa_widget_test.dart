import 'package:finanzasist/data/usuarios_empresa.dart';
import 'package:finanzasist/models/permisos.dart';
import 'package:finanzasist/screens/usuarios_empresa_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class UsuariosFalsos implements GestionUsuariosEmpresa {
  final claves = <String, String>{};
  final usuarios = <UsuarioEmpresa>[
    const UsuarioEmpresa(
      id: 'p',
      nombre: 'Propietaria',
      correo: 'p@tienda.co',
      rol: RolCuenta.propietario,
      activa: true,
    ),
    const UsuarioEmpresa(
      id: 'v',
      nombre: 'Vendedora',
      correo: 'v@tienda.co',
      rol: RolCuenta.vendedor,
      activa: true,
    ),
  ];
  @override
  Future<List<UsuarioEmpresa>> listarUsuarios() async => List.of(usuarios);
  @override
  Future<void> crearUsuario(DatosUsuario datos) async {
    usuarios.add(
      UsuarioEmpresa(
        id: 'nuevo',
        nombre: datos.nombre,
        correo: datos.correo,
        rol: datos.rol,
        activa: true,
      ),
    );
  }

  @override
  Future<void> cambiarEstado(String id, {required bool activa}) async {
    final i = usuarios.indexWhere((u) => u.id == id);
    final u = usuarios[i];
    usuarios[i] = UsuarioEmpresa(
      id: u.id,
      nombre: u.nombre,
      correo: u.correo,
      rol: u.rol,
      activa: activa,
    );
  }

  @override
  Future<void> cambiarRol(String id, RolCuenta rol) async {
    final i = usuarios.indexWhere((u) => u.id == id);
    final u = usuarios[i];
    usuarios[i] = UsuarioEmpresa(
      id: u.id,
      nombre: u.nombre,
      correo: u.correo,
      rol: rol,
      activa: u.activa,
    );
  }

  @override
  Future<void> restablecerClave(String id, String clave) async =>
      claves[id] = clave;
}

void main() {
  Future<void> abrir(WidgetTester t, UsuariosFalsos usuarios) async {
    await t.pumpWidget(
      MaterialApp(home: UsuariosEmpresaScreen(usuarios: usuarios)),
    );
    await t.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester t, String key) async {
    final finder = find.byKey(ValueKey(key));
    await t.ensureVisible(finder);
    await t.tap(finder);
    await t.pumpAndSettle();
  }

  testWidgets('propietario protegido y desactivación confirmada', (t) async {
    final usuarios = UsuariosFalsos();
    await abrir(t, usuarios);
    expect(find.byKey(const ValueKey('estado-p@tienda.co')), findsNothing);
    await tocar(t, 'estado-v@tienda.co');
    expect(usuarios.usuarios[1].activa, isTrue);
    await tocar(t, 'confirmar-desactivar');
    expect(usuarios.usuarios[1].activa, isFalse);
    expect(find.text('Desactivada'), findsOneWidget);
  });
  testWidgets('cambia el rol de un empleado, no el del propietario', (t) async {
    final usuarios = UsuariosFalsos();
    await abrir(t, usuarios);
    expect(find.byKey(const ValueKey('rol-p@tienda.co')), findsNothing);

    await tocar(t, 'rol-v@tienda.co');
    expect(find.text(RolCuenta.consulta.descripcion), findsOneWidget);
    await tocar(t, 'rol-opcion-consulta');

    expect(usuarios.usuarios[1].rol, RolCuenta.consulta);
    expect(find.text('Consulta'), findsOneWidget);
  });
  testWidgets('restablece contraseña con confirmación', (t) async {
    final usuarios = UsuariosFalsos();
    await abrir(t, usuarios);
    await tocar(t, 'clave-v@tienda.co');
    await t.enterText(
      find.byKey(const ValueKey('nueva-clave')),
      'Nueva clave 2026',
    );
    await t.enterText(
      find.byKey(const ValueKey('confirmar-nueva-clave')),
      'Nueva clave 2026',
    );
    await tocar(t, 'guardar-nueva-clave');
    expect(usuarios.claves['v'], 'Nueva clave 2026');
  });
  testWidgets('crea empleado y muestra descripción del rol', (t) async {
    final usuarios = UsuariosFalsos();
    await abrir(t, usuarios);
    await tocar(t, 'nuevo-usuario');
    expect(find.text(RolCuenta.vendedor.descripcion), findsOneWidget);
    await t.enterText(
      find.byKey(const ValueKey('nombre-usuario')),
      'Persona Nueva',
    );
    await t.enterText(
      find.byKey(const ValueKey('correo-usuario')),
      'nueva@tienda.co',
    );
    await t.enterText(
      find.byKey(const ValueKey('clave-usuario')),
      'Nueva clave 2026',
    );
    await t.enterText(
      find.byKey(const ValueKey('confirmar-clave-usuario')),
      'Nueva clave 2026',
    );
    await tocar(t, 'guardar-usuario');
    expect(usuarios.usuarios.last.nombre, 'Persona Nueva');
    expect(usuarios.usuarios.last.rol, RolCuenta.vendedor);
  });
  testWidgets('valida campos fuera de pantalla antes de guardar', (t) async {
    final usuarios = UsuariosFalsos();
    t.view.physicalSize = const Size(360, 450);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await abrir(t, usuarios);
    await tocar(t, 'nuevo-usuario');
    await tocar(t, 'guardar-usuario');
    expect(usuarios.usuarios.length, 2);
    expect(find.text('Escribe el nombre del usuario.'), findsOneWidget);
  });
}
