import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../nucleo/tema/colores.dart';

class BloqueEdificio {
  final String id;
  final String nombre;
  final String descripcion;
  final double latitud;
  final double longitud;
  final IconData icono;
  final bool es_auditorio_viernes;

  const BloqueEdificio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.latitud,
    required this.longitud,
    required this.icono,
    this.es_auditorio_viernes = false,
  });
}

class MapaGeocercaBloquesWidget extends StatefulWidget {
  final bool escaneando;
  final bool dentro_geocerca;
  final Position? posicion;
  final double distancia_m;
  final double radio_m;
  final String? error_gps;
  final BloqueEdificio bloque_detectado;
  final List<BloqueEdificio> bloques_disponibles;
  final VoidCallback? alReescanear;
  final ValueChanged<BloqueEdificio>? alSeleccionarBloque;

  const MapaGeocercaBloquesWidget({
    super.key,
    required this.escaneando,
    required this.dentro_geocerca,
    this.posicion,
    this.distancia_m = 32.0,
    this.radio_m = 60.0,
    this.error_gps,
    required this.bloque_detectado,
    required this.bloques_disponibles,
    this.alReescanear,
    this.alSeleccionarBloque,
  });

  @override
  State<MapaGeocercaBloquesWidget> createState() =>
      _MapaGeocercaBloquesWidgetState();
}

class _MapaGeocercaBloquesWidgetState extends State<MapaGeocercaBloquesWidget> {
  bool _vista_satelital = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera del Mapa y Selector de Vista
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.map_outlined,
                        color: BumandColores.AZUL_DIACONIA,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Plano del Edificio Institucional",
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: BumandColores.NEGRO,
                          ),
                        ),
                        Text(
                          "Geocerca y detección de bloques",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: _vista_satelital ? "Modo vectorial" : "Modo satelital",
                      icon: Icon(
                        _vista_satelital ? Icons.layers : Icons.layers_outlined,
                        size: 20,
                        color: BumandColores.AZUL_DIACONIA,
                      ),
                      onPressed: () =>
                          setState(() => _vista_satelital = !_vista_satelital),
                    ),
                    IconButton(
                      tooltip: "Actualizar GPS",
                      icon: const Icon(
                        Icons.my_location,
                        size: 19,
                        color: BumandColores.TURQUESA_DIACONIA,
                      ),
                      onPressed: widget.alReescanear,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Visualización esquemática del mapa con los bloques del edificio
          Container(
            height: 170,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _vista_satelital
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _vista_satelital
                    ? const Color(0xFF334155)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Cuadrícula y textura del mapa
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PintorMapaInstitucional(
                        satelital: _vista_satelital,
                        dentro_geocerca: widget.dentro_geocerca,
                      ),
                    ),
                  ),

                  // Bloques interactivos sobre el mapa
                  Positioned(
                    top: 14,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: widget.bloques_disponibles.map((b) {
                        final es_seleccionado =
                            widget.bloque_detectado.id == b.id;
                        return GestureDetector(
                          onTap: () => widget.alSeleccionarBloque?.call(b),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: es_seleccionado
                                  ? (b.es_auditorio_viernes
                                      ? BumandColores.AZUL_DIACONIA
                                      : BumandColores.TURQUESA_DIACONIA)
                                  : (_vista_satelital
                                      ? const Color(0xFF334155).withValues(alpha: 0.85)
                                      : Colors.white.withValues(alpha: 0.9)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: es_seleccionado
                                    ? Colors.white
                                    : (b.es_auditorio_viernes
                                        ? BumandColores.AZUL_DIACONIA
                                        : Colors.grey.shade400),
                                width: es_seleccionado ? 2.0 : 1.0,
                              ),
                              boxShadow: [
                                if (es_seleccionado)
                                  BoxShadow(
                                    color: BumandColores.AZUL_DIACONIA
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  b.icono,
                                  size: 18,
                                  color: es_seleccionado
                                      ? Colors.white
                                      : (_vista_satelital
                                          ? const Color(0xFF93C5FD)
                                          : BumandColores.AZUL_DIACONIA),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  b.nombre,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: es_seleccionado
                                        ? Colors.white
                                        : (_vista_satelital
                                            ? Colors.white
                                            : BumandColores.NEGRO),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Pin indicador del usuario con GPS y geocerca
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.dentro_geocerca
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.dentro_geocerca
                                  ? "GPS en rango: ${widget.distancia_m.toStringAsFixed(0)} m"
                                  : "Fuera de geocerca (${widget.distancia_m.toStringAsFixed(0)} m)",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tarjeta Informativa del Bloque Detectado
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.bloque_detectado.es_auditorio_viernes
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.bloque_detectado.es_auditorio_viernes
                      ? const Color(0xFFBFDBFE)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.bloque_detectado.es_auditorio_viernes
                          ? BumandColores.AZUL_DIACONIA
                          : const Color(0xFF64748B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.bloque_detectado.icono,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Bloque detectado: ${widget.bloque_detectado.nombre}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                color: widget.bloque_detectado.es_auditorio_viernes
                                    ? BumandColores.AZUL_DIACONIA
                                    : BumandColores.NEGRO,
                              ),
                            ),
                            if (widget.bloque_detectado.es_auditorio_viernes) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: BumandColores.AZUL_DIACONIA,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "Viernes",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.bloque_detectado.descripcion,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PintorMapaInstitucional extends CustomPainter {
  final bool satelital;
  final bool dentro_geocerca;

  const _PintorMapaInstitucional({
    required this.satelital,
    required this.dentro_geocerca,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linea_paint = Paint()
      ..color = satelital
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    // Cuadrícula isométrica/urbana
    const paso = 28.0;
    for (double x = 0; x < size.width; x += paso) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linea_paint);
    }
    for (double y = 0; y < size.height; y += paso) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linea_paint);
    }

    // Círculo concéntrico de geocerca perimetral
    final centro = Offset(size.width / 2, size.height / 2);
    final circulo_paint = Paint()
      ..color = dentro_geocerca
          ? const Color(0xFF10B981).withValues(alpha: 0.15)
          : const Color(0xFFEF4444).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(centro, 64, circulo_paint);

    final borde_circulo = Paint()
      ..color = dentro_geocerca
          ? const Color(0xFF10B981).withValues(alpha: 0.5)
          : const Color(0xFFEF4444).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(centro, 64, borde_circulo);
  }

  @override
  bool shouldRepaint(covariant _PintorMapaInstitucional oldDelegate) {
    return oldDelegate.satelital != satelital ||
        oldDelegate.dentro_geocerca != dentro_geocerca;
  }
}
