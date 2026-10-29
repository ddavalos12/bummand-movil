import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../servicios/justificaciones-servicio.dart';
import 'solicitar-justificacion-dialogo.dart';

class PermisosPantalla extends ConsumerStatefulWidget {
  const PermisosPantalla({super.key});

  @override
  ConsumerState<PermisosPantalla> createState() => _PermisosPantallaState();
}

class _PermisosPantallaState extends ConsumerState<PermisosPantalla> {
  String _filtro_estado = 'todos';

  @override
  Widget build(BuildContext context) {
    final solicitudes_async = ref.watch(mis_justificaciones_proveedor);

    return Scaffold(
      backgroundColor: BumandColores.FONDO,
      appBar: BarraSuperiorBumand(
        titulo: "Permisos y Justificaciones",
        subtitulo: "Flujo de aprobación y solicitudes anticipadas",
        acciones_adicionales: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Actualizar",
            onPressed: () => ref.invalidate(mis_justificaciones_proveedor),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: BumandColores.AZUL_DIACONIA,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "Solicitar Permiso",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          final enviado = await SolicitarJustificacionDialogo.mostrar(context);
          if (enviado == true) {
            ref.invalidate(mis_justificaciones_proveedor);
          }
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(mis_justificaciones_proveedor),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
          children: [
            // 1. Tarjeta informativa del flujo institucional de 2 niveles
            _construirTarjetaInformativa(),
            const SizedBox(height: 12),

            // 2. Filtros de estado rápido
            _construirFiltros(),
            const SizedBox(height: 12),

            // 3. Listado de solicitudes
            solicitudes_async.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  "Error al cargar solicitudes: $err",
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
              data: (resultado) {
                final solicitudes = resultado.datos ?? [];
                final filtradas = _filtrarSolicitudes(solicitudes);

                if (filtradas.isEmpty) {
                  return _construirEstadoVacio();
                }

                return Column(
                  children: filtradas
                      .map((s) => _construirTarjetaSolicitud(s))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTarjetaInformativa() {
    return Container(
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
              Icons.rule_folder_rounded,
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
                  "Flujo de Aprobación en 2 Niveles",
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: BumandColores.NEGRO,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "1° Paso: Revisión del Supervisor asignado.\n"
                  "2° Paso: Aprobación definitiva por Administración.\n"
                  "Los permisos de viernes aprobados cuentan con exención total de multa.",
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
    );
  }

  Widget _construirFiltros() {
    final opciones = [
      ('todos', 'Todos'),
      ('pendiente', '1. Pendientes'),
      ('revisado_supervisor', '2. Revisados'),
      ('aprobado_administracion', 'Aprobados'),
      ('viernes', 'Viernes (Sin Multa)'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: opciones.map((op) {
          final seleccionado = _filtro_estado == op.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(op.$2),
              selected: seleccionado,
              selectedColor: BumandColores.AZUL_DIACONIA,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: seleccionado ? Colors.white : const Color(0xFF334155),
                fontSize: 12,
                fontWeight: seleccionado ? FontWeight.bold : FontWeight.w500,
              ),
              side: BorderSide(
                color: seleccionado
                    ? BumandColores.AZUL_DIACONIA
                    : const Color(0xFFCBD5E1),
              ),
              onSelected: (val) {
                if (val) setState(() => _filtro_estado = op.$1);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Map<String, dynamic>> _filtrarSolicitudes(
      List<Map<String, dynamic>> lista) {
    if (_filtro_estado == 'todos') return lista;
    if (_filtro_estado == 'viernes') {
      return lista.where((s) {
        final tipo = s['tipo_incidencia']?.toString().toLowerCase() ?? '';
        final es_viernes = tipo.contains('lider') ||
            tipo.contains('evento') ||
            (s['fecha_incidencia']?.toString().contains('vie') ?? false);
        final aprobado = s['estado'] == 'aprobado_administracion' ||
            s['estado'] == 'aprobada';
        return es_viernes && aprobado;
      }).toList();
    }
    return lista.where((s) => s['estado'] == _filtro_estado).toList();
  }

  Widget _construirTarjetaSolicitud(Map<String, dynamic> s) {
    final estado = s['estado']?.toString() ?? 'pendiente';
    final tipo = s['tipo_incidencia']?.toString() ?? 'otro';
    final fecha = s['fecha_incidencia']?.toString() ?? '';
    final motivo = s['motivo']?.toString() ?? 'Sin motivo';
    final descripcion = s['descripcion']?.toString() ?? '';
    final archivo = s['nombre_archivo_prueba']?.toString();
    final obs_sup = s['observacion_supervisor']?.toString();
    final obs_adm = s['observacion_admin']?.toString();

    final es_actividad_viernes = tipo == 'escuela_lideres' ||
        tipo == 'asistencia_evento' ||
        fecha.toLowerCase().contains('vie');
    final permiso_aprobado =
        estado == 'aprobado_administracion' || estado == 'aprobada';

    String tipo_legible = 'Actividad';
    Color color_tipo = BumandColores.AZUL_DIACONIA;
    if (tipo == 'escuela_lideres') {
      tipo_legible = 'Escuela de Líderes (Viernes)';
      color_tipo = const Color(0xFF7C3AED);
    } else if (tipo == 'asistencia_evento') {
      tipo_legible = 'Acción de Servicio (Viernes)';
      color_tipo = BumandColores.azulPetroleo;
    } else if (tipo == 'asistencia_practicas') {
      tipo_legible = 'Prácticas Institucionales';
      color_tipo = BumandColores.azulMarinoSecundario;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera: Tipo de actividad y fecha
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color_tipo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color_tipo.withValues(alpha: 0.3)),
                ),
                child: Text(
                  tipo_legible,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color_tipo,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    fecha,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Motivo y descripción
          Text(
            motivo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: BumandColores.NEGRO,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            descripcion,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF334155),
              height: 1.35,
            ),
          ),

          // Comprobante adjunto
          if (archivo != null && archivo.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.attach_file_rounded,
                    size: 15,
                    color: BumandColores.AZUL_DIACONIA,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      archivo,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: BumandColores.AZUL_DIACONIA,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Línea de progreso de los 2 pasos
          _construirLineaProgresoDosPasos(estado),
          const SizedBox(height: 10),

          // Badge oficial "Sin Multa (Permiso Aprobado)" para viernes
          if (es_actividad_viernes && permiso_aprobado) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF047857),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Sin Multa (Permiso Aprobado) — Bs 0.00",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Observaciones de supervisor y administración
          if (obs_sup != null && obs_sup.isNotEmpty) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.rate_review_outlined,
                    size: 16,
                    color: BumandColores.AZUL_DIACONIA,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Supervisor: $obs_sup",
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (obs_adm != null && obs_adm.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 16,
                    color: Color(0xFF15803D),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Administración: $obs_adm",
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF14532D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirLineaProgresoDosPasos(String estado) {
    final paso1_completado = estado == 'revisado_supervisor' ||
        estado == 'aprobado_administracion' ||
        estado == 'aprobada';
    final paso2_completado =
        estado == 'aprobado_administracion' || estado == 'aprobada';
    final es_rechazado = estado == 'rechazado' || estado == 'rechazada';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Paso 1: Supervisor
              Icon(
                paso1_completado
                    ? Icons.check_circle_rounded
                    : (es_rechazado
                        ? Icons.cancel_rounded
                        : Icons.hourglass_top_rounded),
                size: 18,
                color: paso1_completado
                    ? const Color(0xFF10B981)
                    : (es_rechazado
                        ? Colors.red
                        : BumandColores.amarilloRadiante),
              ),
              const SizedBox(width: 6),
              const Text(
                "Paso 1: Supervisor",
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_rounded,
                  size: 14, color: Color(0xFF94A3B8)),
              const Spacer(),
              // Paso 2: Administración
              Icon(
                paso2_completado
                    ? Icons.check_circle_rounded
                    : (es_rechazado
                        ? Icons.cancel_rounded
                        : (paso1_completado
                            ? Icons.hourglass_top_rounded
                            : Icons.radio_button_unchecked)),
                size: 18,
                color: paso2_completado
                    ? const Color(0xFF10B981)
                    : (es_rechazado
                        ? Colors.red
                        : (paso1_completado
                            ? BumandColores.AZUL_DIACONIA
                            : const Color(0xFFCBD5E1))),
              ),
              const SizedBox(width: 6),
              const Text(
                "Paso 2: Administración",
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _etiquetaEstadoDosPasos(estado),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _colorEstadoDosPasos(estado),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _etiquetaEstadoDosPasos(String estado) {
    switch (estado) {
      case 'pendiente':
        return '● Paso 1 en curso: Pendiente de revisión del Supervisor';
      case 'revisado_supervisor':
        return '✓ Paso 1 completado: Revisado por Supervisor → Esperando aprobación de Administración';
      case 'aprobado_administracion':
      case 'aprobada':
        return '✓ Paso 2 completado: Aprobado por Administración institucional';
      case 'rechazado':
      case 'rechazada':
        return '✕ Solicitud rechazada / con observaciones';
      default:
        return estado;
    }
  }

  Color _colorEstadoDosPasos(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFFD97706);
      case 'revisado_supervisor':
        return BumandColores.AZUL_DIACONIA;
      case 'aprobado_administracion':
      case 'aprobada':
        return const Color(0xFF047857);
      case 'rechazado':
      case 'rechazada':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  Widget _construirEstadoVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_turned_in_outlined,
                size: 48,
                color: BumandColores.AZUL_DIACONIA,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "No hay solicitudes en esta sección",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BumandColores.NEGRO,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Puedes solicitar un permiso anticipado para prácticas o jornadas de viernes cuando lo requieras.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
