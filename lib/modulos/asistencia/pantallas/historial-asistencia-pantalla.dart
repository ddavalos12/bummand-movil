import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../../../widgets-comunes/cargando-skeleton.dart';
import '../../../widgets-comunes/error-widget-personalizado.dart';
import '../../justificaciones/servicios/justificaciones-servicio.dart';
import '../../justificaciones/pantallas/permisos-pantalla.dart';
import '../../pasajes/pantallas/detalle-historial-pasaje-pantalla.dart';
import '../../pasajes/proveedores/pasajes-proveedor.dart';
import '../proveedores/asistencia-proveedor.dart';
import '../widgets/detalle_asistencia_modal.dart';
import '../repositorios/asistencia-repositorio.dart';
import 'detalle-extracto-asistencia-pantalla.dart';

class HistorialAsistenciaPantalla extends ConsumerStatefulWidget {
  final int indice_inicial;
  const HistorialAsistenciaPantalla({super.key, this.indice_inicial = 0});

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

  @override
  void initState() {
    super.initState();
    _controlador_tabs = TabController(length: 4, vsync: this, initialIndex: widget.indice_inicial.clamp(0, 3));
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
              ref.invalidate(mis_justificaciones_proveedor);
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
                  icon: Icon(Icons.assignment_late_outlined, size: 20),
                  text: "Permisos",
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
                _construirPestanaPermisos(),
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
                "HORAS DE PRÁCTICAS PREPROFESIONALES",
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
                          "META MENSUAL PRÁCTICAS (36.00 hrs)",
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
                    final es_lideres = movimientos[i].tipo.contains("lider") ||
                        movimientos[i].actividad.toLowerCase().contains("lider") ||
                        movimientos[i].actividad.toLowerCase().contains("líder");
                    DetalleAsistenciaModal.mostrar(
                      context,
                      titulo:
                          "Jornada ${movimientos[i].fecha_formateada} · ${movimientos[i].dia_semana}",
                      subtitulo: movimientos[i].actividad,
                      tipo_registro: movimientos[i].actividad,
                      lugar: movimientos[i].lugar,
                      ingreso: movimientos[i].hora_entrada,
                      salida: movimientos[i].hora_salida,
                      horas_trabajadas: es_lideres
                          ? "0.00 hrs (No suma horas a prácticas)"
                          : "${movimientos[i].horas_dia.toStringAsFixed(2)} hrs",
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
                          width: 92,
                          child: Builder(
                            builder: (context) {
                              final es_lideres = movimientos[i].tipo.contains("lider") ||
                                  movimientos[i].actividad.toLowerCase().contains("lider") ||
                                  movimientos[i].actividad.toLowerCase().contains("líder");
                              if (es_lideres) {
                                final puntual = movimientos[i].es_puntual;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      puntual ? "✓ Asistencia" : "⚠ Con multa",
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: puntual ? const Color(0xFF059669) : const Color(0xFFD97706),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      puntual ? "Sin multa · 0 hrs" : "Sujeto a multa",
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        color: puntual ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return Column(
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
                              );
                            },
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
                          Builder(
                            builder: (context) {
                              final es_lideres = mov.tipo.contains("lider") ||
                                  mov.actividad.toLowerCase().contains("lider") ||
                                  mov.actividad.toLowerCase().contains("líder");
                              if (es_lideres) {
                                return Text(
                                  mov.es_puntual ? "✓ Asistencia" : "⚠ Multa",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: mov.es_puntual ? const Color(0xFF059669) : const Color(0xFFD97706),
                                  ),
                                );
                              }
                              return Text(
                                "+${mov.horas_dia.toStringAsFixed(1)}h",
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: BumandColores.AZUL_DIACONIA,
                                ),
                              );
                            },
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

  String _filtro_permiso = 'todos';

  Widget _construirPestanaPermisos() {
    final solicitudes_async = ref.watch(mis_justificaciones_proveedor);

    return RefreshIndicator(
      color: BumandColores.NARANJA_OSCURO,
      backgroundColor: BumandColores.AZUL_DIACONIA,
      onRefresh: () async => ref.invalidate(mis_justificaciones_proveedor),
      child: solicitudes_async.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                "Error al cargar solicitudes de permisos: $err",
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
          ],
        ),
        data: (resultado) {
          final solicitudes = resultado.datos ?? [];
          final filtradas = _filtrarSolicitudesPermisos(solicitudes);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
            children: [
              // 1. Tarjeta informativa del flujo institucional de 2 niveles
              _construirTarjetaInformativaPermisos(),
              const SizedBox(height: 12),

              // 2. Filtros de estado rápido
              _construirFiltrosPermisos(),
              const SizedBox(height: 12),

              // 3. Botón para radicar nuevo permiso
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BumandColores.AZUL_DIACONIA,
                    side: const BorderSide(color: BumandColores.AZUL_DIACONIA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PermisosPantalla(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    "Radicar Nuevo Permiso / Justificación",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 4. Listado o Estado Vacío
              if (filtradas.isEmpty)
                _construirEstadoVacioPermisos()
              else
                for (final s in filtradas) _construirTarjetaSolicitudPermiso(s),
            ],
          );
        },
      ),
    );
  }

  Widget _construirTarjetaInformativaPermisos() {
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

  Widget _construirFiltrosPermisos() {
    final opciones = [
      ('todos', 'Todos'),
      ('pendiente', '1. Pendientes'),
      ('revisado_supervisor', '2. Revisados'),
      ('aprobado_administracion', 'Aprobados'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: opciones.map((op) {
          final seleccionado = _filtro_permiso == op.$1;
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
                if (val) setState(() => _filtro_permiso = op.$1);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Map<String, dynamic>> _filtrarSolicitudesPermisos(
      List<Map<String, dynamic>> lista) {
    if (_filtro_permiso == 'todos') return lista;
    return lista.where((s) => s['estado'] == _filtro_permiso).toList();
  }

  Widget _construirEstadoVacioPermisos() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          const Text(
            "Sin solicitudes de permisos",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: BumandColores.NEGRO),
          ),
          const SizedBox(height: 6),
          Text(
            "Tus solicitudes radicadas aparecerán aquí con seguimiento en tiempo real de aprobación.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaSolicitudPermiso(Map<String, dynamic> s) {
    final estado = s['estado']?.toString() ?? 'pendiente';
    final tipo = s['tipo_incidencia']?.toString() ?? 'otro';
    final fecha = s['fecha_incidencia']?.toString() ?? '';
    final motivo = s['motivo']?.toString() ?? 'Sin motivo especificado';
    final descripcion = s['descripcion']?.toString() ?? '';
    final archivo = s['nombre_archivo_prueba']?.toString();
    final obs_sup = s['observacion_supervisor']?.toString();
    final obs_adm = s['observacion_admin']?.toString();
    final fecha_sup = s['fecha_revision_supervisor']?.toString();
    final fecha_adm = s['fecha_aprobacion_admin']?.toString();

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
      color_tipo = BumandColores.AZUL_DIACONIA;
    } else {
      tipo_legible = 'Otro';
      color_tipo = Colors.teal;
    }

    String estado_legible = '1. Pendiente de Revisión';
    Color color_estado = const Color(0xFFD97706);
    Color fondo_estado = const Color(0xFFFEF3C7);
    IconData icono_estado = Icons.hourglass_top_rounded;

    if (estado == 'revisado_supervisor') {
      estado_legible = '2. Revisado por Supervisor';
      color_estado = const Color(0xFF0284C7);
      fondo_estado = const Color(0xFFE0F2FE);
      icono_estado = Icons.supervised_user_circle_rounded;
    } else if (permiso_aprobado) {
      estado_legible = '3. Aprobado por Administración';
      color_estado = const Color(0xFF059669);
      fondo_estado = const Color(0xFFD1FAE5);
      icono_estado = Icons.check_circle_rounded;
    } else if (estado.contains('rechazado')) {
      estado_legible = 'Rechazado';
      color_estado = const Color(0xFFDC2626);
      fondo_estado = const Color(0xFFFEE2E2);
      icono_estado = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _BORDE),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera: Tipo + Fecha
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color_tipo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
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
              Text(
                fecha,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Motivo
          Text(
            motivo,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          if (descripcion.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              descripcion,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF475569),
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Archivo probatorio adjunto
          if (archivo != null && archivo.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_rounded,
                    size: 16,
                    color: BumandColores.AZUL_DIACONIA,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      archivo,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Text(
                    "Respaldo",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: BumandColores.AZUL_DIACONIA,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Estado del flujo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: fondo_estado,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono_estado, size: 14, color: color_estado),
                const SizedBox(width: 6),
                Text(
                  estado_legible,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: color_estado,
                  ),
                ),
              ],
            ),
          ),

          // Observaciones de supervisor y admin
          if (obs_sup != null && obs_sup.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Revisión Supervisor${fecha_sup != null ? ' ($fecha_sup)' : ''}:",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0369A1),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    obs_sup,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
                  ),
                ],
              ),
            ),
          ],

          if (obs_adm != null && obs_adm.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Aprobación Administración${fecha_adm != null ? ' ($fecha_adm)' : ''}:",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    obs_adm,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF166534)),
                  ),
                ],
              ),
            ),
          ],

          // Badge de Exención de Multa de Viernes
          if (es_actividad_viernes && permiso_aprobado) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_rounded, size: 14, color: Color(0xFF047857)),
                  SizedBox(width: 6),
                  Text(
                    "Exención total de multa de viernes aplicada",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF047857),
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

  Widget _construirPestanaPasajes() {
    final solicitudes_async = ref.watch(solicitudes_pasajes_proveedor);

    return RefreshIndicator(
      color: BumandColores.NARANJA_OSCURO,
      backgroundColor: BumandColores.AZUL_DIACONIA,
      onRefresh: () async => ref.invalidate(solicitudes_pasajes_proveedor),
      child: solicitudes_async.when(
        data: (solicitudes) {
          if (solicitudes.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 60),
                Icon(
                  Icons.directions_bus_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Sin solicitudes de pasajes",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: BumandColores.NEGRO,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Aún no registras solicitudes de pasajes para este periodo.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            );
          }
          final lista = solicitudes;

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
    final historial_async = ref.watch(historial_asistencia_proveedor);

    return RefreshIndicator(
      color: BumandColores.NARANJA_OSCURO,
      backgroundColor: BumandColores.AZUL_DIACONIA,
      onRefresh: () async => ref.invalidate(historial_asistencia_proveedor),
      child: historial_async.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                "Error al cargar registro de incidencias: $err",
                style: TextStyle(color: Colors.red.shade800),
              ),
            ),
          ],
        ),
        data: (resultado) {
          final asistencias = resultado.datos ?? [];
          final multas_reales = <Map<String, dynamic>>[];

          for (final a in asistencias) {
            final int minutos = (a['minutos_tarde'] as num?)?.toInt() ??
                (a['minutos_retraso'] as num?)?.toInt() ??
                (a['minutos_penalidad'] as num?)?.toInt() ??
                0;
            final double monto = (a['multa'] as num?)?.toDouble() ??
                (a['monto_bs'] as num?)?.toDouble() ??
                (minutos > 0 ? _calcularMultaPorMinutos(minutos) : 0.0);
            final bool tiene_permiso =
                a['justificacion_id'] != null || a['permiso_aprobado'] == true;

            if (minutos > 0 || monto > 0 || tiene_permiso) {
              multas_reales.add({
                'fecha': a['fecha'] ??
                    a['fecha_asistencia'] ??
                    'Fecha de asistencia',
                'hora_llegada':
                    a['hora_llegada'] ?? a['hora_entrada'] ?? '--:--',
                'hora_limite': a['hora_limite'] ?? '14:35',
                'minutos_penalidad': tiene_permiso ? 0 : minutos,
                'tramo': tiene_permiso
                    ? 'Permiso Aprobado'
                    : '$minutos min de retraso',
                'monto_bs': tiene_permiso ? 0.0 : monto,
                'motivo': a['motivo'] ??
                    (tiene_permiso
                        ? 'Permiso oficial aprobado por Administración'
                        : 'Retraso en asistencia a Escuela de Líderes'),
                'estado': tiene_permiso
                    ? 'Sin Multa (Permiso Aprobado)'
                    : 'Deducido en planilla de pasajes',
                'permiso_aprobado': tiene_permiso,
              });
            }
          }

          if (multas_reales.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 60),
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 64,
                  color: Colors.green.shade500,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Sin multas ni incidencias",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: BumandColores.NEGRO,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "¡Felicidades! Mantienes un registro ejemplar sin sanciones registradas.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            );
          }

          final total_multas_bs = multas_reales.fold<double>(
            0.0,
            (acc, m) => acc + (m["monto_bs"] as double),
          );
          final total_minutos = multas_reales.fold<int>(
            0,
            (acc, m) => acc + (m["minutos_penalidad"] as int),
          );

          return ListView(
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
              for (final inc in multas_reales)
                _construirTarjetaIncidencia(inc),
            ],
          );
        },
      ),
    );
  }

  Widget _construirTarjetaIncidencia(Map<String, dynamic> inc) {
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
