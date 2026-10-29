import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../modelos/cita-seguimiento-modelo.dart';
import '../proveedores/devocionales-proveedor.dart';

class RegistrarAcuerdosCitaModal extends ConsumerStatefulWidget {
  final CitaSeguimientoModelo cita;

  const RegistrarAcuerdosCitaModal({
    super.key,
    required this.cita,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required CitaSeguimientoModelo cita,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RegistrarAcuerdosCitaModal(cita: cita),
    );
  }

  @override
  ConsumerState<RegistrarAcuerdosCitaModal> createState() =>
      _RegistrarAcuerdosCitaModalState();
}

class _RegistrarAcuerdosCitaModalState
    extends ConsumerState<RegistrarAcuerdosCitaModal> {
  late String _estado_seleccionado;
  late TextEditingController _acuerdos_controlador;
  late TextEditingController _nueva_fecha_controlador;
  late TextEditingController _nueva_hora_controlador;

  bool _guardando = false;
  final _formulario_clave = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _estado_seleccionado =
        widget.cita.esta_realizada ? 'realizada' : 'realizada';
    _acuerdos_controlador = TextEditingController(
      text: widget.cita.acuerdos_retroalimentacion ?? '',
    );

    final fecha_base = DateTime.now().add(const Duration(days: 7));
    final fecha_str =
        "${fecha_base.year}-${fecha_base.month.toString().padLeft(2, '0')}-${fecha_base.day.toString().padLeft(2, '0')}";

    _nueva_fecha_controlador = TextEditingController(
      text: widget.cita.fecha_cita.isNotEmpty
          ? widget.cita.fecha_cita
          : fecha_str,
    );
    _nueva_hora_controlador = TextEditingController(
      text: widget.cita.hora_cita.isNotEmpty
          ? widget.cita.hora_cita
          : '15:30',
    );
  }

  @override
  void dispose() {
    _acuerdos_controlador.dispose();
    _nueva_fecha_controlador.dispose();
    _nueva_hora_controlador.dispose();
    super.dispose();
  }

  Future<void> _seleccionarNuevaFecha() async {
    final ahora = DateTime.now();
    final seleccion = await showDatePicker(
      context: context,
      initialDate: ahora.add(const Duration(days: 1)),
      firstDate: ahora,
      lastDate: ahora.add(const Duration(days: 180)),
      locale: const Locale('es'),
    );
    if (seleccion != null) {
      setState(() {
        _nueva_fecha_controlador.text =
            "${seleccion.year}-${seleccion.month.toString().padLeft(2, '0')}-${seleccion.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _seleccionarNuevaHora() async {
    final seleccion = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 15, minute: 30),
    );
    if (seleccion != null) {
      final hora = seleccion.hour.toString().padLeft(2, '0');
      final minuto = seleccion.minute.toString().padLeft(2, '0');
      setState(() {
        _nueva_hora_controlador.text = "$hora:$minuto";
      });
    }
  }

  Future<void> _guardarAcuerdos() async {
    if (!(_formulario_clave.currentState?.validate() ?? false)) return;

    setState(() => _guardando = true);
    try {
      final repo = ref.read(devocionales_repositorio_proveedor);
      await repo.actualizarCitaSeguimiento(
        cita_id: widget.cita.id,
        estado: _estado_seleccionado,
        acuerdos_retroalimentacion: _acuerdos_controlador.text.trim().isNotEmpty
            ? _acuerdos_controlador.text.trim()
            : null,
        nueva_fecha: _estado_seleccionado == 'reprogramada'
            ? _nueva_fecha_controlador.text.trim()
            : null,
        nueva_hora: _estado_seleccionado == 'reprogramada'
            ? _nueva_hora_controlador.text.trim()
            : null,
      );

      ref.invalidate(citas_seguimiento_proveedor);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Acuerdos y estado de seguimiento registrados con éxito',
            ),
            backgroundColor: BumandColores.AZUL_DIACONIA,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formulario_clave,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in_rounded,
                          color: Color(0xFF0D9488),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Registrar Acuerdos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: BumandColores.AZUL_DIACONIA,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Tarjeta Resumen de la Cita
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person_pin_rounded,
                          size: 18,
                          color: BumandColores.AZUL_DIACONIA,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.cita.becario_nombre,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: widget.cita.es_presencial
                                ? BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1)
                                : BumandColores.azulCieloSuave.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.cita.es_presencial ? 'Presencial' : 'Virtual',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: widget.cita.es_presencial
                                  ? BumandColores.AZUL_DIACONIA
                                  : BumandColores.azulMarinoSecundario,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.cita.fecha_cita} a las ${widget.cita.hora_cita}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Motivo: ${widget.cita.motivo_retroalimentacion}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF334155),
                      ),
                    ),
                    if (widget.cita.cita_biblica != null &&
                        widget.cita.cita_biblica!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_stories_rounded,
                            size: 13,
                            color: Color(0xFF0369A1),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.cita.cita_biblica!,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0369A1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Selector de Estado
              const Text(
                'Estado del Seguimiento:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 16),
                          SizedBox(width: 4),
                          Text('Realizada'),
                        ],
                      ),
                      selected: _estado_seleccionado == 'realizada',
                      selectedColor: const Color(0xFFDCFCE7),
                      onSelected: (val) {
                        if (val) setState(() => _estado_seleccionado = 'realizada');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.update_rounded, size: 16),
                          SizedBox(width: 4),
                          Text('Reprogramar'),
                        ],
                      ),
                      selected: _estado_seleccionado == 'reprogramada',
                      selectedColor: const Color(0xFFFEF3C7),
                      onSelected: (val) {
                        if (val) setState(() => _estado_seleccionado = 'reprogramada');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel_rounded, size: 16),
                          SizedBox(width: 4),
                          Text('Cancelar'),
                        ],
                      ),
                      selected: _estado_seleccionado == 'cancelada',
                      selectedColor: const Color(0xFFFFE4E6),
                      onSelected: (val) {
                        if (val) setState(() => _estado_seleccionado = 'cancelada');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Si es reprogramada, mostrar nueva fecha y hora
              if (_estado_seleccionado == 'reprogramada') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nueva_fecha_controlador,
                        readOnly: true,
                        onTap: _seleccionarNuevaFecha,
                        decoration: InputDecoration(
                          labelText: 'Nueva Fecha',
                          prefixIcon: const Icon(Icons.event_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _nueva_hora_controlador,
                        readOnly: true,
                        onTap: _seleccionarNuevaHora,
                        decoration: InputDecoration(
                          labelText: 'Nueva Hora',
                          prefixIcon: const Icon(Icons.access_time_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Acuerdos y Compromisos
              TextFormField(
                controller: _acuerdos_controlador,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Acuerdos de retroalimentación',
                  hintText:
                      'Describe los acuerdos formativos, metas espirituales y compromisos académicos asumidos...',
                  prefixIcon: const Icon(Icons.handshake_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
                validator: (v) {
                  if (_estado_seleccionado == 'realizada' &&
                      (v == null || v.trim().isEmpty)) {
                    return 'Registra los acuerdos asumidos en la cita';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Botón Guardar
              FilledButton.icon(
                onPressed: _guardando ? null : _guardarAcuerdos,
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _guardando ? 'Guardando acuerdos...' : 'Guardar Acuerdos',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: BumandColores.AZUL_DIACONIA,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
