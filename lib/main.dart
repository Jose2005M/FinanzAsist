import 'package:flutter/material.dart';

import 'data/producto_repository.dart';
import 'data/repositorio_simulado.dart';
import 'screens/inventario_screen.dart';

void main() {
  runApp(const FinanzAsistApp());
}

class FinanzAsistApp extends StatelessWidget {
  const FinanzAsistApp({super.key, this.repositorio});

  final ProductoRepository? repositorio;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinanzAsist',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007A69)),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: InventarioScreen(repositorio: repositorio ?? RepositorioSimulado()),
    );
  }
}
