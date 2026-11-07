import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../proveedores/asistencia-proveedor.dart';
import '../repositorios/asistencia-repositorio.dart';
import '../widgets/detalle_asistencia_modal.dart';

/// Pantalla de Extracto Mensual Bancario de Asistencia.
/// Presenta el desglose consolidado de horas del mes, meta reglamentaria,
/// y la lista de movimientos diarios con horas de entrada, salida y saldo acumulado.
class DetalleExtractoAsistenciaPantalla extends ConsumerStatefulWidget {
  final ExtractoMensualAsistencia? extracto_inicial;
  final String? mes_inicial;

  const DetalleExtractoAsistenciaPantalla({
    super.key,
    this.extracto_inicial,
    this.mes_inicial,
  });

  static Future<void> navegar(
    BuildContext context, {
    ExtractoMensualAsistencia? extracto,
    String? mes_inicial,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalleExtractoAsistenciaPantalla(
          extracto_inicial: extracto,
          mes_inicial: mes_inicial,
        ),
      ),
    );
  }

  @override
  ConsumerState<DetalleExtractoAsistenciaPantalla> createState() =>
      _DetalleExtractoAsistenciaPantallaState();
}

class _DetalleExtractoAsistenciaPantallaState
    extends ConsumerState<DetalleExtractoAsistenciaPantalla> {
  late ExtractoMensualAsistencia _extracto;
  List<ExtractoMensualAsistencia> _todos_los_extractos = [];
  String _filtro_actividad = "todos";
  bool _inicializado = false;

  @override
  void initState() {
    super.initState();
    if (widget.extracto_inicial != null) {
      _extracto = widget.extracto_inicial!;
    } else {
      final repo = ref.read(asistencia_repositorio_proveedor);
      _extracto = repo.obtenerExtractoLocalPorMes(
        widget.mes_inicial ?? "Mayo 2026",
      );
    }
  }

  void _sincronizarConLista(List<ExtractoMensualAsistencia> lista) {
    if (!_inicializado) {
      _todos_los_extractos = lista;
      final coincide = lista.firstWhere(
        (e) => e.mes_id == _extracto.mes_id,
        orElse: () => _extracto,
      );
      _extracto = coincide;
      _inicializado = true;
    } else {
      _todos_los_extractos = lista;
    }
  }

  void _cambiarMesRelativo(int direccion) {
    if (_todos_los_extractos.isEmpty) return;
    final indice_actual = _todos_los_extractos.indexWhere(
      (e) => e.mes_id == _extracto.mes_id,
    );
    if (indice_actual == -1) return;

    final nuevo_indice = indice_actual + direccion;
    if (nuevo_indice >= 0 && nuevo_indice < _todos_los_extractos.length) {
      setState(() {
        _extracto = _todos_los_extractos[nuevo_indice];
        _filtro_actividad = "todos";
      });
    }
  }

  List<MovimientoExtractoAsistencia> _filtrarMovimientos() {
    if (_filtro_actividad == "todos") return _extracto.movimientos;
    return _extracto.movimientos.where((m) {
      if (_filtro_actividad == "practicas") {
        return m.tipo == "practicas" || m.actividad.toLowerCase().contains("práctica");
      }
      if (_filtro_actividad == "liderazgo") {
        return m.tipo == "liderazgo" || m.actividad.toLowerCase().contains("líder");
      }
      if (_filtro_actividad == "servicio") {
        return m.tipo == "servicio" || m.actividad.toLowerCase().contains("servicio");
      }
      return m.tipo == _filtro_actividad;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final extractos_async = ref.watch(extractos_mensuales_proveedor);

    extractos_async.whenData((lista) {
      _sincronizarConLista(lista);
    });

    final indice_actual = _todos_los_extractos.indexWhere(
      (e) => e.mes_id == _extracto.mes_id,
    );
    final tiene_anterior = indice_actual != -1 &&
        indice_actual < _todos_los_extractos.length - 1; // orden descendente
    final tiene_siguiente = indice_actual > 0;

    final movimientos_filtrados = _filtrarMovimientos();

    return Scaffold(
      backgroundColor: BumandColores.AZUL_DIACONIA,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera Institucional Diaconía FRIF-IFD
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BumandColores.azulMarinoSecundario,
                    BumandColores.AZUL_DIACONIA,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(10, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Extracto Mensual de Horas",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Periodo: ${_extracto.mes_nombre}",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Text(
                          _extracto.estado,
                          style: TextStyle(
                            color: _extracto.horas_totales >= _extracto.meta_mensual
                                ? const Color(0xFF6EE7B7)
                                : BumandColores.AMARILLO_RADIANTE,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Selector rápido entre meses (< Mes anterior | Mes siguiente >)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: tiene_anterior
                              ? () => _cambiarMesRelativo(1)
                              : null,
                          icon: Icon(
                            Icons.chevron_left_rounded,
                            size: 18,
                            color: tiene_anterior
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                          ),
                          label: Text(
                            "Mes anterior",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: tiene_anterior
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_outlined,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _extracto.mes_nombre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: tiene_siguiente
                              ? () => _cambiarMesRelativo(-1)
                              : null,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Mes siguiente",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: tiene_siguiente
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.35),
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: tiene_siguiente
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contenedor principal estilo hoja con curvas superiores de 28px
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: BumandColores.fondo,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
                  children: [
                    // Tarjeta Bancaria Principal (Gradiente #035683 -> #007BBE -> #00ABBD)
                    _construirTarjetaBancariaPrincipal(),

                    const SizedBox(height: 20),

                    // Filtros por actividad dentro del mes
                    _construirChipsActividad(),

                    const SizedBox(height: 18),

                    // Encabezado de sección
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Movimientos diarios del mes",
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Entradas, salidas y saldo progresivo",
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
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
                            color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "${movimientos_filtrados.length} jornadas",
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: BumandColores.AZUL_DIACONIA,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Tabla / Lista estilo extracto bancario limpio
                    _construirTablaMovimientos(movimientos_filtrados),

                    const SizedBox(height: 20),

                    // Nota institucional inferior
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 20,
                            color: BumandColores.AZUL_DIACONIA,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Extracto oficial del Programa BUMAND · Diaconía FRIF-IFD. "
                              "Toda marcación cuenta con validación geocercada y registro en auditoría.",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTarjetaBancariaPrincipal() {
    final horas = _extracto.horas_totales;
    const meta = 36.0;
    final cumplio = horas >= meta;
    final diferencia = horas - meta;
    final porcentaje = _extracto.porcentaje_cumplido;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            BumandColores.azulMarinoSecundario, // #035683
            BumandColores.AZUL_DIACONIA, // #007BBE
            BumandColores.TURQUESA_DIACONIA, // #00ABBD
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: BumandColores.azulMarinoSecundario.withValues(alpha: 0.32),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TOTAL DE HORAS REALIZADAS EN EL MES",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "${horas.toStringAsFixed(2)} hrs",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _extracto.mes_corto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Divider(
            color: Colors.white.withValues(alpha: 0.25),
            height: 1,
            thickness: 1,
          ),

          const SizedBox(height: 16),

          // Fila inferior tipo estado de cuenta bancario
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "META MENSUAL REGLAMENTARIA (36.00 hrs)",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      cumplio
                          ? "+${diferencia.toStringAsFixed(2)} hrs · $porcentaje% Cumplido"
                          : "En progreso · Faltan ${(meta - horas).toStringAsFixed(2)} hrs · $porcentaje%",
                      style: const TextStyle(
                        color: BumandColores.AMARILLO_RADIANTE, // #FFB600
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${_extracto.jornadas_totales} días asistidos",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${_extracto.tasa_puntualidad}% puntualidad",
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
    );
  }

  Widget _construirChipsActividad() {
    final opciones = [
      {"id": "todos", "etiqueta": "Todos"},
      {"id": "practicas", "etiqueta": "Prácticas"},
      {"id": "liderazgo", "etiqueta": "Escuela de Líderes"},
      {"id": "servicio", "etiqueta": "Servicio"},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: opciones.map((op) {
          final seleccionado = _filtro_actividad == op["id"];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(op["etiqueta"]!),
              selected: seleccionado,
              onSelected: (_) {
                setState(() => _filtro_actividad = op["id"]!);
              },
              selectedColor: BumandColores.AZUL_DIACONIA,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: seleccionado ? Colors.white : const Color(0xFF475569),
                fontWeight: seleccionado ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
    );
  }

  Widget _construirTablaMovimientos(List<MovimientoExtractoAsistencia> movimientos) {
    if (movimientos.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 42,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 10),
            const Text(
              "Sin registros para este filtro",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Intenta seleccionando otra actividad o 'Todos'.",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // Cabecera bancaria sutil
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      "FECHA",
                      style: TextStyle(
                        fontSize: 10,
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
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    width: 86,
                    child: Text(
                      "HORAS / ACUM.",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10,
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
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Columna 1: Badge de Fecha (04-05 arriba, Lun abajo)
                        Container(
                          width: 52,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                movimientos[i].fecha_formateada,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                movimientos[i].dia_semana,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Columna 2: Centro (Actividad, sede y píldora con horarios)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movimientos[i].actividad,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      movimientos[i].lugar,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              // Píldora legible con horario exacto
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
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
                                      size: 7,
                                      color: Color(0xFF10B981),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Entrada: ${movimientos[i].hora_entrada}",
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
                                      child: Text(
                                        "→",
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.circle,
                                      size: 7,
                                      color: BumandColores.AMARILLO_RADIANTE,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Salida: ${movimientos[i].hora_salida}",
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Columna 3: Horas y Acumulado (columna bancaria derecha)
                        SizedBox(
                          width: 86,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "+${movimientos[i].horas_dia.toStringAsFixed(2)} hrs",
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: BumandColores.AZUL_DIACONIA,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Acum: ${movimientos[i].horas_acumuladas.toStringAsFixed(2)} h",
                                style: const TextStyle(
                                  fontSize: 10.5,
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
}
