import 'package:flutter/material.dart';

import '../../../nucleo/tema/colores.dart';
import 'formulario_f03_dialogo.dart';

/// Visor modal / Bottom Sheet de detalle de evaluación semestral
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
    required this.puntaje,
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
    required double puntaje,
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

  Color _obtenerColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case "completada":
      case "completado":
      case "aprobado":
        return const Color(0xFF10B981);
      case "pendiente":
        return const Color(0xFFF59E0B);
      case "incompleto":
      case "observada":
      case "observado":
        return const Color(0xFFEF4444);
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color_estado = _obtenerColorEstado(estado);
    final es_f03 = titulo.toLowerCase().contains("f-03") ||
        titulo.toLowerCase().contains("pastor") ||
        numero_modulo == "01";

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
          // Tirador superior del Bottom Sheet
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

          // Tarjeta de puntaje y estado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${puntaje.toStringAsFixed(0)} / ${puntaje_maximo.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: BumandColores.NEGRO,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color_estado.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        estado.toUpperCase(),
                        style: TextStyle(
                          color: color_estado,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (puntaje / puntaje_maximo).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(color_estado),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Archivo adjunto si existe
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

          // Comentarios / observaciones
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
                    "Observaciones del Evaluador:",
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

          // Si es el módulo F-03 o eclesiástico, botón para abrir Formulario F-03
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.church),
                label: const Text(
                  "Abrir Formulario F-03 del Pastor",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Si es el módulo 02 (Autoevaluación Académica), botón para subir/actualizar récord
          if (numero_modulo == "02" || titulo.toLowerCase().contains("académ") || titulo.toLowerCase().contains("academ")) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF063A6B),
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF10B981)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Récord académico adjuntado exitosamente. Remitido para convalidación por puntos en el panel web.",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BumandColores.AZUL_DIACONIA,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.upload_file),
                label: const Text(
                  "Subir / Actualizar Récord Académico (PDF)",
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
            child: const Text("Cerrar visor"),
          ),
        ],
      ),
    );
  }
}
