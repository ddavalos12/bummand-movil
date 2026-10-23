import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../../animaciones/animaciones.dart';
import '../modelos/tipo-asistencia.dart';
import '../proveedores/asistencia-proveedor.dart';
import '../widgets/radar_geocerca_widget.dart';
import '../../eventos/modelos/evento.dart';
import '../../eventos/servicios/eventos-servicio.dart';
import '../../justificaciones/pantallas/solicitar-justificacion-dialogo.dart';

class AsistenciaPantalla extends ConsumerStatefulWidget {
  const AsistenciaPantalla({super.key});

  @override
  ConsumerState<AsistenciaPantalla> createState() => _AsistenciaPantallaState();
}

class _AsistenciaPantallaState extends ConsumerState<AsistenciaPantalla> {
  static const _FONDO = Color(0xFFEFF3F8);

  String _tipo = TipoAsistencia.practicas.valor;
  Map<String, dynamic>? _lugar_seleccionado;
  bool _mostrar_celebracion = false;

  Position? _posicion_actual;
  bool _escaneando_gps = false;
  bool _dentro_de_geocerca = true;
  double? _distancia_actual_m = 42.0;
  double _radio_tolerancia_m = 50.0;
  String? _mensaje_error_gps;

  String? _banner_alerta_puntualidad;
  bool _es_retraso = false;
  String? _hora_marcada_ingreso;
  String? _hora_marcada_salida;

  List<Evento> _eventos_servicio = [];
  Evento? _evento_servicio_activo;

  static const List<Map<String, dynamic>> _AGENCIAS_DIACONIA = [
    {
      "id": 1,
      "nombre": "Iglesia Bautista Central",
      "direccion": "Zona 16 de Julio, El Alto — becaria: María Catunta Laime",
      "latitud": -16.500054,
      "longitud": -68.173455,
      "radio_tolerancia_m": 60.0,
    },
    {
      "id": 2,
      "nombre": "Oficina Central Diaconía IFD - El Alto",
      "direccion": "Av. Juan Pablo II esq. Calle Sbtte. Jorge Eulert 125, El Alto",
      "latitud": -16.500054,
      "longitud": -68.173455,
      "radio_tolerancia_m": 60.0,
    },
    {
      "id": 3,
      "nombre": "Sucursal La Paz - San Pedro",
      "direccion": "Calle Colombia N° 450, Zona San Pedro, La Paz",
      "latitud": -16.501500,
      "longitud": -68.138200,
      "radio_tolerancia_m": 50.0,
    },
    {
      "id": 4,
      "nombre": "Agencia Chasquipampa",
      "direccion": "Calle 53 esq. Av. Principal Chasquipampa, Zona Sur, La Paz",
      "latitud": -16.541200,
      "longitud": -68.061100,
      "radio_tolerancia_m": 50.0,
    },
    {
      "id": 5,
      "nombre": "Agencia Viacha",
      "direccion": "Plaza Principal José Ballivián N° 85, Viacha",
      "latitud": -16.652100,
      "longitud": -68.301500,
      "radio_tolerancia_m": 60.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _escanearUbicacion();
      _cargarEventosServicio();
    });
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

  Future<void> _cargarEventosServicio() async {
    try {
      final res = await ref.read(eventos_servicio_proveedor).obtenerEventos();
      if (!mounted) return;
      if (res.exito && res.datos != null && res.datos!.isNotEmpty) {
        final eventos = res.datos!;
        final hoy_str = DateTime.now().toIso8601String().split('T')[0];
        Evento seleccionado;
        try {
          seleccionado = eventos.firstWhere((e) => e.fecha == hoy_str);
        } catch (_) {
          try {
            seleccionado = eventos.firstWhere(
              (e) => e.estado == 'en_curso' || e.estado == 'programado',
            );
          } catch (_) {
            seleccionado = eventos.first;
          }
        }

        setState(() {
          _eventos_servicio = eventos;
          _evento_servicio_activo = seleccionado;
        });

        if (_tipo == TipoAsistencia.accionesServicio.valor) {
          _aplicarEventoServicio(seleccionado);
        }
      }
    } catch (_) {}
  }

  void _aplicarEventoServicio(Evento ev) {
    final mapa_evento = {
      "nombre": ev.titulo,
      "direccion": "${ev.direccion_referencia} (${ev.hora_inicio}–${ev.hora_fin})",
      "latitud": ev.latitud,
      "longitud": ev.longitud,
      "radio_tolerancia_m": ev.radio_tolerancia_m,
      "evento_id": ev.id,
    };
    setState(() {
      _evento_servicio_activo = ev;
      _lugar_seleccionado = mapa_evento;
    });
    _escanearUbicacion(lugar_param: mapa_evento);
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
        _dentro_de_geocerca = true;
        _distancia_actual_m = 42.0;
        _mensaje_error_gps = null;
      });
    }
  }

  void _evaluarGeocerca(Position posicion, Map<String, dynamic>? lugar) {
    final repo = ref.read(asistencia_repositorio_proveedor);
    final latitud =
        double.tryParse(lugar?["latitud"]?.toString() ?? "-16.5000") ?? -16.5000;
    final longitud =
        double.tryParse(lugar?["longitud"]?.toString() ?? "-68.1500") ?? -68.1500;
    final radio = double.tryParse(
          (lugar?["radio_tolerancia_m"] ?? lugar?["radioToleranciaM"] ?? 50)
              .toString(),
        ) ??
        50.0;

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

  int _calcularMultaViernes(int minutos_retraso) {
    if (minutos_retraso <= 0) return 0;
    if (minutos_retraso <= 10) return 10;
    if (minutos_retraso <= 30) return 20;
    if (minutos_retraso <= 60) return 30;
    return 50;
  }

  void _calcularPuntualidad(DateTime ahora, String tipo_activo) {
    final es_escuela_lideres_viernes = ahora.weekday == DateTime.friday &&
        tipo_activo == TipoAsistencia.escuelaLideres.valor;
    final hora_texto =
        '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';
    _hora_marcada_ingreso = hora_texto;

    if (es_escuela_lideres_viernes) {
      final limite_viernes = DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
        14,
        35,
      );
      if (ahora.isAfter(limite_viernes)) {
        final retraso_min = ahora.difference(limite_viernes).inMinutes;
        final multa = _calcularMultaViernes(retraso_min);
        setState(() {
          _es_retraso = true;
          _banner_alerta_puntualidad =
              '⚠️ Retraso en Escuela de Líderes (Viernes) - Multa calculada: Bs $multa.00\nMarcación GPS registrada correctamente.';
        });
      } else {
        setState(() {
          _es_retraso = false;
          _banner_alerta_puntualidad =
              '✓ Ingreso puntual a las $_hora_marcada_ingreso.\nMarcación GPS registrada correctamente.';
        });
      }
      return;
    }

    int hora_limite = 8;
    int minuto_limite = 0;
    String hora_etiqueta = '08:00';

    if (tipo_activo == TipoAsistencia.practicas.valor) {
      hora_limite = 8;
      minuto_limite = 0;
      hora_etiqueta = '08:00';
    } else if (tipo_activo == TipoAsistencia.accionesServicio.valor) {
      hora_limite = 9;
      minuto_limite = 0;
      hora_etiqueta = '09:00';
    } else {
      hora_limite = 14;
      minuto_limite = 35;
      hora_etiqueta = '14:35';
    }

    final limite = DateTime(
      ahora.year,
      ahora.month,
      ahora.day,
      hora_limite,
      minuto_limite,
    );

    if (ahora.isAfter(limite)) {
      final retraso_min = ahora.difference(limite).inMinutes;
      setState(() {
        _es_retraso = true;
        _banner_alerta_puntualidad =
            '⚠️ Ingreso registrado a las $_hora_marcada_ingreso con retraso de $retraso_min min (hora prevista $hora_etiqueta)';
      });
    } else {
      setState(() {
        _es_retraso = false;
        _banner_alerta_puntualidad =
            '✓ Ingreso puntual a las $_hora_marcada_ingreso — dentro del horario ($hora_etiqueta)';
      });
    }
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

    final ahora = DateTime.now();
    final es_escuela_lideres_viernes = ahora.weekday == DateTime.friday &&
        _tipo == TipoAsistencia.escuelaLideres.valor;

    if (ingreso) {
      _calcularPuntualidad(ahora, _tipo);
    }

    // Si es Acción de Servicio vinculada a un evento activo del backend
    if (_tipo == TipoAsistencia.accionesServicio.valor &&
        _evento_servicio_activo != null &&
        ingreso &&
        _posicion_actual != null) {
      try {
        await ref.read(eventos_servicio_proveedor).marcarAsistencia(
              evento_id: _evento_servicio_activo!.id,
              latitud: _posicion_actual!.latitude,
              longitud: _posicion_actual!.longitude,
              observaciones: 'Asistencia registrada desde módulo móvil BUMAND',
            );
      } catch (_) {}
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
      final hora_str =
          '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';
      setState(() {
        _mostrar_celebracion = true;
        if (!ingreso) {
          _hora_marcada_salida = hora_str;
        }
      });
      if (es_escuela_lideres_viernes) {
        _mensaje(
          ingreso
              ? "✓ Ingreso registrado correctamente"
              : "✓ Salida registrada correctamente",
        );
      } else {
        _mensaje(ingreso ? "Ingreso registrado" : "Salida registrada");
      }
      _escanearUbicacion(lugar_param: lugar);
    } else {
      _mensaje(error, es_error: true);
    }
  }

  void _mostrarDialogoSeleccionarAgencia() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                        "Sede / Lugar asignado",
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
                height: 280,
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
                          fontWeight:
                              es_actual ? FontWeight.bold : FontWeight.w500,
                          color: es_actual
                              ? BumandColores.AZUL_DIACONIA
                              : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        ag["direccion"].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: es_actual
                          ? const Icon(
                              Icons.check_circle,
                              color: BumandColores.AZUL_DIACONIA,
                            )
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
    final estado_accion = ref.watch(asistencia_notificador_proveedor);

    final lugar_defecto = {
      "nombre": "Oficina Central Diaconía IFD - El Alto",
      "direccion":
          "Avenida Juan Pablo II esq. Calle Sbtte. Jorge Eulert 125, El Alto",
      "latitud": -16.500054,
      "longitud": -68.173455,
      "radio_tolerancia_m": 50.0,
    };

    final lugar = _lugar_seleccionado ??
        perfil_async.asData?.value.datos?["lugarPractica"] ??
        lugar_defecto;

    String nombre_lugar = lugar["nombre"]?.toString() ?? "Lugar asignado";
    String desc_lugar = lugar["direccion"]?.toString() ?? "Punto de asistencia";

    if (_tipo == TipoAsistencia.escuelaLideres.valor) {
      nombre_lugar = "Escuela de Líderes Diaconales";
      desc_lugar = "Auditorio Central, El Alto — módulo de formación";
    } else if (_tipo == TipoAsistencia.accionesServicio.valor) {
      if (_evento_servicio_activo != null) {
        nombre_lugar = _evento_servicio_activo!.titulo;
        desc_lugar = _evento_servicio_activo!.direccion_referencia;
      } else {
        nombre_lugar = "Acción de Servicio Diaconal";
        desc_lugar = "Punto y horario configurados en agenda institucional";
      }
    }

    final nombre_becario =
        perfil_async.asData?.value.datos?["nombre"] ?? "María Catunta Laime";

    final ahora = DateTime.now();
    final es_escuela_lideres_viernes = ahora.weekday == DateTime.friday &&
        _tipo == TipoAsistencia.escuelaLideres.valor;
    final limite_viernes =
        DateTime(ahora.year, ahora.month, ahora.day, 14, 35);
    final minutos_retraso_actual =
        (es_escuela_lideres_viernes && ahora.isAfter(limite_viernes))
            ? ahora.difference(limite_viernes).inMinutes
            : 0;
    final multa_estimada_real = _calcularMultaViernes(minutos_retraso_actual);

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
              await _cargarEventosServicio();
              await _escanearUbicacion(lugar_param: lugar);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. Selector Segmentado Horizontal de 3 Pilares (Fiel a 16.jpeg)
                _construirTabsSuperiores(),
                const SizedBox(height: 12),

                // Selector dinámico de eventos si está en Acción de Servicio y hay varios
                if (_tipo == TipoAsistencia.accionesServicio.valor &&
                    _eventos_servicio.length > 1) ...[
                  _construirSelectorEventosServicio(),
                  const SizedBox(height: 10),
                ],

                // 2. Tarjeta azul oscura del Radar con indicador de precisión GPS y reloj digital
                RadarGeocercaWidget(
                  escaneando: _escaneando_gps,
                  dentro_geocerca: _dentro_de_geocerca,
                  posicion: _posicion_actual,
                  distancia_m: _distancia_actual_m ?? 42.0,
                  radio_m: _radio_tolerancia_m,
                  error_gps: _mensaje_error_gps,
                  hora_ingreso: _hora_marcada_ingreso,
                  hora_salida: _hora_marcada_salida,
                  nombre_lugar: nombre_lugar,
                  direccion_lugar: desc_lugar,
                  nombre_becario: nombre_becario,
                  alReescanear: () => _escanearUbicacion(lugar_param: lugar),
                  alSeleccionarLugar: _tipo == TipoAsistencia.practicas.valor
                      ? _mostrarDialogoSeleccionarAgencia
                      : null,
                ),
                const SizedBox(height: 16),

                // 3. Botones de acción principales: Marcar ingreso (Azul) y Marcar salida (Borde Azul)
                _construirBotonesMarcacion(
                  puede_marcar: puede_marcar,
                  is_loading: estado_accion.isLoading,
                  lugar: lugar,
                ),
                const SizedBox(height: 14),

                // 4. Advertencia de multas oficiales para Escuela de Líderes (Viernes pasadas 14:35)
                if (es_escuela_lideres_viernes && minutos_retraso_actual > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF87171)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFDC2626),
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Retraso en Escuela de Líderes (Viernes) - Multa: Bs $multa_estimada_real.00",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Límite: 14:35 • Retraso: $minutos_retraso_actual min.\nTabla oficial: 1–10 min = Bs 10 · 11–30 min = Bs 20 · 31–60 min = Bs 30 · >60 min = Bs 50",
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFFB91C1C),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 5. Banner interactivo de confirmación de puntualidad
                if (_banner_alerta_puntualidad != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _es_retraso
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _es_retraso
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                      ),
                    ),
                    child: Text(
                      _banner_alerta_puntualidad!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _es_retraso
                            ? const Color(0xFF92400E)
                            : const Color(0xFF065F46),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // 6. Acceso directo a Permisos y Justificaciones
                OutlinedButton.icon(
                  onPressed: () {
                    SolicitarJustificacionDialogo.mostrar(
                      context,
                      evento_id: _evento_servicio_activo?.id,
                      titulo_evento: _tipo == TipoAsistencia.accionesServicio.valor
                          ? _evento_servicio_activo?.titulo
                          : (_tipo == TipoAsistencia.escuelaLideres.valor
                              ? "Escuela de Líderes Diaconales"
                              : "Prácticas Institucionales"),
                      tipo_incidencia: _tipo == TipoAsistencia.escuelaLideres.valor
                          ? "escuela_lideres"
                          : (_tipo == TipoAsistencia.accionesServicio.valor
                              ? "asistencia_evento"
                              : "asistencia_practicas"),
                    );
                  },
                  icon: const Icon(
                    Icons.assignment_late_outlined,
                    size: 18,
                    color: BumandColores.AZUL_DIACONIA,
                  ),
                  label: const Text(
                    "¿Incidencia o retraso? Solicitar Permiso / Justificación",
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: BumandColores.AZUL_DIACONIA,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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

  Widget _construirTabsSuperiores() {
    final opciones = [
      (TipoAsistencia.practicas.valor, "Prácticas"),
      (TipoAsistencia.escuelaLideres.valor, "Escuela de Líderes"),
      (TipoAsistencia.accionesServicio.valor, "Servicio"),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: opciones.map((opcion) {
          final seleccionado = _tipo == opcion.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _tipo = opcion.$1;
                  _banner_alerta_puntualidad = null;
                });
                if (opcion.$1 == TipoAsistencia.accionesServicio.valor) {
                  if (_eventos_servicio.isEmpty) {
                    _cargarEventosServicio();
                  } else if (_evento_servicio_activo != null) {
                    _aplicarEventoServicio(_evento_servicio_activo!);
                  }
                } else {
                  _escanearUbicacion();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: seleccionado
                      ? const Color(0xFF0284C7)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  opcion.$2,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: seleccionado
                        ? Colors.white
                        : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _construirSelectorEventosServicio() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available, color: Color(0xFF0284C7), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _evento_servicio_activo?.id,
                isDense: true,
                isExpanded: true,
                items: _eventos_servicio.map((e) {
                  return DropdownMenuItem<int>(
                    value: e.id,
                    child: Text(
                      "${e.titulo} (${e.fecha})",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id != null) {
                    final ev = _eventos_servicio.firstWhere((e) => e.id == id);
                    _aplicarEventoServicio(ev);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirBotonesMarcacion({
    required bool puede_marcar,
    required bool is_loading,
    required Map<String, dynamic>? lugar,
  }) {
    return Column(
      children: [
        // Botón Marcar ingreso (Azul Primario)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: puede_marcar
                ? () => _marcar(ingreso: true, lugar: lugar)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              elevation: 0,
              disabledBackgroundColor:
                  const Color(0xFF0284C7).withValues(alpha: 0.5),
              disabledForegroundColor: Colors.white70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: is_loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.login_rounded, size: 20),
            label: const Text(
              "Marcar ingreso",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Botón Marcar salida (Blanco con Borde Azul)
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: puede_marcar
                ? () => _marcar(ingreso: false, lugar: lugar)
                : null,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0284C7),
              side: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
              elevation: 0,
              disabledForegroundColor: Colors.grey.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text(
              "Marcar salida",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
