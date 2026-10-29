import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../nucleo/tema/colores.dart';
import '../modelos/evaluacion-modelo.dart';
import '../modelos/pregunta-bienestar-modelo.dart';
import '../repositorios/evaluaciones-repositorio.dart';
import 'formulario_f03_dialogo.dart';

class DetalleEvaluacionModal extends StatelessWidget {
  final String numero_modulo;
  final String titulo;
  final String evaluador;
  final double puntaje;
  final double puntaje_maximo;
  final String estado;
  final String? archivo_nombre;
  final String? fecha_archivo;
  final String? comentario;

  const DetalleEvaluacionModal({
    super.key,
    required this.numero_modulo,
    required this.titulo,
    required this.evaluador,
    this.puntaje = 0.0,
    this.puntaje_maximo = 20.0,
    required this.estado,
    this.archivo_nombre,
    this.fecha_archivo,
    this.comentario,
  });

  static void mostrar(
    BuildContext context, {
    required String numero_modulo,
    required String titulo,
    required String evaluador,
    double puntaje = 0.0,
    double puntaje_maximo = 20.0,
    required String estado,
    String? archivo_nombre,
    String? fecha_archivo,
    String? comentario,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DetalleEvaluacionModal(
        numero_modulo: numero_modulo,
        titulo: titulo,
        evaluador: evaluador,
        puntaje: puntaje,
        puntaje_maximo: puntaje_maximo,
        estado: estado,
        archivo_nombre: archivo_nombre,
        fecha_archivo: fecha_archivo,
        comentario: comentario,
      ),
    );
  }

  Color _obtenerColorEstado(String estado_texto) {
    switch (estado_texto.toLowerCase()) {
      case "completada":
      case "completado":
      case "recibido":
      case "documentos recibidos":
      case "aprobado":
        return BumandColores.azulMarinoProfundo;
      case "pendiente":
      case "en revisión":
        return const Color(0xFFF59E0B);
      case "incompleto":
      case "observada":
      case "observado":
        return const Color(0xFFEF4444);
      default:
        return Colors.blueGrey;
    }
  }

  static void mostrarReceptorAcademico(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ReceptorAcademicoModal(),
    );
  }

  static void mostrarReceptorMentor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ReceptorMentorModal(),
    );
  }

  static void mostrarReceptorLideresClassroom(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ReceptorLideresClassroomModal(),
    );
  }

  static void mostrarReceptorSocioeconomico(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ReceptorSocioeconomicoModal(),
    );
  }

  static Future<Map<String, dynamic>?> verificarIdentidadSupervisor(
    BuildContext context, {
    int becario_id = 1,
    String? becario_nombre,
  }) {
    return showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DialogoVerificacionSupervisor(
        becario_id: becario_id,
        becario_nombre: becario_nombre,
      ),
    ).then((res) {
      if (res is Map<String, dynamic>) return res;
      if (res is Map) return Map<String, dynamic>.from(res);
      if (res is String) {
        return {
          'verificado': true,
          'supervisor_nombre': res,
          'codigo_verificacion': '123456',
        };
      }
      return null;
    });
  }

  static void mostrarFormularioMentor(
    BuildContext context, {
    int becario_id = 1,
    String becario_nombre = "María Catunta Laime",
    String supervisor_nombre_inicial = "Lic. Carlos Mendoza",
    String modalidad_llenado = "perfil_supervisor",
    String? codigo_verificacion,
    Map<String, dynamic>? evaluacion_previa,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioSupervisorEvaluador(
        becario_id: becario_id,
        becario_nombre: becario_nombre,
        supervisor_nombre_inicial: supervisor_nombre_inicial,
        modalidad_llenado: modalidad_llenado,
        codigo_verificacion: codigo_verificacion,
        evaluacion_previa: evaluacion_previa,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color_estado = _obtenerColorEstado(estado);
    final es_f03 = titulo.toLowerCase().contains("f-03") ||
        titulo.toLowerCase().contains("pastor") ||
        numero_modulo == "01" ||
        numero_modulo == "1";
    final es_academica = numero_modulo == "02" ||
        numero_modulo == "2" ||
        titulo.toLowerCase().contains("académ") ||
        titulo.toLowerCase().contains("academ");
    final es_mentor = numero_modulo == "03" ||
        numero_modulo == "3" ||
        titulo.toLowerCase().contains("mentor") ||
        titulo.toLowerCase().contains("supervisor");
    final es_socioeconomica = numero_modulo == "05" ||
        numero_modulo == "5" ||
        titulo.toLowerCase().contains("socio");
    final es_lideres = numero_modulo == "04" ||
        numero_modulo == "4" ||
        titulo.toLowerCase().contains("líder") ||
        titulo.toLowerCase().contains("lider");

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Módulo $numero_modulo",
                  style: const TextStyle(
                    color: BumandColores.AZUL_DIACONIA,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BumandColores.NEGRO,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            evaluador,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color_estado.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    estado.toLowerCase().contains("complet") ||
                            estado.toLowerCase().contains("recib")
                        ? Icons.check_circle_outline
                        : Icons.hourglass_top_outlined,
                    color: color_estado,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Estado de recepción:",
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        estado.toUpperCase(),
                        style: TextStyle(
                          color: color_estado,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Text(
                    "Semestre II - 2026",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (archivo_nombre != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.description,
                      color: BumandColores.AZUL_DIACONIA,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          archivo_nombre!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (fecha_archivo != null)
                          Text(
                            fecha_archivo!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.download, size: 18, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (comentario != null && comentario!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Observaciones institucionales:",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "\"$comentario\"",
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (es_f03) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  FormularioF03Dialogo.mostrar(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BumandColores.amarilloRadiante,
                  foregroundColor: BumandColores.azulMarinoSecundario,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.church_outlined),
                label: const Text(
                  "Abrir Formulario F-03 del Pastor",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (es_academica) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  DetalleEvaluacionModal.mostrarReceptorAcademico(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BumandColores.AZUL_DIACONIA,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.upload_file),
                label: const Text(
                  "Subir Récord e Historial Académico",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (es_mentor) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  DetalleEvaluacionModal.mostrarReceptorMentor(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BumandColores.AZUL_DIACONIA,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.qr_code_2),
                label: const Text(
                  "Ver Código QR / Evaluación del Tutor",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (es_lideres) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  DetalleEvaluacionModal.mostrarReceptorLideresClassroom(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.school_outlined),
                label: const Text(
                  "Abrir Tareas Escuela de Líderes (Classroom)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (es_socioeconomica) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  DetalleEvaluacionModal.mostrarReceptorSocioeconomico(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BumandColores.amarilloRadiante,
                  foregroundColor: BumandColores.azulMarinoSecundario,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.assignment_outlined),
                label: const Text(
                  "Llenar Formulario Socioeconómico",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }
}

class CodigoQrWidget extends StatelessWidget {
  final double tamano;
  const CodigoQrWidget({super.key, this.tamano = 190});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(tamano - 24, tamano - 24),
        painter: _CodigoQrPintor(),
      ),
    );
  }
}

class _CodigoQrPintor extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pintura_modulo = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    final pintura_fondo = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), pintura_fondo);

    const int cuadricula = 21;
    final ancho_celda = size.width / cuadricula;
    final alto_celda = size.height / cuadricula;

    void dibujarPatronPosicion(int col_inicio, int fila_inicio) {
      canvas.drawRect(
        Rect.fromLTWH(
          col_inicio * ancho_celda,
          fila_inicio * alto_celda,
          7 * ancho_celda,
          7 * alto_celda,
        ),
        pintura_modulo,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          (col_inicio + 1) * ancho_celda,
          (fila_inicio + 1) * alto_celda,
          5 * ancho_celda,
          5 * alto_celda,
        ),
        pintura_fondo,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          (col_inicio + 2) * ancho_celda,
          (fila_inicio + 2) * alto_celda,
          3 * ancho_celda,
          3 * alto_celda,
        ),
        pintura_modulo,
      );
    }

    dibujarPatronPosicion(0, 0);
    dibujarPatronPosicion(cuadricula - 7, 0);
    dibujarPatronPosicion(0, cuadricula - 7);

    for (int col = 8; col < cuadricula - 8; col++) {
      if (col % 2 == 0) {
        canvas.drawRect(
          Rect.fromLTWH(col * ancho_celda, 6 * alto_celda, ancho_celda, alto_celda),
          pintura_modulo,
        );
        canvas.drawRect(
          Rect.fromLTWH(6 * ancho_celda, col * alto_celda, ancho_celda, alto_celda),
          pintura_modulo,
        );
      }
    }

    for (int fila = 0; fila < cuadricula; fila++) {
      for (int col = 0; col < cuadricula; col++) {
        final en_posicion_tl = fila < 8 && col < 8;
        final en_posicion_tr = fila < 8 && col >= cuadricula - 8;
        final en_posicion_bl = fila >= cuadricula - 8 && col < 8;
        final en_sincronia = fila == 6 || col == 6;

        if (en_posicion_tl || en_posicion_tr || en_posicion_bl || en_sincronia) {
          continue;
        }

        final hash = ((fila * 31 + col * 17 + 13) % 100);
        if (hash < 48) {
          canvas.drawRect(
            Rect.fromLTWH(
              col * ancho_celda + 0.3,
              fila * alto_celda + 0.3,
              ancho_celda - 0.6,
              alto_celda - 0.6,
            ),
            pintura_modulo,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReceptorAcademicoModal extends StatefulWidget {
  const _ReceptorAcademicoModal();

  @override
  State<_ReceptorAcademicoModal> createState() => _ReceptorAcademicoModalState();
}

class _ReceptorAcademicoModalState extends State<_ReceptorAcademicoModal> {
  final _repositorio = EvaluacionesRepositorio();
  final _promedio_ctrl = TextEditingController(text: "81.5");

  int _periodo_seleccionado_id = 2; // Semestre II - 2026

  static const List<Map<String, dynamic>> PERIODOS_ACADEMICOS = [
    {"id": 2, "nombre": "Semestre II - 2026", "activo": true},
    {"id": 1, "nombre": "Semestre I - 2026", "activo": false},
    {"id": 3, "nombre": "Semestre II - 2025", "activo": false},
  ];

  final Map<int, Map<String, dynamic>> _docs_por_periodo = {
    2: {
      "record_nombre": null,
      "record_tamano": null,
      "record_estado": "Pendiente de subida",
      "historial_nombre": null,
      "historial_tamano": null,
      "historial_estado": "Pendiente de subida",
    },
    1: {
      "record_nombre": "record_academico_semestre_1_2026.pdf",
      "record_tamano": "1.2 MB",
      "record_estado": "Aprobado por Administración",
      "historial_nombre": "historial_completo_2026_s1.pdf",
      "historial_tamano": "2.4 MB",
      "historial_estado": "Aprobado por Administración",
    },
    3: {
      "record_nombre": "record_oficial_2025_s2.pdf",
      "record_tamano": "980 KB",
      "record_estado": "Aprobado por Administración",
      "historial_nombre": "historial_academico_2025.pdf",
      "historial_tamano": "1.8 MB",
      "historial_estado": "Aprobado por Administración",
    },
  };

  bool _subiendo_record = false;
  bool _subiendo_historial = false;

  Map<String, dynamic> get _docActual =>
      _docs_por_periodo[_periodo_seleccionado_id] ??= {
        "record_nombre": null,
        "record_tamano": null,
        "record_estado": "Pendiente de subida",
        "historial_nombre": null,
        "historial_tamano": null,
        "historial_estado": "Pendiente de subida",
      };

  @override
  void dispose() {
    _promedio_ctrl.dispose();
    super.dispose();
  }

  Future<void> _subirDocumento({required bool es_record}) async {
    try {
      final resultado = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (resultado.isNotEmpty) {
        final archivo = resultado.first;
        final bytes = await archivo.readAsBytes();
        final tamano_bytes = archivo.lengthSync() ?? bytes.length;
        final tamano = tamano_bytes > 1024 * 1024
            ? "${(tamano_bytes / (1024 * 1024)).toStringAsFixed(1)} MB"
            : "${(tamano_bytes / 1024).toStringAsFixed(1)} KB";

        setState(() {
          if (es_record) {
            _subiendo_record = true;
            _docActual["record_nombre"] = archivo.name;
            _docActual["record_tamano"] = tamano;
            _docActual["record_estado"] = "Enviado a Administración";
          } else {
            _subiendo_historial = true;
            _docActual["historial_nombre"] = archivo.name;
            _docActual["historial_tamano"] = tamano;
            _docActual["historial_estado"] = "Enviado a Administración";
          }
        });

        final res = await _repositorio.subirDocumentoAcademico(
          periodo_id: _periodo_seleccionado_id,
          tipo_documento: es_record ? 'record_academico' : 'historial_academico',
          bytes: bytes,
          nombre_archivo: archivo.name,
        );

        if (!mounted) return;
        setState(() {
          if (es_record) {
            _subiendo_record = false;
            if (res.exito) {
              _docActual["record_estado"] = "Enviado a Administración";
            }
          } else {
            _subiendo_historial = false;
            if (res.exito) {
              _docActual["historial_estado"] = "Enviado a Administración";
            }
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              es_record
                  ? "✓ Récord Académico recibido para revisión directa por Administración."
                  : "✓ Historial Académico recibido para revisión directa por Administración.",
            ),
            backgroundColor: BumandColores.AZUL_DIACONIA,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _subiendo_record = false;
        _subiendo_historial = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al cargar documento: $e"),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  void _eliminarDocumento({required bool es_record}) {
    setState(() {
      if (es_record) {
        _docActual["record_nombre"] = null;
        _docActual["record_tamano"] = null;
        _docActual["record_estado"] = "Pendiente de subida";
      } else {
        _docActual["historial_nombre"] = null;
        _docActual["historial_tamano"] = null;
        _docActual["historial_estado"] = "Pendiente de subida";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final periodo_actual = PERIODOS_ACADEMICOS.firstWhere(
      (p) => p["id"] == _periodo_seleccionado_id,
      orElse: () => PERIODOS_ACADEMICOS.first,
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Módulo 02 · Receptor Académico",
                    style: TextStyle(
                      color: BumandColores.AZUL_DIACONIA,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Text(
              "Subida de Documentos Académicos",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: BumandColores.NEGRO,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Adjunta tu Récord e Historial Académico por semestre. Ambos documentos son revisados y validados de forma directa por Administración.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),

            // Badge de Revisión Directa por Administración
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Color(0xFF1D4ED8),
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Revisión Directa por Administración",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Los documentos se derivan directamente a Administración Académica sin convalidación previa del supervisor de prácticas.",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Selector dinámico de semestre
            const Text(
              "Selecciona el Semestre Académico:",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: PERIODOS_ACADEMICOS.map((periodo) {
                  final es_seleccionado = periodo["id"] == _periodo_seleccionado_id;
                  final es_activo = periodo["activo"] == true;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: es_seleccionado,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            periodo["nombre"] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  es_seleccionado ? FontWeight.bold : FontWeight.w500,
                              color: es_seleccionado
                                  ? Colors.white
                                  : const Color(0xFF334155),
                            ),
                          ),
                          if (es_activo) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: es_seleccionado
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                "Activo",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: es_seleccionado
                                      ? Colors.white
                                      : const Color(0xFF15803D),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      selectedColor: BumandColores.AZUL_DIACONIA,
                      backgroundColor: const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: es_seleccionado
                              ? BumandColores.AZUL_DIACONIA
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _periodo_seleccionado_id = periodo["id"] as int;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Tarjeta 1: Subir Récord Académico
            _construirTarjetaDocumento(
              titulo: "1. Récord Académico",
              subtitulo: "Calificaciones oficiales del ${periodo_actual['nombre']}",
              nombre_archivo: _docActual["record_nombre"] as String?,
              tamano_archivo: _docActual["record_tamano"] as String?,
              estado: _docActual["record_estado"] as String,
              icono: Icons.description_outlined,
              color_icono: const Color(0xFF2563EB),
              cargando: _subiendo_record,
              alSubir: () => _subirDocumento(es_record: true),
              alEliminar: () => _eliminarDocumento(es_record: true),
              texto_boton: _docActual["record_nombre"] == null
                  ? "Subir Récord Académico"
                  : "Cambiar Récord",
            ),
            const SizedBox(height: 12),

            // Tarjeta 2: Subir Historial Académico
            _construirTarjetaDocumento(
              titulo: "2. Historial Académico",
              subtitulo: "Malla curricular y materias aprobadas a la fecha",
              nombre_archivo: _docActual["historial_nombre"] as String?,
              tamano_archivo: _docActual["historial_tamano"] as String?,
              estado: _docActual["historial_estado"] as String,
              icono: Icons.history_edu_outlined,
              color_icono: const Color(0xFF0D9488),
              cargando: _subiendo_historial,
              alSubir: () => _subirDocumento(es_record: false),
              alEliminar: () => _eliminarDocumento(es_record: false),
              texto_boton: _docActual["historial_nombre"] == null
                  ? "Subir Historial Académico"
                  : "Cambiar Historial",
            ),
            const SizedBox(height: 16),

            // Promedio Semestral Autodeclarado
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Promedio Semestral Autodeclarado",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _promedio_ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: "Ej. 82.50",
                    suffixText: "pts",
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "✓ Documentación académica enviada para revisión por Administración.",
                      ),
                      backgroundColor: BumandColores.AZUL_DIACONIA,
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BumandColores.AZUL_DIACONIA,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  "Finalizar y Confirmar Envío",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTarjetaDocumento({
    required String titulo,
    required String subtitulo,
    required String? nombre_archivo,
    required String? tamano_archivo,
    required String estado,
    required IconData icono,
    required Color color_icono,
    required bool cargando,
    required VoidCallback alSubir,
    required VoidCallback alEliminar,
    required String texto_boton,
  }) {
    final es_aprobado = estado.toLowerCase().contains("aprobado");
    final es_enviado = estado.toLowerCase().contains("enviado");

    Color color_badge_fondo = const Color(0xFFFEF3C7);
    Color color_badge_borde = const Color(0xFFFDE68A);
    Color color_badge_texto = const Color(0xFFB45309);
    IconData icono_badge = Icons.hourglass_empty;

    if (es_aprobado) {
      color_badge_fondo = const Color(0xFFDCFCE7);
      color_badge_borde = const Color(0xFF86EFAC);
      color_badge_texto = const Color(0xFF15803D);
      icono_badge = Icons.verified_rounded;
    } else if (es_enviado) {
      color_badge_fondo = const Color(0xFFEFF6FF);
      color_badge_borde = const Color(0xFFBFDBFE);
      color_badge_texto = const Color(0xFF1D4ED8);
      icono_badge = Icons.schedule_send_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: nombre_archivo != null
              ? BumandColores.AZUL_DIACONIA
              : const Color(0xFFCBD5E1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color_icono.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color_icono, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color_badge_fondo,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color_badge_borde),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icono_badge, size: 12, color: color_badge_texto),
                    const SizedBox(width: 4),
                    Text(
                      estado,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: color_badge_texto,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (nombre_archivo != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.attach_file,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "$nombre_archivo ${tamano_archivo != null ? '($tamano_archivo)' : ''}",
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
                    visualDensity: VisualDensity.compact,
                    onPressed: alEliminar,
                    tooltip: "Quitar archivo",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              onPressed: cargando ? null : alSubir,
              style: ElevatedButton.styleFrom(
                backgroundColor: nombre_archivo == null
                    ? BumandColores.AZUL_DIACONIA
                    : const Color(0xFFF1F5F9),
                foregroundColor: nombre_archivo == null
                    ? Colors.white
                    : BumandColores.azulMarinoSecundario,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: nombre_archivo == null
                        ? Colors.transparent
                        : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
              icon: cargando
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(
                      nombre_archivo == null
                          ? Icons.cloud_upload_outlined
                          : Icons.replay_outlined,
                      size: 16,
                    ),
              label: Text(
                cargando ? "Subiendo..." : texto_boton,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceptorMentorModal extends StatelessWidget {
  const _ReceptorMentorModal();

  void _abrirVerificacionSupervisor(BuildContext context) {
    showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _DialogoVerificacionSupervisor(
        becario_id: 1,
        becario_nombre: "María Catunta Laime",
      ),
    ).then((resultado) {
      if (resultado != null && context.mounted) {
        final String supervisor_nombre = resultado is Map
            ? (resultado['supervisor_nombre']?.toString() ?? "Lic. Carlos Mendoza")
            : resultado.toString();
        final String? codigo_verificacion =
            resultado is Map ? resultado['codigo_verificacion']?.toString() : null;

        Navigator.of(context).pop();
        _mostrarFormularioSupervisor(
          context,
          supervisor_nombre,
          codigo_verificacion,
        );
      }
    });
  }

  void _mostrarFormularioSupervisor(
    BuildContext context,
    String supervisor_nombre,
    String? codigo_verificacion,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioSupervisorEvaluador(
        becario_id: 1,
        becario_nombre: "María Catunta Laime",
        supervisor_nombre_inicial: supervisor_nombre,
        modalidad_llenado: "celular_estudiante",
        codigo_verificacion: codigo_verificacion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Módulo 03 · Acceso QR Supervisor",
                  style: TextStyle(
                    color: BumandColores.AZUL_DIACONIA,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Text(
            "Evaluación del Mentor / Supervisor",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BumandColores.NEGRO,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Muestra este código QR a tu Supervisor/Tutor de área para que realice tu evaluación. El becario no tiene acceso a las preguntas.",
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          const Center(child: CodigoQrWidget(tamano: 200)),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "token: mentor-diaconia-2026-b1",
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: "monospace",
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _abrirVerificacionSupervisor(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: BumandColores.amarilloRadiante,
                  foregroundColor: BumandColores.azulMarinoSecundario,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.person_pin_circle_outlined),
              label: const Text(
                "¿Eres el Supervisor/Tutor? Evaluar aquí",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogoVerificacionSupervisor extends StatefulWidget {
  final int becario_id;
  final String? becario_nombre;

  const _DialogoVerificacionSupervisor({
    this.becario_id = 1,
    this.becario_nombre,
  });

  @override
  State<_DialogoVerificacionSupervisor> createState() =>
      _DialogoVerificacionSupervisorState();
}

class _DialogoVerificacionSupervisorState
    extends State<_DialogoVerificacionSupervisor> {
  final _repositorio = EvaluacionesRepositorio();
  final _codigo_ctrl = TextEditingController();

  bool _enviando_codigo = true;
  bool _verificando = false;
  String? _mensaje_error;

  @override
  void initState() {
    super.initState();
    _solicitarCodigoNotificacion();
  }

  @override
  void dispose() {
    _codigo_ctrl.dispose();
    super.dispose();
  }

  Future<void> _solicitarCodigoNotificacion() async {
    setState(() {
      _enviando_codigo = true;
      _mensaje_error = null;
    });

    await _repositorio.solicitarCodigoTutor(becario_id: widget.becario_id);
    if (!mounted) return;

    setState(() {
      _enviando_codigo = false;
    });
  }

  Future<void> _verificarIdentidad() async {
    final codigo = _codigo_ctrl.text.trim();
    if (codigo.isEmpty) {
      setState(() {
        _mensaje_error = "Ingresa el código de 6 dígitos enviado a su supervisor específico.";
      });
      return;
    }

    setState(() {
      _verificando = true;
      _mensaje_error = null;
    });

    final resultado = await _repositorio.verificarCodigoTutor(
      becario_id: widget.becario_id,
      codigo: codigo,
    );

    if (!mounted) return;
    setState(() => _verificando = false);

    if (resultado.exito && resultado.datos?['verificado'] == true) {
      final nombre =
          resultado.datos?['supervisor_nombre']?.toString() ?? "Supervisor Asignado";
      Navigator.of(context).pop({
        'verificado': true,
        'supervisor_nombre': nombre,
        'codigo_verificacion': codigo,
      });
    } else {
      setState(() {
        _mensaje_error =
            resultado.error ?? "Código incorrecto o expirado.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Verificación de Identidad del Tutor",
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: BumandColores.NEGRO,
                        ),
                      ),
                      Text(
                        widget.becario_nombre != null
                            ? "Evaluando a: ${widget.becario_nombre}"
                            : "Seguridad antifraude · Módulo 03",
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Container(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pin_outlined,
                      size: 15,
                      color: BumandColores.AZUL_DIACONIA,
                    ),
                    SizedBox(width: 5),
                    Text(
                      "Código en pantalla",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: BumandColores.AZUL_DIACONIA,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              "Código de 6 dígitos de su Supervisor",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _codigo_ctrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: BumandColores.AZUL_DIACONIA,
              ),
              decoration: InputDecoration(
                counterText: "",
                hintText: "000000",
                hintStyle: TextStyle(
                  fontSize: 20,
                  letterSpacing: 8,
                  color: Colors.grey.shade400,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed:
                    _enviando_codigo ? null : _solicitarCodigoNotificacion,
                icon: const Icon(Icons.refresh, size: 15),
                label: Text(
                  _enviando_codigo
                      ? "Enviando código..."
                      : "Reenviar código al supervisor",
                  style: const TextStyle(fontSize: 11.5),
                ),
              ),
            ),

            if (_mensaje_error != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFDC2626),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _mensaje_error!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text("Cancelar"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _verificando ? null : _verificarIdentidad,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BumandColores.AZUL_DIACONIA,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _verificando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.lock_open_rounded, size: 17),
                    label: Text(
                      _verificando
                          ? "Verificando..."
                          : "Verificar y abrir evaluación",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FormularioSupervisorEvaluador extends StatefulWidget {
  final int becario_id;
  final String becario_nombre;
  final String supervisor_nombre_inicial;
  final String modalidad_llenado;
  final String? codigo_verificacion;
  final Map<String, dynamic>? evaluacion_previa;

  const _FormularioSupervisorEvaluador({
    this.becario_id = 1,
    this.becario_nombre = "María Catunta Laime",
    this.supervisor_nombre_inicial = "Lic. Carlos Mendoza",
    this.modalidad_llenado = "perfil_supervisor",
    this.codigo_verificacion,
    this.evaluacion_previa,
  });

  @override
  State<_FormularioSupervisorEvaluador> createState() =>
      _FormularioSupervisorEvaluadorState();
}

class _FormularioSupervisorEvaluadorState
    extends State<_FormularioSupervisorEvaluador> {
  final _repositorio = EvaluacionesRepositorio();

  // Sección I: Datos Generales
  late final TextEditingController _mentor_ctrl;
  late final TextEditingController _becario_ctrl;
  late final TextEditingController _agencia_ctrl;
  final _semestre_ctrl = TextEditingController(text: "Semestre II - 2026");
  final _fecha_ctrl = TextEditingController(
    text: "${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}",
  );

  // Sección II: Preguntas 1 al 18 (Escala 1 al 10)
  static const List<Map<String, String>> PREGUNTAS_MENTOR_1_18 = [
    {
      "num": "1",
      "titulo": "Plazos establecidos",
      "desc": "Cumplimiento oportuno de plazos establecidos en sus asignaciones.",
    },
    {
      "num": "2",
      "titulo": "Calidad general del trabajo",
      "desc": "Calidad, orden, rigor y precisión del trabajo realizado.",
    },
    {
      "num": "3",
      "titulo": "Atención al detalle",
      "desc": "Cuidado en los detalles y minimización de errores en entregables.",
    },
    {
      "num": "4",
      "titulo": "Trabajo bajo presión",
      "desc": "Capacidad de adaptación y serenidad ante alta demanda o plazos ajustados.",
    },
    {
      "num": "5",
      "titulo": "Conocimientos técnicos",
      "desc": "Aplicación de conocimientos teóricos y técnicos propios de su carrera.",
    },
    {
      "num": "6",
      "titulo": "Iniciativa para resolver problemas",
      "desc": "Proactividad para resolver dificultades y proponer mejoras en procesos.",
    },
    {
      "num": "7",
      "titulo": "Comunicación clara y empática",
      "desc": "Habilidad de comunicar dudas, avances e ideas con respeto y asertividad.",
    },
    {
      "num": "8",
      "titulo": "Contribución en equipo",
      "desc": "Disposición para aportar positivamente en las actividades grupales.",
    },
    {
      "num": "9",
      "titulo": "Actitud hacia su responsable directo",
      "desc": "Respeto, receptividad y cumplimiento de directrices del tutor.",
    },
    {
      "num": "10",
      "titulo": "Respeto hacia colaboradores / cliente interno",
      "desc": "Trato cordial, inclusivo y colaborativo con compañeros de trabajo.",
    },
    {
      "num": "11",
      "titulo": "Respeto hacia proveedores / cliente externo",
      "desc": "Cortesía, puntualidad y profesionalismo en la atención a terceros.",
    },
    {
      "num": "12",
      "titulo": "Aceptación de retroalimentación constructiva",
      "desc": "Recepción positiva de correcciones y voluntad de aprendizaje continuo.",
    },
    {
      "num": "13",
      "titulo": "Actitud para colaborar",
      "desc": "Voluntad para asistir y apoyar en tareas imprevistas del área.",
    },
    {
      "num": "14",
      "titulo": "Adaptación a cambios inesperados",
      "desc": "Flexibilidad ante imprevistos, reasignación de prioridades o metodologías.",
    },
    {
      "num": "15",
      "titulo": "Asistencia regular al menos 9 horas semanales",
      "desc": "Cumplimiento cabal de la carga horaria comprometida en prácticas.",
    },
    {
      "num": "16",
      "titulo": "Puntualidad y consistencia",
      "desc": "Llegada a tiempo y compromiso constante durante la jornada laboral.",
    },
    {
      "num": "17",
      "titulo": "Comprensión de misión/visión/valores Diaconía IFD",
      "desc": "Identificación y vivencia de la identidad institucional y principios éticos.",
    },
    {
      "num": "18",
      "titulo": "Compromiso con misión y objetivos del área",
      "desc": "Alineación y sentido de pertenencia con las metas del equipo de trabajo.",
    },
  ];

  late final Map<int, int> _calificaciones_1_18;

  // Sección III: Preguntas Abiertas 19 al 21
  final _pregunta_19_ctrl = TextEditingController();
  final _pregunta_20_ctrl = TextEditingController();
  final _pregunta_21_ctrl = TextEditingController();
  final _observaciones_ctrl = TextEditingController();

  double _puntaje_19 = 3.33;
  double _puntaje_20 = 3.33;
  double _puntaje_21 = 3.34;

  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _mentor_ctrl = TextEditingController(text: widget.supervisor_nombre_inicial);
    _becario_ctrl = TextEditingController(text: widget.becario_nombre);
    _agencia_ctrl = TextEditingController(
      text: widget.evaluacion_previa?['agencia']?.toString() ?? "Agencia Central Diaconía",
    );

    final prev_calif = widget.evaluacion_previa?['calificaciones_1_18'];
    _calificaciones_1_18 = {};
    for (int i = 1; i <= 18; i++) {
      int valor = 10;
      if (prev_calif is Map) {
        final v = prev_calif[i] ?? prev_calif[i.toString()] ?? prev_calif['pregunta_$i'];
        if (v != null) valor = int.tryParse(v.toString()) ?? 10;
      } else if (prev_calif is List && prev_calif.length >= i) {
        final v = prev_calif[i - 1];
        if (v != null) valor = int.tryParse(v.toString()) ?? 10;
      }
      _calificaciones_1_18[i] = valor.clamp(1, 10);
    }

    if (widget.evaluacion_previa != null) {
      _pregunta_19_ctrl.text = widget.evaluacion_previa!['pregunta_19_apoyo']?.toString() ??
          widget.evaluacion_previa!['pregunta_19']?['texto']?.toString() ??
          '';
      _pregunta_20_ctrl.text = widget.evaluacion_previa!['pregunta_20_destacado']?.toString() ??
          widget.evaluacion_previa!['pregunta_20']?['texto']?.toString() ??
          '';
      _pregunta_21_ctrl.text = widget.evaluacion_previa!['pregunta_21_sugerencias']?.toString() ??
          widget.evaluacion_previa!['pregunta_21']?['texto']?.toString() ??
          '';
      _observaciones_ctrl.text = widget.evaluacion_previa!['observaciones']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _mentor_ctrl.dispose();
    _becario_ctrl.dispose();
    _agencia_ctrl.dispose();
    _semestre_ctrl.dispose();
    _fecha_ctrl.dispose();
    _pregunta_19_ctrl.dispose();
    _pregunta_20_ctrl.dispose();
    _pregunta_21_ctrl.dispose();
    _observaciones_ctrl.dispose();
    super.dispose();
  }

  double _calcularPromedio1_18() {
    if (_calificaciones_1_18.isEmpty) return 0.0;
    final suma = _calificaciones_1_18.values.fold(0, (acc, n) => acc + n);
    return suma / _calificaciones_1_18.length;
  }

  Future<void> _enviarEvaluacionMentor() async {
    setState(() => _enviando = true);

    final calificaciones_map = <String, dynamic>{
      for (final entry in _calificaciones_1_18.entries)
        "pregunta_${entry.key}": entry.value,
    };

    final respuestas_completas = <String, dynamic>{
      "mentor": _mentor_ctrl.text.trim(),
      "becario": _becario_ctrl.text.trim(),
      "agencia": _agencia_ctrl.text.trim(),
      "semestre": _semestre_ctrl.text.trim(),
      "fecha": _fecha_ctrl.text.trim(),
      "modalidad_llenado": widget.modalidad_llenado,
      if (widget.codigo_verificacion != null)
        "codigo_verificacion": widget.codigo_verificacion,
      "calificaciones_1_18": calificaciones_map,
      "promedio_1_18": _calcularPromedio1_18(),
      "pregunta_19": {
        "texto": _pregunta_19_ctrl.text.trim(),
        "puntaje": _puntaje_19,
      },
      "pregunta_20": {
        "texto": _pregunta_20_ctrl.text.trim(),
        "puntaje": _puntaje_20,
      },
      "pregunta_21": {
        "texto": _pregunta_21_ctrl.text.trim(),
        "puntaje": _puntaje_21,
      },
    };

    final resultado = await _repositorio.enviarEvaluacionMentorQr(
      becario_id: widget.becario_id,
      periodo_id: 1,
      supervisor_nombre: _mentor_ctrl.text.trim(),
      modalidad_llenado: widget.modalidad_llenado,
      codigo_verificacion: widget.codigo_verificacion,
      respuestas: respuestas_completas,
      calificaciones_1_18: calificaciones_map,
      pregunta_19_apoyo: _pregunta_19_ctrl.text.trim(),
      pregunta_20_destacado: _pregunta_20_destacado(),
      pregunta_21_sugerencias: _pregunta_21_ctrl.text.trim(),
      observaciones: _observaciones_ctrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _enviando = false);

    if (resultado.exito) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✓ Evaluación del Mentor registrada exitosamente en BUMAND."),
          backgroundColor: BumandColores.azulMarinoProfundo,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado.error ?? "No se pudo registrar la evaluación."),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  String _pregunta_20_destacado() => _pregunta_20_ctrl.text.trim();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Módulo 03 · Formulario Mentor F-03",
                  style: TextStyle(
                    color: BumandColores.AZUL_DIACONIA,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Evaluación del Becario por el Mentor",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: BumandColores.NEGRO,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Formulario oficial de prácticas preprofesionales (18 preguntas escala 1-10 + 3 preguntas abiertas).",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          const Divider(height: 20),
          Expanded(
            child: ListView(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.modalidad_llenado == 'perfil_supervisor'
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.modalidad_llenado == 'perfil_supervisor'
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.modalidad_llenado == 'perfil_supervisor'
                            ? Icons.verified_user_rounded
                            : Icons.phonelink_lock_rounded,
                        color: widget.modalidad_llenado == 'perfil_supervisor'
                            ? const Color(0xFF047857)
                            : const Color(0xFFB45309),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.modalidad_llenado == 'perfil_supervisor'
                              ? "Perfil Móvil del Supervisor · Código OTP Validado${widget.evaluacion_previa != null ? ' (Modo Edición)' : ''}"
                              : "Celular del Estudiante · Código OTP Validado",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: widget.modalidad_llenado == 'perfil_supervisor'
                                ? const Color(0xFF047857)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // SECCIÓN I: Datos Generales
                _construirCabeceraSeccion(
                  "Sección I — Datos Generales",
                  Icons.badge_outlined,
                ),
                const SizedBox(height: 8),
                _construirCampo("Nombre del Mentor Evaluador(a)", _mentor_ctrl),
                const SizedBox(height: 10),
                _construirCampo("Nombre del Becario", _becario_ctrl),
                const SizedBox(height: 10),
                _construirCampo("Unidad o Agencia de Prácticas", _agencia_ctrl),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _construirCampo("Semestre / Gestión", _semestre_ctrl)),
                    const SizedBox(width: 10),
                    Expanded(child: _construirCampo("Fecha", _fecha_ctrl)),
                  ],
                ),
                const SizedBox(height: 20),

                // SECCIÓN II: Preguntas 1 al 18
                _construirCabeceraSeccion(
                  "Sección II — Preguntas 1 al 18 (Escala 1 al 10)",
                  Icons.star_rate_outlined,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 10),
                  child: Text(
                    "Evalúe cada criterio del 1 (mínimo) al 10 (excelencia).",
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  ),
                ),
                ...PREGUNTAS_MENTOR_1_18.map((item) {
                  final numero = int.parse(item["num"]!);
                  final valor_actual = _calificaciones_1_18[numero] ?? 10;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: BumandColores.AZUL_DIACONIA,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "${item["num"]}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item["titulo"]!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: BumandColores.NEGRO,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item["desc"]!,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "$valor_actual/10",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: BumandColores.AZUL_DIACONIA,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(10, (idx) {
                              final nota = idx + 1;
                              final seleccionada = nota == valor_actual;
                              return Padding(
                                padding: const EdgeInsets.only(right: 5),
                                child: ChoiceChip(
                                  label: Text("$nota"),
                                  selected: seleccionada,
                                  onSelected: (_) {
                                    setState(() {
                                      _calificaciones_1_18[numero] = nota;
                                    });
                                  },
                                  selectedColor: BumandColores.AZUL_DIACONIA,
                                  backgroundColor: Colors.white,
                                  labelStyle: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: seleccionada ? Colors.white : const Color(0xFF334155),
                                  ),
                                  side: BorderSide(
                                    color: seleccionada
                                        ? BumandColores.AZUL_DIACONIA
                                        : const Color(0xFFCBD5E1),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // SECCIÓN III: Preguntas Abiertas 19 al 21
                _construirCabeceraSeccion(
                  "Sección III — Preguntas Abiertas (19 al 21)",
                  Icons.edit_note_outlined,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 10),
                  child: Text(
                    "Preguntas cualitativas de retroalimentación y sugerencias.",
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  ),
                ),

                // Pregunta 19
                _construirPreguntaAbierta(
                  "19",
                  "¿Cómo describiría el apoyo que ha recibido del becario durante este semestre?",
                  _pregunta_19_ctrl,
                  _puntaje_19,
                  (nuevoPuntaje) => setState(() => _puntaje_19 = nuevoPuntaje),
                  3.33,
                ),
                const SizedBox(height: 12),

                // Pregunta 20
                _construirPreguntaAbierta(
                  "20",
                  "¿Hubo alguna tarea o proyecto en particular en el que el becario haya destacado positivamente?",
                  _pregunta_20_ctrl,
                  _puntaje_20,
                  (nuevoPuntaje) => setState(() => _puntaje_20 = nuevoPuntaje),
                  3.33,
                ),
                const SizedBox(height: 12),

                // Pregunta 21
                _construirPreguntaAbierta(
                  "21",
                  "¿Qué sugerencias tiene respecto al programa BUMAND?",
                  _pregunta_21_ctrl,
                  _puntaje_21,
                  (nuevoPuntaje) => setState(() => _puntaje_21 = nuevoPuntaje),
                  3.34,
                ),
                const SizedBox(height: 12),

                // Observaciones
                const Text(
                  "Observaciones adicionales del tutor",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _observaciones_ctrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Observaciones finales de desempeño institucional...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón Enviar
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _enviando ? null : _enviarEvaluacionMentor,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BumandColores.AZUL_DIACONIA,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _enviando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _enviando ? "Guardando..." : "Enviar Evaluación del Mentor",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCabeceraSeccion(String titulo, IconData icono) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icono, size: 16, color: BumandColores.AZUL_DIACONIA),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: BumandColores.AZUL_DIACONIA,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCampo(String etiqueta, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirPreguntaAbierta(
    String numero,
    String titulo,
    TextEditingController ctrl,
    double puntaje_actual,
    ValueChanged<double> alCambiarPuntaje,
    double maximo,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BumandColores.AZUL_DIACONIA,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  numero,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: BumandColores.NEGRO,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "Escriba la respuesta del mentor...",
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                "Puntaje sugerido: ${puntaje_actual.toStringAsFixed(2)} / ${maximo.toStringAsFixed(2)} pts",
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReceptorLideresClassroomModal extends StatefulWidget {
  const _ReceptorLideresClassroomModal();

  @override
  State<_ReceptorLideresClassroomModal> createState() =>
      _ReceptorLideresClassroomModalState();
}

class _ReceptorLideresClassroomModalState
    extends State<_ReceptorLideresClassroomModal> {
  final _repositorio = EvaluacionesRepositorio();

  List<TareaEscuelaLideresModelo> _tareas =
      TareaEscuelaLideresModelo.catalogoCanonico();
  String _filtro = "Todas";

  final Map<int, Map<String, dynamic>> _evidencias_seleccionadas = {};
  final Map<int, bool> _entregando_por_tarea = {};

  @override
  void initState() {
    super.initState();
    _cargarTareas();
  }

  Future<void> _cargarTareas() async {
    final resultado = await _repositorio.obtenerTareasEscuelaLideres();
    if (!mounted) return;
    if (resultado.exito && resultado.datos != null && resultado.datos!.isNotEmpty) {
      setState(() {
        _tareas = resultado.datos!;
      });
    }
  }

  Future<void> _seleccionarEvidencia(int numero_tarea) async {
    try {
      final resultado = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'docx'],
      );

      if (resultado.isNotEmpty) {
        final archivo = resultado.first;
        final bytes = await archivo.readAsBytes();
        final tamano_bytes = archivo.lengthSync() ?? bytes.length;
        final tamano = tamano_bytes > 1024 * 1024
            ? "${(tamano_bytes / (1024 * 1024)).toStringAsFixed(1)} MB"
            : "${(tamano_bytes / 1024).toStringAsFixed(1)} KB";

        setState(() {
          _evidencias_seleccionadas[numero_tarea] = {
            'nombre': archivo.name,
            'tamano': tamano,
            'bytes': bytes,
          };
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al seleccionar evidencia: $e"),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _entregarTarea(int numero_tarea) async {
    final evidencia = _evidencias_seleccionadas[numero_tarea];
    if (evidencia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor adjunta un archivo o informe de evidencia antes de entregar."),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() {
      _entregando_por_tarea[numero_tarea] = true;
    });

    await _repositorio.subirEvidenciaTareaLideres(
      tarea_numero: numero_tarea,
      becario_id: 1,
      bytes: evidencia['bytes'] as List<int>,
      nombre_archivo: evidencia['nombre'] as String,
    );

    await _repositorio.entregarTareaLideres(
      tarea_numero: numero_tarea,
      becario_id: 1,
      archivo_nombre: evidencia['nombre'] as String,
      comentario: "Entrega semestral regular CETI",
    );

    if (!mounted) return;
    setState(() {
      _entregando_por_tarea[numero_tarea] = false;
      _evidencias_seleccionadas.remove(numero_tarea);

      final index = _tareas.indexWhere((t) => t.numero == numero_tarea);
      if (index != -1) {
        _tareas[index] = _tareas[index].copiarCon(
          estado: 'entregado',
          evidencia_nombre: evidencia['nombre'] as String,
          fecha_entrega:
              "${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}",
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✓ Tarea $numero_tarea entregada exitosamente en el aula virtual CETI."),
        backgroundColor: BumandColores.AZUL_DIACONIA,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _abrirDialogoCalificar(TareaEscuelaLideresModelo tarea) {
    final puntaje_ctrl = TextEditingController(text: "95");
    final retro_ctrl = TextEditingController(
      text: "Excelente análisis teológico y aplicabilidad al servicio comunitario.",
    );

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.rate_review_outlined, color: BumandColores.AZUL_DIACONIA),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Calificar Tarea ${tarea.numero}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tarea.tema,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Puntaje (0 - 100):",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: puntaje_ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: "Ej. 95",
                suffixText: "pts",
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Retroalimentación formativa:",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: retro_ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Observaciones teológicas y pastorales...",
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final puntaje = double.tryParse(puntaje_ctrl.text.trim()) ?? 95.0;
              final retro = retro_ctrl.text.trim();
              Navigator.of(ctx).pop();

              await _repositorio.revisarTareaLideres(
                tarea_numero: tarea.numero,
                becario_id: 1,
                puntaje: puntaje,
                retroalimentacion: retro,
              );

              if (!mounted) return;
              setState(() {
                final idx = _tareas.indexWhere((t) => t.numero == tarea.numero);
                if (idx != -1) {
                  _tareas[idx] = _tareas[idx].copiarCon(
                    estado: 'revisado',
                    puntaje_obtenido: puntaje,
                    retroalimentacion: retro,
                  );
                }
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("✓ Tarea ${tarea.numero} calificada y sellada como REVISADA."),
                  backgroundColor: const Color(0xFF15803D),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BumandColores.AZUL_DIACONIA,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Guardar Revisión"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tareas_filtradas = _tareas.where((t) {
      if (_filtro == "Pendientes") return t.estado.toLowerCase().contains("pendiente");
      if (_filtro == "Entregadas") return t.estado.toLowerCase().contains("entregad");
      if (_filtro == "Revisadas") return t.estado.toLowerCase().contains("revisad");
      return true;
    }).toList();

    final cantidad_revisadas =
        _tareas.where((t) => t.estado.toLowerCase().contains("revisad")).length;
    final cantidad_entregadas =
        _tareas.where((t) => t.estado.toLowerCase().contains("entregad")).length;
    final cantidad_pendientes =
        _tareas.where((t) => t.estado.toLowerCase().contains("pendiente")).length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Módulo 04 · Escuela de Líderes CETI",
                  style: TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Text(
            "Aula Virtual · Escuela de Líderes",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: BumandColores.NEGRO,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "12 Tareas Formativas Semestrales · Estilo Classroom con evidencia y retroalimentación",
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),

          // Resumen de progreso de las 12 tareas
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        "Progreso de Tareas Semestrales",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "$cantidad_revisadas de 12 revisadas",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _tareas.isEmpty ? 0 : cantidad_revisadas / _tareas.length,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      "• $cantidad_revisadas Revisadas",
                      style: const TextStyle(
                        color: Color(0xFF86EFAC),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "• $cantidad_entregadas Entregadas",
                      style: const TextStyle(
                        color: Color(0xFF93C5FD),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "• $cantidad_pendientes Pendientes",
                      style: const TextStyle(
                        color: Color(0xFFFDE68A),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Chips de filtro
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _construirChipFiltro("Todas", _tareas.length),
                const SizedBox(width: 6),
                _construirChipFiltro("Pendientes", cantidad_pendientes),
                const SizedBox(width: 6),
                _construirChipFiltro("Entregadas", cantidad_entregadas),
                const SizedBox(width: 6),
                _construirChipFiltro("Revisadas", cantidad_revisadas),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Lista de tareas
          Expanded(
            child: ListView.builder(
                    itemCount: tareas_filtradas.length,
                    itemBuilder: (context, index) {
                      final tarea = tareas_filtradas[index];
                      return _construirTarjetaTarea(tarea);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _construirChipFiltro(String etiqueta, int cantidad) {
    final es_activo = _filtro == etiqueta;
    return ChoiceChip(
      selected: es_activo,
      label: Text(
        "$etiqueta ($cantidad)",
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: es_activo ? FontWeight.bold : FontWeight.w500,
          color: es_activo ? Colors.white : const Color(0xFF334155),
        ),
      ),
      selectedColor: const Color(0xFF6366F1),
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: es_activo ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1),
        ),
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _filtro = etiqueta);
        }
      },
    );
  }

  Widget _construirTarjetaTarea(TareaEscuelaLideresModelo tarea) {
    final es_revisado = tarea.estado.toLowerCase().contains("revisad");
    final es_entregado = tarea.estado.toLowerCase().contains("entregad");

    final evidencia_temp = _evidencias_seleccionadas[tarea.numero];
    final esta_entregando = _entregando_por_tarea[tarea.numero] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: es_revisado
              ? const Color(0xFF86EFAC)
              : (es_entregado ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0)),
          width: es_revisado ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: es_revisado
                      ? const Color(0xFF15803D)
                      : (es_entregado ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  tarea.numero.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tarea.tema,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Ponderación individual: ${tarea.ponderacion}%",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (es_revisado)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 12, color: Color(0xFF15803D)),
                      SizedBox(width: 3),
                      Text(
                        "Revisado",
                        style: TextStyle(
                          color: Color(0xFF15803D),
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                )
              else if (es_entregado)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Text(
                    "Entregado",
                    style: TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Text(
                    "Pendiente",
                    style: TextStyle(
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tarea.descripcion,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
          ),
          const SizedBox(height: 10),

          // SELLO DESTACADO "REVISADO"
          if (es_revisado) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Color(0xFF15803D), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "REVISADO · ${tarea.puntaje_obtenido?.toStringAsFixed(0) ?? '95'}/100 pts",
                      style: const TextStyle(
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  if (tarea.fecha_entrega != null)
                    Text(
                      tarea.fecha_entrega!,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF166534)),
                    ),
                ],
              ),
            ),
            if (tarea.retroalimentacion != null) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.feedback_outlined, size: 15, color: Color(0xFF6366F1)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Retroalimentación: ${tarea.retroalimentacion}",
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (tarea.evidencia_nombre != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.attach_file, size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      tarea.evidencia_nombre!,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ] else if (es_entregado) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Evidencia: ${tarea.evidencia_nombre ?? 'informe_evidencia.pdf'} ${tarea.fecha_entrega != null ? '· ${tarea.fecha_entrega}' : ''}",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1E40AF),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _abrirDialogoCalificar(tarea),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text("Calificar como Revisado", style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (evidencia_temp != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, size: 16, color: BumandColores.AZUL_DIACONIA),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "${evidencia_temp['nombre']} (${evidencia_temp['tamano']})",
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() => _evidencias_seleccionadas.remove(tarea.numero));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _seleccionarEvidencia(tarea.numero),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(
                      evidencia_temp == null ? Icons.upload_file : Icons.replay,
                      size: 15,
                      color: const Color(0xFF475569),
                    ),
                    label: Text(
                      evidencia_temp == null ? "Adjuntar evidencia" : "Cambiar",
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: esta_entregando ? null : () => _entregarTarea(tarea.numero),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: esta_entregando
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 14),
                    label: Text(
                      esta_entregando ? "Enviando..." : "Entregar Tarea",
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReceptorSocioeconomicoModal extends StatefulWidget {
  const _ReceptorSocioeconomicoModal();

  @override
  State<_ReceptorSocioeconomicoModal> createState() =>
      _ReceptorSocioeconomicoModalState();
}

class _ReceptorSocioeconomicoModalState
    extends State<_ReceptorSocioeconomicoModal> {
  final _repositorio = EvaluacionesRepositorio();

  List<PreguntaBienestarModelo> _preguntas = PreguntaBienestarModelo.catalogoCanonico();
  final Map<int, String> _respuestas = {};
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _cargarPreguntasActualizadas();
  }

  Future<void> _cargarPreguntasActualizadas() async {
    try {
      final resultado = await _repositorio.obtenerCuestionarioBienestar();
      if (!mounted) return;
      if (resultado.exito && resultado.datos != null && resultado.datos!.isNotEmpty) {
        setState(() {
          _preguntas = resultado.datos!;
        });
      }
    } catch (_) {}
  }

  Future<void> _enviarCuestionarioBienestar() async {
    if (_respuestas.length < _preguntas.length) {
      final faltantes = _preguntas.length - _respuestas.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Aún te faltan $faltantes preguntas por responder."),
          backgroundColor: BumandColores.amarilloRadiante,
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    final respuestas_dto = <String, dynamic>{
      for (final entry in _respuestas.entries)
        "pregunta_${entry.key}": entry.value,
    };

    final resultado = await _repositorio.enviarEvaluacionSocioeconomica(
      becario_id: 1,
      periodo_id: 1,
      respuestas: respuestas_dto,
    );

    if (!mounted) return;
    setState(() => _enviando = false);

    if (resultado.exito) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✓ Cuestionario de Bienestar Universitario enviado exitosamente."),
          backgroundColor: BumandColores.azulMarinoProfundo,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado.error ?? "Error al enviar cuestionario."),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final respondidas_conteo = _respuestas.length;
    final total_preguntas = _preguntas.length;
    final porcentaje_progreso = total_preguntas > 0 ? (respondidas_conteo / total_preguntas) : 0.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  "Módulo 05 · Bienestar Universitario",
                  style: TextStyle(
                    color: BumandColores.AZUL_DIACONIA,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Cuestionario de Bienestar Universitario",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: BumandColores.NEGRO,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Cuestionario oficial de bienestar personal, social y universitario.",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 12),

          // Barra de progreso interactiva (REGLA: NO mostrar notas ni porcentajes al becario)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Respondidas: $respondidas_conteo de $total_preguntas",
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: BumandColores.AZUL_DIACONIA,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: porcentaje_progreso,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(BumandColores.AZUL_DIACONIA),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Listado de las 26 preguntas
          Expanded(
            child: ListView.builder(
              itemCount: _preguntas.length,
              itemBuilder: (context, index) {
                final preg = _preguntas[index];
                final respuesta_seleccionada = _respuestas[preg.numero_orden];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: respuesta_seleccionada != null
                          ? BumandColores.AZUL_DIACONIA.withValues(alpha: 0.5)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: respuesta_seleccionada != null
                                  ? BumandColores.azulMarinoProfundo
                                  : BumandColores.AZUL_DIACONIA,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${preg.numero_orden}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        preg.titulo,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: BumandColores.NEGRO,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        preg.categoria,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  preg.enunciado,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: preg.opciones.map((op) {
                          final es_seleccionada = respuesta_seleccionada == op.inciso;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _respuestas[preg.numero_orden] = op.inciso;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: es_seleccionada
                                      ? BumandColores.AZUL_DIACONIA.withValues(alpha: 0.08)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: es_seleccionada
                                        ? BumandColores.AZUL_DIACONIA
                                        : const Color(0xFFE2E8F0),
                                    width: es_seleccionada ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: es_seleccionada
                                            ? BumandColores.AZUL_DIACONIA
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: es_seleccionada
                                              ? BumandColores.AZUL_DIACONIA
                                              : const Color(0xFFCBD5E1),
                                        ),
                                      ),
                                      child: Text(
                                        op.inciso,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: es_seleccionada ? Colors.white : const Color(0xFF334155),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        op.texto,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: es_seleccionada ? FontWeight.w600 : FontWeight.normal,
                                          color: es_seleccionada
                                              ? BumandColores.AZUL_DIACONIA
                                              : const Color(0xFF334155),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Botón Enviar Ficha Socioeconómica
          SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _enviando ? null : _enviarCuestionarioBienestar,
              style: ElevatedButton.styleFrom(
                backgroundColor: BumandColores.amarilloRadiante,
                  foregroundColor: BumandColores.azulMarinoSecundario,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: BumandColores.NEGRO),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _enviando
                    ? "Enviando..."
                    : "Enviar Cuestionario ($respondidas_conteo/$total_preguntas)",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

