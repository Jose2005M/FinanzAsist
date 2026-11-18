import 'package:flutter/material.dart';

import '../theme/tema_finanzasist.dart';

/// Superficie compartida para una tarea o un bloque de información relacionado.
class PanelFinanzas extends StatelessWidget {
  const PanelFinanzas({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: ColoresFinanzAsist.panel,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: ColoresFinanzAsist.sombra,
          offset: Offset(0, 8),
          blurRadius: 28,
        ),
      ],
    ),
    child: Padding(padding: padding, child: child),
  );
}

/// Mantiene las listas y formularios legibles cuando hay más ancho disponible.
class AnchoContenido extends StatelessWidget {
  const AnchoContenido({super.key, required this.child, this.maximo = 760});
  final Widget child;
  final double maximo;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maximo),
      child: child,
    ),
  );
}

class CabeceraModulo extends StatelessWidget {
  const CabeceraModulo({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.icono,
  });
  final String titulo;
  final String descripcion;
  final IconData icono;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icono, size: 28, color: ColoresFinanzAsist.foco),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                titulo,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              descripcion,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: ColoresFinanzAsist.secundaria),
            ),
          ],
        ),
      ),
    ],
  );
}

class EstadoModulo extends StatelessWidget {
  const EstadoModulo({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.icono,
    this.accion,
  });
  final String titulo;
  final String descripcion;
  final IconData icono;
  final Widget? accion;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(icono, size: 48, color: ColoresFinanzAsist.foco),
            ),
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text(
                titulo,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              descripcion,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ColoresFinanzAsist.secundaria),
            ),
            if (accion != null) ...[const SizedBox(height: 20), accion!],
          ],
        ),
      ),
    ),
  );
}

/// Encabezado y registros comparten desplazamiento, incluso con texto ampliado.
class ListadoModulo extends StatelessWidget {
  const ListadoModulo({
    super.key,
    required this.cabecera,
    required this.cantidad,
    required this.itemBuilder,
    required this.onActualizar,
    this.controller,
    this.estado,
  });
  final Widget cabecera;
  final int cantidad;
  final IndexedWidgetBuilder itemBuilder;
  final Future<void> Function() onActualizar;
  final ScrollController? controller;
  final Widget? estado;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onActualizar,
    child: CustomScrollView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: cabecera),
        if (estado != null)
          SliverFillRemaining(hasScrollBody: false, child: estado!)
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverList.separated(
              itemCount: cantidad,
              itemBuilder: itemBuilder,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
            ),
          ),
      ],
    ),
  );
}
