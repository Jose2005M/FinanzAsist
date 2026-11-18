import 'package:flutter/material.dart';

import '../theme/tema_finanzasist.dart';

/// Marca vectorial del acceso, basada en las barras y la flecha de la referencia.
class MarcaFinanzAsist extends StatelessWidget {
  const MarcaFinanzAsist({
    super.key,
    this.compacta = false,
    this.reducida = false,
  });
  final bool compacta;
  final bool reducida;

  @override
  Widget build(BuildContext context) {
    final simbolo = ExcludeSemantics(
      child: CustomPaint(
        size: Size(
          compacta ? 48 : (reducida ? 92 : 108),
          compacta ? 40 : (reducida ? 66 : 78),
        ),
        painter: const _SimboloFinanzAsist(),
      ),
    );
    final nombre = Text(
      'FinanzAsist',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: compacta ? 26 : 30,
        fontWeight: FontWeight.w700,
        color: ColoresFinanzAsist.tinta,
        letterSpacing: -0.6,
        height: 1.15,
      ),
    );
    if (compacta) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          simbolo,
          const SizedBox(width: 10),
          Flexible(child: nombre),
        ],
      );
    }
    return Column(children: [simbolo, const SizedBox(height: 4), nombre]);
  }
}

class _SimboloFinanzAsist extends CustomPainter {
  const _SimboloFinanzAsist();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120, size.height / 90);
    final relleno = Paint()..style = PaintingStyle.fill;
    for (final barra in [
      (const Rect.fromLTWH(17, 56, 25, 25), const Color(0xFFF8D35B)),
      (const Rect.fromLTWH(49, 43, 25, 40), const Color(0xFFF5C333)),
      (const Rect.fromLTWH(81, 28, 25, 54), ColoresFinanzAsist.dorado),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          barra.$1,
          topLeft: const Radius.circular(7),
          topRight: const Radius.circular(7),
        ),
        relleno..color = barra.$2,
      );
    }
    final flecha = Path()
      ..moveTo(18, 47)
      ..cubicTo(47, 43, 80, 32, 101, 10)
      ..lineTo(94, 9)
      ..lineTo(111, 2)
      ..lineTo(109, 19)
      ..lineTo(104, 14)
      ..cubicTo(81, 37, 48, 46, 18, 49)
      ..close();
    canvas.drawPath(flecha, relleno..color = const Color(0xFF383A33));
    final base = Path()
      ..moveTo(5, 76)
      ..quadraticBezierTo(59, 94, 117, 76);
    canvas.drawPath(
      base,
      Paint()
        ..color = const Color(0xFFE6A700)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SimboloFinanzAsist oldDelegate) => false;
}
