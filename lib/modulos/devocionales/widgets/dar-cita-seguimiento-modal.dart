import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../proveedores/devocionales-proveedor.dart';
import 'selector-cita-biblica-dialogo.dart';

class DarCitaSeguimientoModal extends ConsumerStatefulWidget {
  final int? becario_id_inicial;
  final String? becario_nombre_inicial;

  const DarCitaSeguimientoModal({
    super.key,
    this.becario_id_inicial,
    this.becario_nombre_inicial,
  });

  static Future<void> mostrar(
    BuildContext context, {
    int? becario_id_inicial,
    String? becario_nombre_inicial,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DarCitaSeguimientoModal(
        becario_id_inicial: becario_id_inicial,
        becario_nombre_inicial: becario_nombre_inicial,
      ),
    );
  }

  @override
  ConsumerState<DarCitaSeguimientoModal> createState() =>
      _DarCitaSeguimientoModalState();
}

class _DarCitaSeguimientoModalState
    extends ConsumerState<DarCitaSeguimientoModal> {
  static const List<Map<String, dynamic>> SUPERVISADOS_DEFAULT = [
    {
      'id': 10,
      'nombre': 'María Catunta Laime',
      'carrera': 'Ing. Comercial',
      'sede': 'Central',
    },
    {
      'id': 11,
      'nombre': 'Carlos Mamani Choque',
      'carrera': 'Contaduría Pública',
      'sede': 'El Alto',
    },
    {
      'id': 12,
      'nombre': 'Ana Quispe Condori',
      'carrera': 'Enfermería',
      'sede': 'Central',
    },
    {
      'id': 13,
      'nombre': 'Joel Flores Ticona',
      'carrera': 'Trabajo Social',
      'sede': 'Viacha',
    },
    {
      'id': 14,
      'nombre': 'Ruth Mendoza Alarcón',
      'carrera': 'Derecho',
      'sede': 'Central',
    },
  ];

  late int _becario_id_seleccionado;
  late String _becario_nombre_seleccionado;
  late TextEditingController _fecha_controlador;
  late TextEditingController _hora_controlador;
  late TextEditingController _lugar_controlador;
  late TextEditingController _motivo_controlador;
  late TextEditingController _cita_biblica_controlador;

  String _modalidad_seleccionada = 'presencial';
  bool _guardando = false;
  final _formulario_clave = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _becario_id_seleccionado = widget.becario_id_inicial ?? 10;
    _becario_nombre_seleccionado = widget.becario_nombre_inicial ??
        SUPERVISADOS_DEFAULT.firstWhere(
          (b) => b['id'] == _becario_id_seleccionado,
          orElse: () => SUPERVISADOS_DEFAULT.first,
        )['nombre'] as String;

    final manana = DateTime.now().add(const Duration(days: 2));
    final fecha_str =
        "${manana.year}-${manana.month.toString().padLeft(2, '0')}-${manana.day.toString().padLeft(2, '0')}";

    _fecha_controlador = TextEditingController(text: fecha_str);
    _hora_controlador = TextEditingController(text: '15:30');
    _lugar_controlador = TextEditingController(
      text: 'Oficina Central Diaconía - Sala Pastoral',
    );
    _motivo_controlador = TextEditingController(
      text: 'Revisión de avance formativo diaconal y balance académico.',
    );
    _cita_biblica_controlador = TextEditingController(text: 'Josué 1:9');
  }

  @override
  void dispose() {
    _fecha_controlador.dispose();
    _hora_controlador.dispose();
    _lugar_controlador.dispose();
    _motivo_controlador.dispose();
    _cita_biblica_controlador.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
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
        _fecha_controlador.text =
            "${seleccion.year}-${seleccion.month.toString().padLeft(2, '0')}-${seleccion.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _seleccionarHora() async {
    final seleccion = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 15, minute: 30),
    );
    if (seleccion != null) {
      final hora = seleccion.hour.toString().padLeft(2, '0');
      final minuto = seleccion.minute.toString().padLeft(2, '0');
      setState(() {
        _hora_controlador.text = "$hora:$minuto";
      });
    }
  }

  Future<void> _guardarCita() async {
    if (!(_formulario_clave.currentState?.validate() ?? false)) return;

    setState(() => _guardando = true);
    try {
      final repo = ref.read(devocionales_repositorio_proveedor);
      await repo.crearCitaSeguimiento(
        becario_id: _becario_id_seleccionado,
        becario_nombre: _becario_nombre_seleccionado,
        fecha_cita: _fecha_controlador.text.trim(),
        hora_cita: _hora_controlador.text.trim(),
        modalidad: _modalidad_seleccionada,
        lugar_o_enlace: _lugar_controlador.text.trim(),
        motivo_retroalimentacion: _motivo_controlador.text.trim(),
        cita_biblica: _cita_biblica_controlador.text.trim().isNotEmpty
            ? _cita_biblica_controlador.text.trim()
            : null,
      );

      ref.invalidate(citas_seguimiento_proveedor);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cita de seguimiento agendada con éxito para $_becario_nombre_seleccionado',
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
                          color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: BumandColores.AZUL_DIACONIA,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Dar Cita a Supervisado',
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
              const SizedBox(height: 16),

              // Selección del Becario Supervisado
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: _becario_id_seleccionado,
                decoration: InputDecoration(
                  labelText: 'Becario a supervisar',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
                items: SUPERVISADOS_DEFAULT.map((becario) {
                  return DropdownMenuItem<int>(
                    value: becario['id'] as int,
                    child: Text(
                      '${becario['nombre']} (${becario['carrera']})',
                      style: const TextStyle(fontSize: 13.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    final encontrado = SUPERVISADOS_DEFAULT.firstWhere(
                      (b) => b['id'] == val,
                    );
                    setState(() {
                      _becario_id_seleccionado = val;
                      _becario_nombre_seleccionado =
                          encontrado['nombre'] as String;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),

              // Selector de Fecha y Hora
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fecha_controlador,
                      readOnly: true,
                      onTap: _seleccionarFecha,
                      decoration: InputDecoration(
                        labelText: 'Fecha de cita',
                        prefixIcon: const Icon(Icons.event_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Requerido'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _hora_controlador,
                      readOnly: true,
                      onTap: _seleccionarHora,
                      decoration: InputDecoration(
                        labelText: 'Hora',
                        prefixIcon: const Icon(Icons.access_time_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Requerido'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Modalidad (Presencial / Virtual)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Modalidad del Encuentro:',
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
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _modalidad_seleccionada = 'presencial';
                              _lugar_controlador.text =
                                  'Oficina Central Diaconía - Sala Pastoral';
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _modalidad_seleccionada == 'presencial'
                                  ? BumandColores.AZUL_DIACONIA.withValues(
                                      alpha: 0.12,
                                    )
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _modalidad_seleccionada == 'presencial'
                                    ? BumandColores.AZUL_DIACONIA
                                    : const Color(0xFFCBD5E1),
                                width: _modalidad_seleccionada == 'presencial'
                                    ? 2
                                    : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.business_rounded,
                                  size: 18,
                                  color: _modalidad_seleccionada == 'presencial'
                                      ? BumandColores.AZUL_DIACONIA
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Presencial',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _modalidad_seleccionada ==
                                            'presencial'
                                        ? BumandColores.AZUL_DIACONIA
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _modalidad_seleccionada = 'virtual';
                              _lugar_controlador.text =
                                  'https://meet.google.com/dia-seg-retro';
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _modalidad_seleccionada == 'virtual'
                                  ? BumandColores.azulCieloSuave.withValues(
                                      alpha: 0.15,
                                    )
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _modalidad_seleccionada == 'virtual'
                                    ? BumandColores.azulCieloSuave
                                    : const Color(0xFFCBD5E1),
                                width: _modalidad_seleccionada == 'virtual'
                                    ? 2
                                    : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.videocam_rounded,
                                  size: 18,
                                  color: _modalidad_seleccionada == 'virtual'
                                      ? BumandColores.azulMarinoSecundario
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Virtual (Meet)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _modalidad_seleccionada == 'virtual'
                                        ? BumandColores.azulMarinoSecundario
                                        : const Color(0xFF64748B),
                                  ),
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
              const SizedBox(height: 14),

              // Lugar o Enlace
              TextFormField(
                controller: _lugar_controlador,
                decoration: InputDecoration(
                  labelText: _modalidad_seleccionada == 'presencial'
                      ? 'Lugar o sala de encuentro'
                      : 'Enlace de videollamada',
                  prefixIcon: Icon(
                    _modalidad_seleccionada == 'presencial'
                        ? Icons.place_outlined
                        : Icons.link_rounded,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
                validator: (v) =>
                    v?.trim().isEmpty ?? true ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 14),

              // Motivo de Retroalimentación
              TextFormField(
                controller: _motivo_controlador,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Motivo de retroalimentación',
                  hintText: 'Ej. Balance espiritual, académico y avance diaconal',
                  prefixIcon: const Icon(Icons.edit_note_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
                validator: (v) =>
                    v?.trim().isEmpty ?? true ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 14),

              // Cita Bíblica con Selector Canónico
              TextFormField(
                controller: _cita_biblica_controlador,
                readOnly: true,
                onTap: () async {
                  final seleccion = await SelectorCitaBiblicaDialogo.mostrar(
                    context,
                    cita_inicial: _cita_biblica_controlador.text.isNotEmpty
                        ? _cita_biblica_controlador.text
                        : 'Josué 1:9',
                  );
                  if (seleccion != null) {
                    setState(() {
                      _cita_biblica_controlador.text = seleccion;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Cita bíblica de orientación (opcional)',
                  hintText: 'Toca para seleccionar cita canónica',
                  prefixIcon: const Icon(Icons.auto_stories_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: BumandColores.AZUL_DIACONIA,
                    ),
                    onPressed: () async {
                      final seleccion =
                          await SelectorCitaBiblicaDialogo.mostrar(
                        context,
                        cita_inicial:
                            _cita_biblica_controlador.text.isNotEmpty
                                ? _cita_biblica_controlador.text
                                : 'Josué 1:9',
                      );
                      if (seleccion != null) {
                        setState(() {
                          _cita_biblica_controlador.text = seleccion;
                        });
                      }
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 20),

              // Botón Guardar
              FilledButton.icon(
                onPressed: _guardando ? null : _guardarCita,
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _guardando
                      ? 'Agendando cita...'
                      : 'Agendar Cita de Seguimiento',
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
