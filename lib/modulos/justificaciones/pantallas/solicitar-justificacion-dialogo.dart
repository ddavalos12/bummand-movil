import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../servicios/justificaciones-servicio.dart';

class SolicitarJustificacionDialogo extends ConsumerStatefulWidget {
  final int? evento_id;
  final String? titulo_evento;
  final String tipo_incidencia;

  const SolicitarJustificacionDialogo({
    super.key,
    this.evento_id,
    this.titulo_evento,
    this.tipo_incidencia = 'asistencia_evento',
  });

  static Future<bool?> mostrar(
    BuildContext context, {
    int? evento_id,
    String? titulo_evento,
    String tipo_incidencia = 'asistencia_evento',
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SolicitarJustificacionDialogo(
        evento_id: evento_id,
        titulo_evento: titulo_evento,
        tipo_incidencia: tipo_incidencia,
      ),
    );
  }

  @override
  ConsumerState<SolicitarJustificacionDialogo> createState() =>
      _SolicitarJustificacionDialogoState();
}

class _SolicitarJustificacionDialogoState
    extends ConsumerState<SolicitarJustificacionDialogo> {
  final _clave_formulario = GlobalKey<FormState>();
  final _descripcion_controlador = TextEditingController();

  static const List<String> MOTIVOS_DISPONIBLES = [
    'Corte de ruta/Paro',
    'Emergencia médica',
    'Trámite académico',
    'Otro',
  ];

  String _motivo_seleccionado = MOTIVOS_DISPONIBLES.first;
  bool _enviando = false;

  @override
  void dispose() {
    _descripcion_controlador.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_clave_formulario.currentState!.validate()) return;

    setState(() => _enviando = true);

    final servicio = ref.read(justificaciones_servicio_proveedor);
    final hoy = DateTime.now();
    final fecha_str =
        "${hoy.year.toString().padLeft(4, '0')}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}";

    final resultado = await servicio.enviarJustificacion(
      tipo_incidencia: widget.tipo_incidencia,
      referencia_id: widget.evento_id,
      fecha_incidencia: fecha_str,
      motivo: _motivo_seleccionado,
      descripcion: _descripcion_controlador.text.trim(),
    );

    if (!mounted) return;
    setState(() => _enviando = false);

    if (resultado.exito) {
      final es_offline = resultado.datos?['offline'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            es_offline
                ? 'Justificación guardada en cola offline'
                : 'Justificación enviada al supervisor correctamente',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado.error ?? 'Error al enviar justificación'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding_inferior = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: padding_inferior + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _clave_formulario,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assignment_late_outlined,
                      color: Color(0xFFD97706),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Solicitud de Justificación",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BumandColores.NEGRO,
                          ),
                        ),
                        Text(
                          "Reporte de incidencia o inasistencia motivada",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              if (widget.titulo_evento != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event,
                        size: 16,
                        color: BumandColores.AZUL_DIACONIA,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.titulo_evento!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                "Motivo de la incidencia:",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MOTIVOS_DISPONIBLES.map((motivo) {
                  final seleccionado = _motivo_seleccionado == motivo;
                  return ChoiceChip(
                    label: Text(motivo),
                    selected: seleccionado,
                    selectedColor: BumandColores.AZUL_DIACONIA,
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: seleccionado ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight:
                          seleccionado ? FontWeight.bold : FontWeight.w500,
                    ),
                    onSelected: (bool valor) {
                      if (valor) {
                        setState(() => _motivo_seleccionado = motivo);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                "Descripción y detalles:",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descripcion_controlador,
                maxLines: 4,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText:
                      "Describe las circunstancias del retraso, corte de transporte o impedimento...",
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return "Ingresa una breve descripción de la justificación";
                  }
                  if (valor.trim().length < 8) {
                    return "La descripción debe tener al menos 8 caracteres";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _enviando ? null : _enviar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BumandColores.AZUL_DIACONIA,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _enviando ? "Enviando solicitud..." : "Enviar Justificación",
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
