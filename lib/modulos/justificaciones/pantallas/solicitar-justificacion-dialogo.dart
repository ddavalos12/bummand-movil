import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../nucleo/tema/colores.dart';
import '../servicios/justificaciones-servicio.dart';

class SolicitarJustificacionDialogo extends ConsumerStatefulWidget {
  final int? evento_id;
  final String? titulo_evento;
  final String tipo_incidencia;

  /// Contexto opcional de un registro de asistencia auditado (paridad con Web):
  /// permite radicar la justificación a nombre del becario del registro.
  final int? becario_id;
  final String? becario_nombre;
  final int? referencia_id;
  final String? fecha_inicial; // yyyy-MM-dd
  final String? tipo_inicial;
  final String? sede_nombre;
  final String? motivo_sugerido;

  const SolicitarJustificacionDialogo({
    super.key,
    this.evento_id,
    this.titulo_evento,
    this.tipo_incidencia = 'escuela_lideres',
    this.becario_id,
    this.becario_nombre,
    this.referencia_id,
    this.fecha_inicial,
    this.tipo_inicial,
    this.sede_nombre,
    this.motivo_sugerido,
  });

  static Future<bool?> mostrar(
    BuildContext context, {
    int? evento_id,
    String? titulo_evento,
    String tipo_incidencia = 'escuela_lideres',
    int? becario_id,
    String? becario_nombre,
    int? referencia_id,
    String? fecha_inicial,
    String? tipo_inicial,
    String? sede_nombre,
    String? motivo_sugerido,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SolicitarJustificacionDialogo(
        evento_id: evento_id,
        titulo_evento: titulo_evento,
        tipo_incidencia: tipo_incidencia,
        becario_id: becario_id,
        becario_nombre: becario_nombre,
        referencia_id: referencia_id,
        fecha_inicial: fecha_inicial,
        tipo_inicial: tipo_inicial,
        sede_nombre: sede_nombre,
        motivo_sugerido: motivo_sugerido,
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
  final _motivo_controlador = TextEditingController();
  final _descripcion_controlador = TextEditingController();

  static const Map<String, String> OPCIONES_INCIDENCIA = {
    'Prácticas Preprofesionales': 'asistencia_practicas',
    'Escuela de Líderes': 'escuela_lideres',
    'Evento Convocado': 'asistencia_evento',
    'Acciones de Servicio': 'otro',
  };

  late String _tipo_incidencia_seleccionada;
  late DateTime _fecha_seleccionada;
  PlatformFile? _archivo_seleccionado;
  List<int>? _bytes_archivo;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _tipo_incidencia_seleccionada =
        widget.tipo_inicial ?? widget.tipo_incidencia;
    _fecha_seleccionada =
        DateTime.tryParse(widget.fecha_inicial ?? '') ?? DateTime.now();
    if ((widget.motivo_sugerido ?? '').trim().isNotEmpty) {
      _motivo_controlador.text = widget.motivo_sugerido!.trim();
    }
  }

  @override
  void dispose() {
    _motivo_controlador.dispose();
    _descripcion_controlador.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();
    final fecha_elegida = await showDatePicker(
      context: context,
      initialDate: _fecha_seleccionada,
      firstDate: _fecha_seleccionada.isBefore(ahora.subtract(const Duration(days: 30)))
          ? _fecha_seleccionada
          : ahora.subtract(const Duration(days: 30)),
      lastDate: ahora.add(const Duration(days: 60)),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: BumandColores.AZUL_DIACONIA,
              onPrimary: Colors.white,
              onSurface: BumandColores.NEGRO,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha_elegida != null) {
      setState(() {
        _fecha_seleccionada = fecha_elegida;
      });
    }
  }

  Future<void> _seleccionarArchivo() async {
    try {
      final archivo = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      );

      if (archivo != null) {
        final bytes = await archivo.readAsBytes();

        if (bytes.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("No se pudo leer el contenido del archivo"),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _archivo_seleccionado = archivo;
          _bytes_archivo = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al seleccionar archivo: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _enviar() async {
    if (!_clave_formulario.currentState!.validate()) return;

    if (_archivo_seleccionado == null || _bytes_archivo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Debes adjuntar la receta o certificado médico emitido (obligatorio)",
          ),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final servicio = ref.read(justificaciones_servicio_proveedor);

      // Subida real del comprobante
      final subida = await servicio.subirComprobante(
        bytes: _bytes_archivo!,
        nombre_archivo: _archivo_seleccionado!.name,
      );

      if (!subida.exito) {
        throw Exception(subida.error ?? "No se pudo subir el archivo probatorio");
      }

      final url_prueba = subida.datos?['archivo_prueba_url']?.toString();
      final nombre_prueba = subida.datos?['nombre_archivo_prueba']?.toString() ??
          _archivo_seleccionado!.name;

      final fecha_str =
          "${_fecha_seleccionada.year.toString().padLeft(4, '0')}-"
          "${_fecha_seleccionada.month.toString().padLeft(2, '0')}-"
          "${_fecha_seleccionada.day.toString().padLeft(2, '0')}";

      final resultado = await servicio.enviarJustificacion(
        tipo_incidencia: _tipo_incidencia_seleccionada,
        referencia_id: widget.referencia_id ?? widget.evento_id,
        becario_id: widget.becario_id,
        fecha_incidencia: fecha_str,
        motivo: _motivo_controlador.text.trim(),
        descripcion: _descripcion_controlador.text.trim(),
        archivo_prueba_url: url_prueba,
        nombre_archivo_prueba: nombre_prueba,
      );

      if (!mounted) return;
      setState(() => _enviando = false);

      if (resultado.exito) {
        ref.invalidate(mis_justificaciones_proveedor);
        final es_offline = resultado.datos?['offline'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              es_offline
                  ? 'Permiso / Justificación guardado en cola offline'
                  : 'Permiso / Justificación radicado exitosamente en 2 niveles',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.error ?? 'Error al radicar justificación'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enviando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al enviar: $e"),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding_inferior = MediaQuery.of(context).viewInsets.bottom;
    final altura_maxima = MediaQuery.of(context).size.height * 0.90;

    final fecha_formateada =
        "${_fecha_seleccionada.day.toString().padLeft(2, '0')}/"
        "${_fecha_seleccionada.month.toString().padLeft(2, '0')}/"
        "${_fecha_seleccionada.year}";

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: altura_maxima),
      child: Container(
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
        child: Form(
          key: _clave_formulario,
          child: ListView(
            shrinkWrap: true,
            children: [
              // Barra de arrastre superior
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment_late_rounded,
                      color: BumandColores.AZUL_DIACONIA,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Registrar Permiso / Justificación",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: BumandColores.NEGRO,
                          ),
                        ),
                        Text(
                          "Flujo de validación médica o institucional",
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Contexto del registro de asistencia auditado (si aplica)
              if (widget.becario_nombre != null || widget.sede_nombre != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BumandColores.AMARILLO_RADIANTE),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registro de asistencia auditado',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      if (widget.becario_nombre != null)
                        Text(
                          widget.becario_nombre!,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: BumandColores.NEGRO,
                          ),
                        ),
                      if (widget.sede_nombre != null)
                        Text(
                          widget.sede_nombre!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Selector de Tipo de Incidencia
              const Text(
                "Tipo de Incidencia *",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: OPCIONES_INCIDENCIA.values.contains(_tipo_incidencia_seleccionada)
                    ? _tipo_incidencia_seleccionada
                    : 'escuela_lideres',
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.category_rounded, size: 20),
                ),
                borderRadius: BorderRadius.circular(12),
                items: OPCIONES_INCIDENCIA.entries.map((e) {
                  return DropdownMenuItem<String>(
                    value: e.value,
                    child: Text(e.key, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _tipo_incidencia_seleccionada = val);
                  }
                },
              ),
              const SizedBox(height: 12),

              // Fecha de Incidencia
              const Text(
                "Fecha de Incidencia *",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _seleccionarFecha,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 18, color: BumandColores.AZUL_DIACONIA),
                      const SizedBox(width: 10),
                      Text(fecha_formateada, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      const Spacer(),
                      const Text(
                        "Cambiar",
                        style: TextStyle(
                          color: BumandColores.AZUL_DIACONIA,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Motivo Resumido (Libre)
              const Text(
                "Motivo Resumido *",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _motivo_controlador,
                decoration: InputDecoration(
                  hintText: "Ej. Cita médica en seguro social, Examen parcial...",
                  hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Ingresa el motivo resumido";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Descripción Detallada
              const Text(
                "Descripción Detallada *",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descripcion_controlador,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Explica las circunstancias de la inasistencia o retraso...",
                  hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 8) {
                    return "Describe la situación (mínimo 8 caracteres)";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Carga de Archivo Real
              const Text(
                "Prueba Justificable (Receta o certificado médico — No carta) *",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              if (_archivo_seleccionado == null)
                InkWell(
                  onTap: _seleccionarArchivo,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_upload_outlined,
                          size: 28,
                          color: BumandColores.AZUL_DIACONIA,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Adjuntar receta o certificado médico",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: BumandColores.AZUL_DIACONIA,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Formatos aceptados: JPG, PNG, WEBP o PDF (Receta o certificado médico emitido)",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF16A34A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description_rounded, color: Color(0xFF16A34A), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _archivo_seleccionado!.name,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _archivo_seleccionado = null;
                            _bytes_archivo = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Botón Radicar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BumandColores.AZUL_DIACONIA,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _enviando ? null : _enviar,
                  icon: _enviando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _enviando ? "Radicando..." : "Radicar Permiso / Justificación",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
