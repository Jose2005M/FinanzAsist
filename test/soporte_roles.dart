import 'dart:io';

import 'package:finanzasist/data/autenticacion_local.dart';
import 'package:finanzasist/data/base_datos_local.dart';
import 'package:finanzasist/data/repositorio_sqlite.dart';
import 'package:finanzasist/data/usuarios_empresa.dart';
import 'package:finanzasist/models/operacion.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const claveRoles = 'contraseña de prueba 2026';
final fechaRoles = DateTime.utc(2026, 11, 19, 15);

class PlantillaRoles {
  late Directory carpeta;
  String get ruta => '${carpeta.path}/plantilla.db';

  Future<void> crear() async {
    sqfliteFfiInit();
    carpeta = await Directory.systemTemp.createTemp('roles-plantilla-');
    final base = BaseDatosLocal(factory: databaseFactoryFfi, ruta: ruta);
    final auth = AutenticacionLocal(base: base);
    await auth.registrar(
      const DatosRegistro(
        empresa: 'Empresa de roles',
        propietario: 'Dueña',
        correo: 'propietario@roles.com',
        clave: claveRoles,
      ),
    );
    final usuarios = UsuariosEmpresa(base: base, sesion: auth.sesion!);
    for (final rol in RolCuenta.empleados) {
      await usuarios.crearUsuario(
        DatosUsuario(
          nombre: rol.etiqueta,
          correo: '${rol.name}@roles.com',
          clave: claveRoles,
          rol: rol,
        ),
      );
    }
    final repo = RepositorioSqlite.conSesion(
      base: base,
      sesion: auth.sesion!,
      reloj: () => fechaRoles,
    );
    final producto = await repo.crearProducto(
      nombre: 'Café',
      costoCompra: 30,
      precioVenta: 50,
    );
    await repo.confirmarOperacion(
      SolicitudOperacion(
        id: 'inicial',
        tipo: TipoOperacion.inicial,
        motivo: 'Apertura',
        lineas: [
          LineaOperacion(
            productoId: producto.id,
            cantidad: 20,
            valorUnitario: 30,
          ),
        ],
      ),
    );
    await repo.confirmarOperacion(
      SolicitudOperacion(
        id: 'venta-duena',
        tipo: TipoOperacion.venta,
        lineas: [
          LineaOperacion(
            productoId: producto.id,
            cantidad: 1,
            valorUnitario: 50,
          ),
        ],
      ),
    );
    auth.dispose();
    await base.cerrar();
  }

  Future<CasoRoles> copiar() async {
    final carpetaCaso = await Directory.systemTemp.createTemp('roles-caso-');
    final rutaCaso = '${carpetaCaso.path}/datos.db';
    await File(ruta).copy(rutaCaso);
    return CasoRoles(
      carpetaCaso,
      BaseDatosLocal(factory: databaseFactoryFfi, ruta: rutaCaso),
    );
  }

  Future<void> cerrar() => carpeta.delete(recursive: true);
}

class CasoRoles {
  CasoRoles(this.carpeta, this.base);
  final Directory carpeta;
  final BaseDatosLocal base;
  final List<AutenticacionLocal> accesos = [];

  Future<RepositorioSqlite> entrar(RolCuenta rol) async {
    final auth = AutenticacionLocal(base: base);
    accesos.add(auth);
    await auth.iniciarSesion('${rol.name}@roles.com', claveRoles);
    return RepositorioSqlite.conSesion(
      base: base,
      sesion: auth.sesion!,
      reloj: () => fechaRoles,
    );
  }

  Future<void> cerrar() async {
    for (final auth in accesos) {
      auth.dispose();
    }
    await base.cerrar();
    await carpeta.delete(recursive: true);
  }
}
