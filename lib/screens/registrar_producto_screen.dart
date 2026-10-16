import 'package:flutter/material.dart';

import '../viewmodels/inventario_view_model.dart';
import 'formulario_producto_screen.dart';

class RegistrarProductoScreen extends StatelessWidget {
  const RegistrarProductoScreen({super.key, required this.viewModel});

  final InventarioViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return FormularioProductoScreen(viewModel: viewModel);
  }
}
