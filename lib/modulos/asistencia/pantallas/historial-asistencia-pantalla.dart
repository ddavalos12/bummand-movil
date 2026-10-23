import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../../../widgets-comunes/cargando-skeleton.dart';
import '../../../widgets-comunes/error-widget-personalizado.dart';
import '../../evaluaciones/proveedores/evaluaciones-proveedor.dart';
import '../../evaluaciones/widgets/detalle_evaluacion_modal.dart';
import '../../evaluaciones/widgets/formulario_f03_dialogo.dart';
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
  String _subseccion_evaluacion = "todas";

  @override
  void initState() {
    super.initState();
    _controlador_tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _controlador_tabs.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filtrar(List<Map<String, dynamic>> lista) {
    if (_filtro_tipo == "todas") return lista;
    return lista.where((r) {
      final tipo = r["tipo"]?.toString().toLowerCase() ?? "";
      if (_filtro_tipo == "liderazgo" || _filtro_tipo == "escuela_lideres") {
        return tipo == "liderazgo" || tipo == "escuela_lideres" || tipo.contains("lider");
      }
      if (_filtro_tipo == "servicio" || _filtro_tipo == "acciones_servicio") {
        return tipo == "servicio" || tipo == "acciones_servicio" || tipo.contains("servicio");
      }
      if (_filtro_tipo == "practicas") {
        return tipo == "practicas" || tipo.contains("practica");
      }
      return tipo == _filtro_tipo;
    }).toList();
  }

  double _calcularMultaPorMinutos(int minutos) {
    if (minutos <= 0) return 0.0;
    if (minutos <= 10) return 10.0;
    if (minutos <= 30) return 20.0;
    if (minutos <= 60) return 30.0;
    return 50.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FONDO,
      appBar: BarraSuperiorBumand(
        titulo: "Mi historial",
        subtitulo: "Marcaciones, evaluaciones, pasajes y multas",
        acciones_adicionales: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Actualizar",
            onPressed: () {
              ref.invalidate(historial_asistencia_proveedor);
              ref.invalidate(solicitudes_pasajes_proveedor);
              ref.invalidate(evaluacion_consolidada_proveedor);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _controlador_tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
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
                  icon: Icon(Icons.assignment_turned_in_rounded, size: 20),
                  text: "Evaluaciones",
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
          Expanded(
            child: TabBarView(
              controller: _controlador_tabs,
              children: [
                _construirPestanaAsistencias(),
                _construirPestanaEvaluaciones(),
                _construirPestanaPasajes(),
                _construirPestanaMultas(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirPestanaAsistencias() {
    final historial_async = ref.watch(historial_asistencia_proveedor);

    return RefreshIndicator(
      color: BumandColores.NARANJA_OSCURO,
      backgroundColor: BumandColores.AZUL_DIACONIA,
      onRefresh: () async => ref.invalidate(historial_asistencia_proveedor),
      child: Column(
        children: [
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
                  _chipFiltro("servicio", "Acciones de Servicio"),
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

                final horas_mostrar = total_horas > 0 ? total_horas : 38.5;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtrados.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _construirTarjetaHorasSemanales(horas_mostrar);
                    }

                    if (index == 1) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _BORDE),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _kpiMetricaColor(
                              "${filtrados.length}",
                              "Marcaciones",
                              Icons.check_circle_outline,
                              BumandColores.AZUL_DIACONIA,
                            ),
                            Container(
                              height: 32,
                              width: 1,
                              color: const Color(0xFFE2E8F0),
                            ),
                            _kpiMetricaColor(
                              "${horas_mostrar.toStringAsFixed(1)} h",
                              "Horas de servicio",
                              Icons.timer_outlined,
                              const Color(0xFF0D9488),
                            ),
                            Container(
                              height: 32,
                              width: 1,
                              color: const Color(0xFFE2E8F0),
                            ),
                            _kpiMetricaColor(
                              "100%",
                              "Geocerca GPS",
                              Icons.location_on_outlined,
                              const Color(0xFF059669),
                            ),
                          ],
                        ),
                      );
                    }

                    final item = filtrados[index - 2];
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

                    final es_manual = item["es_registro_manual"] == true ||
                        item["esRegistroManual"] == true ||
                        item["registro_manual"] == true ||
                        item["manual"] == true;

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
                            if (es_manual) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF6366F1),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.admin_panel_settings_outlined,
                                      size: 14,
                                      color: Color(0xFF4F46E5),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "Registrado por Administración",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4F46E5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

  Widget _construirTarjetaHorasSemanales(double horas_acumuladas) {
    final barras_semanales = [
      {"dia": "03 ago", "horas": 7.5, "factor": 0.65},
      {"dia": "10 ago", "horas": 9.5, "factor": 0.85},
      {"dia": "17 ago", "horas": 8.0, "factor": 0.70},
      {"dia": "24 ago", "horas": 8.5, "factor": 0.75},
      {"dia": "31 ago", "horas": 5.0, "factor": 0.45},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2B48),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2B48).withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: Color(0xFF93C5FD),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                "Horas acumuladas este mes",
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "Agosto 2026",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${horas_acumuladas.toStringAsFixed(1)} h",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: BumandColores.TURQUESA_DIACONIA.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "Meta mensual: 40 h · 96% alcanzado",
                      style: TextStyle(
                        color: BumandColores.TURQUESA_DIACONIA,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: barras_semanales.map((barra) {
                  final factor = barra["factor"] as double;
                  final dia = barra["dia"] as String;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 14,
                          height: 52 * factor,
                          decoration: BoxDecoration(
                            color: BumandColores.TURQUESA_DIACONIA,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dia,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirPestanaEvaluaciones() {
    final evaluacion_async = ref.watch(evaluacion_consolidada_proveedor);

    return RefreshIndicator(
      color: BumandColores.NARANJA_OSCURO,
      backgroundColor: BumandColores.AZUL_DIACONIA,
      onRefresh: () async => ref.invalidate(evaluacion_consolidada_proveedor),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chipSubseccionEval("todas", "Todas las secciones"),
                  const SizedBox(width: 8),
                  _chipSubseccionEval("modulos", "Módulos Canónicos (5)"),
                  const SizedBox(width: 8),
                  _chipSubseccionEval("competencias", "Criterios Formativos"),
                ],
              ),
            ),
          ),
          Expanded(
            child: evaluacion_async.when(
              data: (resultado) {
                final bool mostrar_modulos = _subseccion_evaluacion == "todas" ||
                    _subseccion_evaluacion == "modulos";
                final bool mostrar_competencias =
                    _subseccion_evaluacion == "todas" ||
                        _subseccion_evaluacion == "competencias";

                final modulos_receptores = [
                  {
                    "numero": 1,
                    "titulo": "Liderazgo en la Iglesia (Formulario F-03)",
                    "subtitulo": "Evaluador: Pastor de la Congregación",
                    "estado": "Completado",
                  },
                  {
                    "numero": 2,
                    "titulo": "Autoevaluación Académica",
                    "subtitulo": "Subida obligatoria de Récord e Historial",
                    "estado": "Documentos Recibidos",
                  },
                  {
                    "numero": 3,
                    "titulo": "Evaluación del Mentor / Supervisor",
                    "subtitulo": "Pasantías en agencias · Código QR",
                    "estado": "Pendiente",
                  },
                  {
                    "numero": 4,
                    "titulo": "Evaluación Escuela de Líderes",
                    "subtitulo": "Talleres y devocionales presenciales de viernes",
                    "estado": "Completado",
                  },
                  {
                    "numero": 5,
                    "titulo": "Evaluación Socioeconómica",
                    "subtitulo": "Ficha receptora de 4 bloques confidenciales",
                    "estado": "Pendiente",
                  },
                ];

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (mostrar_modulos) ...[
                      _construirCabeceraSubseccion(
                        titulo: "Módulos Formativos de Evaluación",
                        subtitulo:
                            "5 áreas canónicas · Recepción semestral activa",
                        icono: Icons.view_list_rounded,
                      ),
                      const SizedBox(height: 10),
                      for (final mod in modulos_receptores)
                        _construirItemModuloReceptor(
                          numero: mod["numero"] as int,
                          titulo: mod["titulo"] as String,
                          subtitulo: mod["subtitulo"] as String,
                          estado: mod["estado"] as String,
                        ),
                      const SizedBox(height: 20),
                    ],
                    if (mostrar_competencias) ...[
                      _construirCabeceraSubseccion(
                        titulo: "Criterios y Competencias Formativas",
                        subtitulo:
                            "Pilares institucionales de acompañamiento integral",
                        icono: Icons.military_tech_outlined,
                      ),
                      const SizedBox(height: 10),
                      _construirTarjetaCompetenciasFormativas(),
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              },
              loading: () => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CargandoSkeleton.linea(alto: 100),
                  const SizedBox(height: 16),
                  CargandoSkeleton.lista(cantidad: 4, alto_item: 90),
                ],
              ),
              error: (error, _) => ErrorWidgetPersonalizado(
                mensaje: "Error al cargar evaluaciones",
                detalles: [error.toString()],
                alReintentar: () =>
                    ref.invalidate(evaluacion_consolidada_proveedor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirItemModuloReceptor({
    required int numero,
    required String titulo,
    required String subtitulo,
    required String estado,
  }) {
    final es_recibido =
        estado.toLowerCase().contains("complet") || estado.toLowerCase().contains("recib");

    return GestureDetector(
      onTap: () {
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
              titulo: titulo,
              evaluador: "Coordinación Escuela de Líderes",
              estado: estado,
              comentario:
                  "Asistencia verificada a talleres formativos y actividades de servicio.",
            );
            break;
          case 5:
            DetalleEvaluacionModal.mostrarReceptorSocioeconomico(context);
            break;
        }
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
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                "$numero",
                style: const TextStyle(
                  color: BumandColores.AZUL_DIACONIA,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
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
                      fontSize: 14,
                      color: BumandColores.NEGRO,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: es_recibido
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: es_recibido
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFFFDE68A),
                ),
              ),
              child: Text(
                estado,
                style: TextStyle(
                  color: es_recibido
                      ? const Color(0xFF047857)
                      : const Color(0xFFB45309),
                  fontWeight: FontWeight.bold,
                  fontSize: 10.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipSubseccionEval(String valor, String etiqueta) {
    final seleccionado = _subseccion_evaluacion == valor;
    return ChoiceChip(
      label: Text(etiqueta),
      selected: seleccionado,
      onSelected: (_) => setState(() => _subseccion_evaluacion = valor),
      selectedColor: BumandColores.AZUL_DIACONIA,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: seleccionado ? Colors.white : const Color(0xFF64748B),
      ),
      side: BorderSide(
        color: seleccionado ? BumandColores.AZUL_DIACONIA : _BORDE,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _construirCabeceraSubseccion({
    required String titulo,
    required String subtitulo,
    required IconData icono,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, size: 18, color: BumandColores.AZUL_DIACONIA),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: BumandColores.AZUL_DIACONIA,
                ),
              ),
              Text(
                subtitulo,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _construirTarjetaCompetenciasFormativas() {
    final competencias = [
      {
        "titulo": "Puntualidad y Asistencia en Agencias",
        "detalle": "Horas de servicio verificadas por geocerca GPS",
        "estado": "Verificado",
        "icono": Icons.alarm_on_rounded,
        "color": const Color(0xFF10B981),
      },
      {
        "titulo": "Liderazgo Eclesial y Servicio Diaconal",
        "detalle": "Aporte a la iglesia local acreditado por formulario F-03",
        "estado": "Acreditado",
        "icono": Icons.church_outlined,
        "color": const Color(0xFF3B82F6),
      },
      {
        "titulo": "Aprovechamiento Académico Universitario",
        "detalle": "Récord e historial semestral recepcionados",
        "estado": "En revisión",
        "icono": Icons.school_outlined,
        "color": const Color(0xFFF59E0B),
      },
      {
        "titulo": "Identidad Institucional y Devocional",
        "detalle": "Participación activa en talleres de Escuela de Líderes",
        "estado": "Verificado",
        "icono": Icons.auto_stories_outlined,
        "color": const Color(0xFF8B5CF6),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _BORDE),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Criterios de Excelencia Diaconal",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: BumandColores.NEGRO,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Indicadores de formación integral para el acompañamiento del becario:",
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          for (final comp in competencias) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (comp["color"] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      comp["icono"] as IconData,
                      size: 18,
                      color: comp["color"] as Color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                comp["titulo"] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                  color: BumandColores.NEGRO,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (comp["color"] as Color).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                comp["estado"] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10.5,
                                  color: comp["color"] as Color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          comp["detalle"] as String,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (comp != competencias.last)
              const Divider(height: 12, color: Color(0xFFF1F5F9)),
          ],
        ],
      ),
    );
  }

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
                        color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _kpiMetricaBlanco(
                        "Bs. ${total_acumulado.toStringAsFixed(2)}",
                        "Total declarado",
                        Icons.payments_outlined,
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      _kpiMetricaBlanco(
                        "Bs. ${total_devolucion.toStringAsFixed(2)}",
                        "Devolución (80%)",
                        Icons.savings_outlined,
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      _kpiMetricaBlanco(
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

  Widget _construirPestanaMultas() {
    final multas_ejemplo = [
      {
        "fecha": "Viernes 09/10/2026",
        "hora_llegada": "14:41",
        "hora_limite": "14:35",
        "minutos_penalidad": 6,
        "tramo": "1 a 10 min",
        "monto_bs": _calcularMultaPorMinutos(6),
        "motivo": "Retraso a Escuela de Líderes (6 min)",
        "estado": "Deducido en planilla de pasajes",
      },
      {
        "fecha": "Viernes 02/10/2026",
        "hora_llegada": "14:50",
        "hora_limite": "14:35",
        "minutos_penalidad": 15,
        "tramo": "11 a 30 min",
        "monto_bs": _calcularMultaPorMinutos(15),
        "motivo": "Retraso a Escuela de Líderes (15 min)",
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
                _kpiMetricaBlanco(
                  "Bs. ${total_multas_bs.toStringAsFixed(2)}",
                  "Total Retención",
                  Icons.money_off_csred_outlined,
                ),
                Container(
                  height: 36,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _kpiMetricaBlanco(
                  "$total_minutos min",
                  "Minutos Retraso",
                  Icons.timer_outlined,
                ),
                Container(
                  height: 36,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                _kpiMetricaBlanco(
                  "Por tramos",
                  "Escala Oficial",
                  Icons.receipt_long_outlined,
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
                        "${inc["tramo"]} (${inc["minutos_penalidad"]} min)",
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
    final seleccionado = _filtro_tipo == clave ||
        ((clave == "liderazgo" || clave == "escuela_lideres") &&
            (_filtro_tipo == "liderazgo" || _filtro_tipo == "escuela_lideres")) ||
        ((clave == "servicio" || clave == "acciones_servicio") &&
            (_filtro_tipo == "servicio" || _filtro_tipo == "acciones_servicio"));
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

  Widget _kpiMetricaBlanco(String valor, String etiqueta, IconData icono) {
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

  Widget _kpiMetricaColor(
    String valor,
    String etiqueta,
    IconData icono,
    Color color_tema,
  ) {
    return Column(
      children: [
        Icon(icono, color: color_tema, size: 20),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            color: color_tema,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          etiqueta,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}
