import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../../../widgets-comunes/cargando-skeleton.dart';
import '../../../widgets-comunes/error-widget-personalizado.dart';
import '../../evaluaciones/proveedores/evaluaciones-proveedor.dart';
import '../../evaluaciones/widgets/detalle_evaluacion_modal.dart';
import '../../evaluaciones/widgets/formulario_f03_dialogo.dart';
import '../../pasajes/modelos/recorrido-modelo.dart';
import '../../pasajes/modelos/solicitud-pasaje-modelo.dart';
import '../../pasajes/pantallas/detalle-historial-pasaje-pantalla.dart';
import '../../pasajes/proveedores/pasajes-proveedor.dart';
import '../proveedores/asistencia-proveedor.dart';
import '../widgets/detalle_asistencia_modal.dart';
import '../repositorios/asistencia-repositorio.dart';
import 'detalle-extracto-asistencia-pantalla.dart';

class HistorialAsistenciaPantalla extends ConsumerStatefulWidget {
  const HistorialAsistenciaPantalla({super.key});

  @override
  ConsumerState<HistorialAsistenciaPantalla> createState() =>
      _HistorialAsistenciaPantallaState();
}

class _HistorialAsistenciaPantallaState
    extends ConsumerState<HistorialAsistenciaPantalla>
    with SingleTickerProviderStateMixin {
  static const _FONDO = BumandColores.fondo;
  static const _BORDE = BumandColores.grisClaro;

  late final TabController _controlador_tabs;
  final TextEditingController _controlador_busqueda_asistencia =
      TextEditingController();
  String _mes_seleccionado_asistencia = "todos";
  String _filtro_actividad_inline = "todos";
  String _subseccion_evaluacion = "todas";

  @override
  void initState() {
    super.initState();
    _controlador_tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _controlador_busqueda_asistencia.dispose();
    _controlador_tabs.dispose();
    super.dispose();
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
              ref.invalidate(extractos_mensuales_proveedor);
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

  static const List<String> _MESES_DISPONIBLES = [
    "todos",
    "Noviembre",
    "Octubre",
    "Septiembre",
    "Agosto",
    "Julio",
    "Junio",
    "Mayo",
    "Abril",
    "Marzo",
  ];

  Widget _construirPestanaAsistencias() {
    final extractos_async = ref.watch(extractos_mensuales_proveedor);

    return RefreshIndicator(
      color: BumandColores.NARANJA_OSCURO,
      backgroundColor: BumandColores.AZUL_DIACONIA,
      onRefresh: () async {
        ref.invalidate(historial_asistencia_proveedor);
        ref.invalidate(extractos_mensuales_proveedor);
      },
      child: Column(
        children: [
          // 1. Buscador tecleable superior
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _BORDE),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _controlador_busqueda_asistencia,
              decoration: InputDecoration(
                hintText: "Teclea un mes (ej. Mayo, Junio, Octubre)...",
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: BumandColores.AZUL_DIACONIA,
                  size: 20,
                ),
                suffixIcon: _controlador_busqueda_asistencia.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF94A3B8),
                        ),
                        onPressed: () {
                          _controlador_busqueda_asistencia.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // 2. Píldoras horizontales seleccionables de meses
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _MESES_DISPONIBLES.map((mes) {
                  final seleccionado =
                      _mes_seleccionado_asistencia.toLowerCase() ==
                          mes.toLowerCase();
                  final etiqueta = mes == "todos" ? "Todos los meses" : mes;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(etiqueta),
                      selected: seleccionado,
                      onSelected: (_) {
                        setState(() {
                          _mes_seleccionado_asistencia = mes;
                          if (mes != "todos") {
                            _controlador_busqueda_asistencia.clear();
                          }
                        });
                      },
                      selectedColor: BumandColores.AZUL_DIACONIA,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color:
                            seleccionado ? Colors.white : const Color(0xFF475569),
                        fontWeight:
                            seleccionado ? FontWeight.bold : FontWeight.w600,
                        fontSize: 12,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
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

          // 3. Contenido según filtro
          Expanded(
            child: extractos_async.when(
              data: (lista_extractos) {
                final todos = lista_extractos.isNotEmpty
                    ? lista_extractos
                    : ref.read(asistencia_repositorio_proveedor).generarExtractosLocales();

                final query = _controlador_busqueda_asistencia.text.trim().toLowerCase();

                List<ExtractoMensualAsistencia> filtrados;
                if (query.isNotEmpty) {
                  filtrados = todos.where((e) {
                    return e.mes_nombre.toLowerCase().contains(query) ||
                        e.mes_corto.toLowerCase().contains(query);
                  }).toList();
                } else if (_mes_seleccionado_asistencia != "todos") {
                  filtrados = todos.where((e) {
                    return e.mes_corto.toLowerCase() ==
                        _mes_seleccionado_asistencia.toLowerCase();
                  }).toList();
                } else {
                  filtrados = todos;
                }

                // Caso A: Sin resultados de búsqueda
                if (filtrados.isEmpty) {
                  return ListView(
                    padding: const EdgeInsets.all(32),
                    children: [
                      const SizedBox(height: 20),
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          "No se encontraron registros para '$query'",
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          "Verifica el nombre del mes o selecciona 'Todos los meses'.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _controlador_busqueda_asistencia.clear();
                            setState(() => _mes_seleccionado_asistencia = "todos");
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text("Ver todos los meses"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: BumandColores.AZUL_DIACONIA,
                            side: const BorderSide(
                              color: BumandColores.AZUL_DIACONIA,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Caso B: Mes Único Seleccionado o Tecleado (ej. Mayo) -> Extracto bancario completo en pantalla
                if (filtrados.length == 1 &&
                    (_mes_seleccionado_asistencia != "todos" || query.isNotEmpty)) {
                  return _construirVistaMesUnicoConExtracto(filtrados.first);
                }

                // Caso C: Lista de Meses (Todos los meses o coincidencia múltiple)
                final total_horas_gestion = todos.fold<double>(
                  0.0,
                  (acc, e) => acc + e.horas_totales,
                );

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filtrados.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              BumandColores.AZUL_DIACONIA,
                              BumandColores.azulMarinoSecundario,
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
                            _kpiMetricaBlanco(
                              "${total_horas_gestion.toStringAsFixed(1)} h",
                              "Horas Gestión",
                              Icons.timer_outlined,
                            ),
                            Container(
                              height: 36,
                              width: 1,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            _kpiMetricaBlanco(
                              "36.00 h",
                              "Meta Mensual",
                              Icons.verified_outlined,
                            ),
                            Container(
                              height: 36,
                              width: 1,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            _kpiMetricaBlanco(
                              "${todos.length} meses",
                              "Meses Registrados",
                              Icons.calendar_month_outlined,
                            ),
                          ],
                        ),
                      );
                    }

                    final item = filtrados[i - 1];
                    return _construirTarjetaMensualAsistencia(item);
                  },
                );
              },
              loading: () => CargandoSkeleton.lista(cantidad: 4, alto_item: 120),
              error: (err, _) => ErrorWidgetPersonalizado(
                mensaje: "Error al cargar extractos mensuales",
                detalles: [err.toString()],
                alReintentar: () => ref.invalidate(extractos_mensuales_proveedor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Despliega directamente el extracto bancario completo del mes seleccionado
  Widget _construirVistaMesUnicoConExtracto(ExtractoMensualAsistencia extracto) {
    List<MovimientoExtractoAsistencia> movimientos = extracto.movimientos;
    if (_filtro_actividad_inline != "todos") {
      movimientos = movimientos.where((m) {
        if (_filtro_actividad_inline == "practicas") {
          return m.tipo == "practicas" || m.actividad.toLowerCase().contains("práctica");
        }
        if (_filtro_actividad_inline == "liderazgo") {
          return m.tipo == "liderazgo" || m.actividad.toLowerCase().contains("líder");
        }
        if (_filtro_actividad_inline == "servicio") {
          return m.tipo == "servicio" || m.actividad.toLowerCase().contains("servicio");
        }
        return m.tipo == _filtro_actividad_inline;
      }).toList();
    }

    final horas = extracto.horas_totales;
    const meta = 36.0;
    final cumplio = horas >= meta;
    final diferencia = horas - meta;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        // Tarjeta Resumen Principal del Mes
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                BumandColores.azulMarinoSecundario,
                BumandColores.AZUL_DIACONIA,
                BumandColores.TURQUESA_DIACONIA,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: BumandColores.azulMarinoSecundario.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
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
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        extracto.mes_nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      extracto.estado,
                      style: TextStyle(
                        color: cumplio
                            ? const Color(0xFF6EE7B7)
                            : BumandColores.AMARILLO_RADIANTE,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                "TOTAL DE HORAS REALIZADAS EN EL MES",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "${horas.toStringAsFixed(2)} hrs",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),
              Divider(
                color: Colors.white.withValues(alpha: 0.25),
                height: 1,
                thickness: 1,
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "META MENSUAL REGLAMENTARIA (36.00 hrs)",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          cumplio
                              ? "+${diferencia.toStringAsFixed(2)} hrs · ${extracto.porcentaje_cumplido}% Cumplido"
                              : "En progreso · Faltan ${(meta - horas).toStringAsFixed(2)} hrs",
                          style: const TextStyle(
                            color: BumandColores.AMARILLO_RADIANTE,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${extracto.jornadas_totales} días",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${extracto.tasa_puntualidad}% punt.",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Barra de encabezado del extracto diario ("encimita nomás")
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Extracto diario de entradas y salidas",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  "Mostrando ${movimientos.length} de ${extracto.jornadas_totales} jornadas",
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                DetalleExtractoAsistenciaPantalla.navegar(
                  context,
                  extracto: extracto,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Pantalla completa",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: BumandColores.AZUL_DIACONIA,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 13,
                      color: BumandColores.AZUL_DIACONIA,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Filtros por actividad inline
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              {"id": "todos", "etiqueta": "Todos"},
              {"id": "practicas", "etiqueta": "Prácticas"},
              {"id": "liderazgo", "etiqueta": "Escuela de Líderes"},
              {"id": "servicio", "etiqueta": "Servicio"},
            ].map((op) {
              final sel = _filtro_actividad_inline == op["id"];
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(op["etiqueta"]!),
                  selected: sel,
                  onSelected: (_) {
                    setState(() => _filtro_actividad_inline = op["id"]!);
                  },
                  selectedColor: BumandColores.AZUL_DIACONIA,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: sel ? Colors.white : const Color(0xFF475569),
                    fontWeight: sel ? FontWeight.bold : FontWeight.w600,
                    fontSize: 11.5,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: sel
                          ? BumandColores.AZUL_DIACONIA
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 10),

        // Tabla de movimientos bancaria
        _construirTablaMovimientosInline(movimientos),
      ],
    );
  }

  /// Tabla / Lista bancaria de movimientos diarios del mes
  Widget _construirTablaMovimientosInline(
    List<MovimientoExtractoAsistencia> movimientos,
  ) {
    if (movimientos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 36,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            const Text(
              "Sin registros para este filtro",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Cabecera bancaria
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      "FECHA",
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "DETALLE Y HORARIO (ENTRADA → SALIDA)",
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    width: 82,
                    child: Text(
                      "HORAS / ACUM.",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filas diarias
            for (int i = 0; i < movimientos.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF1F5F9),
                  indent: 12,
                  endIndent: 12,
                ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    DetalleAsistenciaModal.mostrar(
                      context,
                      titulo:
                          "Jornada ${movimientos[i].fecha_formateada} · ${movimientos[i].dia_semana}",
                      subtitulo: movimientos[i].actividad,
                      tipo_registro: movimientos[i].actividad,
                      lugar: movimientos[i].lugar,
                      ingreso: movimientos[i].hora_entrada,
                      salida: movimientos[i].hora_salida,
                      horas_trabajadas:
                          "${movimientos[i].horas_dia.toStringAsFixed(2)} hrs",
                      distancia:
                          "${movimientos[i].distancia_gps.toInt()} m",
                      dentro_geocerca: movimientos[i].dentro_geocerca,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        // Columna 1: Badge de fecha
                        Container(
                          width: 50,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                movimientos[i].fecha_formateada,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                movimientos[i].dia_semana,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Columna 2: Actividad, sede y píldora de horario
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movimientos[i].actividad,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                movimientos[i].lugar,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.circle,
                                      size: 6,
                                      color: Color(0xFF10B981),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      movimientos[i].hora_entrada,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        "→",
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.circle,
                                      size: 6,
                                      color: BumandColores.AMARILLO_RADIANTE,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      movimientos[i].hora_salida,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Columna 3: Horas y Acumulado
                        SizedBox(
                          width: 82,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "+${movimientos[i].horas_dia.toStringAsFixed(2)} hrs",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: BumandColores.AZUL_DIACONIA,
                                ),
                              ),
                              Text(
                                "Acum: ${movimientos[i].horas_acumuladas.toStringAsFixed(2)} h",
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Tarjeta mensual de resumen cuando se listan todos los meses
  Widget _construirTarjetaMensualAsistencia(ExtractoMensualAsistencia item) {
    final previas = item.movimientos.take(2).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            DetalleExtractoAsistenciaPantalla.navegar(
              context,
              extracto: item,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: BumandColores.AZUL_DIACONIA,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          item.mes_nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5,
                            color: BumandColores.NEGRO,
                          ),
                        ),
                      ],
                    ),
                    _chipEstadoMes(item.estado),
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
                            "Total de Horas",
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${item.horas_totales.toStringAsFixed(2)} hrs",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: BumandColores.AZUL_DIACONIA,
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
                            "Días Asistidos",
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${item.jornadas_totales} jornadas",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1E293B),
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
                            "Puntualidad",
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${item.tasa_puntualidad}%",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (previas.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 10),
                  Text(
                    "ÚLTIMAS JORNADAS DEL MES",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final mov in previas)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${mov.fecha_formateada} ${mov.dia_semana}",
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              mov.actividad,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "${mov.hora_entrada} → ${mov.hora_salida}",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "+${mov.horas_dia.toStringAsFixed(1)}h",
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: BumandColores.AZUL_DIACONIA,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_rounded,
                          size: 16,
                          color: BumandColores.AZUL_DIACONIA,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Ver extracto completo de entradas y salidas (${item.jornadas_totales} días)",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: BumandColores.AZUL_DIACONIA,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: BumandColores.AZUL_DIACONIA,
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

  Widget _chipEstadoMes(String estado) {
    final cumplida = estado.toUpperCase().contains("CUMPLIDA");
    final color_fondo =
        cumplida ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7);
    final color_borde =
        cumplida ? const Color(0xFF10B981) : BumandColores.AMARILLO_RADIANTE;
    final color_texto =
        cumplida ? const Color(0xFF047857) : const Color(0xFF92400E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color_fondo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color_borde),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            cumplida ? Icons.check_circle_rounded : Icons.pending_rounded,
            size: 12,
            color: color_texto,
          ),
          const SizedBox(width: 4),
          Text(
            estado,
            style: TextStyle(
              color: color_texto,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
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
                    monto_total: 28.0,
                    monto_devolucion: 22.40,
                    observaciones: "Declaración mensual aprobada por Diaconía IFD",
                    recorridos: [
                      RecorridoModelo(
                        id: 1,
                        fecha: DateTime(2026, 10, 2),
                        tramo: "ida",
                        origen: "Av. Buenos Aires",
                        destino: "Oficina Central",
                        tarifa: 2.50,
                      ),
                      RecorridoModelo(
                        id: 2,
                        fecha: DateTime(2026, 10, 2),
                        tramo: "vuelta",
                        origen: "Oficina Central",
                        destino: "Av. Buenos Aires",
                        tarifa: 2.50,
                      ),
                      RecorridoModelo(
                        id: 3,
                        fecha: DateTime(2026, 10, 4),
                        tramo: "ida",
                        origen: "Av. Buenos Aires",
                        destino: "Oficina Central",
                        tarifa: 2.50,
                      ),
                      RecorridoModelo(
                        id: 4,
                        fecha: DateTime(2026, 10, 4),
                        tramo: "vuelta",
                        origen: "Oficina Central",
                        destino: "Av. Buenos Aires",
                        tarifa: 2.50,
                      ),
                      RecorridoModelo(
                        id: 5,
                        fecha: DateTime(2026, 10, 6),
                        tramo: "ida",
                        origen: "Av. Buenos Aires",
                        destino: "Oficina Central",
                        tarifa: 2.50,
                      ),
                      RecorridoModelo(
                        id: 6,
                        fecha: DateTime(2026, 10, 9),
                        tramo: "ida",
                        origen: "Av. Buenos Aires",
                        destino: "Oficina Central",
                        tarifa: 2.50,
                      ),
                      RecorridoModelo(
                        id: 7,
                        fecha: DateTime(2026, 10, 9),
                        tramo: "vuelta",
                        origen: "Oficina Central",
                        destino: "Av. Buenos Aires",
                        tarifa: 2.50,
                      ),
                      RecorridoModelo(
                        id: 8,
                        fecha: DateTime(2026, 10, 11),
                        tramo: "ida",
                        origen: "Av. Buenos Aires",
                        destino: "Oficina Central",
                        tarifa: 2.50,
                      ),
                      RecorridoModelo(
                        id: 9,
                        fecha: DateTime(2026, 10, 11),
                        tramo: "vuelta",
                        origen: "Oficina Central",
                        destino: "Av. Buenos Aires",
                        tarifa: 2.50,
                      ),
                      RecorridoModelo(
                        id: 10,
                        fecha: DateTime(2026, 10, 13),
                        tramo: "ida",
                        origen: "Av. Buenos Aires",
                        destino: "Oficina Central",
                        tarifa: 2.50,
                      ),
                      RecorridoModelo(
                        id: 11,
                        fecha: DateTime(2026, 10, 16),
                        tramo: "ida",
                        origen: "Av. Buenos Aires",
                        destino: "Oficina Central",
                        tarifa: 2.50,
                      ),
                    ],
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
                        BumandColores.azulMarinoSecundario,
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
                    onTap: () {
                      DetalleHistorialPasajePantalla.navegar(
                        context,
                        solicitud: item,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
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
                                  _etiquetaEstadoPasaje(item.estado),
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
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.alt_route_rounded,
                                    size: 16,
                                    color: BumandColores.AZUL_DIACONIA,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.recorridos.isNotEmpty
                                        ? "Ver paradas declaradas (${item.recorridos.length})"
                                        : "Ver paradas declaradas",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: BumandColores.AZUL_DIACONIA,
                                    ),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: BumandColores.AZUL_DIACONIA,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
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
    switch (estado.toLowerCase()) {
      case "aprobado":
      case "aprobado_administracion":
      case "pagado":
        return const Color(0xFF10B981);
      case "revisado_supervisor":
      case "enviado":
      case "en revisión":
      case "en revision":
        return BumandColores.AZUL_DIACONIA;
      case "pendiente":
        return const Color(0xFFD97706);
      case "observado":
      case "rechazado":
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _etiquetaEstadoPasaje(String estado) {
    switch (estado.toLowerCase()) {
      case "pendiente":
        return "1. PENDIENTE";
      case "revisado_supervisor":
        return "2. REVISADO SUPERVISOR";
      case "aprobado_administracion":
        return "✓ APROBADO ADMIN";
      case "aprobado":
        return "APROBADO";
      case "pagado":
        return "PAGADO";
      case "rechazado":
      case "observado":
        return "CON OBSERVACIONES";
      default:
        return estado.toUpperCase();
    }
  }

  Widget _construirPestanaMultas() {
    final multas_ejemplo = [
      {
        "fecha": "Viernes 23/10/2026",
        "hora_llegada": "15:00",
        "hora_limite": "14:35",
        "minutos_penalidad": 0,
        "tramo": "Permiso Aprobado",
        "monto_bs": 0.0,
        "motivo": "Emergencia médica con receta y certificado — Aprobado por Administración",
        "estado": "Sin Multa (Permiso Aprobado por Administración)",
        "permiso_aprobado": true,
      },
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
                          color: (inc["monto_bs"] as double) == 0.0
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (inc["monto_bs"] as double) == 0.0
                                ? const Color(0xFF10B981)
                                : const Color(0xFFFCA5A5),
                          ),
                        ),
                        child: Text(
                          (inc["monto_bs"] as double) == 0.0
                              ? "Sin Multa (Permiso Aprobado)"
                              : "Bs. ${(inc["monto_bs"] as double).toStringAsFixed(2)}",
                          style: TextStyle(
                            color: (inc["monto_bs"] as double) == 0.0
                                ? const Color(0xFF047857)
                                : const Color(0xFFB91C1C),
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

}
