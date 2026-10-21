import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

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
  final String? nombre_lugar;
  final String? direccion_lugar;
  final String? nombre_becario;
  final VoidCallback? alSeleccionarLugar;

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
    this.nombre_lugar,
    this.direccion_lugar,
    this.nombre_becario,
    this.alSeleccionarLugar,
  });

  @override
  State<RadarGeocercaWidget> createState() => _RadarGeocercaWidgetState();
}

class _RadarGeocercaWidgetState extends State<RadarGeocercaWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador_pulso;
  Timer? _temporizador_reloj;
  DateTime _ahora = DateTime.now();

  static const List<String> _DIAS = [
    'LUN',
    'MAR',
    'MIÉ',
    'JUE',
    'VIE',
    'SÁB',
    'DOM',
  ];

  static const List<String> _MESES = [
    'ENE',
    'FEB',
    'MAR',
    'ABR',
    'MAY',
    'JUN',
    'JUL',
    'AGO',
    'SEP',
    'OCT',
    'NOV',
    'DIC',
  ];

  @override
  void initState() {
    super.initState();
    _controlador_pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _temporizador_reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _ahora = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _temporizador_reloj?.cancel();
    _controlador_pulso.dispose();
    super.dispose();
  }

  String _formatearFecha(DateTime fecha) {
    final dia_nombre = _DIAS[fecha.weekday - 1];
    final mes_nombre = _MESES[fecha.month - 1];
    return "$dia_nombre ${fecha.day} $mes_nombre ${fecha.year}";
  }

  @override
  Widget build(BuildContext context) {
    final precision_m = (widget.posicion?.accuracy ?? 6.0).round();
    final distancia_m = (widget.distancia_m ?? 42.0).round();
    final hora_ingreso_texto = widget.hora_ingreso ?? '--:--';
    final hora_salida_texto = widget.hora_salida ?? '--:--';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0A1E3F),
            Color(0xFF0C192E),
            Color(0xFF060E1D),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1E3F).withValues(alpha: 0.40),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Fila superior: Precisión GPS institucional y botón de refresco
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.escaneando
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.escaneando ? 'Detectando satélites...' : 'GPS sincronizado',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.gps_fixed_rounded,
                    color: Color(0xFF38BDF8),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "GPS · precisión $precision_m m",
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: widget.alReescanear,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Centro: Círculos concéntricos de radar con marcador ámbar institucional
          SizedBox(
            height: 140,
            width: 140,
            child: AnimatedBuilder(
              animation: _controlador_pulso,
              builder: (ctx, child) {
                return CustomPaint(
                  painter: _PintorRadarAzul(
                    progreso: _controlador_pulso.value,
                    color_onda: const Color(0xFF0284C7),
                  ),
                  child: Center(
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF0F172A),
                        border: Border.all(
                          color: const Color(0xFFF59E0B),
                          width: 2.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFF59E0B),
                        size: 24,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Insignia: Dentro del radio permitido · X m
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: widget.dentro_geocerca
                  ? const Color(0xFF065F46).withValues(alpha: 0.8)
                  : const Color(0xFF991B1B).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.dentro_geocerca
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 7,
                  color: widget.dentro_geocerca
                      ? const Color(0xFF34D399)
                      : const Color(0xFFF87171),
                ),
                const SizedBox(width: 7),
                Text(
                  widget.dentro_geocerca
                      ? "Dentro del radio permitido · $distancia_m m"
                      : "Fuera del radio permitido · $distancia_m m",
                  style: TextStyle(
                    color: widget.dentro_geocerca
                        ? const Color(0xFFD1FAE5)
                        : const Color(0xFFFEE2E2),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Información de Sede/Lugar y Becario
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: widget.alSeleccionarLugar,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.apartment_rounded,
                        color: Color(0xFF38BDF8),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.nombre_lugar ?? "Iglesia Bautista Central",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.direccion_lugar != null &&
                                widget.direccion_lugar!.isNotEmpty)
                              Text(
                                widget.direccion_lugar!,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      if (widget.alSeleccionarLugar != null) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.swap_horiz_rounded,
                          color: Color(0xFF38BDF8),
                          size: 18,
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.nombre_becario != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Divider(color: Colors.white12, height: 8),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF38BDF8),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.nombre_becario!,
                          style: const TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Reloj Digital Grande y Fecha oficial
          Text(
            "${_ahora.hour.toString().padLeft(2, '0')}:${_ahora.minute.toString().padLeft(2, '0')}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatearFecha(_ahora),
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          // Fila sutil con estado de marcaciones de hoy
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Ingreso: $hora_ingreso_texto",
                style: TextStyle(
                  color: widget.hora_ingreso != null
                      ? const Color(0xFF34D399)
                      : const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text("•", style: TextStyle(color: Color(0xFF475569))),
              ),
              Text(
                "Salida: $hora_salida_texto",
                style: TextStyle(
                  color: widget.hora_salida != null
                      ? const Color(0xFF38BDF8)
                      : const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PintorRadarAzul extends CustomPainter {
  final double progreso;
  final Color color_onda;

  const _PintorRadarAzul({
    required this.progreso,
    required this.color_onda,
  });

  @override
  void paint(Canvas lienzo, Size tamano) {
    final centro = Offset(tamano.width / 2, tamano.height / 2);
    final radio_maximo = tamano.shortestSide / 2;

    for (int i = 0; i < 3; i++) {
      final fase = (progreso + (i * 0.33)) % 1.0;
      final radio = 22.0 + (fase * (radio_maximo - 22.0));
      final opacidad = ((1.0 - fase) * 0.45).clamp(0.0, 1.0);

      final pintura_relleno = Paint()
        ..color = color_onda.withValues(alpha: opacidad * 0.15)
        ..style = PaintingStyle.fill;

      final pintura_borde = Paint()
        ..color = color_onda.withValues(alpha: opacidad)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3;

      lienzo.drawCircle(centro, radio, pintura_relleno);
      lienzo.drawCircle(centro, radio, pintura_borde);
    }

    final pintura_fija = Paint()
      ..color = color_onda.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    lienzo.drawCircle(centro, radio_maximo, pintura_fija);
  }

  @override
  bool shouldRepaint(covariant _PintorRadarAzul oldDelegate) =>
      oldDelegate.progreso != progreso || oldDelegate.color_onda != color_onda;
}
