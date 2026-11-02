import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../nucleo/tema/colores.dart';
import '../modelos/refrigerio-modelo.dart';
import '../proveedores/refrigerios-proveedor.dart';

class RendirRefrigerioModal extends ConsumerStatefulWidget {
  final RefrigerioModelo refrigerio;

  const RendirRefrigerioModal({
    super.key,
    required this.refrigerio,
  });

  static Future<void> mostrar(BuildContext context, RefrigerioModelo refrigerio) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RendirRefrigerioModal(refrigerio: refrigerio),
    );
  }

  @override
  ConsumerState<RendirRefrigerioModal> createState() => _RendirRefrigerioModalState();
}


class _RendirRefrigerioModalState extends ConsumerState<RendirRefrigerioModal> {
  late TextEditingController _menu_ctrl;
  late TextEditingController _costo_total_ctrl;
  late TextEditingController _gasto1_ctrl;
  late TextEditingController _gasto2_ctrl;

  @override
  void initState() {
    super.initState();
    final total_inicial = widget.refrigerio.costo_total_bs > 0
        ? widget.refrigerio.costo_total_bs
        : 138.0;
    _menu_ctrl = TextEditingController(
      text: widget.refrigerio.menu_detalle.isNotEmpty
          ? widget.refrigerio.menu_detalle
          : 'Refrigerio de Viernes (Escuela de Líderes)',
    );
    _costo_total_ctrl = TextEditingController(
      text: total_inicial.toStringAsFixed(2),
    );
    _gasto1_ctrl = TextEditingController(
      text: (total_inicial / 2).toStringAsFixed(2),
    );
    _gasto2_ctrl = TextEditingController(
      text: (total_inicial / 2).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _menu_ctrl.dispose();
    _costo_total_ctrl.dispose();
    _gasto1_ctrl.dispose();
    _gasto2_ctrl.dispose();
    super.dispose();
  }

  double _obtenerTotal() {
    return double.tryParse(_costo_total_ctrl.text.replaceAll(',', '.')) ?? 0.0;
  }

  double _obtenerGasto1() {
    return double.tryParse(_gasto1_ctrl.text.replaceAll(',', '.')) ?? 0.0;
  }

  double _obtenerGasto2() {
    return double.tryParse(_gasto2_ctrl.text.replaceAll(',', '.')) ?? 0.0;
  }

  void _guardarRendicion() {
    final menu = _menu_ctrl.text.trim();
    if (menu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor indica una referencia para el refrigerio.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final total = _obtenerTotal();
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto total debe ser mayor a 0 Bs.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    ref.read(refrigerios_proveedor.notifier).rendirRefrigerio(
          id: widget.refrigerio.id,
          menu_detalle: menu,
          modalidad_preparacion: widget.refrigerio.modalidad_preparacion,
          ingredientes: const [],
          costo_total_bs: total,
        );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '¡Rendición registrada con éxito! Costo: Bs ${total.toStringAsFixed(2)}. Devolución solicitada al 100%.',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF059669),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre1 = widget.refrigerio.becario_encargado_1_nombre ?? 'Becario 1';
    final nombre2 = widget.refrigerio.becario_encargado_2_nombre ?? 'Becario 2';

    final total_actual = _obtenerTotal();
    final gasto1 = _obtenerGasto1();
    final gasto2 = _obtenerGasto2();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: BumandColores.blanco,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Asa de arrastre
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
                      color: BumandColores.azulMarinoProfundo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.soup_kitchen_rounded,
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
                          'Diaconía FRIF-IFD · BUMAND',
                          style: GoogleFonts.montserrat(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: BumandColores.azulCieloSuave,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Rendición de Refrigerio (Dupla)',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: BumandColores.azulMarinoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: BumandColores.grisMedio),
                  ),
                ],
              ),
            ),

            // Contenido escroleable
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                children: [
                  // Tarjeta Informativa de la Dupla y Regla del 100%
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.group_rounded,
                              size: 18,
                              color: BumandColores.azulMarinoSecundario,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Dupla encargada: $nombre1 & $nombre2',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: BumandColores.azulMarinoSecundario,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Presupuesto: 23 raciones · Bs 5.50–6.00 c/u (~Bs 138 - 150).\n'
                          '• Regla oficial: Devolución del 100% de lo gastado. Administración entregará el total a uno de los dos para que arreglen cuentas entre ustedes con total transparencia.',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: const Color(0xFF1E3A8A),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Menú preparado
                  Text(
                    'Menú Preparado / Servido',
                    style: GoogleFonts.montserrat(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: BumandColores.azulMarinoSecundario,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _menu_ctrl,
                    style: GoogleFonts.montserrat(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Ej. Sándwich de huevo tibio y café/té caliente con pan casero',
                      hintStyle: GoogleFonts.montserrat(fontSize: 12, color: BumandColores.grisMedio),
                      filled: true,
                      fillColor: BumandColores.fondo,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: BumandColores.grisClaro),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: BumandColores.grisClaro),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Inversión Total y Aporte de la Dupla
                  Text(
                    'Inversión Total y Aporte de la Dupla',
                    style: GoogleFonts.montserrat(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: BumandColores.azulMarinoSecundario,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: BumandColores.fondo,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: BumandColores.grisClaro),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Costo Total a Reembolsar (100% Devolución)',
                          style: GoogleFonts.montserrat(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: BumandColores.azulMarinoSecundario,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _costo_total_ctrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: BumandColores.azulMarinoSecundario,
                          ),
                          onChanged: (val) {
                            final nuevo_total = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                            setState(() {
                              _gasto1_ctrl.text = (nuevo_total / 2).toStringAsFixed(2);
                              _gasto2_ctrl.text = (nuevo_total / 2).toStringAsFixed(2);
                            });
                          },
                          decoration: InputDecoration(
                            prefixText: 'Bs ',
                            prefixStyle: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: BumandColores.azulMarinoSecundario,
                            ),
                            filled: true,
                            fillColor: BumandColores.blanco,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: BumandColores.grisClaro),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$nombre1 pagó:',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: BumandColores.textoSecundario,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _gasto1_ctrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      prefixText: 'Bs ',
                                      filled: true,
                                      fillColor: BumandColores.blanco,
                                      isDense: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: BumandColores.grisClaro),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$nombre2 pagó:',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: BumandColores.textoSecundario,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _gasto2_ctrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      prefixText: 'Bs ',
                                      filled: true,
                                      fillColor: BumandColores.blanco,
                                      isDense: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: const BorderSide(color: BumandColores.grisClaro),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'ℹ️ La receta y preparación de alimentos se realiza en reserva por cada dupla. No es necesario detallar ingredientes.',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: BumandColores.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Resumen de Devolución 100% y Desglose por Becario
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Devolución Solicitada (100%):',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF166534),
                              ),
                            ),
                            Text(
                              'Bs ${total_actual.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 14, color: Color(0xFFBBF7D0)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '• $nombre1 pagó:',
                              style: GoogleFonts.montserrat(fontSize: 11, color: const Color(0xFF14532D)),
                            ),
                            Text(
                              'Bs ${gasto1.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF14532D),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '• $nombre2 pagó:',
                              style: GoogleFonts.montserrat(fontSize: 11, color: const Color(0xFF14532D)),
                            ),
                            Text(
                              'Bs ${gasto2.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF14532D),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botón de Envío
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BumandColores.amarilloRadiante,
                      foregroundColor: BumandColores.azulMarinoSecundario,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _guardarRendicion,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                    label: Text(
                      'Registrar Rendición (Solicitar 100% Devolución)',
                      style: GoogleFonts.montserrat(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
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
}
