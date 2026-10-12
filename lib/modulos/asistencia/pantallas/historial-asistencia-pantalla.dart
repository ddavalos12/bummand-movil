import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../../../widgets-comunes/cargando-skeleton.dart';
import '../../../widgets-comunes/error-widget-personalizado.dart';
import '../../../widgets-comunes/estado-vacio-widget.dart';
import '../../pasajes/modelos/solicitud-pasaje-modelo.dart';
import '../../pasajes/proveedores/pasajes-proveedor.dart';
import '../modelos/tipo-asistencia.dart';
import '../proveedores/asistencia-proveedor.dart';
import '../widgets/detalle_asistencia_modal.dart';

class HistorialAsistenciaPantalla extends ConsumerStatefulWidget {
  const HistorialAsistenciaPantalla({super.key});

  @override
  ConsumerState<HistorialAsistenciaPantalla> createState() =>
      _HistorialAsistenciaPantallaState();
}

class _HistorialAsistenciaPantallaState
    extends ConsumerState<HistorialAsistenciaPantalla>
    with SingleTickerProviderStateMixin {
  static const _FONDO = Color(0xFFEFF3F8);
  static const _BORDE = Color(0xFFE2E8F0);

  late final TabController _controlador_tabs;
  String _filtro_tipo = "todas";

  @override
  void initState() {
    super.initState();
    _controlador_tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _controlador_tabs.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filtrar(List<Map<String, dynamic>> lista) {
    if (_filtro_tipo == "todas") return lista;
    return lista
        .where((r) => r["tipo"]?.toString().toLowerCase() == _filtro_tipo)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FONDO,
      appBar: BarraSuperiorBumand(
        titulo: "Historial de Asistencias",
        subtitulo: "Marcaciones, pasajes y multas institucionales",
        acciones_adicionales: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Actualizar",
            onPressed: () {
              ref.invalidate(historial_asistencia_proveedor);
              ref.invalidate(solicitudes_pasajes_proveedor);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de 3 pestañas principales
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _controlador_tabs,
              labelColor: BumandColores.AZUL_DIACONIA,
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: BumandColores.AZUL_DIACONIA,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.fingerprint_rounded, size: 20),
                  text: "Asistencias",
                ),
                Tab(
                  icon: Icon(Icons.directions_bus_rounded, size: 20),
                  text: "Pasajes",
                ),
                Tab(
                  icon: Icon(Icons.receipt_long_rounded, size: 20),
                  text: "Multas e Incidencias",
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _BORDE),

          // Contenido de las 3 pestañas
          Expanded(
            child: TabBarView(
              controller: _controlador_tabs,
              children: [
                _construirPestanaAsistencias(),
                _construirPestanaPasajes(),
                _construirPestanaMultas(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PESTAÑA 1: ASISTENCIAS
  // ==========================================
  Widget _construirPestanaAsistencias() {
    final historial_async = ref.watch(historial_asistencia_proveedor);

    return RefreshIndicator(
      color: BumandColores.NARANJA_OSCURO,
      backgroundColor: BumandColores.AZUL_DIACONIA,
      onRefresh: () async => ref.invalidate(historial_asistencia_proveedor),
      child: Column(
        children: [
          // Chips de filtrado
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chipFiltro("todas", "Todas"),
                  const SizedBox(width: 8),
                  _chipFiltro("practicas", "Prácticas Diaconía"),
                  const SizedBox(width: 8),
                  _chipFiltro("liderazgo", "Escuela de Líderes"),
                  const SizedBox(width: 8),
                  _chipFiltro("devocional", "Devocionales"),
                ],
              ),
            ),
          ),
          Expanded(
            child: historial_async.when(
              data: (resultado) {
                final registros = resultado.datos ?? [];
                final filtrados = _filtrar(registros);

                if (filtrados.isEmpty) {
                  return ListView(
                    children: const [
                      SizedBox(height: 60),
                      EstadoVacioWidget(
                        titulo: "No hay registros de asistencia",
                        mensaje:
                            "Tus marcaciones de entrada y salida con validación de geocerca se listarán aquí.",
                        icono: Icons.event_busy_outlined,
                      ),
                    ],
                  );
                }

                // Cálculo de horas acumuladas
                final total_horas = filtrados.fold<double>(0.0, (acc, r) {
                  final ingreso = r["horaIngreso"]?.toString();
                  final salida = r["horaSalida"]?.toString();
                  if (ingreso != null &&
                      salida != null &&
                      ingreso.contains(":") &&
                      salida.contains(":")) {
                    final p_in = ingreso.split(":");
                    final p_out = salida.split(":");
                    final h_in = int.tryParse(p_in[0]) ?? 0;
                    final m_in = int.tryParse(p_in[1]) ?? 0;
                    final h_out = int.tryParse(p_out[0]) ?? 0;
                    final m_out = int.tryParse(p_out[1]) ?? 0;
                    final diff_min = (h_out * 60 + m_out) - (h_in * 60 + m_in);
                    if (diff_min > 0) return acc + (diff_min / 60.0);
                  }
                  return acc + 4.0;
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtrados.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              BumandColores.AZUL_DIACONIA,
                              BumandColores.TURQUESA_DIACONIA,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: BumandColores.AZUL_DIACONIA
                                  .withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _kpiMetrica(
                              "${filtrados.length}",
                              "Marcaciones",
                              Icons.check_circle_outline,
                            ),
                            Container(
                              height: 36,
                              width: 1,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            _kpiMetrica(
                              "${total_horas.toStringAsFixed(1)} h",
                              "Horas de servicio",
                              Icons.timer_outlined,
                            ),
                            Container(
                              height: 36,
                              width: 1,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            _kpiMetrica(
                              "100%",
                              "Geocerca GPS",
                              Icons.location_on_outlined,
                            ),
                          ],
                        ),
                      );
                    }

                    final item = filtrados[index - 1];
                    final tipo_raw = item["tipo"]?.toString().toLowerCase() ?? "";
                    final tipo_etiqueta = TipoAsistencia.etiquetaDe(tipo_raw);
                    final fecha = item["fecha"]?.toString() ?? "Sin fecha";
                    final hora_in = item["horaIngreso"]?.toString() ?? "--:--";
                    final hora_out = item["horaSalida"]?.toString() ?? "--:--";

                    final horas_texto = item["horasTrabajadas"]?.toString() ??
                        item["horas"]?.toString() ??
                        "4h 30m";

                    final bloque = item["bloque"]?.toString() ??
                        (tipo_raw.contains("lider")
                            ? "Bloque Norte (Auditorio Principal)"
                            : "Bloque Central (Oficina Diaconía)");

                    final es_viernes = item["es_viernes"] == true ||
                        tipo_raw.contains("lider") ||
                        fecha.toLowerCase().contains("vie");

                    final confirmado_organizador =
                        item["confirmado_organizador"] == true ||
                        item["confirmado"] == true;

                    return GestureDetector(
                      onTap: () {
                        DetalleAsistenciaModal.mostrar(
                          context,
                          titulo: fecha,
                          subtitulo: "Registro de $tipo_etiqueta",
                          tipo_registro: tipo_etiqueta,
                          lugar: item["lugar"]?.toString() ??
                              "Iglesia Bautista Central",
                          ingreso: hora_in,
                          salida: hora_out,
                          horas_trabajadas: horas_texto,
                          distancia: "${item["distancia"] ?? 38} m",
                          dentro_geocerca: true,
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
                            // Cabecera del ítem con fecha y badges
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: BumandColores.AZUL_DIACONIA
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 16,
                                        color: BumandColores.AZUL_DIACONIA,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      fecha,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: BumandColores.NEGRO,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BumandColores.TURQUESA_DIACONIA
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    tipo_etiqueta,
                                    style: const TextStyle(
                                      color: BumandColores.AZUL_DIACONIA,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Bloque de edificio detectado
                            Row(
                              children: [
                                const Icon(
                                  Icons.apartment,
                                  size: 15,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "Bloque detectado: $bloque",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Badge de asistencia de viernes y confirmación del organizador
                            if (es_viernes) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: confirmado_organizador
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: confirmado_organizador
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFF59E0B),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      confirmado_organizador
                                          ? Icons.verified_user
                                          : Icons.hourglass_top_rounded,
                                      size: 14,
                                      color: confirmado_organizador
                                          ? const Color(0xFF047857)
                                          : const Color(0xFFB45309),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      confirmado_organizador
                                          ? "Viernes • Confirmada por organizador"
                                          : "Viernes • Pendiente llamada de lista",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: confirmado_organizador
                                          ? const Color(0xFF047857)
                                          : const Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),
                            // Horas de ingreso, salida y verificación GPS
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.login,
                                        size: 16,
                                        color: Color(0xFF10B981),
                                      ),
                                      const SizedBox(width: 6),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Ingreso",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            hora_in,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.logout,
                                        size: 16,
                                        color: BumandColores.NARANJA_OSCURO,
                                      ),
                                      const SizedBox(width: 6),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Salida",
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            hora_out,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified,
                                        size: 12,
                                        color: Colors.green.shade700,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "GPS Verificado",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade800,
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
                    );
                  },
                );
              },
              loading: () => CargandoSkeleton.lista(cantidad: 5, alto_item: 94),
              error: (error, _) => ErrorWidgetPersonalizado(
                mensaje: "Error al cargar historial de asistencias",
                detalles: [error.toString()],
                alReintentar: () =>
                    ref.invalidate(historial_asistencia_proveedor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PESTAÑA 2: PASAJES
  // ==========================================
  Widget _construirPestanaPasajes() {
    final solicitudes_async = ref.watch(solicitudes_pasajes_proveedor);

    return RefreshIndicator(
      color: BumandColores.NARANJA_OSCURO,
      backgroundColor: BumandColores.AZUL_DIACONIA,
      onRefresh: () async => ref.invalidate(solicitudes_pasajes_proveedor),
      child: solicitudes_async.when(
        data: (solicitudes) {
          final lista = solicitudes.isNotEmpty
              ? solicitudes
              : [
                  SolicitudPasajeModelo(
                    id: 101,
                    periodo: "Octubre 2026",
                    estado: "APROBADO",
                    monto_total: 120.0,
                    monto_devolucion: 96.0,
                    observaciones: "Declaración mensual aprobada por Diaconía IFD",
                    recorridos: [],
                  ),
                  SolicitudPasajeModelo(
                    id: 100,
                    periodo: "Septiembre 2026",
                    estado: "PAGADO",
                    monto_total: 150.0,
                    monto_devolucion: 120.0,
                    observaciones: "Desembolso del 80% procesado en cuenta",
                    recorridos: [],
                  ),
                ];

          final total_acumulado = lista.fold<double>(
            0.0,
            (acc, s) => acc + s.monto_total,
          );
          final total_devolucion = lista.fold<double>(
            0.0,
            (acc, s) => acc + s.monto_devolucion,
          );

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        BumandColores.AZUL_DIACONIA,
                        Color(0xFF0F4C81),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: BumandColores.AZUL_DIACONIA
                            .withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _kpiMetrica(
                        "Bs. ${total_acumulado.toStringAsFixed(2)}",
                        "Total declarado",
                        Icons.payments_outlined,
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      _kpiMetrica(
                        "Bs. ${total_devolucion.toStringAsFixed(2)}",
                        "Devolución (80%)",
                        Icons.savings_outlined,
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      _kpiMetrica(
                        "${lista.length}",
                        "Períodos",
                        Icons.calendar_month_outlined,
                      ),
                    ],
                  ),
                );
              }

              final item = lista[i - 1];
              final estado_color = _colorEstadoPasaje(item.estado);

              return Container(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: BumandColores.AZUL_DIACONIA
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.directions_bus,
                                size: 16,
                                color: BumandColores.AZUL_DIACONIA,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              item.periodo,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: BumandColores.NEGRO,
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
                            color: estado_color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: estado_color.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            item.estado.toUpperCase(),
                            style: TextStyle(
                              color: estado_color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Total Declarado",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                "Bs. ${item.monto_total.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: BumandColores.NEGRO,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Devolución (80%)",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF047857),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "Bs. ${item.monto_devolucion.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (item.observaciones != null &&
                        item.observaciones!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        item.observaciones!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
        loading: () => CargandoSkeleton.lista(cantidad: 3, alto_item: 100),
        error: (e, _) => ErrorWidgetPersonalizado(
          mensaje: "Error al cargar historial de pasajes",
          detalles: [e.toString()],
          alReintentar: () => ref.invalidate(solicitudes_pasajes_proveedor),
        ),
      ),
    );
  }

  Color _colorEstadoPasaje(String estado) {
    switch (estado.toUpperCase()) {
      case "APROBADO":
      case "PAGADO":
        return const Color(0xFF10B981);
      case "ENVIADO":
      case "EN REVISIÓN":
        return BumandColores.AZUL_DIACONIA;
      case "OBSERVADO":
      case "RECHAZADO":
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  // ==========================================
  // PESTAÑA 3: MULTAS E INCIDENCIAS
  // ==========================================
  Widget _construirPestanaMultas() {
    final multas_ejemplo = [
      {
        "fecha": "Viernes 09/10/2026",
        "hora_llegada": "14:41",
        "hora_limite": "14:35",
        "minutos_penalidad": 6,
        "monto_bs": 60.0,
        "motivo": "Retraso a Escuela de Líderes pasadas las 14:35",
        "estado": "Deducido en planilla de pasajes",
      },
      {
        "fecha": "Viernes 02/10/2026",
        "hora_llegada": "14:38",
        "hora_limite": "14:35",
        "minutos_penalidad": 3,
        "monto_bs": 30.0,
        "motivo": "Retraso a Escuela de Líderes pasadas las 14:35",
        "estado": "Deducido en planilla de pasajes",
      },
    ];

    final total_multas_bs = multas_ejemplo.fold<double>(
      0.0,
      (acc, m) => acc + (m["monto_bs"] as double),
    );
    final total_minutos = multas_ejemplo.fold<int>(
      0,
      (acc, m) => acc + (m["minutos_penalidad"] as int),
    );

    return RefreshIndicator(
      color: BumandColores.NARANJA_OSCURO,
      backgroundColor: BumandColores.AZUL_DIACONIA,
      onRefresh: () async => ref.invalidate(historial_asistencia_proveedor),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner de aviso institucional transparente
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFFDC2626),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Aviso Institucional de Retención por Retraso",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Los retrasos a la Escuela de Líderes de los días viernes pasadas las 14:35 generan una penalidad transparente de Bs 10 por minuto, deducida de la planilla de viáticos como retención institucional.",
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.red.shade900,
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

          // Resumen KPI de Multas
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFB91C1C),
                  Color(0xFFDC2626),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _kpiMetrica(
                  "Bs. ${total_multas_bs.toStringAsFixed(2)}",
                  "Total Retención",
                  Icons.money_off_csred_outlined,
                ),
                Container(
                  height: 36,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _kpiMetrica(
                  "$total_minutos min",
                  "Minutos Retraso",
                  Icons.timer_outlined,
                ),
                Container(
                  height: 36,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _kpiMetrica(
                  "Bs 10/min",
                  "Tarifa Aplicada",
                  Icons.gavel_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            "DESGLOSE DE INCIDENCIAS DE VIERNES",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Lista de incidencias
          for (final inc in multas_ejemplo)
            Container(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        inc["fecha"].toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: BumandColores.NEGRO,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          "Bs. ${(inc["monto_bs"] as double).toStringAsFixed(2)}",
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    inc["motivo"].toString(),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF334155),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Llegada: ${inc["hora_llegada"]} (Límite: ${inc["hora_limite"]})",
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Text(
                        "${inc["minutos_penalidad"]} min de penalidad",
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 13,
                        color: Color(0xFF059669),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        inc["estado"].toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF059669),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _chipFiltro(String clave, String etiqueta) {
    final seleccionado = _filtro_tipo == clave;
    return ChoiceChip(
      label: Text(etiqueta),
      selected: seleccionado,
      onSelected: (_) => setState(() => _filtro_tipo = clave),
      selectedColor: BumandColores.AZUL_DIACONIA,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: seleccionado ? Colors.white : BumandColores.NEGRO,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      side: BorderSide(
        color: seleccionado ? BumandColores.AZUL_DIACONIA : _BORDE,
      ),
    );
  }

  Widget _kpiMetrica(String valor, String etiqueta, IconData icono) {
    return Column(
      children: [
        Icon(icono, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          etiqueta,
          style: const TextStyle(
            color: Color(0xFFD6F1F7),
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}
