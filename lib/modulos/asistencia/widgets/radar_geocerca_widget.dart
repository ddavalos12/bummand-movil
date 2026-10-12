import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../nucleo/tema/colores.dart';

/// Widget interactivo de Radar de Geocerca con círculos concéntricos animados,
/// badge de GPS con precisión en metros y chip de estado de radio permitido.
class RadarGeocercaWidget extends StatefulWidget {
  final bool escaneando;
  final bool dentro_geocerca;
  final Position? posicion;
  final double? distancia_m;
  final double radio_m;
  final String? error_gps;
  final VoidCallback? alReescanear;

  const RadarGeocercaWidget({
    super.key,
    required this.escaneando,
    required this.dentro_geocerca,
    this.posicion,
    this.distancia_m,
    this.radio_m = 50.0,
    this.error_gps,
    this.alReescanear,
  });

  @override
  State<RadarGeocercaWidget> createState() => _RadarGeocercaWidgetState();
}

class _RadarGeocercaWidgetState extends State<RadarGeocercaWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador_pulso;

  @override
  void initState() {
    super.initState();
    _controlador_pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controlador_pulso.dispose();
    super.dispose();
  }

  Color _obtenerColorRadar() {
    if (widget.escaneando) return BumandColores.AZUL_DIACONIA;
    if (widget.dentro_geocerca) return const Color(0xFF10B981);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final color_radar = _obtenerColorRadar();
    final precision_m = widget.posicion?.accuracy ?? 6.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.dentro_geocerca
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Círculos concéntricos animados de Radar
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 150,
                width: 150,
                child: AnimatedBuilder(
                  animation: _controlador_pulso,
                  builder: (ctx, child) {
                    return CustomPaint(
                      painter: _PintorCirculosConcentricos(
                        progreso: _controlador_pulso.value,
                        color_onda: color_radar,
                        activo: widget.escaneando || widget.dentro_geocerca,
                      ),
                      child: Center(
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color_radar,
                            boxShadow: [
                              BoxShadow(
                                color: color_radar.withValues(alpha: 0.35),
                                blurRadius: 12,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.escaneando
                                ? Icons.radar
                                : widget.dentro_geocerca
                                    ? Icons.location_on
                                    : Icons.location_off,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Badge de precisión GPS
              Positioned(
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.gps_fixed,
                        color: BumandColores.TURQUESA_DIACONIA,
                        size: 12,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'GPS · precisión ${precision_m.round()}m',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chip de estado de geocerca
          if (widget.escaneando)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: BumandColores.AZUL_DIACONIA,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Escaneando ubicación GPS...',
                    style: TextStyle(
                      color: BumandColores.AZUL_DIACONIA,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else if (widget.dentro_geocerca)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dentro del radio permitido · ${(widget.distancia_m ?? 42).round()} m',
                    style: const TextStyle(
                      color: Color(0xFF065F46),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFEF4444)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.distancia_m != null
                        ? 'Fuera de radio · ${widget.distancia_m!.round()} m (Tolerancia: ${widget.radio_m.round()}m)'
                        : 'Fuera de radio',
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          if (widget.error_gps != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.error_gps!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 12,
              ),
            ),
          ],

          if (widget.alReescanear != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: widget.escaneando ? null : widget.alReescanear,
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text(
                'Reescanear GPS',
                style: TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                foregroundColor: BumandColores.AZUL_DIACONIA,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PintorCirculosConcentricos extends CustomPainter {
  final double progreso;
  final Color color_onda;
  final bool activo;

  const _PintorCirculosConcentricos({
    required this.progreso,
    required this.color_onda,
    required this.activo,
  });

  @override
  void paint(Canvas lienzo, Size tamano) {
    final centro = Offset(tamano.width / 2, tamano.height / 2);
    final radio_maximo = tamano.shortestSide / 2;

    for (int i = 0; i < 3; i++) {
      final fase = (progreso + (i * 0.33)) % 1.0;
      final radio = 28.0 + (fase * (radio_maximo - 28.0));
      final opacidad = activo ? ((1.0 - fase) * 0.40).clamp(0.0, 1.0) : 0.10;

      final pintura_relleno = Paint()
        ..color = color_onda.withValues(alpha: opacidad * 0.25)
        ..style = PaintingStyle.fill;

      final pintura_borde = Paint()
        ..color = color_onda.withValues(alpha: opacidad)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      lienzo.drawCircle(centro, radio, pintura_relleno);
      lienzo.drawCircle(centro, radio, pintura_borde);
    }

    final pintura_fija = Paint()
      ..color = color_onda.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    lienzo.drawCircle(centro, radio_maximo, pintura_fija);
  }

  @override
  bool shouldRepaint(covariant _PintorCirculosConcentricos oldDelegate) =>
      oldDelegate.progreso != progreso ||
      oldDelegate.color_onda != color_onda ||
      oldDelegate.activo != activo;
}
