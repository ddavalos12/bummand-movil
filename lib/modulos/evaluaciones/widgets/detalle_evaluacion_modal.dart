import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../nucleo/constantes/api-constantes.dart';
import '../../../nucleo/tema/colores.dart';
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
        return const Color(0xFF10B981);
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

  static void mostrarReceptorSocioeconomico(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ReceptorSocioeconomicoModal(),
    );
  }

  static void mostrarFormularioMentor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FormularioSupervisorEvaluador(),
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
                borderRadius: BorderRadius.circular(12),
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
                borderRadius: BorderRadius.circular(12),
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
                  backgroundColor: BumandColores.NARANJA,
                  foregroundColor: BumandColores.NEGRO,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(12),
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
                  backgroundColor: BumandColores.NARANJA,
                  foregroundColor: BumandColores.NEGRO,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                borderRadius: BorderRadius.circular(12),
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
  final _promedio_ctrl = TextEditingController(text: "81.5");
  String? _archivo_record = "Record_Academico_Semestre_II_2026.pdf";
  String? _archivo_historial = "Historial_Academico_Institucional.pdf";
  bool _enviando = false;

  @override
  void dispose() {
    _promedio_ctrl.dispose();
    super.dispose();
  }

  Future<void> _enviarDocumentos() async {
    if (_archivo_record == null || _archivo_historial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes adjuntar el Récord y el Historial Académico."),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    try {
      final ruta = '${ApiConstantes.RUTA_BASE}/api/evaluaciones/receptor/academica';
      await http
          .post(
            Uri.parse(ruta),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "becario_id": 1,
              "periodo": "Semestre II - 2026",
              "promedio_semestral": double.tryParse(_promedio_ctrl.text) ?? 80.0,
              "record_archivo": _archivo_record,
              "historial_archivo": _archivo_historial,
              "fecha_recepcion": DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}

    if (!mounted) return;
    setState(() => _enviando = false);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✓ Récord e Historial Académico recibidos exitosamente."),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 3),
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
            "Adjunta tus 2 documentos oficiales semestrales. La convalidación y ponderación se efectúa en la plataforma web.",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          _construirSelectorDocumento(
            etiqueta: "1. Récord Académico (Semestre II - 2026)",
            archivo: _archivo_record,
            alPresionar: () {
              setState(() {
                _archivo_record = "Record_Academico_Semestre_II_2026.pdf";
              });
            },
          ),
          const SizedBox(height: 10),
          _construirSelectorDocumento(
            etiqueta: "2. Historial Académico Completo",
            archivo: _archivo_historial,
            alPresionar: () {
              setState(() {
                _archivo_historial = "Historial_Academico_Institucional.pdf";
              });
            },
          ),
          const SizedBox(height: 14),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
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
              onPressed: _enviando ? null : _enviarDocumentos,
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(
                _enviando ? "Enviando recepción..." : "Enviar documentos académicos",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirSelectorDocumento({
    required String etiqueta,
    required String? archivo,
    required VoidCallback alPresionar,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: archivo != null ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            archivo != null ? Icons.check_circle : Icons.upload_file,
            color: archivo != null ? const Color(0xFF10B981) : const Color(0xFF64748B),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiqueta,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  archivo ?? "Ningún archivo seleccionado",
                  style: TextStyle(
                    fontSize: 11,
                    color: archivo != null ? const Color(0xFF047857) : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: alPresionar,
            child: Text(archivo == null ? "Adjuntar" : "Cambiar"),
          ),
        ],
      ),
    );
  }
}

class _ReceptorMentorModal extends StatelessWidget {
  const _ReceptorMentorModal();

  void _abrirVerificacionSupervisor(BuildContext context) {
    showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _DialogoVerificacionSupervisor(),
    ).then((supervisor_verificado) {
      if (supervisor_verificado != null && context.mounted) {
        Navigator.of(context).pop();
        _mostrarFormularioSupervisor(context, supervisor_verificado);
      }
    });
  }

  void _mostrarFormularioSupervisor(
    BuildContext context,
    String supervisor_nombre,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioSupervisorEvaluador(
        supervisor_nombre_inicial: supervisor_nombre,
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
                backgroundColor: BumandColores.NARANJA,
                foregroundColor: BumandColores.NEGRO,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
  const _DialogoVerificacionSupervisor();

  @override
  State<_DialogoVerificacionSupervisor> createState() =>
      _DialogoVerificacionSupervisorState();
}

class _DialogoVerificacionSupervisorState
    extends State<_DialogoVerificacionSupervisor> {
  final _repositorio = EvaluacionesRepositorio();
  final _codigo_ctrl = TextEditingController();
  final _correo_ctrl = TextEditingController(text: "angel.ali@bumand.bo");
  final _contrasena_ctrl = TextEditingController();

  bool _usar_credenciales = false;
  bool _enviando_codigo = true;
  bool _verificando = false;
  String _supervisor_nombre = "Lic. Carlos Mendoza";
  String? _mensaje_error;

  @override
  void initState() {
    super.initState();
    _solicitarCodigoNotificacion();
  }

  @override
  void dispose() {
    _codigo_ctrl.dispose();
    _correo_ctrl.dispose();
    _contrasena_ctrl.dispose();
    super.dispose();
  }

  Future<void> _solicitarCodigoNotificacion() async {
    setState(() {
      _enviando_codigo = true;
      _mensaje_error = null;
    });

    final resultado = await _repositorio.solicitarCodigoTutor(becario_id: 1);
    if (!mounted) return;

    final datos = resultado.datos;
    final nombre =
        datos?['supervisor_nombre']?.toString() ?? "Lic. Carlos Mendoza";

    setState(() {
      _enviando_codigo = false;
      _supervisor_nombre = nombre;
    });
  }

  Future<void> _verificarIdentidad() async {
    setState(() {
      _verificando = true;
      _mensaje_error = null;
    });

    final resultado = await _repositorio.verificarCodigoTutor(
      becario_id: 1,
      codigo: _usar_credenciales ? null : _codigo_ctrl.text.trim(),
      correo: _usar_credenciales ? _correo_ctrl.text.trim() : null,
      contrasena: _usar_credenciales ? _contrasena_ctrl.text : null,
    );

    if (!mounted) return;
    setState(() => _verificando = false);

    if (resultado.exito && resultado.datos?['verificado'] == true) {
      final nombre =
          resultado.datos?['supervisor_nombre']?.toString() ?? _supervisor_nombre;
      Navigator.of(context).pop(nombre);
    } else {
      setState(() {
        _mensaje_error =
            resultado.error ?? "No se pudo verificar la identidad del supervisor.";
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
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Verificación de Identidad del Tutor",
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: BumandColores.NEGRO,
                        ),
                      ),
                      Text(
                        "Seguridad antifraude · Módulo 03",
                        style: TextStyle(
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
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _usar_credenciales = false;
                        _mensaje_error = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !_usar_credenciales
                              ? BumandColores.AZUL_DIACONIA
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          "Código en pantalla",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: !_usar_credenciales
                                ? Colors.white
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _usar_credenciales = true;
                        _mensaje_error = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _usar_credenciales
                              ? BumandColores.AZUL_DIACONIA
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          "Credenciales Tutor",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _usar_credenciales
                                ? Colors.white
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (!_usar_credenciales) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_outlined,
                          size: 17,
                          color: Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _enviando_codigo
                                ? "Enviando notificación al supervisor..."
                                : "Notificación enviada a $_supervisor_nombre",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0369A1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Se ha enviado una notificación con un código de 6 dígitos a la pantalla del Supervisor ($_supervisor_nombre). Pídele a tu supervisor que ingrese el código que aparece en su pantalla o sus credenciales institucionales.",
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF334155),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                "Código de 6 dígitos del Supervisor",
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed:
                      _enviando_codigo ? null : _solicitarCodigoNotificacion,
                  icon: const Icon(Icons.refresh, size: 15),
                  label: const Text(
                    "Reenviar código a pantalla del supervisor",
                    style: TextStyle(fontSize: 11.5),
                  ),
                ),
              ),
            ] else ...[
              const Text(
                "Ingresa las credenciales institucionales del Supervisor/Tutor asignado:",
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _correo_ctrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Correo institucional del supervisor",
                  prefixIcon: const Icon(Icons.email_outlined, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _contrasena_ctrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Contraseña del supervisor",
                  prefixIcon: const Icon(Icons.lock_outline, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

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
                        borderRadius: BorderRadius.circular(12),
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
                        borderRadius: BorderRadius.circular(12),
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
  final String supervisor_nombre_inicial;

  const _FormularioSupervisorEvaluador({
    this.supervisor_nombre_inicial = "Lic. Carlos Mendoza",
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
  final _becario_ctrl = TextEditingController(text: "María Catunta Laime");
  final _agencia_ctrl = TextEditingController(text: "Agencia Central Diaconía");
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
    _calificaciones_1_18 = {
      for (int i = 1; i <= 18; i++) i: 10,
    };
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
      becario_id: 1,
      periodo_id: 1,
      supervisor_nombre: _mentor_ctrl.text.trim(),
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
          backgroundColor: Color(0xFF10B981),
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
                      borderRadius: BorderRadius.circular(12),
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
                        borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
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
          backgroundColor: Colors.amber.shade800,
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
          backgroundColor: Color(0xFF10B981),
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
              borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(12),
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
                                  ? const Color(0xFF10B981)
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
                backgroundColor: BumandColores.NARANJA,
                foregroundColor: BumandColores.NEGRO,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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

