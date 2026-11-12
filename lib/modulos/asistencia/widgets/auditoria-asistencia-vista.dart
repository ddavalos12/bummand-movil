import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/cargando-skeleton.dart';
import '../../../widgets-comunes/error-widget-personalizado.dart';
import '../../autenticacion/proveedores/autenticacion-proveedor.dart';
import '../../justificaciones/pantallas/solicitar-justificacion-dialogo.dart';
import '../modelos/registro-auditoria-asistencia-modelo.dart';
import '../proveedores/asistencia-proveedor.dart';
import 'detalle_asistencia_modal.dart';

const Color _AZUL_INSTITUCIONAL = Color(0xFF004E7C);

/// Rol normalizado del usuario en sesión.
enum RolAuditoria { administrador, supervisor, becario }

RolAuditoria resolverRolAuditoria(String? rol_crudo) {
  final rol = (rol_crudo ?? 'becario').toString().toLowerCase().trim();
  if (rol == 'admin' || rol == 'administrador') return RolAuditoria.administrador;
  if (rol == 'supervisor') return RolAuditoria.supervisor;
  return RolAuditoria.becario;
}

/// Mapea el tipo de actividad de asistencia al tipo de incidencia de justificación.
String tipoIncidenciaDesdeActividad(String tipo) {
  switch (tipo) {
    case 'escuela_lideres':
      return 'escuela_lideres';
    case 'acciones_servicio':
      return 'asistencia_evento';
    default:
      return 'asistencia_practicas';
  }
}

/// Abre el modal de detalle georreferenciado para un registro de auditoría.
void abrirDetalleRegistroAuditoria(
  BuildContext context,
  WidgetRef ref,
  RegistroAuditoriaAsistencia registro,
  RolAuditoria rol,
) {
  DetalleAsistenciaModal.mostrar(
    context,
    titulo: registro.becario_nombre,
    subtitulo: '${registro.carrera} · ${registro.fecha}',
    tipo_registro: _etiquetaTipo(registro.tipo),
    lugar: registro.sede_nombre,
    ingreso: registro.hora_ingreso,
    salida: registro.hora_salida ?? '--:--',
    horas_trabajadas: registro.horas_texto,
    distancia: registro.distancia_ingreso_m == null
        ? '--'
        : '${registro.distancia_ingreso_m!.round()} m',
    dentro_geocerca: registro.dentro_de_radio,
    becario_nombre: registro.becario_nombre,
    carrera: registro.carrera,
    latitud: registro.lat_ingreso,
    longitud: registro.lng_ingreso,
    minutos_retraso: registro.minutos_retraso,
    monto_multa_bs: registro.multa_vigente_bs,
    confirmacion_presencial: registro.confirmacion_presencial,
    estado_aprobacion_texto: registro.esta_aprobado_administracion
        ? 'Aprobado por Administración (Exento de multa)'
        : (registro.esta_revisado_supervisor
            ? 'Revisado por Supervisor'
            : 'Pendiente'),
    al_justificar: registro.requiere_convalidacion
        ? () => justificarRegistroAuditoria(context, ref, registro)
        : null,
    al_aprobar_administracion:
        rol == RolAuditoria.administrador && registro.requiere_convalidacion
            ? () => aprobarRegistroAuditoria(context, ref, registro)
            : null,
  );
}

String _etiquetaTipo(String tipo) {
  switch (tipo) {
    case 'escuela_lideres':
      return 'Escuela de Líderes';
    case 'acciones_servicio':
      return 'Acciones de Servicio';
    default:
      return 'Prácticas Preprofesionales';
  }
}

/// Aprueba por Administración y muestra un SnackBar de resultado.
Future<void> aprobarRegistroAuditoria(
  BuildContext context,
  WidgetRef ref,
  RegistroAuditoriaAsistencia registro,
) async {
  final mensajero = ScaffoldMessenger.of(context);
  final nombre_admin = ref.read(autenticacion_proveedor).usuario?.nombre;
  final error = await ref
      .read(auditoria_asistencia_proveedor.notifier)
      .aprobarAdministracion(registro, nombre_administrador: nombre_admin);
  mensajero.showSnackBar(
    SnackBar(
      backgroundColor:
          error == null ? const Color(0xFF10B981) : const Color(0xFFDC2626),
      content: Text(
        error ??
            'Asistencia aprobada por Administración: se convalidó la jornada de ${registro.becario_nombre} (sin multa).',
      ),
    ),
  );
}

/// Marca como revisado por Supervisor y muestra un SnackBar de resultado.
Future<void> revisarRegistroSupervisor(
  BuildContext context,
  WidgetRef ref,
  RegistroAuditoriaAsistencia registro,
) async {
  final mensajero = ScaffoldMessenger.of(context);
  final error = await ref
      .read(auditoria_asistencia_proveedor.notifier)
      .revisarSupervisor(registro);
  mensajero.showSnackBar(
    SnackBar(
      backgroundColor:
          error == null ? const Color(0xFF10B981) : const Color(0xFFDC2626),
      content: Text(
        error ??
            'Marcación revisada por Supervisor: se elevó a Administración la jornada de ${registro.becario_nombre}.',
      ),
    ),
  );
}

/// Abre el diálogo de justificación pre-cargado con los datos del registro.
Future<void> justificarRegistroAuditoria(
  BuildContext context,
  WidgetRef ref,
  RegistroAuditoriaAsistencia registro,
) async {
  final radicada = await SolicitarJustificacionDialogo.mostrar(
    context,
    becario_id: registro.becario_id,
    becario_nombre: registro.becario_nombre,
    referencia_id: registro.id,
    fecha_inicial: registro.fecha,
    tipo_inicial: tipoIncidenciaDesdeActividad(registro.tipo),
    tipo_incidencia: tipoIncidenciaDesdeActividad(registro.tipo),
    sede_nombre: registro.sede_nombre,
    motivo_sugerido: registro.minutos_retraso > 0
        ? 'Retraso de ${registro.minutos_retraso} min registrado en marcación'
        : null,
  );
  if (radicada == true) {
    await ref
        .read(auditoria_asistencia_proveedor.notifier)
        .actualizarTrasJustificar();
  }
}

/// Vista de auditoría institucional de asistencias (Administrador / Supervisor).
class AuditoriaAsistenciaVista extends ConsumerStatefulWidget {
  final RolAuditoria rol;
  const AuditoriaAsistenciaVista({super.key, required this.rol});

  @override
  ConsumerState<AuditoriaAsistenciaVista> createState() =>
      _AuditoriaAsistenciaVistaState();
}

class _AuditoriaAsistenciaVistaState
    extends ConsumerState<AuditoriaAsistenciaVista> {
  final TextEditingController _busqueda = TextEditingController();
  String _filtro_estado = 'todos';

  static const Map<String, String> _FILTROS = {
    'todos': 'Todos',
    'alertas': 'Alertas',
    'tardanza': 'Tardanza',
    'fuera_geocerca': 'Fuera de geocerca',
    'convalidado': 'Convalidado',
  };

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  bool _coincide(RegistroAuditoriaAsistencia r) {
    final coincide_estado = switch (_filtro_estado) {
      'todos' => true,
      'alertas' => !r.dentro_de_radio || r.estado == 'tardanza',
      _ => r.estado == _filtro_estado,
    };
    final texto = _busqueda.text.trim().toLowerCase();
    final coincide_texto = texto.isEmpty ||
        r.becario_nombre.toLowerCase().contains(texto) ||
        r.carrera.toLowerCase().contains(texto) ||
        r.sede_nombre.toLowerCase().contains(texto);
    return coincide_estado && coincide_texto;
  }

  @override
  Widget build(BuildContext context) {
    final registros_async = ref.watch(auditoria_asistencia_proveedor);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: BumandColores.grisClaro),
          ),
          child: TextField(
            controller: _busqueda,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Buscar becario, carrera o sede...',
              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: BumandColores.AZUL_DIACONIA,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _FILTROS.entries.map((e) {
                final seleccionado = _filtro_estado == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: seleccionado,
                    onSelected: (_) => setState(() => _filtro_estado = e.key),
                    selectedColor: BumandColores.AZUL_DIACONIA,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: seleccionado
                          ? Colors.white
                          : const Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: seleccionado
                            ? BumandColores.AZUL_DIACONIA
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: registros_async.when(
            loading: () => CargandoSkeleton.lista(cantidad: 4, alto_item: 150),
            error: (err, _) => ErrorWidgetPersonalizado(
              mensaje: 'Error al cargar la auditoría de asistencias',
              detalles: [err.toString()],
              alReintentar: () => ref.invalidate(auditoria_asistencia_proveedor),
            ),
            data: (registros) {
              final filtrados = registros.where(_coincide).toList();
              return RefreshIndicator(
                color: BumandColores.NARANJA_OSCURO,
                backgroundColor: BumandColores.AZUL_DIACONIA,
                onRefresh: () =>
                    ref.read(auditoria_asistencia_proveedor.notifier).recargar(),
                child: filtrados.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(32),
                        children: const [
                          SizedBox(height: 24),
                          Icon(Icons.search_off_rounded,
                              size: 48, color: Color(0xFF94A3B8)),
                          SizedBox(height: 12),
                          Center(
                            child: Text(
                              'No hay registros que coincidan con el filtro',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filtrados.length,
                        itemBuilder: (context, i) => FilaAuditoriaAsistencia(
                          registro: filtrados[i],
                          rol: widget.rol,
                        ),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Fila / tarjeta de auditoría de asistencia (misma información que Web).
class FilaAuditoriaAsistencia extends ConsumerWidget {
  final RegistroAuditoriaAsistencia registro;
  final RolAuditoria rol;

  const FilaAuditoriaAsistencia({
    super.key,
    required this.registro,
    required this.rol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = registro;
    final es_admin = rol == RolAuditoria.administrador;
    final es_supervisor = rol == RolAuditoria.supervisor;
    final anomalia_pendiente =
        r.estado == 'tardanza' || r.estado == 'fuera_geocerca';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          // Avatar + nombre + carrera
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.12),
                child: Text(
                  r.iniciales,
                  style: const TextStyle(
                    color: BumandColores.AZUL_DIACONIA,
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
                      r.becario_nombre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    _chip(
                      r.carrera,
                      fondo: const Color(0xFFF1F5F9),
                      borde: const Color(0xFFE2E8F0),
                      color_texto: const Color(0xFF475569),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Sede y fecha
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${r.sede_nombre} · ${r.fecha}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Horario, horas y distancia
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    r.horario_texto,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              Text(
                r.horas_texto,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BumandColores.AZUL_DIACONIA,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.navigation_rounded,
                    size: 13,
                    color: r.dentro_de_radio
                        ? const Color(0xFF047857)
                        : const Color(0xFFBE123C),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    r.distancia_texto,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: r.dentro_de_radio
                          ? const Color(0xFF047857)
                          : const Color(0xFFBE123C),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Badges
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ..._badgesEstado(r),
              if (r.tiene_multa_vigente)
                _chip(
                  r.multa_texto,
                  fondo: const Color(0xFFFFF1F2),
                  borde: const Color(0xFFFDA4AF),
                  color_texto: const Color(0xFFBE123C),
                  icono: Icons.paid_rounded,
                ),
              if (r.esta_aprobado_administracion)
                _chip(
                  '✓ Aprobado por Administración (Exento de multa)',
                  fondo: const Color(0xFFD1FAE5),
                  borde: const Color(0xFF6EE7B7),
                  color_texto: const Color(0xFF065F46),
                  icono: Icons.verified_user_rounded,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            r.confirmacion_presencial
                ? '✓ Verificado presencial'
                : 'Sin confirmación en vivo',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: r.confirmacion_presencial
                  ? const Color(0xFF047857)
                  : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),

          // Acciones
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                tooltip: 'Ver detalle',
                icon: const Icon(Icons.visibility_outlined,
                    size: 20, color: Color(0xFF035683)),
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    abrirDetalleRegistroAuditoria(context, ref, r, rol),
              ),
              if (anomalia_pendiente || r.esta_revisado_supervisor) ...[
                if (es_admin && !r.esta_aprobado_administracion)
                  FilledButton.icon(
                    onPressed: () => aprobarRegistroAuditoria(context, ref, r),
                    style: FilledButton.styleFrom(
                      backgroundColor: _AZUL_INSTITUCIONAL,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.verified_user_rounded,
                        size: 16, color: BumandColores.AMARILLO_RADIANTE),
                    label: const Text(
                      'Aprobar por Administración',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (es_supervisor && anomalia_pendiente)
                  OutlinedButton.icon(
                    onPressed: () => revisarRegistroSupervisor(context, ref, r),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF035683),
                      side: const BorderSide(color: BumandColores.AZUL_CIELO_SUAVE),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.check,
                        size: 16, color: BumandColores.AZUL_CIELO_SUAVE),
                    label: const Text(
                      'Marcar Revisado por Supervisor',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (!r.esta_aprobado_administracion)
                  OutlinedButton.icon(
                    onPressed: () => justificarRegistroAuditoria(context, ref, r),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF035683),
                      backgroundColor:
                          BumandColores.AMARILLO_RADIANTE.withValues(alpha: 0.12),
                      side: const BorderSide(color: BumandColores.AMARILLO_RADIANTE),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
                    label: const Text(
                      'Justificar',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _badgesEstado(RegistroAuditoriaAsistencia r) {
    switch (r.estado) {
      case 'conforme':
        return [
          _chip('✓ Conforme WGS84',
              fondo: const Color(0xFFD1FAE5),
              borde: const Color(0xFFA7F3D0),
              color_texto: const Color(0xFF065F46)),
        ];
      case 'en_curso':
        return [
          _chip('En Curso',
              fondo: const Color(0xFFFEF3C7),
              borde: const Color(0xFFFDE68A),
              color_texto: const Color(0xFF92400E),
              icono: Icons.schedule_rounded),
        ];
      case 'tardanza':
        return [
          _chip('⚠ Tardanza',
              fondo: const Color(0xFFFEF3C7),
              borde: const Color(0xFFFDE68A),
              color_texto: const Color(0xFF92400E)),
        ];
      case 'fuera_geocerca':
        return [
          _chip('⚠ Fuera de Geocerca',
              fondo: const Color(0xFFFFE4E6),
              borde: const Color(0xFFFECDD3),
              color_texto: const Color(0xFF9F1239)),
        ];
      case 'convalidado':
        return [
          _chip('Convalidado',
              fondo: const Color(0xFFE0F2FE),
              borde: const Color(0xFFBAE6FD),
              color_texto: const Color(0xFF075985),
              icono: Icons.verified_user_rounded),
        ];
      case 'revisado_supervisor':
        return [
          _chip('Revisado por Supervisor',
              fondo: const Color(0xFFF0F9FF),
              borde: const Color(0xFF7DD3FC),
              color_texto: const Color(0xFF075985),
              icono: Icons.check_circle_outline),
        ];
      default:
        return const [];
    }
  }
}

Widget _chip(
  String etiqueta, {
  required Color fondo,
  required Color borde,
  required Color color_texto,
  IconData? icono,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: fondo,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: borde),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icono != null) ...[
          Icon(icono, size: 12, color: color_texto),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            etiqueta,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: color_texto,
            ),
          ),
        ),
      ],
    ),
  );
}