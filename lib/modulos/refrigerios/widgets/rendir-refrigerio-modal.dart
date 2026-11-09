import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../nucleo/tema/colores.dart';
import '../modelos/refrigerio-modelo.dart';
import '../proveedores/refrigerios-proveedor.dart';

class RendirRefrigerioModal extends ConsumerStatefulWidget {
  final RefrigerioModelo? refrigerio;

  const RendirRefrigerioModal({
    super.key,
    this.refrigerio,
  });

  static Future<void> mostrar(BuildContext context, [RefrigerioModelo? refrigerio]) {
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
  final _clave_form = GlobalKey<FormState>();

  late DateTime _fecha_entrega;
  late TextEditingController _evento_ctrl;
  late TextEditingController _cantidad_ctrl;
  late TextEditingController _costo_total_ctrl;
  late TextEditingController _costo_unitario_ctrl;
  late TextEditingController _responsable_ctrl;
  late TextEditingController _observaciones_ctrl;

  String? _encargado_1;
  String? _encargado_2;
  String _sede_seleccionada = 'Oficina Central El Alto';
  String _bloque_seleccionado = 'Bloque B (Auditorio / Cocina Diaconía)';
  bool _guardando = false;

  final List<String> _sedes = const [
    'Oficina Central El Alto',
    'Agencia Juan Pablo II',
    'Agencia La Paz Central',
    'Sucursal Villa Adela',
  ];

  final List<String> _bloques = const [
    'Bloque A (Administración)',
    'Bloque B (Auditorio / Cocina Diaconía)',
    'Bloque Único',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.refrigerio;

    if (item != null && item.fecha.isNotEmpty) {
      _fecha_entrega = DateTime.tryParse(item.fecha) ?? DateTime.now();
    } else {
      _fecha_entrega = DateTime.now();
    }

    _evento_ctrl = TextEditingController(
      text: item?.evento_o_jornada.isNotEmpty == true
          ? item!.evento_o_jornada
          : 'Escuela de Líderes (Viernes Formativo)',
    );

    final cantidad_inicial = item?.cantidad_raciones ?? 23;
    final unitario_inicial = item?.costo_unitario_bs ?? 5.0;
    final total_inicial = item?.costo_total_bs ?? (cantidad_inicial * unitario_inicial);

    _cantidad_ctrl = TextEditingController(text: cantidad_inicial.toString());
    _costo_unitario_ctrl = TextEditingController(text: unitario_inicial.toStringAsFixed(2));
    _costo_total_ctrl = TextEditingController(text: total_inicial.toStringAsFixed(2));

    _responsable_ctrl = TextEditingController(
      text: item?.responsable_entrega.isNotEmpty == true
          ? item!.responsable_entrega
          : 'Coordinación General BUMAND',
    );

    _observaciones_ctrl = TextEditingController(
      text: item?.observaciones ?? item?.menu_detalle ?? '',
    );

    _encargado_1 = item?.becario_encargado_1_nombre;
    _encargado_2 = item?.becario_encargado_2_nombre;

    if (item != null) {
      if (_sedes.contains(item.sede_nombre)) {
        _sede_seleccionada = item.sede_nombre;
      }
      if (_bloques.contains(item.bloque)) {
        _bloque_seleccionado = item.bloque;
      }
    }
  }

  @override
  void dispose() {
    _evento_ctrl.dispose();
    _cantidad_ctrl.dispose();
    _costo_total_ctrl.dispose();
    _costo_unitario_ctrl.dispose();
    _responsable_ctrl.dispose();
    _observaciones_ctrl.dispose();
    super.dispose();
  }

  void _recalcularDesdeCantidadOUnitario() {
    final cant = int.tryParse(_cantidad_ctrl.text) ?? 23;
    final unitario = double.tryParse(_costo_unitario_ctrl.text.replaceAll(',', '.')) ?? 5.0;
    final total = cant * unitario;
    _costo_total_ctrl.text = total.toStringAsFixed(2);
    setState(() {});
  }

  void _recalcularDesdeTotal() {
    final total = double.tryParse(_costo_total_ctrl.text.replaceAll(',', '.')) ?? 115.0;
    final cant = int.tryParse(_cantidad_ctrl.text) ?? 23;
    if (cant > 0) {
      final unitario = total / cant;
      _costo_unitario_ctrl.text = unitario.toStringAsFixed(2);
    }
    setState(() {});
  }

  Future<void> _seleccionarFecha() async {
    final nueva_fecha = await showDatePicker(
      context: context,
      initialDate: _fecha_entrega,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: BumandColores.azulMarinoProfundo,
              onPrimary: Colors.white,
              onSurface: BumandColores.azulMarinoSecundario,
            ),
          ),
          child: child!,
        );
      },
    );

    if (nueva_fecha != null) {
      setState(() {
        _fecha_entrega = nueva_fecha;
      });
    }
  }

  Future<void> _guardarRendicion() async {
    if (!_clave_form.currentState!.validate()) {
      return;
    }

    final cant = int.tryParse(_cantidad_ctrl.text) ?? 23;
    final total = double.tryParse(_costo_total_ctrl.text.replaceAll(',', '.')) ?? 115.0;
    final unitario = double.tryParse(_costo_unitario_ctrl.text.replaceAll(',', '.')) ?? 5.0;

    final fecha_str =
        '${_fecha_entrega.year.toString().padLeft(4, '0')}-${_fecha_entrega.month.toString().padLeft(2, '0')}-${_fecha_entrega.day.toString().padLeft(2, '0')}';

    final enc1 = _encargado_1 ?? 'María Catunta Laime';
    final enc2 = _encargado_2 ?? 'Juan Carlos Quispe';
    final obs = _observaciones_ctrl.text.trim();

    final datos = <String, dynamic>{
      'fecha': fecha_str,
      'actividad_viernes': _evento_ctrl.text.trim(),
      'evento_vinculado': _evento_ctrl.text.trim(),
      'descripcion': _evento_ctrl.text.trim(),
      'sede': _sede_seleccionada,
      'sede_nombre': _sede_seleccionada,
      'bloque': _bloque_seleccionado,
      'cantidad_raciones': cant,
      'costo_unitario_bs': unitario,
      'costo_total_bs': total,
      'presupuesto_referencial_bs': cant * 5.0,
      'porcentaje_devolucion': 100,
      'monto_devolucion_bs': total,
      'becario_encargado_1_nombre': enc1,
      'becario_encargado_2_nombre': enc2,
      'responsable_entrega': _responsable_ctrl.text.trim(),
      'observaciones': obs.isNotEmpty ? obs : 'Detalle de alimentos entregados a los becarios.',
      'menu_descripcion': obs.isNotEmpty ? obs : 'Suministro institucional de refrigerio.',
      'estado_reposicion': 'rendido_pendiente',
    };

    setState(() => _guardando = true);

    try {
      if (widget.refrigerio != null && widget.refrigerio!.id > 0) {
        await ref.read(refrigerios_proveedor.notifier).rendirRefrigerio(
              id: widget.refrigerio!.id,
              menu_detalle: obs.isNotEmpty ? obs : _evento_ctrl.text.trim(),
              modalidad_preparacion: widget.refrigerio!.modalidad_preparacion,
              ingredientes: const [],
              costo_total_bs: total,
              observaciones: obs,
            );
      } else {
        await ref.read(refrigerios_proveedor.notifier).registrarRacionesRefrigerio(datos);
      }

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Rendición registrada exitosamente! Devolución íntegra al 100% por Bs ${total.toStringAsFixed(2)}.',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
          ),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error al guardar la rendición. Intente nuevamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final becarios_disponibles = ref.watch(lista_becarios_refrigerios_proveedor);

    // Asegurar que los seleccionados existan en la lista
    if (_encargado_1 == null && becarios_disponibles.isNotEmpty) {
      _encargado_1 = becarios_disponibles.first;
    }
    if (_encargado_2 == null && becarios_disponibles.length > 1) {
      _encargado_2 = becarios_disponibles[1];
    } else if (_encargado_2 == null && becarios_disponibles.isNotEmpty) {
      _encargado_2 = becarios_disponibles.first;
    }

    final cant_actual = int.tryParse(_cantidad_ctrl.text) ?? 23;
    final total_presupuesto_oficial = cant_actual * 5.0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.94,
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

            // Encabezado del Modal
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
                      Icons.restaurant_menu_rounded,
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
                          'Registrar Raciones de Refrigerio',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: BumandColores.azulMarinoSecundario,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          'Descargo oficial de la dupla del viernes para devolución íntegra al 100%.',
                          style: GoogleFonts.montserrat(
                            fontSize: 10.5,
                            color: BumandColores.textoSecundario,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

            // Cuerpo del Formulario Escroleable
            Expanded(
              child: Form(
                key: _clave_form,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                  children: [
                    // Banner Amarillo Informativo Oficial
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.monetization_on_rounded,
                            color: Color(0xFFD97706),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Presupuesto Oficial: Bs 5.00 por persona ($cant_actual raciones × Bs 5.00 = Bs ${total_presupuesto_oficial.toStringAsFixed(2)})',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Tarifa institucional oficial de Bs 5.00 por persona. Al rendir el descargo, se procesará la devolución íntegra del 100%.',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10.5,
                                    color: const Color(0xFFB45309),
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

                    // Fila 1: Fecha de Entrega y Evento Vinculado
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _construirEtiqueta('Fecha de Entrega (Viernes)'),
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: _seleccionarFecha,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: BumandColores.fondo,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: BumandColores.grisClaro),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${_fecha_entrega.year}-${_fecha_entrega.month.toString().padLeft(2, '0')}-${_fecha_entrega.day.toString().padLeft(2, '0')}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: BumandColores.negro,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.calendar_month_rounded,
                                        size: 18,
                                        color: BumandColores.azulMarinoProfundo,
                                      ),
                                    ],
                                  ),
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
                              _construirEtiqueta('Evento o Jornada Vinculada'),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _evento_ctrl,
                                style: GoogleFonts.montserrat(fontSize: 12),
                                decoration: _construirDecoracionInput(
                                  hint: 'Escuela de Líderes (Viernes Formativo)',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Fila 2: Dupla de Becarios Encargados del Viernes
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.group_rounded,
                                size: 16,
                                color: BumandColores.azulMarinoProfundo,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Dupla de Becarios Encargados del Viernes',
                                style: GoogleFonts.montserrat(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: BumandColores.azulMarinoSecundario,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _construirEtiqueta('Becario Encargado 1'),
                                    const SizedBox(height: 4),
                                    DropdownButtonFormField<String>(
                                      initialValue: becarios_disponibles.contains(_encargado_1)
                                          ? _encargado_1
                                          : (becarios_disponibles.isNotEmpty
                                              ? becarios_disponibles.first
                                              : null),
                                      isExpanded: true,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        color: BumandColores.negro,
                                      ),
                                      decoration: _construirDecoracionInput(hint: 'Encargado 1'),
                                      items: becarios_disponibles
                                          .map((b) => DropdownMenuItem(
                                                value: b,
                                                child: Text(b, overflow: TextOverflow.ellipsis),
                                              ))
                                          .toList(),
                                      onChanged: (val) => setState(() => _encargado_1 = val),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _construirEtiqueta('Becario Encargado 2'),
                                    const SizedBox(height: 4),
                                    DropdownButtonFormField<String>(
                                      initialValue: becarios_disponibles.contains(_encargado_2)
                                          ? _encargado_2
                                          : (becarios_disponibles.length > 1
                                              ? becarios_disponibles[1]
                                              : (becarios_disponibles.isNotEmpty
                                                  ? becarios_disponibles.first
                                                  : null)),
                                      isExpanded: true,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        color: BumandColores.negro,
                                      ),
                                      decoration: _construirDecoracionInput(hint: 'Encargado 2'),
                                      items: becarios_disponibles
                                          .map((b) => DropdownMenuItem(
                                                value: b,
                                                child: Text(b, overflow: TextOverflow.ellipsis),
                                              ))
                                          .toList(),
                                      onChanged: (val) => setState(() => _encargado_2 = val),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Fila 3: Cantidad de Raciones, Costo Total y Costo Unitario
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _construirEtiqueta('Cantidad de Raciones'),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _cantidad_ctrl,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: _construirDecoracionInput(hint: '23'),
                                onChanged: (_) => _recalcularDesdeCantidadOUnitario(),
                                validator: (v) =>
                                    (v == null || int.tryParse(v) == null) ? 'Inválido' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _construirEtiqueta('Costo Total (Bs)'),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _costo_total_ctrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: BumandColores.azulMarinoProfundo,
                                ),
                                decoration: _construirDecoracionInput(hint: '115.00'),
                                onChanged: (_) => _recalcularDesdeTotal(),
                                validator: (v) =>
                                    (v == null || double.tryParse(v.replaceAll(',', '.')) == null)
                                        ? 'Inválido'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _construirEtiqueta('Costo Unitario (Bs)'),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _costo_unitario_ctrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: _construirDecoracionInput(hint: '5.00'),
                                onChanged: (_) => _recalcularDesdeCantidadOUnitario(),
                                validator: (v) =>
                                    (v == null || double.tryParse(v.replaceAll(',', '.')) == null)
                                        ? 'Inválido'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Fila 4: Sede Institucional y Bloque
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _construirEtiqueta('Sede Institucional'),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: _sede_seleccionada,
                                isExpanded: true,
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: BumandColores.negro,
                                ),
                                decoration: _construirDecoracionInput(),
                                items: _sedes
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s, overflow: TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _sede_seleccionada = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _construirEtiqueta('Bloque'),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                initialValue: _bloque_seleccionado,
                                isExpanded: true,
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  color: BumandColores.negro,
                                ),
                                decoration: _construirDecoracionInput(),
                                items: _bloques
                                    .map((b) => DropdownMenuItem(
                                          value: b,
                                          child: Text(b, overflow: TextOverflow.ellipsis),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _bloque_seleccionado = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Fila 5: Supervisor / Responsable de Entrega
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _construirEtiqueta('Supervisor / Responsable de Entrega'),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _responsable_ctrl,
                          style: GoogleFonts.montserrat(fontSize: 12),
                          decoration: _construirDecoracionInput(
                            hint: 'Coordinación General BUMAND',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Fila 6: Observaciones / Menú Detallado
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _construirEtiqueta('Observaciones / Menú Detallado'),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _observaciones_ctrl,
                          maxLines: 3,
                          style: GoogleFonts.montserrat(fontSize: 12),
                          decoration: _construirDecoracionInput(
                            hint: 'Detalle de los alimentos entregados a los becarios...',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Pie de Acciones: Botón Cancelar y Guardar Rendición
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: BumandColores.grisClaro)),
                color: Color(0xFFF8FAFC),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: const BorderSide(color: BumandColores.grisClaro),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.montserrat(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: BumandColores.negro,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BumandColores.azulMarinoProfundo,
                        foregroundColor: BumandColores.blanco,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 1,
                      ),
                      onPressed: _guardando ? null : _guardarRendicion,
                      icon: _guardando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline_rounded, size: 18),
                      label: Text(
                        _guardando ? 'Guardando...' : 'Guardar Rendición',
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

  Widget _construirEtiqueta(String texto) {
    return Text(
      texto,
      style: GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: BumandColores.azulMarinoSecundario,
      ),
    );
  }

  InputDecoration _construirDecoracionInput({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.montserrat(fontSize: 11, color: BumandColores.grisMedio),
      filled: true,
      fillColor: BumandColores.fondo,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BumandColores.grisClaro),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BumandColores.grisClaro),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BumandColores.azulMarinoProfundo, width: 1.5),
      ),
    );
  }
}
