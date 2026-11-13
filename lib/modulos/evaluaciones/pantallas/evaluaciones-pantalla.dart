import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../../../widgets-comunes/cargando-skeleton.dart';
import '../../../widgets-comunes/error-widget-personalizado.dart';
import '../../autenticacion/proveedores/autenticacion-proveedor.dart';
import '../modelos/evaluacion-modelo.dart';
import '../proveedores/evaluaciones-proveedor.dart';
import '../widgets/botones-accion-evaluacion.dart';
import '../widgets/detalle_evaluacion_modal.dart';
import '../widgets/formulario_f03_dialogo.dart';
import 'evaluacion-socioeconomica-pantalla.dart';

class EvaluacionesPantalla extends ConsumerStatefulWidget {
  const EvaluacionesPantalla({super.key});

  @override
  ConsumerState<EvaluacionesPantalla> createState() =>
      _EvaluacionesPantallaState();
}

class _EvaluacionesPantallaState extends ConsumerState<EvaluacionesPantalla> {
  static const _FONDO = BumandColores.fondo;
  static const _BORDE = BumandColores.grisClaro;

  int _pestana_supervisor = 0; // 0: Becarios Asignados, 1: Mis Módulos

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
    final auth = ref.read(autenticacion_proveedor);
    final rol_usuario = auth.usuario?.rol.toLowerCase() ?? 'becario';
    final es_supervisor_o_admin =
        rol_usuario.contains('supervisor') || rol_usuario.contains('admin');

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
        DetalleEvaluacionModal.mostrarReceptorLideresClassroom(
          context,
          es_becario: !es_supervisor_o_admin,
        );
        break;
      case 5:
        _abrirEvaluacionSocioeconomica(context);
        break;
    }
  }

  void _iniciarEvaluacionSupervisor(
    BuildContext context,
    BecarioAsignadoModulo3Modelo becario,
  ) {
    final auth = ref.read(autenticacion_proveedor);

    DetalleEvaluacionModal.verificarIdentidadSupervisor(
      context,
      becario_id: becario.becario_id,
      becario_nombre: becario.nombre,
    ).then((resultado) {
      if (resultado != null && context.mounted) {
        final String supervisor_nombre =
            resultado['supervisor_nombre']?.toString() ??
                auth.usuario?.nombre ??
                "Lic. Carlos Mendoza";
        final String? codigo_verificacion =
            resultado['codigo_verificacion']?.toString();

        DetalleEvaluacionModal.mostrarFormularioMentor(
          context,
          becario_id: becario.becario_id,
          becario_nombre: becario.nombre,
          supervisor_nombre_inicial: supervisor_nombre,
          modalidad_llenado: "perfil_supervisor",
          codigo_verificacion: codigo_verificacion,
          evaluacion_previa: becario.evaluacion_previa,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(autenticacion_proveedor);
    final rol_usuario = auth.usuario?.rol.toLowerCase() ?? 'becario';
    final es_supervisor_o_admin =
        rol_usuario.contains('supervisor') || rol_usuario.contains('admin');

    final subtitulo_app_bar = es_supervisor_o_admin && _pestana_supervisor == 0
        ? "Supervisión Módulo 3 · Prácticas y Mentoría"
        : "5 módulos · 1 vez por semestre";

    return Scaffold(
      backgroundColor: _FONDO,
      appBar: BarraSuperiorBumand(
        titulo: "Evaluación de Desempeño",
        subtitulo: subtitulo_app_bar,
        acciones_adicionales: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Actualizar",
            onPressed: () {
              ref.invalidate(evaluacion_consolidada_proveedor);
              ref.invalidate(becarios_asignados_modulo3_proveedor);
            },
          ),
        ],
      ),
      body: es_supervisor_o_admin
          ? _construirContenidoSupervisor(context)
          : _construirContenidoEstudiante(context),
    );
  }

  Widget _construirContenidoSupervisor(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  selected: _pestana_supervisor == 0,
                  label: const Text(
                    "Mis Becarios Asignados (Módulo 3)",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  selectedColor: BumandColores.AZUL_DIACONIA,
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _pestana_supervisor = 0);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  selected: _pestana_supervisor == 1,
                  label: const Text(
                    "Módulos Formativos",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  selectedColor: BumandColores.AZUL_DIACONIA,
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _pestana_supervisor = 1);
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _pestana_supervisor == 0
              ? _construirVistaListaSupervisor(context)
              : _construirContenidoEstudiante(context),
        ),
      ],
    );
  }

  Widget _construirVistaListaSupervisor(BuildContext context) {
    final becarios_async = ref.watch(becarios_asignados_modulo3_proveedor);

    return RefreshIndicator(
      color: BumandColores.NARANJA_OSCURO,
      backgroundColor: BumandColores.AZUL_DIACONIA,
      onRefresh: () async => ref.invalidate(becarios_asignados_modulo3_proveedor),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
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
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.supervised_user_circle_rounded,
                    color: BumandColores.AZUL_DIACONIA,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Mis Becarios Asignados (Módulo 3)",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: BumandColores.NEGRO,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "Evaluación del Mentor / Prácticas preprofesionales en agencia",
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "Becarios asignados para evaluación y seguimiento:",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: BumandColores.AZUL_DIACONIA,
            ),
          ),
          const SizedBox(height: 8),
          becarios_async.when(
            data: (resultado) {
              final lista =
                  resultado.datos ?? BecarioAsignadoModulo3Modelo.listaEjemplo();
              if (lista.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      "No tienes becarios asignados en este periodo.",
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                  ),
                );
              }
              return Column(
                children: lista
                    .map((becario) => _construirTarjetaBecarioSupervisor(context, becario))
                    .toList(),
              );
            },
            loading: () => CargandoSkeleton.lista(cantidad: 3, alto_item: 120),
            error: (err, _) => ErrorWidgetPersonalizado(
              mensaje: "Error al cargar becarios asignados",
              detalles: [err.toString()],
              alReintentar: () =>
                  ref.invalidate(becarios_asignados_modulo3_proveedor),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _construirTarjetaBecarioSupervisor(
    BuildContext context,
    BecarioAsignadoModulo3Modelo becario,
  ) {
    final estado_lower = becario.estado_evaluacion.toLowerCase();
    final es_aprobado = estado_lower.contains("aprob");
    final es_completada =
        es_aprobado ||
        estado_lower.contains("complet") ||
        estado_lower.contains("evaluad");
    final es_observado = estado_lower.contains("observ");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: es_completada ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.12),
                child: Text(
                  becario.nombre.isNotEmpty ? becario.nombre[0].toUpperCase() : 'B',
                  style: const TextStyle(
                    color: BumandColores.AZUL_DIACONIA,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      becario.nombre,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: BumandColores.NEGRO,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${becario.carrera} · ${becario.agencia}",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: es_completada
                      ? const Color(0xFFDCFCE7)
                      : es_observado
                      ? const Color(0xFFFFF1F2)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: es_completada
                        ? const Color(0xFF86EFAC)
                        : es_observado
                        ? const Color(0xFFFDA4AF)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      es_completada
                          ? Icons.check_circle
                          : es_observado
                          ? Icons.warning_amber_rounded
                          : Icons.hourglass_top,
                      size: 12,
                      color: es_completada
                          ? const Color(0xFF15803D)
                          : es_observado
                          ? const Color(0xFFE11D48)
                          : const Color(0xFFB45309),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      es_aprobado
                          ? "Aprobado (${becario.puntaje_actual?.toStringAsFixed(0) ?? '94'})"
                          : es_completada
                          ? "Evaluado (${becario.puntaje_actual?.toStringAsFixed(0) ?? '94'})"
                          : es_observado
                          ? "Observado"
                          : "Pendiente",
                      style: TextStyle(
                        color: es_completada
                            ? const Color(0xFF15803D)
                            : es_observado
                            ? const Color(0xFF9F1239)
                            : const Color(0xFFB45309),
                        fontWeight: FontWeight.bold,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
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
              Expanded(
                child: Text(
                  es_aprobado
                      ? "Evaluación convalidada en sistema"
                      : es_completada
                      ? "Evaluación disponible para edición"
                      : "Requiere validación OTP",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BotonesAccionEvaluacion(
                estado: es_completada
                    ? EstadoAccionEvaluacion.completado
                    : es_observado
                    ? EstadoAccionEvaluacion.observado
                    : EstadoAccionEvaluacion.pendiente,
                texto_revisar: "Revisar",
                al_revisar: () => _iniciarEvaluacionSupervisor(context, becario),
                texto_pendiente: "Evaluar",
                icono_pendiente: Icons.person_outline,
                al_ejecutar_pendiente: () =>
                    _iniciarEvaluacionSupervisor(context, becario),
                texto_completado: es_aprobado ? "Aprobado" : "Evaluado",
                al_hacer_clic_completado: () =>
                    _iniciarEvaluacionSupervisor(context, becario),
                al_hacer_clic_observado: () =>
                    _iniciarEvaluacionSupervisor(context, becario),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirContenidoEstudiante(BuildContext context) {
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
        "accion": "Ver tareas",
      },
      {
        "numero": 5,
        "titulo": "Evaluación Socioeconómica",
        "subtitulo": "Cuestionario de Bienestar Universitario · 26 preguntas",
        "estado": "26 Preguntas",
        "accion": "Abrir cuestionario",
      },
    ];

    return RefreshIndicator(
      color: BumandColores.NARANJA_OSCURO,
      backgroundColor: BumandColores.AZUL_DIACONIA,
      onRefresh: () async => ref.invalidate(evaluacion_consolidada_proveedor),
      child: evaluacion_async.when(
        data: (resultado) {
          final desglose = resultado.datos?.desglose_modulos ?? const [];
          String estadoModuloReal(int numero, String respaldo) {
            for (final mod in desglose) {
              if (mod.modulo_id == numero && mod.estado.trim().isNotEmpty) {
                final e = mod.estado.toLowerCase();
                if (e.contains("aprob")) return "Aprobado";
                if (e.contains("complet") || e.contains("evaluad")) {
                  return "Completado";
                }
                if (e.contains("revis")) return "Revisado";
                if (e.contains("recib")) return "Documentos Recibidos";
                if (e.contains("enviad")) return "Enviado";
                if (e.contains("observ")) return "Observado";
                return "Pendiente";
              }
            }
            return respaldo;
          }
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
                  estado: estadoModuloReal(
                    item["numero"] as int,
                    item["estado"] as String,
                  ),
                  accion: item["accion"] as String,
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Los 5 módulos están habilitados para recepción semestral.",
                      ),
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
    final estado_lower = estado.toLowerCase();
    final es_completado =
        estado_lower.contains("complet") ||
        estado_lower.contains("recib") ||
        estado_lower.contains("aprob") ||
        estado_lower.contains("revis") ||
        estado_lower.contains("enviad");
    final es_observado = estado_lower.contains("observ");

    final texto_accion_pendiente = numero == 2
        ? "Subir"
        : numero == 3
        ? "Evaluar QR"
        : numero == 4
        ? "Entregar"
        : "Completar";

    final texto_estado_completado = estado_lower.contains("aprob")
        ? "Aprobado"
        : estado_lower.contains("revis")
        ? "Revisado"
        : estado_lower.contains("recib") || estado_lower.contains("enviad")
        ? "Enviado"
        : "Completado";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: es_completado ? const Color(0xFF86EFAC) : _BORDE,
        ),
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
                            : es_observado
                            ? const Color(0xFFFFF1F2)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: es_completado
                              ? const Color(0xFF86EFAC)
                              : es_observado
                              ? const Color(0xFFFDA4AF)
                              : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Text(
                        estado,
                        style: TextStyle(
                          color: es_completado
                              ? const Color(0xFF047857)
                              : es_observado
                              ? const Color(0xFF9F1239)
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
                      "Módulo 0$numero",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: BotonesAccionEvaluacion(
                        estado: es_completado
                            ? EstadoAccionEvaluacion.completado
                            : es_observado
                            ? EstadoAccionEvaluacion.observado
                            : EstadoAccionEvaluacion.pendiente,
                        texto_revisar: "Revisar",
                        al_revisar: () => _abrirModuloReceptor(context, numero),
                        texto_pendiente: texto_accion_pendiente,
                        icono_pendiente: numero == 3
                            ? Icons.qr_code_rounded
                            : Icons.verified_user_outlined,
                        al_ejecutar_pendiente: () =>
                            _abrirModuloReceptor(context, numero),
                        texto_completado: texto_estado_completado,
                        al_hacer_clic_completado: () =>
                            _abrirModuloReceptor(context, numero),
                        al_hacer_clic_observado: () =>
                            _abrirModuloReceptor(context, numero),
                      ),
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
