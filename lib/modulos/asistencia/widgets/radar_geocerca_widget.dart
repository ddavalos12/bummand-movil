import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Widget interactivo de Radar de Geocerca con gradiente cian-turquesa institucional,
/// círculos concéntricos animados, ícono de transeúnte y marcas horarias de ingreso/salida.
class RadarGeocercaWidget extends StatefulWidget {
  final bool escaneando;
  final bool dentro_geocerca;
  final Position? posicion;
  final double? distancia_m;
  final double radio_m;
  final String? error_gps;
  final VoidCallback? alReescanear;
  final String? hora_ingreso;
  final String? hora_salida;

  const RadarGeocercaWidget({
    super.key,
    required this.escaneando,
    required this.dentro_geocerca,
    this.posicion,
    this.distancia_m,
    this.radio_m = 50.0,
    this.error_gps,
    this.alReescanear,
    this.hora_ingreso,
    this.hora_salida,
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

  @override
  Widget build(BuildContext context) {
    final hora_ingreso_texto = widget.hora_ingreso ?? '--:--';
    final hora_salida_texto = widget.hora_salida ?? '--:--';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0284C7),
            Color(0xFF009EA8),
            Color(0xFF06B6D4),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Fila Superior: Estado de Búsqueda y Spinner/Refresco
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.escaneando ? 'Buscando GPS...' : 'Buscando GPS...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              if (widget.escaneando)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                GestureDetector(
                  onTap: widget.alReescanear,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Centro: Radar con Ondas Concéntricas y Monigote Central
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 160,
                width: 160,
                child: AnimatedBuilder(
                  animation: _controlador_pulso,
                  builder: (ctx, child) {
                    return CustomPaint(
                      painter: _PintorCirculosConcentricos(
                        progreso: _controlador_pulso.value,
                        color_onda: Colors.white,
                        activo: true,
                      ),
                      child: Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_walk_rounded,
                            color: Color(0xFF475569),
                            size: 28,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Balizas decorativas orbitales
              Positioned(
                top: 30,
                right: 38,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                  child: const Center(
                    child: Icon(Icons.circle, size: 6, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                bottom: 34,
                left: 36,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                  child: const Center(
                    child: Icon(Icons.circle, size: 5, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fila Inferior: Horas de Ingreso y Salida
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Ingreso
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBAE6FD),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Ingreso · de dónde partió',
                        style: TextStyle(
                          color: Color(0xFFE0F2FE),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hora_ingreso_texto,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),

              // Salida
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBAE6FD),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Salida',
                        style: TextStyle(
                          color: Color(0xFFE0F2FE),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hora_salida_texto,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      final opacidad = activo ? ((1.0 - fase) * 0.35).clamp(0.0, 1.0) : 0.08;

      final pintura_relleno = Paint()
        ..color = color_onda.withValues(alpha: opacidad * 0.20)
        ..style = PaintingStyle.fill;

      final pintura_borde = Paint()
        ..color = color_onda.withValues(alpha: opacidad)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      lienzo.drawCircle(centro, radio, pintura_relleno);
      lienzo.drawCircle(centro, radio, pintura_borde);
    }

    final pintura_fija = Paint()
      ..color = color_onda.withValues(alpha: 0.20)
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
