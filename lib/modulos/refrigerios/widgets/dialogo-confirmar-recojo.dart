import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../nucleo/tema/colores.dart';
import '../../autenticacion/proveedores/autenticacion-proveedor.dart';
import '../modelos/refrigerio-modelo.dart';
import '../proveedores/refrigerios-proveedor.dart';
import 'constancia-recojo-modal.dart';

class DialogoConfirmarRecojo extends ConsumerStatefulWidget {
  final RefrigerioModelo refrigerio;

  const DialogoConfirmarRecojo({
    super.key,
    required this.refrigerio,
  });

  static Future<void> mostrar(BuildContext context, RefrigerioModelo refrigerio) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DialogoConfirmarRecojo(refrigerio: refrigerio),
    );
  }

  @override
  ConsumerState<DialogoConfirmarRecojo> createState() => _DialogoConfirmarRecojoState();
}

class _DialogoConfirmarRecojoState extends ConsumerState<DialogoConfirmarRecojo> {
  bool _conformidad_aceptada = true;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(autenticacion_proveedor);
    final nombre_becario = auth.usuario?.nombre ?? 'Estudiante Becario BUMAND';
    final ahora = DateTime.now();
    final hora_actual_str =
        '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')} hrs';

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: BumandColores.grisClaro)),
                color: Color(0xFFF8FAFC),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: BumandColores.azulMarinoProfundo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.how_to_reg_rounded,
                      color: BumandColores.azulMarinoProfundo,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Confirmar Recojo de Refrigerio',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: BumandColores.azulMarinoSecundario,
                          ),
                        ),
                        Text(
                          'Registro de conformidad del estudiante',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: BumandColores.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contenido con detalles del refrigerio a recoger
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tarjeta del Becario y Jornada
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
                            children: [
                              const Icon(
                                Icons.person_rounded,
                                size: 18,
                                color: BumandColores.azulMarinoProfundo,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  nombre_becario,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: BumandColores.azulMarinoSecundario,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: BumandColores.azulCieloSuave.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'BECARIO',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: BumandColores.azulMarinoProfundo,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: BumandColores.grisClaro),
                          const SizedBox(height: 12),

                          _construirFila(
                            icono: Icons.event_note_rounded,
                            etiqueta: 'Jornada',
                            valor: widget.refrigerio.evento_o_jornada,
                          ),
                          const SizedBox(height: 8),
                          _construirFila(
                            icono: Icons.calendar_today_rounded,
                            etiqueta: 'Fecha',
                            valor: widget.refrigerio.fecha,
                          ),
                          const SizedBox(height: 8),
                          _construirFila(
                            icono: Icons.apartment_rounded,
                            etiqueta: 'Punto de Recojo',
                            valor: '${widget.refrigerio.sede_nombre} · ${widget.refrigerio.bloque}',
                          ),
                          const SizedBox(height: 8),
                          _construirFila(
                            icono: Icons.access_time_rounded,
                            etiqueta: 'Hora de Registro',
                            valor: hora_actual_str,
                            es_hora: true,
                          ),
                          const SizedBox(height: 8),
                          _construirFila(
                            icono: Icons.verified_user_outlined,
                            etiqueta: 'Despachado por',
                            valor: widget.refrigerio.responsable_entrega,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tarjeta destacada del Menú asignado
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            BumandColores.azulMarinoProfundo.withValues(alpha: 0.08),
                            BumandColores.azulCieloSuave.withValues(alpha: 0.12),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: BumandColores.azulCieloSuave.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: BumandColores.blanco,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.restaurant_rounded,
                              color: BumandColores.azulMarinoProfundo,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MENÚ CORRESPONDIENTE',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: BumandColores.azulMarinoProfundo,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.refrigerio.menu_detalle,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Declaración de Conformidad
                    InkWell(
                      onTap: () {
                        setState(() {
                          _conformidad_aceptada = !_conformidad_aceptada;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _conformidad_aceptada,
                              onChanged: (val) {
                                setState(() {
                                  _conformidad_aceptada = val ?? false;
                                });
                              },
                              activeColor: BumandColores.azulMarinoProfundo,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Declaro haber recibido en persona mi ración de refrigerio correspondiente a esta jornada de BUMAND.',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF92400E),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botones Inferiores
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: BumandColores.grisClaro)),
                color: BumandColores.blanco,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: const BorderSide(color: BumandColores.grisClaro),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: BumandColores.negro,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _conformidad_aceptada
                            ? BumandColores.azulMarinoProfundo
                            : BumandColores.grisMedio,
                        foregroundColor: BumandColores.blanco,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                      ),
                      onPressed: _conformidad_aceptada
                          ? () {
                              ref
                                  .read(refrigerios_proveedor.notifier)
                                  .confirmarRecojo(widget.refrigerio.id);
                              Navigator.of(context).pop();

                              // Buscar el refrigerio recién actualizado para mostrar su constancia
                              final actualizado = ref
                                  .read(refrigerios_proveedor)
                                  .firstWhere((r) => r.id == widget.refrigerio.id);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: BumandColores.azulMarinoProfundo,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  content: Text(
                                    '¡Recojo registrado exitosamente! Tu constancia digital está lista.',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: BumandColores.blanco,
                                    ),
                                  ),
                                ),
                              );

                              // Abrir automáticamente la constancia digital
                              ConstanciaRecojoModal.mostrar(context, actualizado);
                            }
                          : null,
                      child: Text(
                        'Confirmar Recojo',
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
          ],
        ),
      ),
    );
  }

  Widget _construirFila({
    required IconData icono,
    required String etiqueta,
    required String valor,
    bool es_hora = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, size: 16, color: BumandColores.grisMedio),
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
            style: es_hora
                ? GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: BumandColores.azulMarinoProfundo,
                  )
                : GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: BumandColores.negro,
                  ),
          ),
        ),
      ],
    );
  }
}
