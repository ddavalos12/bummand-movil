import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../../../widgets-comunes/cargando-skeleton.dart';
import '../../../widgets-comunes/estado-vacio-widget.dart';
import '../../animaciones/animaciones.dart';
import '../../justificaciones/pantallas/solicitar-justificacion-dialogo.dart';
import '../modelos/evento.dart';
import '../servicios/eventos-servicio.dart';

class EventosPantalla extends ConsumerStatefulWidget {
  const EventosPantalla({super.key});

  @override
  ConsumerState<EventosPantalla> createState() => _EventosPantallaState();
}

class _EventosPantallaState extends ConsumerState<EventosPantalla>
    with SingleTickerProviderStateMixin {
  static const _COLOR_FONDO = Color(0xFFEFF3F8);

  late final AnimationController _controlador_pulso;
  Position? _posicion_actual;
  bool _escaneando_gps = false;
  String? _mensaje_error_gps;
  int? _evento_seleccionado_id;
  bool _mostrar_celebracion = false;
  bool _marcando = false;

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

  Future<void> _escanearUbicacion() async {
    if (!mounted) return;
    setState(() {
      _escaneando_gps = true;
      _mensaje_error_gps = null;
    });

    try {
      final servicio_activo = await Geolocator.isLocationServiceEnabled();
      if (!servicio_activo) {
        throw Exception("El GPS se encuentra desactivado");
      }

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          throw Exception("Permiso de GPS denegado");
        }
      }
      if (permiso == LocationPermission.deniedForever) {
        throw Exception("Permiso de GPS denegado permanentemente");
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!mounted) return;
      setState(() {
        _posicion_actual = posicion;
        _escaneando_gps = false;
        _mensaje_error_gps = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _escaneando_gps = false;
        _mensaje_error_gps = e.toString().replaceFirst("Exception: ", "");
      });
    }
  }

  Future<void> _marcarAsistencia(Evento evento) async {
    if (_posicion_actual == null) {
      _mostrarMensaje("Escaneando ubicación GPS actual...", es_error: true);
      await _escanearUbicacion();
      return;
    }

    setState(() => _marcando = true);
    final servicio = ref.read(eventos_servicio_proveedor);

    final resultado = await servicio.marcarAsistencia(
      evento_id: evento.id,
      latitud: _posicion_actual!.latitude,
      longitud: _posicion_actual!.longitude,
      observaciones: "Asistencia presencial verificada por geocerca móvil",
    );

    if (!mounted) return;
    setState(() => _marcando = false);

    if (resultado.exito) {
      setState(() => _mostrar_celebracion = true);
      _mostrarMensaje("¡Asistencia confirmada exitosamente!");
      ref.invalidate(eventos_lista_proveedor);
    } else {
      _mostrarMensaje(
        resultado.error ?? "No se pudo registrar la asistencia",
        es_error: true,
      );
    }
  }

  void _mostrarMensaje(String texto, {bool es_error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor:
            es_error ? Colors.red.shade700 : const Color(0xFF10B981),
      ),
    );
  }

  void _mostrarDetalleEvento(BuildContext context, Evento evento) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Hero(
          tag: 'hero-evento-${evento.id}',
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        evento.tipo_evento.toUpperCase().replaceAll('_', ' '),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: BumandColores.AZUL_DIACONIA,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      evento.titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: BumandColores.NEGRO,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      evento.descripcion,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: BumandColores.AZUL_DIACONIA),
                        const SizedBox(width: 6),
                        Text(
                          "${evento.fecha} | ${evento.hora_inicio} - ${evento.hora_fin}",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: BumandColores.NARANJA_OSCURO),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            evento.direccion_referencia,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Cerrar"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado_eventos = ref.watch(eventos_lista_proveedor);

    return Scaffold(
      backgroundColor: _COLOR_FONDO,
      appBar: const BarraSuperiorBumand(
        titulo: "Eventos y Convocatorias",
        subtitulo: "Encuentros y talleres diaconales",
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: BumandColores.NARANJA_OSCURO,
            backgroundColor: BumandColores.AZUL_DIACONIA,
            onRefresh: () async {
              ref.invalidate(eventos_lista_proveedor);
              await _escanearUbicacion();
            },
            child: estado_eventos.when(
              data: (resultado) {
                final eventos = resultado.datos ?? [];
                if (eventos.isEmpty) {
                  return EstadoVacioWidget(
                    titulo: "No hay eventos programados",
                    mensaje:
                        "Los encuentros y talleres diaconales convocados por tus supervisores aparecerán aquí.",
                    icono: Icons.event_busy_outlined,
                    texto_boton_accion: "Actualizar lista",
                    alPresionarAccion: () =>
                        ref.invalidate(eventos_lista_proveedor),
                  );
                }

                // Obtener el evento seleccionado actualmente
                final evento_activo = eventos.firstWhere(
                  (e) => e.id == _evento_seleccionado_id,
                  orElse: () => eventos.first,
                );

                double? distancia_m;
                bool dentro_radio = false;
                bool en_horario = evento_activo.estaEnHorario();

                if (_posicion_actual != null) {
                  distancia_m = evento_activo.calcularDistanciaMetros(
                    _posicion_actual!.latitude,
                    _posicion_actual!.longitude,
                  );
                  dentro_radio = distancia_m <= evento_activo.radio_tolerancia_m;
                }

                final puede_marcar_asistencia =
                    dentro_radio && en_horario && !_marcando;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Radar de proximidad hacia el evento seleccionado
                    _RadarEventoCard(
                      evento: evento_activo,
                      controlador_pulso: _controlador_pulso,
                      escaneando: _escaneando_gps,
                      dentro_radio: dentro_radio,
                      en_horario: en_horario,
                      distancia_m: distancia_m,
                      posicion: _posicion_actual,
                      error_gps: _mensaje_error_gps,
                      onReescanear: _escanearUbicacion,
                      onMarcar: () => _marcarAsistencia(evento_activo),
                      puede_marcar: puede_marcar_asistencia,
                      marcando: _marcando,
                    ),

                    const SizedBox(height: 20),

                    // Encabezado de la lista
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 20,
                            color: BumandColores.AZUL_DIACONIA,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Agenda de Convocatorias",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Lista de eventos con ElementoEscalonado y TarjetaSpotlight
                    for (int i = 0; i < eventos.length; i++) ...[
                      ElementoEscalonado(
                        indice: i,
                        hijo: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Hero(
                            tag: 'hero-evento-${eventos[i].id}',
                            child: Material(
                              type: MaterialType.transparency,
                              child: TarjetaSpotlight(
                                color_fondo: eventos[i].id == evento_activo.id
                                    ? const Color(0xFFF0FDF4)
                                    : Colors.white,
                                color_luz: eventos[i].id == evento_activo.id
                                    ? const Color(0x3310B981)
                                    : const Color(0x2817B4C4),
                                radio_borde: BorderRadius.circular(16),
                                padding: const EdgeInsets.all(16),
                                alPresionar: () {
                                  setState(() {
                                    _evento_seleccionado_id = eventos[i].id;
                                  });
                                  _mostrarDetalleEvento(context, eventos[i]);
                                },
                                hijo: _ItemEventoCard(
                                  evento: eventos[i],
                                  es_seleccionado:
                                      eventos[i].id == evento_activo.id,
                                  posicion_usuario: _posicion_actual,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () =>
                  CargandoSkeleton.lista(cantidad: 3, alto_item: 120),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Error al cargar eventos: $err",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(eventos_lista_proveedor),
                        child: const Text("Reintentar"),
                      ),
                    ],
                  ),
                ),
              ),
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

class _RadarEventoCard extends StatelessWidget {
  final Evento evento;
  final AnimationController controlador_pulso;
  final bool escaneando;
  final bool dentro_radio;
  final bool en_horario;
  final double? distancia_m;
  final Position? posicion;
  final String? error_gps;
  final VoidCallback onReescanear;
  final VoidCallback onMarcar;
  final bool puede_marcar;
  final bool marcando;

  const _RadarEventoCard({
    required this.evento,
    required this.controlador_pulso,
    required this.escaneando,
    required this.dentro_radio,
    required this.en_horario,
    required this.distancia_m,
    required this.posicion,
    required this.error_gps,
    required this.onReescanear,
    required this.onMarcar,
    required this.puede_marcar,
    required this.marcando,
  });

  Color _obtenerColorRadar() {
    if (escaneando) return BumandColores.AZUL_DIACONIA;
    if (dentro_radio && en_horario) return const Color(0xFF10B981);
    if (!en_horario) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final color_radar = _obtenerColorRadar();

    final contenido_tarjeta = Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (dentro_radio && en_horario)
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  evento.tipo_evento.toUpperCase().replaceAll('_', ' '),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: BumandColores.AZUL_DIACONIA,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                "Tolerancia: ${evento.radio_tolerancia_m.round()} m",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            evento.titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.place, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  evento.direccion_referencia,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Gráfico Radar con ondas circulares dinámicas
          SizedBox(
            height: 140,
            width: 140,
            child: AnimatedBuilder(
              animation: controlador_pulso,
              builder: (ctx, child) {
                return CustomPaint(
                  painter: _RadarEventoPintor(
                    progreso: controlador_pulso.value,
                    color_radar: color_radar,
                    activo: escaneando || (dentro_radio && en_horario),
                  ),
                  child: Center(
                    child: Container(
                      width: 54,
                      height: 54,
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
                            : (dentro_radio && en_horario)
                                ? Icons.check_circle_rounded
                                : Icons.location_on_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // Estado del radar en badges
          if (escaneando)
            const Text(
              "Escaneando ubicación GPS...",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: BumandColores.AZUL_DIACONIA,
              ),
            )
          else if (dentro_radio && en_horario)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "En el punto de encuentro",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF047857),
                ),
              ),
            )
          else if (!en_horario)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "Fuera de horario (${evento.hora_inicio} - ${evento.hora_fin})",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB45309),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Fuera de radio geodésico",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB91C1C),
                ),
              ),
            ),

          const SizedBox(height: 6),

          if (distancia_m != null)
            Text(
              "Distancia estimada: ${distancia_m!.round()} m al epicentro",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),

          if (error_gps != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error_gps!,
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
            ),

          const SizedBox(height: 12),

          // Botón con micro-rebote si está dentro de radio y horario
          if (puede_marcar) ...[
            _BotonMarcacionRebote(
              onPresionar: onMarcar,
              cargando: marcando,
            ),
          ] else ...[
            // Si está fuera de horario o fuera de radio: opción para solicitar justificación
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: escaneando ? null : onReescanear,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text(
                      "Reescanear",
                      style: TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      SolicitarJustificacionDialogo.mostrar(
                        context,
                        evento_id: evento.id,
                        titulo_evento: evento.titulo,
                        tipo_incidencia: 'asistencia_evento',
                      );
                    },
                    icon: const Icon(Icons.assignment_late_outlined, size: 16),
                    label: const Text(
                      "Justificar",
                      style: TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    // Cuando el becario está dentro del radio y en horario, se ilumina con BordeLuminoso esmeralda
    if (dentro_radio && en_horario) {
      return BordeLuminoso(
        radio_esquinas: 20.0,
        ancho_borde: 2.2,
        color_haz: const Color(0xFF10B981),
        color_haz_secundario: const Color(0xFF17B4C4),
        hijo: contenido_tarjeta,
      );
    }

    return contenido_tarjeta;
  }
}

/// Botón reactivo con física de micro-rebote (Transform.scale) para confirmación de asistencia
class _BotonMarcacionRebote extends StatefulWidget {
  final VoidCallback onPresionar;
  final bool cargando;

  const _BotonMarcacionRebote({
    required this.onPresionar,
    required this.cargando,
  });

  @override
  State<_BotonMarcacionRebote> createState() => _BotonMarcacionReboteState();
}

class _BotonMarcacionReboteState extends State<_BotonMarcacionRebote>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador_escala;
  late final Animation<double> _animacion_escala;

  @override
  void initState() {
    super.initState();
    _controlador_escala = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _animacion_escala = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: _controlador_escala,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controlador_escala.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controlador_escala.forward(),
      onTapUp: (_) {
        _controlador_escala.reverse();
        if (!widget.cargando) {
          widget.onPresionar();
        }
      },
      onTapCancel: () => _controlador_escala.reverse(),
      child: AnimatedBuilder(
        animation: _animacion_escala,
        builder: (ctx, child) {
          return Transform.scale(
            scale: _animacion_escala.value,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x3310B981),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: widget.cargando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fingerprint, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            "Registrar Asistencia Presencial",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ItemEventoCard extends StatelessWidget {
  final Evento evento;
  final bool es_seleccionado;
  final Position? posicion_usuario;

  const _ItemEventoCard({
    required this.evento,
    required this.es_seleccionado,
    required this.posicion_usuario,
  });

  @override
  Widget build(BuildContext context) {
    double? distancia;
    if (posicion_usuario != null) {
      distancia = evento.calcularDistanciaMetros(
        posicion_usuario!.latitude,
        posicion_usuario!.longitude,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: es_seleccionado
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                evento.tipo_evento.toUpperCase().replaceAll('_', ' '),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: es_seleccionado
                      ? const Color(0xFF047857)
                      : const Color(0xFF475569),
                ),
              ),
            ),
            const Spacer(),
            if (es_seleccionado)
              const Row(
                children: [
                  Icon(Icons.radar, size: 14, color: Color(0xFF10B981)),
                  SizedBox(width: 4),
                  Text(
                    "Activo en radar",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          evento.titulo,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: es_seleccionado
                ? const Color(0xFF064E3B)
                : const Color(0xFF1E293B),
          ),
        ),
        if (evento.descripcion.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            evento.descripcion,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.calendar_today, size: 13, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              evento.fecha,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(width: 12),
            Icon(Icons.access_time, size: 13, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              "${evento.hora_inicio} - ${evento.hora_fin}",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const Spacer(),
            if (distancia != null)
              Text(
                "${distancia.round()} m",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BumandColores.AZUL_DIACONIA,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RadarEventoPintor extends CustomPainter {
  final double progreso;
  final Color color_radar;
  final bool activo;

  const _RadarEventoPintor({
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
      final radio = 27.0 + (fase * (radio_maximo - 27.0));
      final opacidad = activo ? ((1.0 - fase) * 0.45).clamp(0.0, 1.0) : 0.12;

      final pintura_relleno = Paint()
        ..color = color_radar.withValues(alpha: opacidad * 0.18)
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
  bool shouldRepaint(covariant _RadarEventoPintor oldDelegate) =>
      oldDelegate.progreso != progreso ||
      oldDelegate.color_radar != color_radar ||
      oldDelegate.activo != activo;
}
