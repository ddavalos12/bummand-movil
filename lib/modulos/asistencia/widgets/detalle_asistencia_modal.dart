import 'package:flutter/material.dart';

import '../../../nucleo/tema/colores.dart';
import 'radar_geocerca_widget.dart';

/// BottomSheet para ver el detalle completo de un registro de asistencia con radar GPS.
class DetalleAsistenciaModal extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String tipo_registro;
  final String lugar;
  final String ingreso;
  final String salida;
  final String horas_trabajadas;
  final String distancia;
  final bool dentro_geocerca;
  final double precision_gps;

  const DetalleAsistenciaModal({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.tipo_registro,
    required this.lugar,
    required this.ingreso,
    required this.salida,
    required this.horas_trabajadas,
    required this.distancia,
    this.dentro_geocerca = true,
    this.precision_gps = 6.0,
  });

  static void mostrar(
    BuildContext context, {
    required String titulo,
    required String subtitulo,
    required String tipo_registro,
    required String lugar,
    required String ingreso,
    required String salida,
    required String horas_trabajadas,
    required String distancia,
    bool dentro_geocerca = true,
    double precision_gps = 6.0,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DetalleAsistenciaModal(
        titulo: titulo,
        subtitulo: subtitulo,
        tipo_registro: tipo_registro,
        lugar: lugar,
        ingreso: ingreso,
        salida: salida,
        horas_trabajadas: horas_trabajadas,
        distancia: distancia,
        dentro_geocerca: dentro_geocerca,
        precision_gps: precision_gps,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tirador superior del Bottom Sheet
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Registro de Asistencia',
                  style: TextStyle(
                    color: BumandColores.AZUL_DIACONIA,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          Text(
            titulo,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BumandColores.NEGRO,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),

          // Radar de Geocerca
          RadarGeocercaWidget(
            escaneando: false,
            dentro_geocerca: dentro_geocerca,
            distancia_m: double.tryParse(distancia.replaceAll(RegExp(r'[^0-9\.]'), '')) ?? 38.0,
            radio_m: 50.0,
          ),
          const SizedBox(height: 18),

          // Filas con la información del registro
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _construirFila('Tipo de registro', tipo_registro),
                const Divider(height: 18, color: Color(0xFFE2E8F0)),
                _construirFila('Lugar', lugar),
                const Divider(height: 18, color: Color(0xFFE2E8F0)),
                _construirFila('Ingreso', ingreso, icono: Icons.login, color_icono: const Color(0xFF10B981)),
                const Divider(height: 18, color: Color(0xFFE2E8F0)),
                _construirFila('Salida', salida, icono: Icons.logout, color_icono: BumandColores.NARANJA_OSCURO),
                const Divider(height: 18, color: Color(0xFFE2E8F0)),
                _construirFila('Horas trabajadas', horas_trabajadas, destacado: true),
                const Divider(height: 18, color: Color(0xFFE2E8F0)),
                _construirFila('Distancia al punto', distancia),
              ],
            ),
          ),
          const SizedBox(height: 20),

          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: BumandColores.AZUL_DIACONIA,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _construirFila(
    String etiqueta,
    String valor, {
    IconData? icono,
    Color? color_icono,
    bool destacado = false,
  }) {
    return Row(
      children: [
        if (icono != null) ...[
          Icon(icono, size: 16, color: color_icono ?? Colors.grey.shade600),
          const SizedBox(width: 6),
        ],
        Text(
          etiqueta,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Text(
          valor,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: destacado
                ? BumandColores.AZUL_DIACONIA
                : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
