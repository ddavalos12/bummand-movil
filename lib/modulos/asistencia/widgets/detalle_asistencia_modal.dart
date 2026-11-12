import 'package:flutter/material.dart';

import '../../../nucleo/tema/colores.dart';
import 'radar_geocerca_widget.dart';

/// BottomSheet para ver el detalle completo de un registro de asistencia con radar GPS.
///
/// Paridad con el modal Web "Auditoría Georreferenciada (WGS84)": además de la
/// jornada, puede mostrar datos del becario, coordenadas, desglose de
/// tardanza/multa y acciones de Justificar / Aprobar por Administración.
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

  // Contexto opcional de auditoría institucional
  final String? becario_nombre;
  final String? carrera;
  final double? latitud;
  final double? longitud;
  final int minutos_retraso;
  final double monto_multa_bs;
  final bool? confirmacion_presencial;
  final String? estado_aprobacion_texto;
  final VoidCallback? al_justificar;
  final VoidCallback? al_aprobar_administracion;

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
    this.becario_nombre,
    this.carrera,
    this.latitud,
    this.longitud,
    this.minutos_retraso = 0,
    this.monto_multa_bs = 0,
    this.confirmacion_presencial,
    this.estado_aprobacion_texto,
    this.al_justificar,
    this.al_aprobar_administracion,
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
    String? becario_nombre,
    String? carrera,
    double? latitud,
    double? longitud,
    int minutos_retraso = 0,
    double monto_multa_bs = 0,
    bool? confirmacion_presencial,
    String? estado_aprobacion_texto,
    VoidCallback? al_justificar,
    VoidCallback? al_aprobar_administracion,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
        becario_nombre: becario_nombre,
        carrera: carrera,
        latitud: latitud,
        longitud: longitud,
        minutos_retraso: minutos_retraso,
        monto_multa_bs: monto_multa_bs,
        confirmacion_presencial: confirmacion_presencial,
        estado_aprobacion_texto: estado_aprobacion_texto,
        al_justificar: al_justificar,
        al_aprobar_administracion: al_aprobar_administracion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiene_coordenadas = latitud != null && longitud != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
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
      child: SingleChildScrollView(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tiene_coordenadas
                        ? 'Auditoría Georreferenciada (WGS84)'
                        : 'Registro de Asistencia',
                    style: const TextStyle(
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
              distancia_m: double.tryParse(
                    distancia.replaceAll(RegExp(r'[^0-9\.]'), ''),
                  ) ??
                  38.0,
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
                  if (becario_nombre != null) ...[
                    _construirFila('Becario', becario_nombre!),
                    const Divider(height: 18, color: Color(0xFFE2E8F0)),
                  ],
                  if (carrera != null) ...[
                    _construirFila('Carrera', carrera!),
                    const Divider(height: 18, color: Color(0xFFE2E8F0)),
                  ],
                  _construirFila('Tipo de registro', tipo_registro),
                  const Divider(height: 18, color: Color(0xFFE2E8F0)),
                  _construirFila('Lugar', lugar),
                  const Divider(height: 18, color: Color(0xFFE2E8F0)),
                  _construirFila(
                    'Ingreso',
                    ingreso,
                    icono: Icons.login,
                    color_icono: const Color(0xFF10B981),
                  ),
                  const Divider(height: 18, color: Color(0xFFE2E8F0)),
                  _construirFila(
                    'Salida',
                    salida,
                    icono: Icons.logout,
                    color_icono: BumandColores.NARANJA_OSCURO,
                  ),
                  const Divider(height: 18, color: Color(0xFFE2E8F0)),
                  _construirFila('Horas trabajadas', horas_trabajadas,
                      destacado: true),
                  const Divider(height: 18, color: Color(0xFFE2E8F0)),
                  _construirFila(
                    tiene_coordenadas
                        ? 'Distancia Haversine al punto'
                        : 'Distancia al punto',
                    distancia,
                    color_valor: dentro_geocerca
                        ? const Color(0xFF047857)
                        : const Color(0xFFBE123C),
                  ),
                  if (tiene_coordenadas) ...[
                    const Divider(height: 18, color: Color(0xFFE2E8F0)),
                    _construirFila(
                      'Coordenadas WGS84',
                      '${latitud!.toStringAsFixed(5)}, ${longitud!.toStringAsFixed(5)}',
                      icono: Icons.my_location_rounded,
                      color_icono: BumandColores.AZUL_DIACONIA,
                    ),
                  ],
                  if (minutos_retraso > 0) ...[
                    const Divider(height: 18, color: Color(0xFFE2E8F0)),
                    _construirFila(
                      'Tardanza',
                      '$minutos_retraso min de retraso',
                      icono: Icons.warning_amber_rounded,
                      color_icono: const Color(0xFFD97706),
                      color_valor: const Color(0xFFB45309),
                    ),
                  ],
                  if (monto_multa_bs > 0) ...[
                    const Divider(height: 18, color: Color(0xFFE2E8F0)),
                    _construirFila(
                      'Multa Escuela de Líderes',
                      'Bs ${monto_multa_bs.toStringAsFixed(2)}',
                      icono: Icons.paid_rounded,
                      color_icono: const Color(0xFFE11D48),
                      color_valor: const Color(0xFFBE123C),
                    ),
                  ],
                  if (confirmacion_presencial != null) ...[
                    const Divider(height: 18, color: Color(0xFFE2E8F0)),
                    _construirFila(
                      'Verificación',
                      confirmacion_presencial!
                          ? '✓ Verificado presencial'
                          : 'Sin confirmación en vivo',
                      color_valor: confirmacion_presencial!
                          ? const Color(0xFF047857)
                          : const Color(0xFF64748B),
                    ),
                  ],
                  if (estado_aprobacion_texto != null) ...[
                    const Divider(height: 18, color: Color(0xFFE2E8F0)),
                    _construirFila('Aprobación', estado_aprobacion_texto!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (al_aprobar_administracion != null) ...[
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  al_aprobar_administracion!();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF004E7C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(
                  Icons.verified_user_rounded,
                  size: 18,
                  color: BumandColores.AMARILLO_RADIANTE,
                ),
                label: const Text('Aprobar por Administración'),
              ),
              const SizedBox(height: 10),
            ],
            if (al_justificar != null) ...[
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  al_justificar!();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF004E7C),
                  backgroundColor:
                      BumandColores.AMARILLO_RADIANTE.withValues(alpha: 0.12),
                  side: const BorderSide(color: BumandColores.AMARILLO_RADIANTE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.assignment_turned_in_rounded, size: 18),
                label: const Text('Justificar con Comprobante'),
              ),
              const SizedBox(height: 10),
            ],

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
      ),
    );
  }

  Widget _construirFila(
    String etiqueta,
    String valor, {
    IconData? icono,
    Color? color_icono,
    Color? color_valor,
    bool destacado = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            valor,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color_valor ??
                  (destacado
                      ? BumandColores.AZUL_DIACONIA
                      : const Color(0xFF0F172A)),
            ),
          ),
        ),
      ],
    );
  }
}
