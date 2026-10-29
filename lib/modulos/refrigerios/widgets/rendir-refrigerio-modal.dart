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

class _ItemIngredienteEdicion {
  final TextEditingController insumo_ctrl;
  final TextEditingController cantidad_ctrl;
  final TextEditingController costo_ctrl;
  int? pagado_por_id;
  String pagado_por_nombre;

  _ItemIngredienteEdicion({
    required String insumo,
    required String cantidad,
    required double costo_bs,
    this.pagado_por_id,
    required this.pagado_por_nombre,
  })  : insumo_ctrl = TextEditingController(text: insumo),
        cantidad_ctrl = TextEditingController(text: cantidad),
        costo_ctrl = TextEditingController(
          text: costo_bs > 0 ? costo_bs.toStringAsFixed(2) : '',
        );

  void dispose() {
    insumo_ctrl.dispose;
    cantidad_ctrl.dispose;
    costo_ctrl.dispose;
  }
}

class _RendirRefrigerioModalState extends ConsumerState<RendirRefrigerioModal> {
  late TextEditingController _menu_ctrl;
  late String _modalidad_seleccionada;
  final List<_ItemIngredienteEdicion> _items_ingredientes = [];

  @override
  void initState() {
    super.initState();
    _menu_ctrl = TextEditingController(text: widget.refrigerio.menu_detalle);
    _modalidad_seleccionada = widget.refrigerio.modalidad_preparacion;

    final nombre1 = widget.refrigerio.becario_encargado_1_nombre ?? 'Encargado 1';
    final id1 = widget.refrigerio.becario_encargado_1_id ?? 1;

    if (widget.refrigerio.ingredientes.isNotEmpty) {
      for (final ing in widget.refrigerio.ingredientes) {
        _items_ingredientes.add(
          _ItemIngredienteEdicion(
            insumo: ing.insumo,
            cantidad: ing.cantidad,
            costo_bs: ing.costo_bs,
            pagado_por_id: ing.pagado_por_becario_id ?? id1,
            pagado_por_nombre: ing.pagado_por_nombre ?? nombre1,
          ),
        );
      }
    } else {
      _items_ingredientes.add(
        _ItemIngredienteEdicion(
          insumo: 'Huevos de granja',
          cantidad: '1 maple (30 u)',
          costo_bs: 38.0,
          pagado_por_id: id1,
          pagado_por_nombre: nombre1,
        ),
      );
      _items_ingredientes.add(
        _ItemIngredienteEdicion(
          insumo: 'Pan de batalla',
          cantidad: '50 unidades',
          costo_bs: 40.0,
          pagado_por_id: id1,
          pagado_por_nombre: nombre1,
        ),
      );
    }
  }

  @override
  void dispose() {
    _menu_ctrl.dispose();
    for (final item in _items_ingredientes) {
      item.dispose();
    }
    super.dispose();
  }

  double _calcularTotal() {
    double suma = 0.0;
    for (final item in _items_ingredientes) {
      final val = double.tryParse(item.costo_ctrl.text.replaceAll(',', '.')) ?? 0.0;
      suma += val;
    }
    return suma;
  }

  double _calcularGastoPorNombre(String nombre) {
    double suma = 0.0;
    for (final item in _items_ingredientes) {
      if (item.pagado_por_nombre.trim().toLowerCase() == nombre.trim().toLowerCase()) {
        final val = double.tryParse(item.costo_ctrl.text.replaceAll(',', '.')) ?? 0.0;
        suma += val;
      }
    }
    return suma;
  }

  void _guardarRendicion() {
    final menu = _menu_ctrl.text.trim();
    if (menu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor escribe el detalle del menú preparado.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final lista_final = <IngredienteRefrigerioModelo>[];
    for (final item in _items_ingredientes) {
      final insumo = item.insumo_ctrl.text.trim();
      final cantidad = item.cantidad_ctrl.text.trim();
      final costo = double.tryParse(item.costo_ctrl.text.replaceAll(',', '.')) ?? 0.0;
      if (insumo.isNotEmpty) {
        lista_final.add(
          IngredienteRefrigerioModelo(
            insumo: insumo,
            cantidad: cantidad,
            costo_bs: costo,
            pagado_por_becario_id: item.pagado_por_id,
            pagado_por_nombre: item.pagado_por_nombre,
          ),
        );
      }
    }

    final total = _calcularTotal();

    ref.read(refrigerios_proveedor.notifier).rendirRefrigerio(
          id: widget.refrigerio.id,
          menu_detalle: menu,
          modalidad_preparacion: _modalidad_seleccionada,
          ingredientes: lista_final,
          costo_total_bs: total,
        );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '¡Rendición guardada con éxito! Costo: Bs ${total.toStringAsFixed(2)}. Devolución solicitada al 100%.',
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
    final id1 = widget.refrigerio.becario_encargado_1_id ?? 1;
    final nombre2 = widget.refrigerio.becario_encargado_2_nombre ?? 'Becario 2';
    final id2 = widget.refrigerio.becario_encargado_2_id ?? 2;

    final total_actual = _calcularTotal();
    final gasto1 = _calcularGastoPorNombre(nombre1);
    final gasto2 = _calcularGastoPorNombre(nombre2);

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
                  const SizedBox(height: 14),

                  // Selector de modalidad
                  Text(
                    'Modalidad de Preparación',
                    style: GoogleFonts.montserrat(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: BumandColores.azulMarinoSecundario,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: BumandColores.fondo,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: BumandColores.grisClaro),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _modalidad_seleccionada,
                        isExpanded: true,
                        style: GoogleFonts.montserrat(
                          fontSize: 12.5,
                          color: BumandColores.negro,
                          fontWeight: FontWeight.w600,
                        ),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _modalidad_seleccionada = val);
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'cocina_diaconia',
                            child: Text('Preparado en Cocina de Diaconía'),
                          ),
                          DropdownMenuItem(
                            value: 'traido_de_casa',
                            child: Text('Elaborado en Casa y Traído Listo'),
                          ),
                          DropdownMenuItem(
                            value: 'compra_directa',
                            child: Text('Compra Directa Listo para Servir'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Sección de ingredientes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ingredientes e Insumos Comprados',
                        style: GoogleFonts.montserrat(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: BumandColores.azulMarinoSecundario,
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: BumandColores.azulMarinoProfundo,
                        ),
                        onPressed: () {
                          setState(() {
                            _items_ingredientes.add(
                              _ItemIngredienteEdicion(
                                insumo: '',
                                cantidad: '',
                                costo_bs: 0.0,
                                pagado_por_id: id1,
                                pagado_por_nombre: nombre1,
                              ),
                            );
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                        label: Text(
                          'Agregar',
                          style: GoogleFonts.montserrat(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Lista de items de ingredientes
                  ...List.generate(_items_ingredientes.length, (idx) {
                    final item = _items_ingredientes[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: BumandColores.blanco,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: BumandColores.grisClaro),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Insumo #${idx + 1}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: BumandColores.textoSecundario,
                                ),
                              ),
                              const Spacer(),
                              if (_items_ingredientes.length > 1)
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _items_ingredientes.removeAt(idx);
                                    });
                                  },
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: item.insumo_ctrl,
                                  style: GoogleFonts.montserrat(fontSize: 12),
                                  decoration: InputDecoration(
                                    hintText: 'Insumo (ej. Pan, Huevo)',
                                    filled: true,
                                    fillColor: BumandColores.fondo,
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: BumandColores.grisClaro),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: item.cantidad_ctrl,
                                  style: GoogleFonts.montserrat(fontSize: 12),
                                  decoration: InputDecoration(
                                    hintText: 'Cant. (ej. 50 u)',
                                    filled: true,
                                    fillColor: BumandColores.fondo,
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: BumandColores.grisClaro),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: item.costo_ctrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => setState(() {}),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Bs 0.00',
                                    filled: true,
                                    fillColor: BumandColores.fondo,
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: BumandColores.grisClaro),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Quién pagó este insumo
                          Row(
                            children: [
                              Text(
                                'Pagado por: ',
                                style: GoogleFonts.montserrat(
                                  fontSize: 10.5,
                                  color: BumandColores.textoSecundario,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: BumandColores.fondo,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: BumandColores.grisClaro),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: item.pagado_por_nombre,
                                      isDense: true,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: BumandColores.azulMarinoSecundario,
                                      ),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setState(() {
                                            item.pagado_por_nombre = val;
                                            item.pagado_por_id = (val == nombre1) ? id1 : id2;
                                          });
                                        }
                                      },
                                      items: [
                                        DropdownMenuItem(
                                          value: nombre1,
                                          child: Text(nombre1, overflow: TextOverflow.ellipsis),
                                        ),
                                        DropdownMenuItem(
                                          value: nombre2,
                                          child: Text(nombre2, overflow: TextOverflow.ellipsis),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),

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
