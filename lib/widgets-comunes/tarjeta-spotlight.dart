import 'package:flutter/material.dart';

import '../nucleo/tema/colores.dart';

/// Tarjeta con reflector de luz reactivo (Cult UI - Spotlight Card)
/// Proyecta un halo radial sutil siguiendo la interacción y puede trazar un borde luminoso.
class TarjetaSpotlight extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radio_borde;
  final Color color_fondo;
  final Color? color_foco;
  final bool mostrar_borde_luminoso;

  const TarjetaSpotlight({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radio_borde = 24.0,
    this.color_fondo = Colors.white,
    this.color_foco,
    this.mostrar_borde_luminoso = false,
  });

  @override
  State<TarjetaSpotlight> createState() => _TarjetaSpotlightState();
}

class _TarjetaSpotlightState extends State<TarjetaSpotlight>
    with SingleTickerProviderStateMixin {
  Offset? _posicion_cursor;
  bool _esta_interactuando = false;
  late final AnimationController? _controlador_borde;

  @override
  void initState() {
    super.initState();
    if (widget.mostrar_borde_luminoso) {
      _controlador_borde = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 4),
      )..repeat();
    } else {
      _controlador_borde = null;
    }
  }

  @override
  void dispose() {
    _controlador_borde?.dispose();
    super.dispose();
  }

  void _actualizarPosicion(Offset local) {
    setState(() {
      _posicion_cursor = local;
      _esta_interactuando = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color_luz = widget.color_foco ??
        BumandColores.TURQUESA_DIACONIA.withValues(alpha: 0.15);

    return MouseRegion(
      onHover: (e) => _actualizarPosicion(e.localPosition),
      onExit: (_) => setState(() => _esta_interactuando = false),
      child: GestureDetector(
        onPanDown: (e) => _actualizarPosicion(e.localPosition),
        onPanUpdate: (e) => _actualizarPosicion(e.localPosition),
        onPanEnd: (_) => setState(() => _esta_interactuando = false),
        onPanCancel: () => setState(() => _esta_interactuando = false),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radio_borde),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.radio_borde),
            child: Stack(
              children: [
                // Fondo base
                Container(
                  color: widget.color_fondo,
                ),

                // Reflector dinámico (Spotlight)
                if (_esta_interactuando && _posicion_cursor != null)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PintorSpotlight(
                        centro: _posicion_cursor!,
                        color_luz: color_luz,
                        radio: 160.0,
                      ),
                    ),
                  ),

                // Borde animado perimetral si está activo
                if (widget.mostrar_borde_luminoso && _controlador_borde != null)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _controlador_borde,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _PintorBordeLuminoso(
                            progreso: _controlador_borde.value,
                            radio_borde: widget.radio_borde,
                          ),
                        );
                      },
                    ),
                  ),

                // Contenido interno
                Padding(
                  padding: widget.padding,
                  child: widget.child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PintorSpotlight extends CustomPainter {
  final Offset centro;
  final Color color_luz;
  final double radio;

  _PintorSpotlight({
    required this.centro,
    required this.color_luz,
    required this.radio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: centro, radius: radio);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color_luz, color_luz.withValues(alpha: 0.0)],
        stops: const [0.0, 1.0],
      ).createShader(rect);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _PintorSpotlight oldDelegate) {
    return oldDelegate.centro != centro ||
        oldDelegate.color_luz != color_luz ||
        oldDelegate.radio != radio;
  }
}

class _PintorBordeLuminoso extends CustomPainter {
  final double progreso;
  final double radio_borde;

  _PintorBordeLuminoso({required this.progreso, required this.radio_borde});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(radio_borde),
    );

    final sweep = SweepGradient(
      startAngle: 0.0,
      endAngle: 3.14159 * 2,
      transform: GradientRotation(progreso * 3.14159 * 2),
      colors: const [
        Colors.transparent,
        BumandColores.TURQUESA_DIACONIA,
        BumandColores.NARANJA,
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 0.55, 1.0],
    );

    final paint = Paint()
      ..shader = sweep.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _PintorBordeLuminoso oldDelegate) {
    return oldDelegate.progreso != progreso;
  }
}
