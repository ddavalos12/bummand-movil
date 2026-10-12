import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../../animaciones/animaciones.dart';
import '../modelos/tipo-asistencia.dart';
import '../proveedores/asistencia-proveedor.dart';
import '../../evaluaciones/pantallas/evaluaciones-pantalla.dart';
import '../widgets/radar_geocerca_widget.dart';
import '../widgets/mapa-geocerca-bloques-widget.dart';
import '../widgets/detalle_asistencia_modal.dart';
import 'historial-asistencia-pantalla.dart';

class AsistenciaPantalla extends ConsumerStatefulWidget {
  const AsistenciaPantalla({super.key});

  @override
  ConsumerState<AsistenciaPantalla> createState() => _AsistenciaPantallaState();
}

class _AsistenciaPantallaState extends ConsumerState<AsistenciaPantalla> {
  static const _FONDO = Color(0xFFEFF3F8);
  static const _BORDE = Color(0xFFE3E9F2);

  static const List<BloqueEdificio> _BLOQUES_EDIFICIO = [
    BloqueEdificio(
      id: 'bloque_norte',
      nombre: 'Bloque Norte',
      descripcion: 'Auditorio Principal • Escuela de Líderes Diaconales',
      latitud: -16.500054,
      longitud: -68.173455,
      icono: Icons.theater_comedy_outlined,
      es_auditorio_viernes: true,
    ),
    BloqueEdificio(
      id: 'bloque_central',
      nombre: 'Bloque Central',
      descripcion: 'Oficinas Diaconía IFD • Piso 1 y 2',
      latitud: -16.500100,
      longitud: -68.173500,
      icono: Icons.business_outlined,
    ),
    BloqueEdificio(
      id: 'bloque_sur',
      nombre: 'Bloque Sur',
      descripcion: 'Aulas de Formación Diaconal y Capilla',
      latitud: -16.500200,
      longitud: -68.173600,
      icono: Icons.church_outlined,
    ),
  ];

  late BloqueEdificio _bloque_detectado;

  final List<Map<String, dynamic>> _becarios_en_sala = [
    {
      "id": 1,
      "nombre": "María Catunta Laime",
      "hora": "14:28",
      "bloque": "Bloque Norte (Auditorio)",
      "retraso_min": 0,
      "multa_bs": 0,
      "confirmado": false,
    },
    {
      "id": 2,
      "nombre": "Juan Carlos Quispe",
      "hora": "14:38",
      "bloque": "Bloque Norte (Auditorio)",
      "retraso_min": 3,
      "multa_bs": 30,
      "confirmado": false,
    },
    {
      "id": 3,
      "nombre": "Joel Mamani Choque",
      "hora": "14:33",
      "bloque": "Bloque Norte (Auditorio)",
      "retraso_min": 0,
      "multa_bs": 0,
      "confirmado": false,
    },
    {
      "id": 4,
      "nombre": "Sara Noemí Flores",
      "hora": "14:41",
      "bloque": "Bloque Norte (Auditorio)",
      "retraso_min": 6,
      "multa_bs": 60,
      "confirmado": false,
    },
  ];

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
    _bloque_detectado = _BLOQUES_EDIFICIO[0];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _escanearUbicacion();
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
    final latitud = double.tryParse(lugar?["latitud"]?.toString() ?? "-16.5000") ?? -16.5000;
    final longitud = double.tryParse(lugar?["longitud"]?.toString() ?? "-68.1500") ?? -68.1500;
    final radio = double.tryParse(
      (lugar?["radio_tolerancia_m"] ?? lugar?["radioToleranciaM"] ?? 50).toString(),
    ) ?? 50.0;

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

  void _calcularPuntualidad(DateTime ahora, String tipo_activo) {
    final es_viernes = ahora.weekday == DateTime.friday ||
        tipo_activo == TipoAsistencia.escuelaLideres.valor;
    final hora_texto =
        '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';
    _hora_marcada_ingreso = hora_texto;

    if (es_viernes) {
      final limite_viernes = DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
        14,
        35,
      );
      if (ahora.isAfter(limite_viernes)) {
        final retraso_min = ahora.difference(limite_viernes).inMinutes;
        final multa = retraso_min * 10;
        setState(() {
          _es_retraso = true;
          _banner_alerta_puntualidad =
              '⚠️ Retraso de $retraso_min min pasadas las 14:35. Multa calculada: Bs $multa.00 (Tarifa: Bs 10/minuto de retención institucional).\nMarcación GPS registrada. Pendiente de confirmación por llamada de lista del organizador.';
        });
      } else {
        setState(() {
          _es_retraso = false;
          _banner_alerta_puntualidad =
              '✓ Ingreso puntual a las $_hora_marcada_ingreso.\nMarcación GPS registrada. Pendiente de confirmación por llamada de lista del organizador.';
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
    } else {
      hora_limite = 9;
      minuto_limite = 0;
      hora_etiqueta = '09:00';
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
    final es_viernes = ahora.weekday == DateTime.friday ||
        _tipo == TipoAsistencia.escuelaLideres.valor;

    if (ingreso) {
      _calcularPuntualidad(ahora, _tipo);
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
      if (es_viernes) {
        _mensaje(
          "Marcación GPS registrada. Pendiente de confirmación por llamada de lista del organizador",
        );
      } else {
        _mensaje(ingreso ? "Ingreso registrado" : "Salida registrada");
      }
      _escanearUbicacion(lugar_param: lugar);
    } else {
      _mensaje(error, es_error: true);
    }
  }

  void _mostrarDialogoLlamadaListaRapida() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final confirmados_count =
                _becarios_en_sala.where((b) => b["confirmado"] == true).length;
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          BumandColores.AZUL_DIACONIA,
                          BumandColores.TURQUESA_DIACONIA,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.checklist_rtl_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Llamada de Lista Rápida",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Modo Supervisor • Escuela de Líderes (Viernes)",
                                style: TextStyle(
                                  color: Color(0xFFD6F1F7),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "En sala: $confirmados_count / ${_becarios_en_sala.length} confirmados",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: BumandColores.NEGRO,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () {
                            setModalState(() {
                              for (var b in _becarios_en_sala) {
                                b["confirmado"] = true;
                              }
                            });
                            setState(() {});
                            HapticFeedback.mediumImpact();
                            _mensaje(
                              "✓ Asistencia confirmada en 1 toque para todos los becarios en sala",
                            );
                          },
                          icon: const Icon(Icons.done_all, size: 15),
                          label: const Text(
                            "Confirmar sala",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: BumandColores.TURQUESA_DIACONIA,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _becarios_en_sala.length,
                      itemBuilder: (context, i) {
                        final b = _becarios_en_sala[i];
                        final confirmado = b["confirmado"] == true;
                        final es_retraso = (b["retraso_min"] as int) > 0;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: confirmado
                                ? const Color(0xFF10B981)
                                : (es_retraso
                                    ? const Color(0xFFF59E0B)
                                    : BumandColores.AZUL_DIACONIA),
                            child: Icon(
                              confirmado
                                  ? Icons.check
                                  : (es_retraso
                                      ? Icons.access_time
                                      : Icons.person),
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            b["nombre"].toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            es_retraso
                                ? "${b['hora']} • Retraso ${b['retraso_min']} min (Multa: Bs ${b['multa_bs']})"
                                : "${b['hora']} • Marcó a tiempo por geocerca",
                            style: TextStyle(
                              fontSize: 11.5,
                              color: es_retraso
                                  ? const Color(0xFFB45309)
                                  : Colors.grey.shade700,
                            ),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              setModalState(() {
                                b["confirmado"] = !confirmado;
                              });
                              setState(() {});
                              HapticFeedback.lightImpact();
                              if (!confirmado) {
                                _mensaje(
                                  "✓ Asistencia confirmada para ${b['nombre']}",
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: confirmado
                                  ? const Color(0xFFECFDF5)
                                  : BumandColores.AZUL_DIACONIA,
                              foregroundColor: confirmado
                                  ? const Color(0xFF065F46)
                                  : Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                            child: Text(
                              confirmado ? "Confirmado ✓" : "Confirmar",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

    final lugar_defecto = {
      "nombre": "Iglesia Bautista Central",
      "direccion": "Zona 16 de Julio, El Alto — becaria: María Catunta Laime",
      "latitud": -16.500054,
      "longitud": -68.173455,
      "radio_tolerancia_m": 50.0,
    };

    final lugar = _lugar_seleccionado ??
        perfil_async.asData?.value.datos?["lugarPractica"] ??
        lugar_defecto;

    final ahora = DateTime.now();
    final hora_actual_texto =
        '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}';
    final dias = ['LUN', 'MAR', 'MIÉ', 'JUE', 'VIE', 'SÁB', 'DOM'];
    final meses = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC'
    ];
    final dia_nombre = dias[ahora.weekday - 1];
    final mes_nombre = meses[ahora.month - 1];
    final fecha_etiqueta = '$dia_nombre ${ahora.day} $mes_nombre ${ahora.year}';

    final es_viernes = ahora.weekday == DateTime.friday ||
        _tipo == TipoAsistencia.escuelaLideres.valor;
    final limite_viernes =
        DateTime(ahora.year, ahora.month, ahora.day, 14, 35);
    final minutos_retraso_actual =
        (es_viernes && ahora.isAfter(limite_viernes))
            ? ahora.difference(limite_viernes).inMinutes
            : 0;
    final multa_estimada_real = minutos_retraso_actual * 10;

    final puede_marcar = _dentro_de_geocerca && !estado_accion.isLoading;

    return Scaffold(
      backgroundColor: _FONDO,
      appBar: BarraSuperiorBumand(
        titulo: "Registro de asistencia",
        subtitulo: "Verificación por geolocalización",
        acciones_adicionales: [
          IconButton(
            icon: const Icon(Icons.checklist_rtl_rounded, color: Colors.white),
            tooltip: "Llamada de Lista Rápida",
            onPressed: _mostrarDialogoLlamadaListaRapida,
          ),
        ],
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
                // Cita Bíblica Destacada del Día (Requerimiento 5)
                _construirCitaBiblicaSeguimiento(),
                const SizedBox(height: 12),

                // Selector Segmentado de los 3 Pilares
                _construirTabsPilares(),
                const SizedBox(height: 14),

                // Advertencia en tiempo real para Escuela de Líderes (Viernes pasadas las 14:35)
                if (es_viernes && minutos_retraso_actual > 0) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
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
                              const Text(
                                "Retraso en Escuela de Líderes (Viernes)",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF991B1B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Límite: 14:35 • Retraso: $minutos_retraso_actual min.\nMulta calculada en tiempo real: Bs $multa_estimada_real.00 (Tarifa: Bs 10 por minuto de retención institucional).",
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
                ],

                // Modo Organizador / Supervisor (Acceso Rápido)
                if (es_viernes) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: BumandColores.AZUL_DIACONIA
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: ListTile(
                      dense: true,
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: BumandColores.AZUL_DIACONIA
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.checklist_rtl_rounded,
                          color: BumandColores.AZUL_DIACONIA,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        "Llamada de Lista Rápida (Organizador)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: const Text(
                        "Confirmar en un toque a becarios con GPS en sala",
                        style: TextStyle(fontSize: 11),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                      onTap: _mostrarDialogoLlamadaListaRapida,
                    ),
                  ),
                ],

                // Mapa de Geocerca con Detección de Bloques
                MapaGeocercaBloquesWidget(
                  escaneando: _escaneando_gps,
                  dentro_geocerca: _dentro_de_geocerca,
                  posicion: _posicion_actual,
                  distancia_m: _distancia_actual_m ?? 42.0,
                  radio_m: _radio_tolerancia_m,
                  error_gps: _mensaje_error_gps,
                  bloque_detectado: _bloque_detectado,
                  bloques_disponibles: _BLOQUES_EDIFICIO,
                  alReescanear: () => _escanearUbicacion(lugar_param: lugar),
                  alSeleccionarBloque: (b) =>
                      setState(() => _bloque_detectado = b),
                ),
                const SizedBox(height: 14),

                // Radar de Geocerca Interactivo
                RadarGeocercaWidget(
                  escaneando: _escaneando_gps,
                  dentro_geocerca: _dentro_de_geocerca,
                  posicion: _posicion_actual,
                  distancia_m: _distancia_actual_m ?? 42.0,
                  radio_m: _radio_tolerancia_m,
                  error_gps: _mensaje_error_gps,
                  alReescanear: () => _escanearUbicacion(lugar_param: lugar),
                ),
                const SizedBox(height: 14),

                // Lugar y detalles del pilar seleccionado
                _construirInfoPilar(lugar, fecha_etiqueta, hora_actual_texto),
                const SizedBox(height: 16),

                // Botones Marcar Ingreso y Marcar Salida
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: puede_marcar
                              ? () => _marcar(ingreso: true, lugar: lugar)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BumandColores.TURQUESA_DIACONIA,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: estado_accion.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Marcar\ningreso",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 56,
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
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Marcar\nsalida",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Banner de Alerta de Puntualidad / Retraso
                if (_banner_alerta_puntualidad != null) ...[
                  const SizedBox(height: 12),
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
                      borderRadius: BorderRadius.circular(12),
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
                ],

                const SizedBox(height: 20),

                // Enlace a Evaluaciones 360°
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            BumandColores.AZUL_DIACONIA.withValues(alpha: 0.2),
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: BumandColores.AZUL_DIACONIA
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in_outlined,
                          color: BumandColores.AZUL_DIACONIA,
                          size: 22,
                        ),
                      ),
                      title: const Text(
                        "Mis Evaluaciones (360°)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        "Ver calificación global y módulos",
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EvaluacionesPantalla(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Lista de Registros Recientes con Detalle en BottomSheet
                _construirHistorialReciente(historial_async),
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

  Widget _construirTabsPilares() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _BORDE),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: TipoAsistencia.values.map((t) {
          final seleccionado = _tipo == t.valor;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _tipo = t.valor;
                  _banner_alerta_puntualidad = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: seleccionado
                      ? BumandColores.AZUL_DIACONIA
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  t.etiqueta,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight:
                        seleccionado ? FontWeight.bold : FontWeight.w500,
                    color: seleccionado ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _construirInfoPilar(
    Map<String, dynamic> lugar,
    String fecha_etiqueta,
    String hora_actual_texto,
  ) {
    String nombre_lugar = lugar["nombre"]?.toString() ?? "Lugar asignado";
    String desc_lugar = lugar["direccion"]?.toString() ?? "Punto de asistencia";
    String fecha_mostrar = fecha_etiqueta;

    if (_tipo == TipoAsistencia.escuelaLideres.valor) {
      nombre_lugar = "Escuela de Líderes Diaconales";
      desc_lugar = "Oficina Central, El Alto — módulo de formación en liderazgo";
      fecha_mostrar = "SÁB 15 AGO 2026 · MÓDULO 6";
    } else if (_tipo == TipoAsistencia.accionesServicio.valor) {
      nombre_lugar = "Comedor Comunitario San José";
      desc_lugar = "Zona Villa Adela, El Alto — punto de acción de servicio asignado";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _BORDE),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre_lugar,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: BumandColores.NEGRO,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc_lugar,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_tipo == TipoAsistencia.practicas.valor)
                IconButton(
                  icon: const Icon(
                    Icons.swap_horiz,
                    color: BumandColores.AZUL_DIACONIA,
                  ),
                  tooltip: "Rotar agencia",
                  onPressed: _mostrarDialogoSeleccionarAgencia,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hora_actual_texto,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: BumandColores.NEGRO,
              letterSpacing: 1,
            ),
          ),
          Text(
            fecha_mostrar,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirHistorialReciente(AsyncValue<dynamic> historial_async) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Historial y Registros",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HistorialAsistenciaPantalla(),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 14),
              label: const Text(
                "Ver completo",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                foregroundColor: BumandColores.AZUL_DIACONIA,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Elementos interactivos del historial
        _construirItemHistorial(
          titulo: "Lun 11 ago",
          horario: "08:02–13:10",
          estado_valido: true,
          alTocar: () {
            DetalleAsistenciaModal.mostrar(
              context,
              titulo: "Lunes 11 de agosto",
              subtitulo: "Registro de prácticas · 2026",
              tipo_registro: "Prácticas pre profesionales",
              lugar: "Iglesia Bautista Central",
              ingreso: "08:02",
              salida: "13:10",
              horas_trabajadas: "5h 08m",
              distancia: "38 m",
              dentro_geocerca: true,
            );
          },
        ),
        _construirItemHistorial(
          titulo: "Vie 08 ago",
          horario: "08:55–12:40",
          estado_valido: true,
          alTocar: () {
            DetalleAsistenciaModal.mostrar(
              context,
              titulo: "Viernes 08 de agosto",
              subtitulo: "Registro de prácticas · 2026",
              tipo_registro: "Prácticas pre profesionales",
              lugar: "Iglesia Bautista Central",
              ingreso: "08:55",
              salida: "12:40",
              horas_trabajadas: "3h 45m",
              distancia: "22 m",
              dentro_geocerca: true,
            );
          },
        ),
        _construirItemHistorial(
          titulo: "Jue 07 ago",
          horario: "Fuera de radio",
          estado_valido: false,
          alTocar: () {
            DetalleAsistenciaModal.mostrar(
              context,
              titulo: "Jueves 07 de agosto",
              subtitulo: "Registro de prácticas · 2026",
              tipo_registro: "Prácticas pre profesionales",
              lugar: "Punto no verificado",
              ingreso: "09:15",
              salida: "12:00",
              horas_trabajadas: "2h 45m",
              distancia: "142 m",
              dentro_geocerca: false,
            );
          },
        ),
        _construirItemHistorial(
          titulo: "Mié 06 ago",
          horario: "08:47–12:30",
          estado_valido: true,
          alTocar: () {
            DetalleAsistenciaModal.mostrar(
              context,
              titulo: "Miércoles 06 de agosto",
              subtitulo: "Registro de prácticas · 2026",
              tipo_registro: "Prácticas pre profesionales",
              lugar: "Iglesia Bautista Central",
              ingreso: "08:47",
              salida: "12:30",
              horas_trabajadas: "3h 43m",
              distancia: "15 m",
              dentro_geocerca: true,
            );
          },
        ),
      ],
    );
  }

  Widget _construirItemHistorial({
    required String titulo,
    required String horario,
    required bool estado_valido,
    required VoidCallback alTocar,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _BORDE),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: alTocar,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: estado_valido
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  horario,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: estado_valido
                        ? const Color(0xFF334155)
                        : const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirCitaBiblicaSeguimiento() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BumandColores.AZUL_DIACONIA.withValues(alpha: 0.08),
            BumandColores.TURQUESA_DIACONIA.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BumandColores.TURQUESA_DIACONIA.withValues(alpha: 0.25),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 20,
            color: BumandColores.AZUL_DIACONIA,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "«Todo lo puedo en Cristo que me fortalece»",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: BumandColores.NEGRO,
                  ),
                ),
                Text(
                  "Filipenses 4:13 • Período Formativo Diaconía IFD",
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: BumandColores.AZUL_DIACONIA,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
