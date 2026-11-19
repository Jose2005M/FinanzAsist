import 'package:finanzasist/data/almacen_guias.dart';
import 'package:finanzasist/models/guia_modulo.dart';

// Los recorridos de negocio representan a un usuario que ya leyó las guías.
// El primer uso y la ayuda abierta se comprueban en guias_widget_test.dart.
AlmacenGuias guiasRevisadas() =>
    AlmacenGuiasMemoria(vistas: ModuloGuia.values.toSet());
