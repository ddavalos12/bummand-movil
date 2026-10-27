import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../nucleo/tema/colores.dart';
import '../../autenticacion/proveedores/autenticacion-proveedor.dart';
import '../modelos/refrigerio-modelo.dart';

class ConstanciaRecojoModal extends ConsumerWidget {
  final RefrigerioModelo refrigerio;

  const ConstanciaRecojoModal({
    super.key,
    required this.refrigerio,
  });

  static Future<void> mostrar(BuildContext context, RefrigerioModelo refrigerio) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConstanciaRecojoModal(refrigerio: refrigerio),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(autenticacion_proveedor);
    final nombre_becario = auth.usuario?.nombre ?? 'Estudiante Becario BUMAND';
    final codigo = refrigerio.codigo_constancia ?? 'CR-2026-1025-01';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: BumandColores.blanco,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Asa de arrastre superior
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: BumandColores.grisClaro,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Encabezado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: BumandColores.grisClaro)),
                color: Color(0xFFF8FAFC),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF059669),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Diaconía FRIF-IFD · BUMAND',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: BumandColores.azulCieloSuave,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Constancia de Recojo',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: BumandColores.azulMarinoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: BumandColores.azulMarinoProfundo,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      codigo,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: BumandColores.blanco,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido con la constancia
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tarjeta Principal de la Constancia
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: BumandColores.fondo,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: BumandColores.grisClaro),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'DATOS DEL BENEFICIARIO',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: BumandColores.textoSecundario,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'RECIBIDO',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF065F46),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            nombre_becario,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: BumandColores.azulMarinoSecundario,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: BumandColores.grisClaro),
                          const SizedBox(height: 12),

                          _construirFila(
                            icono: Icons.event_available_rounded,
                            etiqueta: 'Jornada',
                            valor: refrigerio.evento_o_jornada,
                          ),
                          const SizedBox(height: 8),
                          _construirFila(
                            icono: Icons.calendar_today_rounded,
                            etiqueta: 'Fecha de Jornada',
                            valor: refrigerio.fecha,
                          ),
                          const SizedBox(height: 8),
                          _construirFila(
                            icono: Icons.access_time_filled_rounded,
                            etiqueta: 'Hora de Recojo',
                            valor: refrigerio.hora_recojo ?? '16:24 hrs',
                            es_destacado: true,
                          ),
                          const SizedBox(height: 8),
                          _construirFila(
                            icono: Icons.apartment_rounded,
                            etiqueta: 'Sede y Bloque',
                            valor: '${refrigerio.sede_nombre} · ${refrigerio.bloque}',
                          ),
                          const SizedBox(height: 8),
                          _construirFila(
                            icono: Icons.verified_user_rounded,
                            etiqueta: 'Supervisor que entregó',
                            valor: refrigerio.responsable_entrega,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tarjeta del Menú entregado
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: BumandColores.blanco,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: BumandColores.grisClaro),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MENÚ ALIMENTARIO RECIBIDO',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: BumandColores.textoSecundario,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            refrigerio.menu_detalle,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: BumandColores.negro,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Banner de Certificación Oficial
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF059669),
                            Color(0xFF047857),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF059669).withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: BumandColores.blanco.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: BumandColores.blanco,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CONFORMIDAD REGISTRADA',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFA7F3D0),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ración recibida y verificada mediante la App Móvil BUMAND.',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: BumandColores.blanco,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Pie de validación institucional
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: BumandColores.fondo,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Esta constancia digital certifica el recojo oportuno del refrigerio de la jornada formativa en conformidad con las normas de bienestar universitario de Diaconía FRIF-IFD.',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: BumandColores.textoSecundario,
                          height: 1.35,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botón Cerrar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: BumandColores.grisClaro)),
                color: BumandColores.blanco,
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BumandColores.azulMarinoProfundo,
                  foregroundColor: BumandColores.blanco,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Entendido / Cerrar',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirFila({
    required IconData icono,
    required String etiqueta,
    required String valor,
    bool es_destacado = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icono,
          size: 16,
          color: es_destacado ? BumandColores.azulMarinoProfundo : BumandColores.grisMedio,
        ),
        const SizedBox(width: 8),
        Text(
          '$etiqueta: ',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: BumandColores.textoSecundario,
          ),
        ),
        Expanded(
          child: Text(
            valor,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: es_destacado ? FontWeight.w700 : FontWeight.w600,
              color: es_destacado ? BumandColores.azulMarinoProfundo : BumandColores.negro,
            ),
          ),
        ),
      ],
    );
  }
}
