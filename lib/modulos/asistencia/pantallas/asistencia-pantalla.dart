import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../../animaciones/animaciones.dart';
import '../modelos/tipo-asistencia.dart';
import '../proveedores/asistencia-proveedor.dart';

class AsistenciaPantalla extends ConsumerStatefulWidget {
  const AsistenciaPantalla({super.key});

  @override
  ConsumerState<AsistenciaPantalla> createState() => _AsistenciaPantallaState();
}

class _AsistenciaPantallaState extends ConsumerState<AsistenciaPantalla>
    with SingleTickerProviderStateMixin {
  static const _FONDO = Color(0xFFEFF3F8);
  static const _BORDE = Color(0xFFE3E9F2);

  String _tipo = TipoAsistencia.practicas.valor;
  Map<String, dynamic>? _lugar_seleccionado;
  bool _mostrar_celebracion = false;

  static const List<Map<String, dynamic>> _AGENCIAS_DIACONIA = [
    {
      "id": 1,
      "nombre": "Oficina Central Diaconía IFD - El Alto",
      "direccion": "Av. Juan Pablo II esq. Calle Sbtte. Jorge Eulert 125, El Alto",
      "latitud": -16.500054,
      "longitud": -68.173455,
      "radio_tolerancia_m": 60.0,
    },
    {
      "id": 2,
      "nombre": "Sucursal La Paz - San Pedro",
      "direccion": "Calle Colombia N° 450, Zona San Pedro, La Paz",
      "latitud": -16.501500,
      "longitud": -68.138200,
      "radio_tolerancia_m": 50.0,
    },
    {
      "id": 3,
      "nombre": "Agencia Chasquipampa",
      "direccion": "Calle 53 esq. Av. Principal Chasquipampa, Zona Sur, La Paz",
      "latitud": -16.541200,
      "longitud": -68.061100,
      "radio_tolerancia_m": 50.0,
    },
    {
      "id": 4,
      "nombre": "Agencia Viacha",
      "direccion": "Plaza Principal José Ballivián N° 85, Viacha",
      "latitud": -16.652100,
      "longitud": -68.301500,
      "radio_tolerancia_m": 60.0,
    },
    {
      "id": 5,
      "nombre": "Agencia Laguna San Pedro",
      "direccion": "Calle Boquerón N° 120 esq. Almirante Grau, La Paz",
      "latitud": -16.502800,
      "longitud": -68.136900,
      "radio_tolerancia_m": 50.0,
    },
    {
      "id": 6,
      "nombre": "Agencia Puente Seco",
      "direccion": "Av. Juan Pablo II, Altura Ceja de El Alto",
      "latitud": -16.512000,
      "longitud": -68.179500,
      "radio_tolerancia_m": 50.0,
    },
    {
      "id": 7,
      "nombre": "Agencia Franz Tamayo",
      "direccion": "Av. Franz Tamayo N° 230, Villa Adela, El Alto",
      "latitud": -16.529800,
      "longitud": -68.192300,
      "radio_tolerancia_m": 50.0,
    },
    {
      "id": 8,
      "nombre": "Agencia Villa Dolores",
      "direccion": "Plaza Juana Azurduy de Padilla N° 40, El Alto",
      "latitud": -16.516500,
      "longitud": -68.161000,
      "radio_tolerancia_m": 50.0,
    },
    {
      "id": 9,
      "nombre": "Agencia Senkata",
      "direccion": "Av. 6 de Marzo Km 14, Senkata, El Alto",
      "latitud": -16.568000,
      "longitud": -68.175000,
      "radio_tolerancia_m": 60.0,
    },
    {
      "id": 10,
      "nombre": "Agencia Río Seco",
      "direccion": "Av. Juan Pablo II, Ex-Tranca Río Seco, El Alto",
      "latitud": -16.488000,
      "longitud": -68.195000,
      "radio_tolerancia_m": 50.0,
    },
    {
      "id": 11,
      "nombre": "Agencia Ciudad Satélite",
      "direccion": "Av. del Policía esq. Calle 14, Ciudad Satélite, El Alto",
      "latitud": -16.518000,
      "longitud": -68.148000,
      "radio_tolerancia_m": 50.0,
    },
  ];

  late final AnimationController _controlador_pulso;
  Position? _posicion_actual;
  bool _escaneando_gps = false;
  bool _dentro_de_geocerca = false;
  double? _distancia_actual_m;
  double _radio_tolerancia_m = 150.0;
  String? _mensaje_error_gps;

  @override
  void initState() {
    super.initState();
    _controlador_pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _escanearUbicacion();
    });
  }

  @override
  void dispose() {
    _controlador_pulso.dispose();
    super.dispose();
  }

  void _mensaje(String texto, {bool es_error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: es_error
            ? Colors.red.shade700
            : BumandColores.TURQUESA_DIACONIA,
      ),
    );
  }

  Future<void> _escanearUbicacion({Map<String, dynamic>? lugar_param}) async {
    if (!mounted) return;
    setState(() {
      _escaneando_gps = true;
      _mensaje_error_gps = null;
    });

    try {
      final repo = ref.read(asistencia_repositorio_proveedor);
      final posicion = await repo.obtenerPosicionActual();
      if (!mounted) return;

      final perfil = ref.read(perfil_proveedor).asData?.value.datos;
      final lugar = lugar_param ?? _lugar_seleccionado ?? perfil?["lugarPractica"];
      _evaluarGeocerca(posicion, lugar);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _escaneando_gps = false;
        _dentro_de_geocerca = false;
        _mensaje_error_gps = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  void _evaluarGeocerca(Position posicion, Map<String, dynamic>? lugar) {
    final repo = ref.read(asistencia_repositorio_proveedor);
    final latitud = double.tryParse(lugar?["latitud"]?.toString() ?? "-16.5000") ?? -16.5000;
    final longitud = double.tryParse(lugar?["longitud"]?.toString() ?? "-68.1500") ?? -68.1500;
    final radio = double.tryParse(
      (lugar?["radio_tolerancia_m"] ?? lugar?["radioToleranciaM"] ?? 150).toString(),
    ) ?? 150.0;

    final distancia = repo.calcularDistancia(
      posicion: posicion,
      latitud_destino: latitud,
      longitud_destino: longitud,
    );
    final dentro = repo.validarGeocerca(
      posicion: posicion,
      latitud_destino: latitud,
      longitud_destino: longitud,
      radio_tolerancia_m: radio,
    );

    if (dentro && !_dentro_de_geocerca) {
      HapticFeedback.lightImpact();
    }

    setState(() {
      _posicion_actual = posicion;
      _escaneando_gps = false;
      _distancia_actual_m = distancia;
      _radio_tolerancia_m = radio;
      _dentro_de_geocerca = dentro;
      _mensaje_error_gps = null;
    });
  }

  Future<void> _marcar({
    required bool ingreso,
    required Map<String, dynamic>? lugar,
  }) async {
    HapticFeedback.mediumImpact();
    if (!_dentro_de_geocerca) {
      _mensaje("Fuera de rango de la geocerca asignada", es_error: true);
      return;
    }
    final notificador = ref.read(asistencia_notificador_proveedor.notifier);
    final error = ingreso
        ? await notificador.registrarIngreso(
            _tipo,
            posicion: _posicion_actual,
            lugar: lugar,
          )
        : await notificador.registrarSalida(
            _tipo,
            posicion: _posicion_actual,
            lugar: lugar,
          );
    if (error == null) {
      setState(() => _mostrar_celebracion = true);
      _mensaje(ingreso ? "Ingreso registrado" : "Salida registrada");
      _escanearUbicacion(lugar_param: lugar);
    } else {
      _mensaje(error, es_error: true);
    }
  }

  void _mostrarDialogoSeleccionarAgencia() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.swap_horiz, color: BumandColores.AZUL_DIACONIA),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Sede / Agencia de Diaconía (Rotación)",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SizedBox(
                height: 320,
                child: ListView.builder(
                  itemCount: _AGENCIAS_DIACONIA.length,
                  itemBuilder: (ctx, i) {
                    final ag = _AGENCIAS_DIACONIA[i];
                    final es_actual = (_lugar_seleccionado != null &&
                            _lugar_seleccionado!["nombre"] == ag["nombre"]);
                    return ListTile(
                      leading: Icon(
                        Icons.apartment,
                        color: es_actual
                            ? BumandColores.AZUL_DIACONIA
                            : Colors.grey.shade600,
                      ),
                      title: Text(
                        ag["nombre"].toString(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: es_actual ? FontWeight.bold : FontWeight.w500,
                          color: es_actual ? BumandColores.AZUL_DIACONIA : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        ag["direccion"].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: es_actual
                          ? const Icon(Icons.check_circle, color: BumandColores.AZUL_DIACONIA)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _lugar_seleccionado = ag;
                        });
                        _escanearUbicacion(lugar_param: ag);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final perfil_async = ref.watch(perfil_proveedor);
    final historial_async = ref.watch(historial_asistencia_proveedor);
    final estado_accion = ref.watch(asistencia_notificador_proveedor);

    final lugar = _lugar_seleccionado ?? perfil_async.asData?.value.datos?["lugarPractica"];
    if (_posicion_actual != null && _distancia_actual_m == null && lugar != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _evaluarGeocerca(_posicion_actual!, lugar);
      });
    }

    final puede_marcar = _dentro_de_geocerca && !estado_accion.isLoading;

    return Scaffold(
      backgroundColor: _FONDO,
      appBar: const BarraSuperiorBumand(
        titulo: "Registro de asistencia",
        subtitulo: "Verificación por geolocalización",
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(perfil_proveedor);
              ref.invalidate(historial_asistencia_proveedor);
              await _escanearUbicacion(lugar_param: lugar);
            },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final t in TipoAsistencia.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ChoiceChip(
                    label: Text(t.etiqueta),
                    selected: _tipo == t.valor,
                    onSelected: estado_accion.isLoading
                        ? null
                        : (_) => setState(() => _tipo = t.valor),
                    selectedColor: BumandColores.AZUL_DIACONIA,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _tipo == t.valor
                          ? Colors.white
                          : BumandColores.NEGRO,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            if (_tipo == TipoAsistencia.escuelaLideres.valor)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.access_time_filled, color: Color(0xFFB45309), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Horario oficial: Viernes 14:30. Se audita el turno de formación diaconal.",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            perfil_async.when(
              data: (res) {
                final l_perfil = res.datos?["lugarPractica"];
                final l_activo = _lugar_seleccionado ?? l_perfil;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _BORDE),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.apartment,
                        color: BumandColores.AZUL_DIACONIA,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l_activo?["nombre"]?.toString() ?? "Lugar por asignar",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (l_activo?["direccion"] != null)
                              Text(
                                l_activo!["direccion"].toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.swap_horiz, color: BumandColores.AZUL_DIACONIA),
                        tooltip: "Cambiar agencia por rotación",
                        onPressed: _mostrarDialogoSeleccionarAgencia,
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text("Error: $e"),
            ),

            const SizedBox(height: 16),

            _RadarGeocercaCard(
              controlador_pulso: _controlador_pulso,
              escaneando: _escaneando_gps,
              dentro_geocerca: _dentro_de_geocerca,
              posicion: _posicion_actual,
              distancia_m: _distancia_actual_m,
              radio_m: _radio_tolerancia_m,
              error_gps: _mensaje_error_gps,
              onReescanear: () => _escanearUbicacion(lugar_param: lugar),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: puede_marcar
                          ? () => _marcar(ingreso: true, lugar: lugar)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BumandColores.NARANJA,
                        foregroundColor: BumandColores.NEGRO,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: estado_accion.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : const Text(
                              "Marcar\ningreso",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: OutlinedButton(
                      onPressed: puede_marcar
                          ? () => _marcar(ingreso: false, lugar: lugar)
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BumandColores.AZUL_DIACONIA,
                        disabledForegroundColor: Colors.grey.shade400,
                        side: BorderSide(
                          color: puede_marcar
                              ? BumandColores.AZUL_DIACONIA
                              : Colors.grey.shade300,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Marcar\nsalida",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (!_dentro_de_geocerca && !_escaneando_gps) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "Debes estar dentro de la geocerca para registrar asistencia",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Text(
              "Historial",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),

            historial_async.when(
              data: (res) {
                if (!res.exito || res.datos == null || res.datos!.isEmpty) {
                  return const Text("No hay registros.");
                }
                return Column(
                  children: res.datos!
                      .map(
                        (r) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _BORDE),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${r["fecha"]} · ${TipoAsistencia.etiquetaDe(r["tipo"].toString())}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Ingreso: ${r["horaIngreso"] ?? "--:--"} | Salida: ${r["horaSalida"] ?? "--:--"}",
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text("Error: $e"),
            ),
          ],
        ),
      ),
      RafagaCelebracion(
        activo: _mostrar_celebracion,
        alTerminar: () => setState(() => _mostrar_celebracion = false),
      ),
    ],
  ),
);
  }
}

class _RadarGeocercaCard extends StatelessWidget {
  final AnimationController controlador_pulso;
  final bool escaneando;
  final bool dentro_geocerca;
  final Position? posicion;
  final double? distancia_m;
  final double radio_m;
  final String? error_gps;
  final VoidCallback onReescanear;

  const _RadarGeocercaCard({
    required this.controlador_pulso,
    required this.escaneando,
    required this.dentro_geocerca,
    required this.posicion,
    required this.distancia_m,
    required this.radio_m,
    required this.error_gps,
    required this.onReescanear,
  });

  Color _obtenerColorRadar() {
    if (escaneando) return BumandColores.AZUL_DIACONIA;
    if (dentro_geocerca) return const Color(0xFF10B981);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final color_radar = _obtenerColorRadar();

    final tarjeta = Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dentro_geocerca
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : const Color(0xFFE3E9F2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            width: 140,
            child: AnimatedBuilder(
              animation: controlador_pulso,
              builder: (ctx, child) {
                return CustomPaint(
                  painter: _RadarPintor(
                    progreso: controlador_pulso.value,
                    color_radar: color_radar,
                    activo: escaneando || dentro_geocerca,
                  ),
                  child: Center(
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color_radar,
                        boxShadow: [
                          BoxShadow(
                            color: color_radar.withValues(alpha: 0.35),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        escaneando
                            ? Icons.radar
                            : dentro_geocerca
                                ? Icons.check_circle_rounded
                                : Icons.location_off_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          if (escaneando)
            const Text(
              "Escaneando ubicación...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BumandColores.AZUL_DIACONIA,
              ),
            )
          else if (dentro_geocerca)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Dentro de la geocerca",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF047857),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Fuera de rango",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB91C1C),
                ),
              ),
            ),

          const SizedBox(height: 8),

          if (posicion != null)
            Text(
              "Precisión: ${posicion!.accuracy.toStringAsFixed(1)} m",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),

          if (distancia_m != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                "Distancia: ${distancia_m!.round()} m (Tolerancia: ${radio_m.round()} m)",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

          if (error_gps != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error_gps!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 8),

          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: escaneando ? null : onReescanear,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(
                "Reescanear GPS",
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );

    if (dentro_geocerca) {
      return BordeLuminoso(
        radio_esquinas: 20.0,
        ancho_borde: 2.0,
        color_haz: const Color(0xFF10B981),
        color_haz_secundario: const Color(0xFF17B4C4),
        hijo: tarjeta,
      );
    }

    return tarjeta;
  }
}

class _RadarPintor extends CustomPainter {
  final double progreso;
  final Color color_radar;
  final bool activo;

  const _RadarPintor({
    required this.progreso,
    required this.color_radar,
    required this.activo,
  });

  @override
  void paint(Canvas lienzo, Size tamano) {
    final centro = Offset(tamano.width / 2, tamano.height / 2);
    final radio_maximo = tamano.shortestSide / 2;

    for (int i = 0; i < 3; i++) {
      final fase = (progreso + (i * 0.33)) % 1.0;
      final radio = 26.0 + (fase * (radio_maximo - 26.0));
      final opacidad = activo ? ((1.0 - fase) * 0.45).clamp(0.0, 1.0) : 0.12;

      final pintura_relleno = Paint()
        ..color = color_radar.withValues(alpha: opacidad * 0.2)
        ..style = PaintingStyle.fill;

      final pintura_borde = Paint()
        ..color = color_radar.withValues(alpha: opacidad)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      lienzo.drawCircle(centro, radio, pintura_relleno);
      lienzo.drawCircle(centro, radio, pintura_borde);
    }

    final pintura_base = Paint()
      ..color = color_radar.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    lienzo.drawCircle(centro, radio_maximo, pintura_base);
  }

  @override
  bool shouldRepaint(covariant _RadarPintor oldDelegate) =>
      oldDelegate.progreso != progreso ||
      oldDelegate.color_radar != color_radar ||
      oldDelegate.activo != activo;
}
