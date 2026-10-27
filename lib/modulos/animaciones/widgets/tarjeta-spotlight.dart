import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores.dart';

/// Cult UI — Tarjeta con Reflector de Puntero (Spotlight Card)
/// Proyecta una fuente de luz radial interactiva al tocar o arrastrar el dedo/mouse,
/// realzando la profundidad y estética visual del contenedor.
class TarjetaSpotlight extends StatefulWidget {
  final Widget hijo;
  final Color color_fondo;
  final Color color_luz;
  final double radio_luz;
  final BorderRadius? radio_borde;
  final EdgeInsetsGeometry padding;
  final VoidCallback? alPresionar;

  const TarjetaSpotlight({
    super.key,
    required this.hijo,
    this.color_fondo = Colors.white,
    this.color_luz = const Color(0x2800ABBD),
    this.radio_luz = 140.0,
    this.radio_borde,
    this.padding = const EdgeInsets.all(16.0),
    this.alPresionar,
  });

  @override
  State<TarjetaSpotlight> createState() => _TarjetaSpotlightState();
}

class _TarjetaSpotlightState extends State<TarjetaSpotlight> {
  Offset? _posicion_puntero;

  @override
  Widget build(BuildContext context) {
    final radio = widget.radio_borde ?? BorderRadius.circular(16.0);

    return MouseRegion(
      onHover: (evento) {
        setState(() {
          _posicion_puntero = evento.localPosition;
        });
      },
      onExit: (_) {
        setState(() {
          _posicion_puntero = null;
        });
      },
      child: GestureDetector(
        onPanUpdate: (detalles) {
          setState(() {
            _posicion_puntero = detalles.localPosition;
          });
        },
        onPanEnd: (_) {
          setState(() {
            _posicion_puntero = null;
          });
        },
        onTap: widget.alPresionar,
        child: Container(
          decoration: BoxDecoration(
            color: widget.color_fondo,
            borderRadius: radio,
            border: Border.all(
              color: BumandColores.grisClaro,
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8.0,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radio,
            child: Stack(
              children: [
                if (_posicion_puntero != null)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PintorLuzSpotlight(
                        posicion: _posicion_puntero!,
                        color_luz: widget.color_luz,
                        radio: widget.radio_luz,
                      ),
                    ),
                  ),
                Padding(
                  padding: widget.padding,
                  child: widget.hijo,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PintorLuzSpotlight extends CustomPainter {
  final Offset posicion;
  final Color color_luz;
  final double radio;

  const _PintorLuzSpotlight({
    required this.posicion,
    required this.color_luz,
    required this.radio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (posicion.dx / size.width) * 2 - 1,
          (posicion.dy / size.height) * 2 - 1,
        ),
        radius: radio / (size.width > 0 ? size.width : 1.0),
        colors: [
          color_luz,
          color_luz.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), pincel);
  }

  @override
  bool shouldRepaint(covariant _PintorLuzSpotlight oldDelegate) {
    return oldDelegate.posicion != posicion ||
        oldDelegate.color_luz != color_luz ||
        oldDelegate.radio != radio;
  }
}
