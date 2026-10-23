import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/recorrido-modelo.dart';
import '../proveedores/pasajes-proveedor.dart';
import '../utilidades/formato-pasajes.dart';
import '../../../nucleo/tema/colores.dart';
import '../../../compartido/componentes/seleccionador_fecha.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../../inicio/proveedores/inicio-proveedor.dart';

/// Modelo interno para una parada dinámica
class _ParadaRuta {
  final TextEditingController controlador;
  Position? posicion_gps;
  bool confirmada;

  _ParadaRuta({
    required this.controlador,
    this.posicion_gps,
    this.confirmada = false,
  });

  void dispose() {
    controlador.dispose();
  }
}

/// Modelo interno para un tramo de tarifa
class _TramoTarifa {
  double monto;
  String? nombre;
  final TextEditingController controlador_personalizado;

  _TramoTarifa({
    required this.monto,
    this.nombre,
    required this.controlador_personalizado,
  });

  void dispose() {
    controlador_personalizado.dispose();
  }
}

class DeclararRecorridoPantalla extends ConsumerStatefulWidget {
  final String? destino_inicial;
  final String? tipo_actividad_inicial;
  final bool es_pestana;
  final bool solo_hoy;

  const DeclararRecorridoPantalla({
    super.key,
    this.destino_inicial,
    this.tipo_actividad_inicial,
    this.es_pestana = false,
    this.solo_hoy = false,
  });

  @override
  ConsumerState<DeclararRecorridoPantalla> createState() =>
      _DeclararRecorridoPantallaState();
}

class _DeclararRecorridoPantallaState
    extends ConsumerState<DeclararRecorridoPantalla> {
  static const _CLAVE_ORIGEN = "pasajes_ultimo_origen";
  static const _CLAVE_DESTINO = "pasajes_ultimo_destino";

  final _clave_formulario = GlobalKey<FormState>();
  final _apoyo_controlador = TextEditingController(
    text: "Envío de reportes, control CAEDEC",
  );

  DateTime _fecha = DateTime.now();
  int _paso_activo = 1; // 1 = Ida, 2 = Vuelta
  bool _guardando = false;
  String? _capturando_gps_id;
  String _tipo_actividad = "Prácticas";
  bool _formulario_inicializado_con_hoy = false;
  int? _id_recorrido_ida_hoy;
  int? _id_recorrido_vuelta_hoy;

  static const List<String> TIPOS_ACTIVIDAD = [
    "Prácticas",
    "Escuela de Líderes",
    "Acciones de Servicio",
  ];

  // Paradas dinámicas para Ida y Vuelta
  final List<_ParadaRuta> _paradas_ida = [];
  final List<_ParadaRuta> _paradas_vuelta = [];

  // Tramos de tarifas para Ida y Vuelta
  final List<_TramoTarifa> _tramos_ida = [];
  final List<_TramoTarifa> _tramos_vuelta = [];

  static const List<Map<String, dynamic>> TARIFAS_PREDEFINIDAS = [
    {"nombre": "Minibús (dentro de El Alto)", "monto": 2.0},
    {"nombre": "Micro (dentro de El Alto)", "monto": 1.5},
    {"nombre": "Minibús (Centro La Paz – Ceja)", "monto": 3.5},
    {"nombre": "Minibús (UMSA – Ceja)", "monto": 4.0},
    {"nombre": "Teleférico (línea regular)", "monto": 3.0},
    {"nombre": "Teleférico (por transbordo)", "monto": 2.0},
    {"nombre": "Otro (escribir monto)...", "monto": 0.0},
  ];

  static const List<String> PARADAS_FRECUENTES = [
    'Oficina Central Diaconía',
    'Villa Adela, El Alto',
    'Agencia Diaconía Ceja',
    'Sede Escuela de Líderes',
    'Ceja',
    'Pérez Velasco',
    'Plaza San Francisco',
    'San Pedro',
    'Cruce Viacha',
    'Miraflores',
    'Sopocachi',
    'Teleférico',
  ];

  List<String> _obtenerOpcionesParadaDisponibles(
    List<_ParadaRuta> lista_paradas,
    int indice_actual,
  ) {
    final usadas_en_otras = <String>{};
    for (int i = 0; i < lista_paradas.length; i++) {
      if (i == indice_actual) continue;
      final valor = lista_paradas[i].controlador.text.trim().toLowerCase();
      if (valor.isNotEmpty) {
        usadas_en_otras.add(valor);
      }
    }

    final catalogo = <String>[
      ...PARADAS_FRECUENTES,
      if (widget.destino_inicial != null &&
          widget.destino_inicial!.trim().isNotEmpty &&
          !PARADAS_FRECUENTES.contains(widget.destino_inicial!.trim()))
        widget.destino_inicial!.trim(),
    ];

    return catalogo
        .where((op) => !usadas_en_otras.contains(op.trim().toLowerCase()))
        .toList();
  }

  bool _tieneParadasDuplicadas(List<_ParadaRuta> lista_paradas) {
    final vistos = <String>{};
    for (final p in lista_paradas) {
      final texto = p.controlador.text.trim().toLowerCase();
      if (texto.isEmpty) continue;
      if (vistos.contains(texto)) return true;
      vistos.add(texto);
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    if (widget.tipo_actividad_inicial != null &&
        TIPOS_ACTIVIDAD.contains(widget.tipo_actividad_inicial)) {
      _tipo_actividad = widget.tipo_actividad_inicial!;
    }
    final destino_base =
        (widget.destino_inicial != null && widget.destino_inicial!.isNotEmpty)
            ? widget.destino_inicial!
            : "Oficina Central Diaconía";

    // Inicializar paradas mínimas de Ida
    _paradas_ida.add(
      _ParadaRuta(controlador: TextEditingController(text: "Villa Adela, El Alto")),
    );
    _paradas_ida.add(
      _ParadaRuta(
        controlador: TextEditingController(text: destino_base),
      ),
    );

    // Inicializar paradas mínimas de Vuelta
    _paradas_vuelta.add(
      _ParadaRuta(
        controlador: TextEditingController(text: destino_base),
      ),
    );
    _paradas_vuelta.add(
      _ParadaRuta(controlador: TextEditingController(text: "Villa Adela, El Alto")),
    );

    // Inicializar al menos 1 tramo de tarifa en Ida y Vuelta
    _tramos_ida.add(
      _TramoTarifa(
        monto: 2.0,
        nombre: "Minibús (dentro de El Alto)",
        controlador_personalizado: TextEditingController(text: "2.00"),
      ),
    );
    _tramos_vuelta.add(
      _TramoTarifa(
        monto: 2.0,
        nombre: "Minibús (dentro de El Alto)",
        controlador_personalizado: TextEditingController(text: "2.00"),
      ),
    );

    _cargarUltimoRecorrido();
  }

  @override
  void dispose() {
    _apoyo_controlador.dispose();
    for (final p in _paradas_ida) {
      p.dispose();
    }
    for (final p in _paradas_vuelta) {
      p.dispose();
    }
    for (final t in _tramos_ida) {
      t.dispose();
    }
    for (final t in _tramos_vuelta) {
      t.dispose();
    }
    super.dispose();
  }

  bool _esMismaFecha(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _cargarDatosDesdeRecorridosExistentes(
    RecorridoModelo? ida,
    RecorridoModelo? vuelta,
  ) {
    _id_recorrido_ida_hoy = ida?.id;
    _id_recorrido_vuelta_hoy = vuelta?.id;

    if (ida != null) {
      if (ida.apoyo_realizado != null && ida.apoyo_realizado!.isNotEmpty) {
        final texto = ida.apoyo_realizado!;
        if (texto.startsWith('[')) {
          final fin_actividad = texto.indexOf(']');
          if (fin_actividad > 1) {
            final act = texto.substring(1, fin_actividad);
            if (TIPOS_ACTIVIDAD.contains(act)) {
              _tipo_actividad = act;
            }
            final resto = texto.substring(fin_actividad + 1).trim();
            final partes_resto = resto.split('| Calles:');
            if (partes_resto.isNotEmpty) {
              _apoyo_controlador.text = partes_resto.first.trim();
            }
          }
        } else {
          final partes = texto.split('| Calles:');
          _apoyo_controlador.text = partes.first.trim();
        }
      }

      List<String> paradas_texto = [];
      if (ida.detalle_tramos_json != null && ida.detalle_tramos_json!.isNotEmpty) {
        try {
          final json_data = jsonDecode(ida.detalle_tramos_json!) as Map<String, dynamic>;
          if (json_data['calles_paradas'] is List) {
            paradas_texto = (json_data['calles_paradas'] as List)
                .map((e) => e.toString())
                .where((s) => s.isNotEmpty)
                .toList();
          }
        } catch (_) {}
      }
      if (paradas_texto.isEmpty && ida.calles_declaradas != null && ida.calles_declaradas!.isNotEmpty) {
        paradas_texto = ida.calles_declaradas!.split(' → ').where((s) => s.isNotEmpty).toList();
      }
      if (paradas_texto.isEmpty) {
        paradas_texto = [ida.origen, ida.destino];
      }

      if (paradas_texto.length >= 2) {
        for (final p in _paradas_ida) {
          p.dispose();
        }
        _paradas_ida.clear();
        for (int i = 0; i < paradas_texto.length; i++) {
          final pos = (i == 0 && ida.lat_origen != null && ida.lng_origen != null)
              ? Position(
                  latitude: ida.lat_origen!,
                  longitude: ida.lng_origen!,
                  timestamp: DateTime.now(),
                  accuracy: 10,
                  altitude: 0,
                  altitudeAccuracy: 0,
                  heading: 0,
                  headingAccuracy: 0,
                  speed: 0,
                  speedAccuracy: 0,
                )
              : (i == paradas_texto.length - 1 && ida.lat_destino != null && ida.lng_destino != null)
                  ? Position(
                      latitude: ida.lat_destino!,
                      longitude: ida.lng_destino!,
                      timestamp: DateTime.now(),
                      accuracy: 10,
                      altitude: 0,
                      altitudeAccuracy: 0,
                      heading: 0,
                      headingAccuracy: 0,
                      speed: 0,
                      speedAccuracy: 0,
                    )
                  : null;
          _paradas_ida.add(
            _ParadaRuta(
              controlador: TextEditingController(text: paradas_texto[i]),
              posicion_gps: pos,
              confirmada: pos != null,
            ),
          );
        }
      }

      List<Map<String, dynamic>> tramos_data = [];
      if (ida.detalle_tramos_json != null && ida.detalle_tramos_json!.isNotEmpty) {
        try {
          final json_data = jsonDecode(ida.detalle_tramos_json!) as Map<String, dynamic>;
          if (json_data['tramos'] is List) {
            tramos_data = (json_data['tramos'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
        } catch (_) {}
      }
      if (tramos_data.isNotEmpty) {
        for (final t in _tramos_ida) {
          t.dispose();
        }
        _tramos_ida.clear();
        for (final item in tramos_data) {
          final monto = double.tryParse(item['monto']?.toString() ?? '') ?? 2.0;
          final nombre = item['nombre']?.toString() ?? 'Minibús';
          _tramos_ida.add(
            _TramoTarifa(
              monto: monto,
              nombre: nombre,
              controlador_personalizado: TextEditingController(text: monto.toStringAsFixed(2)),
            ),
          );
        }
      } else if (ida.tarifa > 0) {
        for (final t in _tramos_ida) {
          t.dispose();
        }
        _tramos_ida.clear();
        _tramos_ida.add(
          _TramoTarifa(
            monto: ida.tarifa,
            nombre: ida.medio_transporte ?? "Minibús",
            controlador_personalizado: TextEditingController(text: ida.tarifa.toStringAsFixed(2)),
          ),
        );
      }
    }

    if (vuelta != null) {
      List<String> paradas_texto = [];
      if (vuelta.detalle_tramos_json != null && vuelta.detalle_tramos_json!.isNotEmpty) {
        try {
          final json_data = jsonDecode(vuelta.detalle_tramos_json!) as Map<String, dynamic>;
          if (json_data['calles_paradas'] is List) {
            paradas_texto = (json_data['calles_paradas'] as List)
                .map((e) => e.toString())
                .where((s) => s.isNotEmpty)
                .toList();
          }
        } catch (_) {}
      }
      if (paradas_texto.isEmpty && vuelta.calles_declaradas != null && vuelta.calles_declaradas!.isNotEmpty) {
        paradas_texto = vuelta.calles_declaradas!.split(' → ').where((s) => s.isNotEmpty).toList();
      }
      if (paradas_texto.isEmpty) {
        paradas_texto = [vuelta.origen, vuelta.destino];
      }

      if (paradas_texto.length >= 2) {
        for (final p in _paradas_vuelta) {
          p.dispose();
        }
        _paradas_vuelta.clear();
        for (int i = 0; i < paradas_texto.length; i++) {
          final pos = (i == 0 && vuelta.lat_origen != null && vuelta.lng_origen != null)
              ? Position(
                  latitude: vuelta.lat_origen!,
                  longitude: vuelta.lng_origen!,
                  timestamp: DateTime.now(),
                  accuracy: 10,
                  altitude: 0,
                  altitudeAccuracy: 0,
                  heading: 0,
                  headingAccuracy: 0,
                  speed: 0,
                  speedAccuracy: 0,
                )
              : (i == paradas_texto.length - 1 && vuelta.lat_destino != null && vuelta.lng_destino != null)
                  ? Position(
                      latitude: vuelta.lat_destino!,
                      longitude: vuelta.lng_destino!,
                      timestamp: DateTime.now(),
                      accuracy: 10,
                      altitude: 0,
                      altitudeAccuracy: 0,
                      heading: 0,
                      headingAccuracy: 0,
                      speed: 0,
                      speedAccuracy: 0,
                    )
                  : null;
          _paradas_vuelta.add(
            _ParadaRuta(
              controlador: TextEditingController(text: paradas_texto[i]),
              posicion_gps: pos,
              confirmada: pos != null,
            ),
          );
        }
      }

      List<Map<String, dynamic>> tramos_data = [];
      if (vuelta.detalle_tramos_json != null && vuelta.detalle_tramos_json!.isNotEmpty) {
        try {
          final json_data = jsonDecode(vuelta.detalle_tramos_json!) as Map<String, dynamic>;
          if (json_data['tramos'] is List) {
            tramos_data = (json_data['tramos'] as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          }
        } catch (_) {}
      }
      if (tramos_data.isNotEmpty) {
        for (final t in _tramos_vuelta) {
          t.dispose();
        }
        _tramos_vuelta.clear();
        for (final item in tramos_data) {
          final monto = double.tryParse(item['monto']?.toString() ?? '') ?? 2.0;
          final nombre = item['nombre']?.toString() ?? 'Minibús';
          _tramos_vuelta.add(
            _TramoTarifa(
              monto: monto,
              nombre: nombre,
              controlador_personalizado: TextEditingController(text: monto.toStringAsFixed(2)),
            ),
          );
        }
      } else if (vuelta.tarifa > 0) {
        for (final t in _tramos_vuelta) {
          t.dispose();
        }
        _tramos_vuelta.clear();
        _tramos_vuelta.add(
          _TramoTarifa(
            monto: vuelta.tarifa,
            nombre: vuelta.medio_transporte ?? "Minibús",
            controlador_personalizado: TextEditingController(text: vuelta.tarifa.toStringAsFixed(2)),
          ),
        );
      }
    }

    setState(() {});
  }

  Widget _construirTarjetaEstadoHoy(
    RecorridoModelo? ida_hoy,
    RecorridoModelo? vuelta_hoy,
  ) {
    final subtotal_registrado = (ida_hoy?.tarifa ?? 0.0) + (vuelta_hoy?.tarifa ?? 0.0);
    final devolucion_registrada = subtotal_registrado * 0.8;

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC)),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Recorrido de hoy declarado",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF14532D),
                      ),
                    ),
                    Text(
                      "Disponible para editar sólo hoy · Puedes ajustar cualquier parada o tarifa",
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Column(
              children: [
                if (ida_hoy != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Ida: ${ida_hoy.origen} → ${ida_hoy.destino}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Bs ${ida_hoy.tarifa.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: BumandColores.AZUL_DIACONIA,
                        ),
                      ),
                    ],
                  ),
                if (vuelta_hoy != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Vuelta: ${vuelta_hoy.origen} → ${vuelta_hoy.destino}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Bs ${vuelta_hoy.tarifa.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: BumandColores.AZUL_DIACONIA,
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 12, color: Color(0xFFE2E8F0)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total guardado (Devolución 80%):",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "Bs ${subtotal_registrado.toStringAsFixed(2)} (Bs ${devolucion_registrada.toStringAsFixed(2)})",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D),
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

  Widget _construirTarjetaFechaHoy() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBAE6FD)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: BumandColores.AZUL_DIACONIA,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Recorrido de hoy: ${FormatoPasajes.fechaCompleta(_fecha)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                const Row(
                  children: [
                    Icon(
                      Icons.lock_clock_outlined,
                      size: 13,
                      color: Color(0xFF0284C7),
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Disponible para editar sólo hoy",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Text(
              "HOY",
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF065F46),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cargarUltimoRecorrido() async {
    final preferencias = await SharedPreferences.getInstance();
    final origen = preferencias.getString(_CLAVE_ORIGEN);
    final destino = preferencias.getString(_CLAVE_DESTINO);
    if (!mounted) return;
    setState(() {
      if (origen != null && origen.isNotEmpty && _paradas_ida.isNotEmpty) {
        _paradas_ida[0].controlador.text = origen;
      }
      if ((widget.destino_inicial == null || widget.destino_inicial!.isEmpty) &&
          destino != null &&
          destino.isNotEmpty &&
          _paradas_ida.length > 1) {
        _paradas_ida[1].controlador.text = destino;
      }
    });
  }

  void _mensaje(String texto, {bool es_error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor:
            es_error ? Colors.red.shade700 : BumandColores.TURQUESA_DIACONIA,
      ),
    );
  }

  Future<void> _capturarGps(String identificador, _ParadaRuta parada) async {
    setState(() => _capturando_gps_id = identificador);
    HapticFeedback.selectionClick();
    try {
      final servicioHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicioHabilitado) {
        _mensaje("Activa el servicio de GPS", es_error: true);
        return;
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          _mensaje("Permiso GPS denegado", es_error: true);
          return;
        }
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!mounted) return;
      setState(() {
        parada.posicion_gps = posicion;
        if (parada.controlador.text.trim().isEmpty) {
          parada.controlador.text =
              "GPS (${posicion.latitude.toStringAsFixed(4)}, ${posicion.longitude.toStringAsFixed(4)})";
        }
      });
      _mensaje("📍 Ubicación fijada (±${posicion.accuracy.round()} m)");
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (parada.controlador.text.trim().isEmpty) {
          parada.controlador.text = "Villa Adela, El Alto";
        }
      });
      _mensaje("📍 Ubicación fijada por aproximación local");
    } finally {
      if (mounted) setState(() => _capturando_gps_id = null);
    }
  }

  void _usarIdaEnReversa() {
    HapticFeedback.heavyImpact();
    setState(() {
      final valores_ida = _paradas_ida
          .map((p) => p.controlador.text.trim())
          .where((t) => t.isNotEmpty)
          .toList()
          .reversed
          .toList();

      if (valores_ida.isNotEmpty) {
        for (final p in _paradas_vuelta) {
          p.dispose();
        }
        _paradas_vuelta.clear();

        for (final val in valores_ida) {
          _paradas_vuelta.add(
            _ParadaRuta(
              controlador: TextEditingController(text: val),
              confirmada: true,
            ),
          );
        }
      }

      // Replicar monto de la ida
      final total_ida = _calcularSubtotal(_tramos_ida);
      for (final t in _tramos_vuelta) {
        t.dispose();
      }
      _tramos_vuelta.clear();
      _tramos_vuelta.add(
        _TramoTarifa(
          monto: total_ida,
          nombre: "Ida en reversa",
          controlador_personalizado: TextEditingController(
            text: total_ida.toStringAsFixed(2),
          ),
        ),
      );
    });

    _mensaje("↺ Ruta y tarifa de ida invertidas para la vuelta");
  }

  double _calcularSubtotal(List<_TramoTarifa> tramos) {
    return tramos.fold(0.0, (acc, t) => acc + t.monto);
  }

  Future<void> _guardarRecorridoFinal() async {
    final origen = _paradas_ida.isNotEmpty
        ? _paradas_ida.first.controlador.text.trim()
        : "";
    final destino = _paradas_ida.length > 1
        ? _paradas_ida.last.controlador.text.trim()
        : "";

    if (origen.isEmpty || destino.isEmpty) {
      _mensaje("Completa el origen y destino de la ida", es_error: true);
      return;
    }

    if (_tieneParadasDuplicadas(_paradas_ida)) {
      _mensaje(
        "No puedes elegir dos veces el mismo lugar en el tramo de ida",
        es_error: true,
      );
      return;
    }

    if (_tieneParadasDuplicadas(_paradas_vuelta)) {
      _mensaje(
        "No puedes elegir dos veces el mismo lugar en el tramo de vuelta",
        es_error: true,
      );
      return;
    }

    final total_ida = _calcularSubtotal(_tramos_ida);
    if (total_ida <= 0) {
      _mensaje("Selecciona al menos una tarifa para la ida", es_error: true);
      return;
    }

    setState(() => _guardando = true);

    final fecha_str = FormatoPasajes.fechaApi(_fecha);
    final texto_apoyo = _apoyo_controlador.text.trim();
    final repositorio = ref.read(pasajes_repositorio_proveedor);

    if (_id_recorrido_ida_hoy != null) {
      await repositorio.eliminarRecorrido(_id_recorrido_ida_hoy!);
    }
    if (_id_recorrido_vuelta_hoy != null) {
      await repositorio.eliminarRecorrido(_id_recorrido_vuelta_hoy!);
    }

    // Tramo IDA: Calles completas, medios y detalle JSON
    final calles_ida = _paradas_ida
        .map((p) => p.controlador.text.trim())
        .where((t) => t.isNotEmpty)
        .join(' → ');

    final medios_ida_set = _tramos_ida
        .map((t) => t.nombre ?? "Minibús")
        .where((n) => n.isNotEmpty)
        .toSet();
    final medios_ida = medios_ida_set.isNotEmpty
        ? medios_ida_set.join(" + ")
        : "Minibús";

    final detalle_ida_json = jsonEncode({
      "sentido": "ida",
      "calles_paradas": _paradas_ida.map((p) => p.controlador.text.trim()).toList(),
      "tramos": _tramos_ida
          .map((t) => {
                "nombre": t.nombre ?? "Minibús",
                "monto": t.monto,
              })
          .toList(),
    });

    final apoyo_ida = texto_apoyo.isNotEmpty
        ? "[$_tipo_actividad] $texto_apoyo | Calles: $calles_ida | Transporte: $medios_ida"
        : "[$_tipo_actividad] Calles: $calles_ida | Transporte: $medios_ida";

    final ida = await repositorio.agregarRecorrido(
      fecha: fecha_str,
      tramo: "ida",
      origen: origen,
      destino: destino,
      tarifa: total_ida,
      apoyo_realizado: apoyo_ida,
      calles_declaradas: calles_ida,
      medio_transporte: medios_ida,
      detalle_tramos_json: detalle_ida_json,
      lat_origen: _paradas_ida.first.posicion_gps?.latitude,
      lng_origen: _paradas_ida.first.posicion_gps?.longitude,
      lat_destino: _paradas_ida.last.posicion_gps?.latitude,
      lng_destino: _paradas_ida.last.posicion_gps?.longitude,
    );

    if (!mounted) return;

    if (!ida.exito) {
      setState(() => _guardando = false);
      _mensaje(ida.error ?? "Error al registrar la ida", es_error: true);
      return;
    }

    final total_vuelta = _calcularSubtotal(_tramos_vuelta);
    if (total_vuelta > 0 && _paradas_vuelta.isNotEmpty) {
      final origen_vuelta = _paradas_vuelta.first.controlador.text.trim();
      final destino_vuelta = _paradas_vuelta.last.controlador.text.trim();

      // Tramo VUELTA: Calles completas, medios y detalle JSON
      final calles_vuelta = _paradas_vuelta
          .map((p) => p.controlador.text.trim())
          .where((t) => t.isNotEmpty)
          .join(' → ');

      final medios_vuelta_set = _tramos_vuelta
          .map((t) => t.nombre ?? "Minibús")
          .where((n) => n.isNotEmpty)
          .toSet();
      final medios_vuelta = medios_vuelta_set.isNotEmpty
          ? medios_vuelta_set.join(" + ")
          : "Minibús";

      final detalle_vuelta_json = jsonEncode({
        "sentido": "vuelta",
        "calles_paradas": _paradas_vuelta.map((p) => p.controlador.text.trim()).toList(),
        "tramos": _tramos_vuelta
            .map((t) => {
                  "nombre": t.nombre ?? "Minibús",
                  "monto": t.monto,
                })
            .toList(),
      });

      final apoyo_vuelta = texto_apoyo.isNotEmpty
          ? "[$_tipo_actividad] $texto_apoyo | Calles: $calles_vuelta | Transporte: $medios_vuelta"
          : "[$_tipo_actividad] Calles: $calles_vuelta | Transporte: $medios_vuelta";

      await repositorio.agregarRecorrido(
        fecha: fecha_str,
        tramo: "vuelta",
        origen: origen_vuelta.isNotEmpty ? origen_vuelta : destino,
        destino: destino_vuelta.isNotEmpty ? destino_vuelta : origen,
        tarifa: total_vuelta,
        apoyo_realizado: apoyo_vuelta,
        calles_declaradas: calles_vuelta,
        medio_transporte: medios_vuelta,
        detalle_tramos_json: detalle_vuelta_json,
        lat_origen: _paradas_vuelta.first.posicion_gps?.latitude,
        lng_origen: _paradas_vuelta.first.posicion_gps?.longitude,
        lat_destino: _paradas_vuelta.last.posicion_gps?.latitude,
        lng_destino: _paradas_vuelta.last.posicion_gps?.longitude,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_CLAVE_ORIGEN, origen);
    await prefs.setString(_CLAVE_DESTINO, destino);

    ref.invalidate(solicitudes_pasajes_proveedor);

    if (!mounted) return;
    if (widget.es_pestana) {
      setState(() {
        _guardando = false;
        _formulario_inicializado_con_hoy = false;
      });
      _mensaje(
        (_id_recorrido_ida_hoy != null || _id_recorrido_vuelta_hoy != null)
            ? "✓ Recorrido de hoy actualizado correctamente"
            : "✓ Recorrido de hoy guardado correctamente",
      );
    } else {
      _mensaje("✓ Recorrido del día guardado correctamente");
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal_ida = _calcularSubtotal(_tramos_ida);
    final subtotal_vuelta = _calcularSubtotal(_tramos_vuelta);
    final total_dia = subtotal_ida + subtotal_vuelta;
    final devolucion_80 = total_dia * 0.8;

    final solicitudes_async = ref.watch(solicitudes_pasajes_proveedor);
    final solicitudes = solicitudes_async.asData?.value ?? [];
    final hoy = DateTime.now();

    RecorridoModelo? rec_ida_hoy;
    RecorridoModelo? rec_vuelta_hoy;

    for (final s in solicitudes) {
      for (final r in s.recorridos) {
        if (_esMismaFecha(r.fecha, hoy)) {
          if (r.tramo.toLowerCase() == 'ida') {
            rec_ida_hoy = r;
          } else if (r.tramo.toLowerCase() == 'vuelta') {
            rec_vuelta_hoy = r;
          }
        }
      }
    }

    if (widget.solo_hoy &&
        !_formulario_inicializado_con_hoy &&
        (rec_ida_hoy != null || rec_vuelta_hoy != null)) {
      _formulario_inicializado_con_hoy = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _cargarDatosDesdeRecorridosExistentes(rec_ida_hoy, rec_vuelta_hoy);
        }
      });
    }

    final bool ya_declarado_hoy = (rec_ida_hoy != null ||
        rec_vuelta_hoy != null ||
        _id_recorrido_ida_hoy != null);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      appBar: widget.es_pestana
          ? BarraSuperiorBumand(
              titulo: "Declarar pasajes",
              subtitulo: "Recorrido de hoy",
              alTocarLogo: () =>
                  ref.read(menu_principal_proveedor.notifier).mostrar(),
            )
          : AppBar(
              title: const Text(
                "Declarar recorrido",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              foregroundColor: BumandColores.NEGRO,
            ),
      body: Form(
        key: _clave_formulario,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Chip o tarjeta de estado de hoy
            if (widget.solo_hoy && ya_declarado_hoy)
              _construirTarjetaEstadoHoy(rec_ida_hoy, rec_vuelta_hoy)
            else
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Color(0xFF10B981), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        widget.solo_hoy
                            ? "Declaración activa para hoy"
                            : "Correo y datos confirmados",
                        style: const TextStyle(
                          color: Color(0xFF065F46),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Mapa interactivo del trayecto declarado (Ida / Vuelta)
            _construirMapaRutaRecorrido(),
            const SizedBox(height: 14),

            // Selector de Tipo de Actividad (Prácticas, Escuela de Líderes, Acciones de Servicio)
            _construirSelectorTipoActividad(),
            const SizedBox(height: 14),

            // Campo de Apoyo Realizado
            const Text(
              "Apoyo realizado",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _apoyo_controlador,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Ej. Envío de reportes, control CAEDEC",
                prefixIcon: const Icon(
                  Icons.assignment_outlined,
                  color: BumandColores.AZUL_DIACONIA,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Selector de fecha del recorrido o Tarjeta fija de Hoy
            if (widget.solo_hoy)
              _construirTarjetaFechaHoy()
            else
              SeleccionadorFecha(
                fecha: _fecha,
                onCambiada: (v) => setState(() => _fecha = v),
                primeraFecha: DateTime(
                  DateTime.now().year,
                  DateTime.now().month - 2,
                  1,
                ),
                ultimaFecha: DateTime.now(),
                etiqueta: "Fecha del recorrido",
              ),
            const SizedBox(height: 16),

            // Stepper Segmentado: 1 · Ida  |  2 · Vuelta
            _construirStepperTabs(subtotal_ida, subtotal_vuelta),
            const SizedBox(height: 16),

            // Contenido dinámico según el paso activo
            if (_paso_activo == 1)
              _construirPasoIda(subtotal_ida)
            else
              _construirPasoVuelta(subtotal_vuelta),

            const SizedBox(height: 20),

            // Tarjeta de Cálculo Instantáneo (Monto Total + Devolución del 80%)
            _construirTarjetaCalculo(total_dia, devolucion_80),
            const SizedBox(height: 20),

            // Botón Guardar Recorrido del Día
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _guardando ? null : _guardarRecorridoFinal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BumandColores.NARANJA,
                  foregroundColor: BumandColores.NEGRO,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        (widget.solo_hoy && ya_declarado_hoy)
                            ? Icons.published_with_changes_rounded
                            : Icons.check_circle_outline,
                      ),
                label: Text(
                  widget.solo_hoy
                      ? (ya_declarado_hoy
                          ? "Actualizar recorrido de hoy"
                          : "Guardar recorrido de hoy")
                      : "Guardar recorrido del día",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (widget.es_pestana) ...[
              const SizedBox(height: 14),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    ref.read(pestana_inicio_proveedor.notifier).cambiarPestana(3);
                  },
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: const Text(
                    "Ver historial mensual de pasajes",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: BumandColores.AZUL_DIACONIA,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _construirStepperTabs(double subtotal_ida, double subtotal_vuelta) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _paso_activo = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _paso_activo == 1
                      ? BumandColores.AZUL_DIACONIA
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "1 · Ida (Bs ${subtotal_ida.toStringAsFixed(2)})",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _paso_activo == 1 ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _paso_activo = 2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _paso_activo == 2
                      ? BumandColores.AZUL_DIACONIA
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "2 · Vuelta (Bs ${subtotal_vuelta.toStringAsFixed(2)})",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _paso_activo == 2 ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirPasoIda(double subtotal_ida) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCBD5E1)),
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
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: BumandColores.TURQUESA_DIACONIA,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "IDA",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                "Bs ${subtotal_ida.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: BumandColores.AZUL_DIACONIA,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Paradas dinámicas de la Ida con autocompletado integrado
          for (int i = 0; i < _paradas_ida.length; i++)
            _construirFilaParada(
              numero: i + 1,
              parada: _paradas_ida[i],
              es_ida: true,
              puede_eliminar: _paradas_ida.length > 2,
              alEliminar: () {
                setState(() {
                  _paradas_ida[i].dispose();
                  _paradas_ida.removeAt(i);
                });
              },
            ),

          TextButton.icon(
            onPressed: () {
              setState(() {
                final indice_insercion = _paradas_ida.length >= 2
                    ? _paradas_ida.length - 1
                    : _paradas_ida.length;
                _paradas_ida.insert(
                  indice_insercion,
                  _ParadaRuta(controlador: TextEditingController()),
                );
              });
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text("Agregar parada intermedia"),
            style: TextButton.styleFrom(
              foregroundColor: BumandColores.AZUL_DIACONIA,
            ),
          ),
          const Divider(height: 24),

          // Caja de tarifas de la ida
          const Text(
            "TARIFA DE LA IDA (La Paz y El Alto)",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),

          for (int t = 0; t < _tramos_ida.length; t++)
            _construirSelectorTarifaTramo(_tramos_ida[t], () {
              if (_tramos_ida.length > 1) {
                setState(() {
                  _tramos_ida[t].dispose();
                  _tramos_ida.removeAt(t);
                });
              }
            }),

          TextButton.icon(
            onPressed: () {
              setState(() {
                _tramos_ida.add(
                  _TramoTarifa(
                    monto: 2.0,
                    nombre: "Minibús (dentro de El Alto)",
                    controlador_personalizado:
                        TextEditingController(text: "2.00"),
                  ),
                );
              });
            },
            icon: const Icon(Icons.add_road, size: 16),
            label: const Text("Agregar tramo de tarifa (transbordo)"),
            style: TextButton.styleFrom(
              foregroundColor: BumandColores.AZUL_DIACONIA,
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_tieneParadasDuplicadas(_paradas_ida)) {
                  _mensaje(
                    "No puedes elegir dos veces el mismo lugar en el tramo de ida",
                    es_error: true,
                  );
                  return;
                }
                HapticFeedback.lightImpact();
                setState(() => _paso_activo = 2);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BumandColores.TURQUESA_DIACONIA,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Siguiente: Vuelta →"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirPasoVuelta(double subtotal_vuelta) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _paso_activo = 1),
                icon: const Icon(Icons.arrow_back, size: 14),
                label: const Text("← Volver a Ida"),
                style: TextButton.styleFrom(
                  foregroundColor: BumandColores.AZUL_DIACONIA,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Text(
                "Bs ${subtotal_vuelta.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: BumandColores.NARANJA_OSCURO,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Botón destacado: ↺ Usar la ida en reversa
          InkWell(
            onTap: _usarIdaEnReversa,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.swap_horiz, color: Color(0xFFB45309), size: 20),
                  SizedBox(width: 8),
                  Text(
                    "↺ Usar la ida en reversa",
                    style: TextStyle(
                      color: Color(0xFF92400E),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Paradas dinámicas de la Vuelta
          for (int i = 0; i < _paradas_vuelta.length; i++)
            _construirFilaParada(
              numero: i + 1,
              parada: _paradas_vuelta[i],
              es_ida: false,
              puede_eliminar: _paradas_vuelta.length > 2,
              alEliminar: () {
                setState(() {
                  _paradas_vuelta[i].dispose();
                  _paradas_vuelta.removeAt(i);
                });
              },
            ),

          TextButton.icon(
            onPressed: () {
              setState(() {
                final indice_insercion = _paradas_vuelta.length >= 2
                    ? _paradas_vuelta.length - 1
                    : _paradas_vuelta.length;
                _paradas_vuelta.insert(
                  indice_insercion,
                  _ParadaRuta(controlador: TextEditingController()),
                );
              });
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text("Agregar parada intermedia"),
            style: TextButton.styleFrom(
              foregroundColor: BumandColores.AZUL_DIACONIA,
            ),
          ),
          const Divider(height: 24),

          // Caja de tarifas de la vuelta
          const Text(
            "TARIFA DE LA VUELTA (La Paz y El Alto)",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),

          for (int t = 0; t < _tramos_vuelta.length; t++)
            _construirSelectorTarifaTramo(_tramos_vuelta[t], () {
              if (_tramos_vuelta.length > 1) {
                setState(() {
                  _tramos_vuelta[t].dispose();
                  _tramos_vuelta.removeAt(t);
                });
              }
            }),

          TextButton.icon(
            onPressed: () {
              setState(() {
                _tramos_vuelta.add(
                  _TramoTarifa(
                    monto: 2.0,
                    nombre: "Minibús (dentro de El Alto)",
                    controlador_personalizado:
                        TextEditingController(text: "2.00"),
                  ),
                );
              });
            },
            icon: const Icon(Icons.add_road, size: 16),
            label: const Text("Agregar tramo de tarifa (transbordo)"),
            style: TextButton.styleFrom(
              foregroundColor: BumandColores.AZUL_DIACONIA,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirSelectorTipoActividad() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tipo de actividad",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: TIPOS_ACTIVIDAD.map((tipo) {
              final seleccionado = _tipo_actividad == tipo;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tipo_actividad = tipo),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: seleccionado
                          ? BumandColores.AZUL_DIACONIA
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      tipo,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: seleccionado
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _construirFilaParada({
    required int numero,
    required _ParadaRuta parada,
    required bool es_ida,
    required bool puede_eliminar,
    required VoidCallback alEliminar,
  }) {
    final lista_paradas = es_ida ? _paradas_ida : _paradas_vuelta;
    final es_ultima = numero == lista_paradas.length;
    final opciones_disponibles = _obtenerOpcionesParadaDisponibles(
      lista_paradas,
      numero - 1,
    );

    return Container(
      key: ObjectKey(parada),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Número de parada
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF1F5F9),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Center(
              child: Text(
                '$numero',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Pin GPS
          IconButton(
            icon: Text(
              parada.posicion_gps != null ? "✓" : "📍",
              style: const TextStyle(fontSize: 16),
            ),
            tooltip: "Fijar ubicación GPS",
            visualDensity: VisualDensity.compact,
            onPressed: _capturando_gps_id != null
                ? null
                : () => _capturarGps('parada_${es_ida ? "ida" : "vuelta"}_$numero', parada),
          ),

          // Campo dinámico con autocompletado y menú de paradas frecuentes sin duplicados
          Expanded(
            child: _CampoParadaCombobox(
              key: ObjectKey(parada.controlador),
              controlador: parada.controlador,
              pista: numero == 1
                  ? "Origen (escribe o elige parada)"
                  : es_ultima
                      ? "Destino final (escribe o elige parada)"
                      : "Parada intermedia $numero",
              opciones: opciones_disponibles,
              alCambiar: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 6),

          // Botón Confirmar / ✓ En esta parada
          GestureDetector(
            onTap: () {
              if (parada.controlador.text.trim().isEmpty) {
                _mensaje("Ingresa el nombre o fija el GPS de la parada");
                return;
              }
              HapticFeedback.lightImpact();
              setState(() {
                parada.confirmada = !parada.confirmada;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: parada.confirmada
                    ? const Color(0xFF10B981)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: parada.confirmada
                      ? const Color(0xFF059669)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: Text(
                parada.confirmada ? "✓ En esta parada" : "Confirmar",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: parada.confirmada ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          ),

          if (puede_eliminar) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
              visualDensity: VisualDensity.compact,
              onPressed: alEliminar,
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirSelectorTarifaTramo(
    _TramoTarifa tramo,
    VoidCallback alEliminar,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: TARIFAS_PREDEFINIDAS
                            .any((p) => p["nombre"] == tramo.nombre)
                        ? tramo.nombre
                        : null,
                    hint: Text(
                      tramo.nombre != null && tramo.nombre!.isNotEmpty
                          ? (tramo.nombre == "Otro (escribir monto)..."
                              ? "Otro (Bs ${tramo.monto.toStringAsFixed(2)})"
                              : tramo.nombre!)
                          : "Selecciona una tarifa...",
                      style: const TextStyle(fontSize: 13),
                    ),
                    isExpanded: true,
                    items: [
                      ...TARIFAS_PREDEFINIDAS.map((p) {
                        final nombre = p["nombre"] as String;
                        final monto = p["monto"] as double;
                        return DropdownMenuItem<String>(
                          value: nombre,
                          child: Text(
                            nombre == "Otro (escribir monto)..."
                                ? nombre
                                : "Bs ${monto.toStringAsFixed(2)} — $nombre",
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        );
                      }),
                    ],
                    onChanged: (nuevoNombre) {
                      if (nuevoNombre != null) {
                        final item = TARIFAS_PREDEFINIDAS
                            .firstWhere((p) => p["nombre"] == nuevoNombre);
                        final monto = item["monto"] as double;
                        setState(() {
                          tramo.nombre = nuevoNombre;
                          if (nuevoNombre != "Otro (escribir monto)...") {
                            tramo.monto = monto;
                            tramo.controlador_personalizado.text =
                                monto.toStringAsFixed(2);
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                visualDensity: VisualDensity.compact,
                onPressed: alEliminar,
              ),
            ],
          ),
          if (tramo.nombre == "Otro (escribir monto)...") ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  "Bs ",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: tramo.controlador_personalizado,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      hintText: "0.00",
                    ),
                    onChanged: (val) {
                      final n = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                      setState(() {
                        tramo.monto = n;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "Ingresa el monto del tramo",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirTarjetaCalculo(double total_dia, double devolucion_80) {
    return Container(
      width: double.infinity,
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
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Monto total del pasaje",
            style: TextStyle(
              color: Color(0xFFBEE3F8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            "Bs ${total_dia.toStringAsFixed(2)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 18, color: Colors.white24),
          const Text(
            "Devolución del 80%",
            style: TextStyle(
              color: Color(0xFFBEE3F8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            "Bs ${devolucion_80.toStringAsFixed(2)}",
            style: const TextStyle(
              color: BumandColores.NARANJA,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirMapaRutaRecorrido() {
    final paradas_activas = _paso_activo == 1 ? _paradas_ida : _paradas_vuelta;
    final tramos_activos = _paso_activo == 1 ? _tramos_ida : _tramos_vuelta;
    final nombres_paradas = paradas_activas
        .map((p) => p.controlador.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final origen_txt =
        nombres_paradas.isNotEmpty ? nombres_paradas.first : "Origen por definir";
    final destino_txt =
        nombres_paradas.length > 1 ? nombres_paradas.last : "Destino por definir";
    final medios_txt = tramos_activos
        .map((t) => t.nombre ?? "Minibús")
        .where((n) => n.isNotEmpty)
        .toSet()
        .join(" + ");

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F294A), Color(0xFF153E6C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F294A).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.map_outlined,
                      color: Color(0xFF38BDF8),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _paso_activo == 1
                        ? "Mapa de Ruta · Tramo de Ida"
                        : "Mapa de Ruta · Tramo de Vuelta",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF34D399).withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  "${nombres_paradas.length} paradas",
                  style: const TextStyle(
                    color: Color(0xFF6EE7B7),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: _PintorMapaTrayecto(
                  paradas: nombres_paradas.isEmpty
                      ? ["Origen", "Destino"]
                      : nombres_paradas,
                  es_vuelta: _paso_activo == 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.trip_origin,
                size: 13,
                color: Color(0xFF38BDF8),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  "$origen_txt  →  $destino_txt",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFE2E8F0),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                medios_txt.isNotEmpty ? medios_txt : "Minibús",
                style: const TextStyle(
                  color: Color(0xFFFBBF24),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PintorMapaTrayecto extends CustomPainter {
  final List<String> paradas;
  final bool es_vuelta;

  _PintorMapaTrayecto({
    required this.paradas,
    required this.es_vuelta,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fondo_paint = Paint()..color = const Color(0xFF0A1D37);
    canvas.drawRect(Offset.zero & size, fondo_paint);

    final grilla_paint = Paint()
      ..color = const Color(0xFF1E3A5F).withValues(alpha: 0.55)
      ..strokeWidth = 1;

    const paso_grilla = 24.0;
    for (double x = 0; x < size.width; x += paso_grilla) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grilla_paint);
    }
    for (double y = 0; y < size.height; y += paso_grilla) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grilla_paint);
    }

    // Avenidas referenciales estilizadas (Autopista La Paz - El Alto / Av. Juan Pablo II)
    final avenida_paint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.7)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final via_path = Path()
      ..moveTo(0, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.25,
        size.width,
        size.height * 0.45,
      );
    canvas.drawPath(via_path, avenida_paint);

    final total = paradas.length < 2 ? 2 : paradas.length;
    final puntos = <Offset>[];
    final margen_x = 34.0;
    final ancho_util = (size.width - margen_x * 2).clamp(40.0, size.width);

    for (int i = 0; i < total; i++) {
      final t = total == 1 ? 0.5 : i / (total - 1);
      final x = margen_x + ancho_util * t;
      final variacion_y = (i.isEven ? 0.62 : 0.36);
      final y = size.height * variacion_y;
      puntos.add(Offset(x, y));
    }

    // Sombra de ruta activa
    final ruta_sombra = Paint()
      ..color = (es_vuelta
              ? const Color(0xFFF59E0B)
              : const Color(0xFF38BDF8))
          .withValues(alpha: 0.28)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final ruta_paint = Paint()
      ..color = es_vuelta ? const Color(0xFFFBBF24) : const Color(0xFF38BDF8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path_ruta = Path()..moveTo(puntos.first.dx, puntos.first.dy);
    for (int i = 1; i < puntos.length; i++) {
      final prev = puntos[i - 1];
      final curr = puntos[i];
      final ctrl_x = (prev.dx + curr.dx) / 2;
      path_ruta.cubicTo(ctrl_x, prev.dy, ctrl_x, curr.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(path_ruta, ruta_sombra);
    canvas.drawPath(path_ruta, ruta_paint);

    // Dibujar nodos y etiquetas de cada parada
    for (int i = 0; i < puntos.length; i++) {
      final p = puntos[i];
      final es_extremo = i == 0 || i == puntos.length - 1;
      final color_nodo = i == 0
          ? const Color(0xFF38BDF8)
          : (i == puntos.length - 1
              ? const Color(0xFF10B981)
              : const Color(0xFFFBBF24));

      canvas.drawCircle(
        p,
        es_extremo ? 9 : 6,
        Paint()..color = color_nodo.withValues(alpha: 0.28),
      );
      canvas.drawCircle(
        p,
        es_extremo ? 5.5 : 4,
        Paint()..color = color_nodo,
      );
      canvas.drawCircle(
        p,
        2,
        Paint()..color = Colors.white,
      );

      final texto_parada = i < paradas.length ? paradas[i] : "Parada ${i + 1}";
      final etiqueta_corta = texto_parada.length > 16
          ? "${texto_parada.substring(0, 15)}…"
          : texto_parada;

      final tp = TextPainter(
        text: TextSpan(
          text: etiqueta_corta,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final dy_texto = (i.isEven) ? p.dy + 10 : p.dy - 22;
      final dx_texto =
          (p.dx - tp.width / 2).clamp(6.0, size.width - tp.width - 6.0);

      final rect_etiqueta = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          dx_texto - 4,
          dy_texto - 2,
          tp.width + 8,
          tp.height + 4,
        ),
        const Radius.circular(5),
      );
      canvas.drawRRect(
        rect_etiqueta,
        Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.85),
      );
      tp.paint(canvas, Offset(dx_texto, dy_texto));
    }
  }

  @override
  bool shouldRepaint(covariant _PintorMapaTrayecto oldDelegate) {
    return oldDelegate.es_vuelta != es_vuelta ||
        oldDelegate.paradas.join('|') != paradas.join('|');
  }
}

class _CampoParadaCombobox extends StatelessWidget {
  final TextEditingController controlador;
  final String pista;
  final List<String> opciones;
  final ValueChanged<String>? alCambiar;

  const _CampoParadaCombobox({
    super.key,
    required this.controlador,
    required this.pista,
    required this.opciones,
    this.alCambiar,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<String>(
          initialValue: TextEditingValue(text: controlador.text),
          optionsBuilder: (TextEditingValue valorTexto) {
            if (valorTexto.text.isEmpty) {
              return opciones;
            }
            return opciones.where((opcion) =>
                opcion.toLowerCase().contains(valorTexto.text.toLowerCase()));
          },
          onSelected: (String seleccion) {
            controlador.text = seleccion;
            alCambiar?.call(seleccion);
          },
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
            if (controlador.text != textController.text && !focusNode.hasFocus) {
              textController.text = controlador.text;
            }
            return TextField(
              controller: textController,
              focusNode: focusNode,
              onChanged: (val) {
                controlador.text = val;
                alCambiar?.call(val);
              },
              onSubmitted: (_) => onFieldSubmitted(),
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: pista,
                hintStyle:
                    TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                suffixIcon: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    size: 22,
                    color: Color(0xFF64748B),
                  ),
                  tooltip: "Paradas frecuentes",
                  onSelected: (String parada) {
                    textController.text = parada;
                    controlador.text = parada;
                    alCambiar?.call(parada);
                  },
                  itemBuilder: (context) {
                    return opciones.map((p) {
                      return PopupMenuItem<String>(
                        value: p,
                        height: 38,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: BumandColores.AZUL_DIACONIA,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: 200,
                    maxWidth: constraints.maxWidth,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: BumandColores.AZUL_DIACONIA,
                        ),
                        title:
                            Text(option, style: const TextStyle(fontSize: 13)),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

