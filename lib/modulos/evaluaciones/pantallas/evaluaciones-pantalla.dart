import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../../../widgets-comunes/cargando-skeleton.dart';
import '../../../widgets-comunes/error-widget-personalizado.dart';
import '../modelos/evaluacion-modelo.dart';
import '../proveedores/evaluaciones-proveedor.dart';
import '../widgets/formulario_f03_dialogo.dart';
import '../widgets/detalle_evaluacion_modal.dart';

class EvaluacionesPantalla extends ConsumerWidget {
  const EvaluacionesPantalla({super.key});

  static const _FONDO = Color(0xFFEFF3F8);
  static const _BORDE = Color(0xFFE2E8F0);

  Color _obtenerColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case "completada":
        return const Color(0xFF10B981);
      case "pendiente":
        return const Color(0xFFF59E0B);
      case "observada":
        return const Color(0xFFEF4444);
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evaluacion_async = ref.watch(evaluacion_consolidada_proveedor);

    return Scaffold(
      backgroundColor: _FONDO,
      appBar: BarraSuperiorBumand(
        titulo: "Mis Evaluaciones",
        subtitulo: "Desempeño Integral 360°",
        acciones_adicionales: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Actualizar",
            onPressed: () => ref.invalidate(evaluacion_consolidada_proveedor),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: BumandColores.NARANJA_OSCURO,
        backgroundColor: BumandColores.AZUL_DIACONIA,
        onRefresh: () async => ref.invalidate(evaluacion_consolidada_proveedor),
        child: evaluacion_async.when(
          data: (resultado) {
            if (!resultado.exito || resultado.datos == null) {
              return Center(
                child: Text(resultado.error ?? "No se pudieron cargar las evaluaciones"),
              );
            }
            final EvaluacionConsolidadaModelo datos = resultado.datos!;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Tarjeta Principal de Calificación Ponderada 360°
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        BumandColores.AZUL_DIACONIA,
                        Color(0xFF0F4C81),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                datos.periodo_nombre,
                                style: const TextStyle(
                                  color: Color(0xFFBEE3F8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Calificación Global",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: BumandColores.NARANJA,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${datos.total_vigesimal.toStringAsFixed(1)} / 20 pts",
                              style: const TextStyle(
                                color: BumandColores.NEGRO,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          // Indicador Circular de Progreso
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: (datos.total_vigesimal / 20).clamp(0.0, 1.0),
                                  strokeWidth: 8,
                                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    BumandColores.TURQUESA_DIACONIA,
                                  ),
                                ),
                                Text(
                                  datos.total_vigesimal.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Evaluación integral basada en los 5 pilares formativos institucionales.",
                                  style: TextStyle(
                                    color: Color(0xFFE2E8F0),
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "${datos.modulos_evaluados} de ${datos.total_modulos} módulos calificados",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Acceso al Formulario F-03 del Pastor
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: BumandColores.NARANJA.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.church_outlined,
                          color: Color(0xFFB45309),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Formulario F-03 del Pastor",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: BumandColores.NEGRO,
                              ),
                            ),
                            Text(
                              "Evaluación del aporte a la iglesia local",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => FormularioF03Dialogo.mostrar(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BumandColores.NARANJA,
                          foregroundColor: BumandColores.NEGRO,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Abrir F-03",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    "Desglose por Módulos Canónicos",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: BumandColores.AZUL_DIACONIA,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Lista de Módulos Formativos
                for (final mod in datos.desglose_modulos)
                  GestureDetector(
                    onTap: () {
                      DetalleEvaluacionModal.mostrar(
                        context,
                        numero_modulo: (datos.desglose_modulos.indexOf(mod) + 1)
                            .toString()
                            .padLeft(2, '0'),
                        titulo: mod.nombre,
                        evaluador: "Evaluador: ${mod.evaluador_rol}",
                        puntaje: mod.puntaje,
                        puntaje_maximo: 100.0,
                        estado: mod.estado,
                        archivo_nombre: "${mod.nombre.replaceAll(' ', '_')}.pdf",
                        fecha_archivo: "Periodo activo 2026",
                        comentario: mod.observaciones ??
                            "Cumplimiento adecuado de las actividades encomendadas durante el periodo.",
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _BORDE),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mod.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: BumandColores.NEGRO,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Evaluador: ${mod.evaluador_rol}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Barra de puntaje
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: (mod.puntaje / 100).clamp(0.0, 1.0),
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _obtenerColorEstado(mod.estado),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "${mod.puntaje.toStringAsFixed(0)} / 100",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _obtenerColorEstado(mod.estado).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            mod.estado.toUpperCase(),
                            style: TextStyle(
                              color: _obtenerColorEstado(mod.estado),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),

                        if (mod.observaciones != null && mod.observaciones!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              "\"${mod.observaciones}\"",
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => CargandoSkeleton.lista(cantidad: 4, alto_item: 120),
          error: (error, _) => ErrorWidgetPersonalizado(
            mensaje: "Error al cargar evaluaciones",
            detalles: [error.toString()],
            alReintentar: () => ref.invalidate(evaluacion_consolidada_proveedor),
          ),
        ),
      ),
    );
  }
}
