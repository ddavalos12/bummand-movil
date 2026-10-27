import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores.dart';

/// Cult UI — Borde Luminoso en Rotación (Border Beam)
/// Traza un haz de luz suave y animado por el perímetro de una tarjeta para
/// destacar logros institucionales o estado de validación.
class BordeLuminoso extends StatefulWidget {
  final Widget hijo;
  final double ancho_borde;
  final double radio_esquinas;
  final Duration duracion;
  final Color color_haz;
  final Color color_haz_secundario;

  const BordeLuminoso({
    super.key,
    required this.hijo,
    this.ancho_borde = 2.0,
    this.radio_esquinas = 16.0,
    this.duracion = const Duration(seconds: 4),
    this.color_haz = BumandColores.azulCieloSuave,
    this.color_haz_secundario = BumandColores.amarilloRadiante,
  });

  @override
  State<BordeLuminoso> createState() => _BordeLuminosoState();
}

class _BordeLuminosoState extends State<BordeLuminoso>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(
      vsync: this,
      duration: widget.duracion,
    )..repeat();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controlador,
      builder: (context, child) {
        return CustomPaint(
          painter: _PintorBordeLuminoso(
            progreso: _controlador.value,
            ancho_borde: widget.ancho_borde,
            radio_esquinas: widget.radio_esquinas,
            color_primario: widget.color_haz,
            color_secundario: widget.color_haz_secundario,
          ),
          child: widget.hijo,
        );
      },
    );
  }
}

class _PintorBordeLuminoso extends CustomPainter {
  final double progreso;
  final double ancho_borde;
  final double radio_esquinas;
  final Color color_primario;
  final Color color_secundario;

  const _PintorBordeLuminoso({
    required this.progreso,
    required this.ancho_borde,
    required this.radio_esquinas,
    required this.color_primario,
    required this.color_secundario,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      ancho_borde / 2,
      ancho_borde / 2,
      size.width - ancho_borde,
      size.height - ancho_borde,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(radio_esquinas),
    );

    final angulo_actual = progreso * 2 * math.pi;

    final pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ancho_borde
      ..shader = SweepGradient(
        startAngle: 0.0,
        endAngle: 2 * math.pi,
        transform: GradientRotation(angulo_actual),
        colors: [
          color_primario,
          color_secundario,
          Colors.transparent,
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.45, 1.0],
      ).createShader(rect);

    canvas.drawRRect(rrect, pincel);
  }

  @override
  bool shouldRepaint(covariant _PintorBordeLuminoso oldDelegate) {
    return oldDelegate.progreso != progreso;
  }
}
