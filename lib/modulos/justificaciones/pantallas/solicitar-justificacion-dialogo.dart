import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

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
    'Emergencia médica / Receta',
    'Corte de ruta / Transporte',
    'Trámite académico / Examen',
    'Asunto pastoral / Institucional',
    'Otro',
  ];

  static const List<Map<String, String>> TIPOS_PRUEBA = [
    {
      'etiqueta': 'Receta médica prescrita',
      'archivo': 'Receta_Medica_Prescrita.pdf',
    },
    {
      'etiqueta': 'Certificado médico SSU',
      'archivo': 'Certificado_Medico_SSU.pdf',
    },
    {
      'etiqueta': 'Comprobante fotográfico',
      'archivo': 'Comprobante_Fotografico_Incidencia.jpg',
    },
    {
      'etiqueta': 'Boleta de trámite',
      'archivo': 'Boleta_Tramite_Universitario.pdf',
    },
  ];

  String _motivo_seleccionado = MOTIVOS_DISPONIBLES.first;
  String? _archivo_adjunto;
  bool _enviando = false;

  @override
  void dispose() {
    _descripcion_controlador.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_clave_formulario.currentState!.validate()) return;

    if (_archivo_adjunto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Debes adjuntar una prueba justificable (receta, certificado o fotografía — No carta)",
          ),
          backgroundColor: Color(0xFFD97706),
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    final servicio = ref.read(justificaciones_servicio_proveedor);
    final hoy = DateTime.now();
    final fecha_str =
        "${hoy.year.toString().padLeft(4, '0')}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}";

    final detalle_texto = _descripcion_controlador.text.trim();
    final descripcion_final =
        "$detalle_texto\n\n[Prueba Justificable: $_archivo_adjunto]";

    final resultado = await servicio.enviarJustificacion(
      tipo_incidencia: widget.tipo_incidencia,
      referencia_id: widget.evento_id,
      fecha_incidencia: fecha_str,
      motivo: _motivo_seleccionado,
      descripcion: descripcion_final,
    );

    if (!mounted) return;
    setState(() => _enviando = false);

    if (resultado.exito) {
      final es_offline = resultado.datos?['offline'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            es_offline
                ? 'Permiso / Justificación guardado en cola offline'
                : 'Permiso / Justificación con prueba enviado al supervisor correctamente',
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
                          "Permisos y Justificaciones",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BumandColores.NEGRO,
                          ),
                        ),
                        Text(
                          "Reporte con prueba médica o comprobante justificable",
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
                "Motivo del permiso o incidencia:",
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

              // Sección obligatoria: Prueba Justificable (No carta)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _archivo_adjunto != null
                        ? const Color(0xFF10B981)
                        : const Color(0xFFE2E8F0),
                    width: _archivo_adjunto != null ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 18,
                          color: _archivo_adjunto != null
                              ? const Color(0xFF059669)
                              : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Prueba Justificable (Obligatoria)",
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Receta médica, certificado o comprobante fotográfico — No carta.",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Selector rápido de tipos de prueba válidos
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: TIPOS_PRUEBA.map((item) {
                        final etiqueta = item['etiqueta']!;
                        final archivo = item['archivo']!;
                        final seleccionado = _archivo_adjunto == archivo;
                        return ActionChip(
                          avatar: Icon(
                            seleccionado
                                ? Icons.check_circle_rounded
                                : Icons.attach_file_rounded,
                            size: 14,
                            color: seleccionado
                                ? Colors.white
                                : BumandColores.AZUL_DIACONIA,
                          ),
                          label: Text(
                            etiqueta,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: seleccionado
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: seleccionado
                                  ? Colors.white
                                  : const Color(0xFF334155),
                            ),
                          ),
                          backgroundColor: seleccionado
                              ? BumandColores.AZUL_DIACONIA
                              : Colors.white,
                          side: BorderSide(
                            color: seleccionado
                                ? BumandColores.AZUL_DIACONIA
                                : const Color(0xFFCBD5E1),
                          ),
                          onPressed: () {
                            setState(() {
                              _archivo_adjunto = archivo;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),

                    // Vista de archivo adjunto
                    if (_archivo_adjunto != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.description_rounded,
                              color: Color(0xFF059669),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _archivo_adjunto!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF065F46),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _archivo_adjunto = null),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final resultado = await FilePicker.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
                            );
                            if (resultado.isNotEmpty) {
                              setState(() {
                                _archivo_adjunto = resultado.first.name;
                              });
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("No se pudo abrir el selector: $e"),
                                backgroundColor: const Color(0xFFDC2626),
                              ),
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF0284C7),
                            style: BorderStyle.solid,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(
                          Icons.camera_alt_outlined,
                          size: 16,
                          color: Color(0xFF0284C7),
                        ),
                        label: const Text(
                          "Adjuntar fotografía o certificado médico (PDF/IMG)",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0284C7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                "Explicación de las circunstancias:",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descripcion_controlador,
                maxLines: 3,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText:
                      "Describe las circunstancias de la ausencia o retraso e indica la prueba adjunta...",
                  hintStyle:
                      TextStyle(fontSize: 13, color: Colors.grey.shade400),
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
                    _enviando
                        ? "Enviando justificación..."
                        : "Enviar Permiso / Justificación",
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
