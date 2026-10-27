import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../../../widgets-comunes/cargando-skeleton.dart';
import '../../../widgets-comunes/error-widget-personalizado.dart';
import '../proveedores/evaluaciones-proveedor.dart';
import '../widgets/detalle_evaluacion_modal.dart';
import '../widgets/formulario_f03_dialogo.dart';
import 'evaluacion-socioeconomica-pantalla.dart';

class EvaluacionesPantalla extends ConsumerWidget {
  const EvaluacionesPantalla({super.key});

  static const _FONDO = BumandColores.fondo;
  static const _BORDE = BumandColores.grisClaro;

  Color _obtenerColorModulo(int numero) {
    switch (numero) {
      case 1:
        return const Color(0xFF2563EB);
      case 2:
        return const Color(0xFF0D9488);
      case 3:
        return const Color(0xFFEA580C);
      case 4:
        return const Color(0xFF6366F1);
      case 5:
        return const Color(0xFF059669);
      default:
        return BumandColores.AZUL_DIACONIA;
    }
  }

  void _abrirEvaluacionSocioeconomica(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EvaluacionSocioeconomicaPantalla(),
      ),
    );
  }

  void _abrirModuloReceptor(BuildContext context, int numero) {
    switch (numero) {
      case 1:
        FormularioF03Dialogo.mostrar(context);
        break;
      case 2:
        DetalleEvaluacionModal.mostrarReceptorAcademico(context);
        break;
      case 3:
        DetalleEvaluacionModal.mostrarReceptorMentor(context);
        break;
      case 4:
        DetalleEvaluacionModal.mostrar(
          context,
          numero_modulo: "04",
          titulo: "Evaluación Escuela de Líderes",
          evaluador: "Coordinación de Formación Espiritual",
          estado: "Completado / Recibido",
          comentario:
              "Asistencia verificada en talleres presenciales de viernes y devocionales centrales.",
        );
        break;
      case 5:
        _abrirEvaluacionSocioeconomica(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evaluacion_async = ref.watch(evaluacion_consolidada_proveedor);

    final modulos_receptores = [
      {
        "numero": 1,
        "titulo": "Liderazgo en la Iglesia",
        "subtitulo": "Formación y servicio comunitario · Formulario F-03",
        "estado": "Completado",
        "accion": "Ver formulario",
      },
      {
        "numero": 2,
        "titulo": "Autoevaluación Académica",
        "subtitulo": "Récord Académico + Historial Académico",
        "estado": "Documentos Recibidos",
        "accion": "Subir documentos",
      },
      {
        "numero": 3,
        "titulo": "Evaluación del Mentor",
        "subtitulo": "Pasantías en agencias · Acceso exclusivo por QR",
        "estado": "Pendiente",
        "accion": "Acceso QR",
      },
      {
        "numero": 4,
        "titulo": "Evaluación Escuela de Líderes",
        "subtitulo": "Asistencia y participación en talleres de viernes",
        "estado": "Completado",
        "accion": "Ver asistencia",
      },
      {
        "numero": 5,
        "titulo": "Evaluación Socioeconómica",
        "subtitulo": "Cuestionario de Bienestar Universitario · 26 preguntas",
        "estado": "26 Preguntas",
        "accion": "Abrir cuestionario",
      },
    ];

    return Scaffold(
      backgroundColor: _FONDO,
      appBar: BarraSuperiorBumand(
        titulo: "Evaluación de Desempeño",
        subtitulo: "5 módulos · 1 vez por semestre",
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
          data: (_) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              Icons.calendar_month_outlined,
                              size: 18,
                              color: BumandColores.AZUL_DIACONIA,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Semestre II - 2026",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: BumandColores.NEGRO,
                                ),
                              ),
                              Text(
                                "Periodo activo de recepción",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 14, color: Color(0xFF15803D)),
                            SizedBox(width: 4),
                            Text(
                              "Habilitado",
                              style: TextStyle(
                                color: Color(0xFF15803D),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    "Módulos Formativos Semestrales",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: BumandColores.AZUL_DIACONIA,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                for (final item in modulos_receptores)
                  _construirTarjetaModulo(
                    context: context,
                    numero: item["numero"] as int,
                    titulo: item["titulo"] as String,
                    subtitulo: item["subtitulo"] as String,
                    estado: item["estado"] as String,
                    accion: item["accion"] as String,
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Los 5 módulos están habilitados para recepción semestral."),
                        backgroundColor: BumandColores.AZUL_DIACONIA,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: const Text(
                    "Ver todos los módulos",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: BumandColores.AZUL_DIACONIA,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
          loading: () => CargandoSkeleton.lista(cantidad: 5, alto_item: 100),
          error: (error, _) => ErrorWidgetPersonalizado(
            mensaje: "Error al cargar evaluaciones",
            detalles: [error.toString()],
            alReintentar: () => ref.invalidate(evaluacion_consolidada_proveedor),
          ),
        ),
      ),
    );
  }

  Widget _construirTarjetaModulo({
    required BuildContext context,
    required int numero,
    required String titulo,
    required String subtitulo,
    required String estado,
    required String accion,
  }) {
    final color_icono = _obtenerColorModulo(numero);
    final es_completado =
        estado.toLowerCase().contains("complet") || estado.toLowerCase().contains("recib");

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _abrirModuloReceptor(context, numero),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color_icono,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color_icono.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "$numero",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: BumandColores.NEGRO,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitulo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: es_completado
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: es_completado
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Text(
                        estado,
                        style: TextStyle(
                          color: es_completado
                              ? const Color(0xFF047857)
                              : const Color(0xFFB45309),
                          fontWeight: FontWeight.bold,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Módulo receptor 0$numero",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          accion,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color_icono,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: color_icono,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
