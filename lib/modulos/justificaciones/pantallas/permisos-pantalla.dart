import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../../autenticacion/proveedores/autenticacion-proveedor.dart';
import '../../inicio/proveedores/inicio-proveedor.dart';
import '../servicios/justificaciones-servicio.dart';

class PermisosPantalla extends ConsumerStatefulWidget {
  const PermisosPantalla({super.key});

  @override
  ConsumerState<PermisosPantalla> createState() => _PermisosPantallaState();
}

class _PermisosPantallaState extends ConsumerState<PermisosPantalla> {
  final _clave_formulario = GlobalKey<FormState>();
  final _motivo_controlador = TextEditingController();
  final _descripcion_controlador = TextEditingController();

  static const Map<String, String> TIPOS_INCIDENCIA_MAPA = {
    'Prácticas Preprofesionales': 'asistencia_practicas',
    'Escuela de Líderes': 'escuela_lideres',
    'Evento Convocado': 'asistencia_evento',
    'Acciones de Servicio': 'otro',
  };

  String _tipo_incidencia_seleccionado = 'Escuela de Líderes';
  DateTime _fecha_incidencia = DateTime.now();

  PlatformFile? _archivo_seleccionado;
  List<int>? _bytes_archivo;
  bool _enviando = false;

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
      initialDate: _fecha_incidencia,
      firstDate: ahora.subtract(const Duration(days: 30)),
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
        _fecha_incidencia = fecha_elegida;
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

        if (bytes.length > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("El archivo no debe exceder 10 MB"),
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

  Future<void> _radicarJustificacion() async {
    if (!_clave_formulario.currentState!.validate()) {
      return;
    }

    if (_bytes_archivo == null || _archivo_seleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Debes adjuntar la receta o certificado médico de respaldo (obligatorio)",
          ),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final servicio = ref.read(justificaciones_servicio_proveedor);

      // 1. Subida real del archivo justificativo
      final res_subida = await servicio.subirArchivoJustificativo(
        _bytes_archivo!,
        _archivo_seleccionado!.name,
      );

      if (!res_subida.exito) {
        throw Exception(
          res_subida.error ?? "Error al subir comprobante al servidor",
        );
      }

      final url_archivo = res_subida.datos?['archivo_prueba_url']?.toString();
      final nombre_archivo = res_subida.datos?['nombre_archivo_prueba']?.toString() ??
          _archivo_seleccionado!.name;

      // 2. Radicación de la justificación
      final fecha_str =
          "${_fecha_incidencia.year.toString().padLeft(4, '0')}-"
          "${_fecha_incidencia.month.toString().padLeft(2, '0')}-"
          "${_fecha_incidencia.day.toString().padLeft(2, '0')}";

      final tipo_incidencia_backend =
          TIPOS_INCIDENCIA_MAPA[_tipo_incidencia_seleccionado] ?? 'otro';

      final res_envio = await servicio.enviarJustificacion(
        tipo_incidencia: tipo_incidencia_backend,
        fecha_incidencia: fecha_str,
        motivo: _motivo_controlador.text.trim(),
        descripcion: _descripcion_controlador.text.trim(),
        archivo_prueba_url: url_archivo,
        nombre_archivo_prueba: nombre_archivo,
      );

      if (!res_envio.exito) {
        throw Exception(res_envio.error ?? "Error al registrar la justificación");
      }

      ref.invalidate(mis_justificaciones_proveedor);

      if (!mounted) return;

      _mostrarDialogoExito();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al radicar solicitud: $e"),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  void _mostrarDialogoExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "¡Permiso Radicado!",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tu justificación ha sido enviada al flujo institucional de 2 niveles:",
              style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
            ),
            SizedBox(height: 10),
            Text(
              "• 1° Nivel: Revisión del Supervisor asignado.\n"
              "• 2° Nivel: Aprobación definitiva por Administración (con exención de multa si es viernes).",
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _limpiarFormulario();
            },
            child: const Text("Registrar otro"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BumandColores.AZUL_DIACONIA,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
              // Cambiar a la pestaña Historial (índice 3)
              ref.read(pestana_inicio_proveedor.notifier).cambiarPestana(3);
            },
            child: const Text("Ver en Historial"),
          ),
        ],
      ),
    );
  }

  void _limpiarFormulario() {
    setState(() {
      _motivo_controlador.clear();
      _descripcion_controlador.clear();
      _archivo_seleccionado = null;
      _bytes_archivo = null;
      _fecha_incidencia = DateTime.now();
      _tipo_incidencia_seleccionado = 'Escuela de Líderes';
    });
  }

  InputDecoration _decoracionCampo({
    required String etiqueta,
    String? hint,
    required IconData icono,
  }) {
    return InputDecoration(
      labelText: etiqueta,
      hintText: hint,
      prefixIcon: Icon(icono, color: BumandColores.AZUL_DIACONIA, size: 20),
      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: BumandColores.AZUL_DIACONIA, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado_auth = ref.watch(autenticacion_proveedor);
    final usuario = estado_auth.usuario;
    final nombre_becario = usuario?.nombre ?? "Becario Solicitante";
    final rol_becario = (usuario?.rol ?? 'becario').toUpperCase();

    final fecha_formateada =
        "${_fecha_incidencia.day.toString().padLeft(2, '0')}/"
        "${_fecha_incidencia.month.toString().padLeft(2, '0')}/"
        "${_fecha_incidencia.year}";

    return Scaffold(
      backgroundColor: BumandColores.FONDO,
      appBar: const BarraSuperiorBumand(
        titulo: "Registrar Permiso",
        subtitulo: "Ingreso oficial con respaldo médico o académico",
      ),
      body: SafeArea(
        child: Form(
          key: _clave_formulario,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // Banner informativo institucional
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
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
                            "Solicitud Formal con Respaldo",
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: BumandColores.NEGRO,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            "Toda inasistencia o retraso justificado con receta o certificado médico cuenta con exención total de multas tras la aprobación de Supervisor y Administración.",
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 1. Becario Solicitante (Solo lectura institucional)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: BumandColores.AZUL_DIACONIA,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Becario Solicitante",
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          Text(
                            nombre_becario,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rol_becario,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: BumandColores.AZUL_DIACONIA,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. Tipo de Incidencia
              DropdownButtonFormField<String>(
                initialValue: _tipo_incidencia_seleccionado,
                decoration: _decoracionCampo(
                  etiqueta: "Tipo de Incidencia *",
                  icono: Icons.category_rounded,
                ),
                borderRadius: BorderRadius.circular(14),
                items: TIPOS_INCIDENCIA_MAPA.keys.map((tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo,
                    child: Text(
                      tipo == 'Escuela de Líderes'
                          ? 'Escuela de Líderes (Viernes)'
                          : tipo,
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _tipo_incidencia_seleccionado = val);
                  }
                },
              ),
              const SizedBox(height: 14),

              // 3. Fecha de Incidencia
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _seleccionarFecha,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: BumandColores.AZUL_DIACONIA,
                        size: 20,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Fecha de la Incidencia *",
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              fecha_formateada,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        "Cambiar",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: BumandColores.AZUL_DIACONIA,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 4. Motivo Resumido (Texto libre sin chips limitantes)
              TextFormField(
                controller: _motivo_controlador,
                decoration: _decoracionCampo(
                  etiqueta: "Motivo Resumido *",
                  hint: "Ej. Cita médica en seguro social, Examen parcial...",
                  icono: Icons.edit_note_rounded,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Ingresa el motivo resumido de la justificación";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // 5. Descripción Detallada
              TextFormField(
                controller: _descripcion_controlador,
                maxLines: 4,
                decoration: _decoracionCampo(
                  etiqueta: "Descripción Detallada *",
                  hint: "Explica las circunstancias de la inasistencia o retraso...",
                  icono: Icons.notes_rounded,
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 10) {
                    return "Ingresa una explicación detallada (mínimo 10 caracteres)";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 6. Prueba Justificable (Receta médica o certificado)
              const Text(
                "Prueba Justificable (Receta médica o certificado emitido) *",
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              if (_archivo_seleccionado == null)
                InkWell(
                  onTap: _seleccionarArchivo,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            size: 32,
                            color: BumandColores.AZUL_DIACONIA,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Adjuntar receta o certificado médico",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: BumandColores.AZUL_DIACONIA,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Formatos aceptados: JPG, PNG, WEBP o PDF (Receta o certificado médico emitido)",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF10B981), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
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
                              _archivo_seleccionado!.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${(_bytes_archivo!.length / 1024).toStringAsFixed(1)} KB · Documento adjunto",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        tooltip: "Quitar archivo",
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
              const SizedBox(height: 24),

              // Botón de radicación
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BumandColores.AZUL_DIACONIA,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _enviando ? null : _radicarJustificacion,
                  icon: _enviando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  label: Text(
                    _enviando
                        ? "Radicando solicitud..."
                        : "Radicar Permiso / Justificación",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
