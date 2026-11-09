import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../modelos/recorrido-modelo.dart';
import '../proveedores/pasajes-proveedor.dart';
import '../utilidades/formato-pasajes.dart';
import '../../../nucleo/tema/colores.dart';
import '../../../compartido/componentes/seleccionador_fecha.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../../autenticacion/proveedores/autenticacion-proveedor.dart';
import '../../refrigerios/pantallas/refrigerios-pantalla.dart';

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

  double? get lat => posicion_gps?.latitude;
  double? get lng => posicion_gps?.longitude;

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
  String _tipo_actividad = "Escuela de Líderes";
  String get tipo_actividad_seleccionado => _tipo_actividad;
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

  List<Map<String, dynamic>> _tarifas = [
    {"nombre": "Minibús (dentro de El Alto)", "monto": 2.0},
    {"nombre": "Micro (dentro de El Alto)", "monto": 1.5},
    {"nombre": "Minibús (Centro La Paz – Ceja)", "monto": 3.5},
    {"nombre": "Minibús (UMSA – Ceja)", "monto": 4.0},
    {"nombre": "Teleférico (línea regular)", "monto": 3.0},
    {"nombre": "Otro (escribir monto)...", "monto": 0.0},
  ];
  bool _cargando_tarifas = false;

  static const List<String> PARADAS_FRECUENTES = [
    'Oficina Central Diaconía (Av. Juan Pablo II, El Alto)',
    'Agencia Diaconía Ceja (El Alto)',
    'Sede Escuela de Líderes (La Paz)',
    'La Ceja — Calle 1 / Puente Distribuidor (El Alto)',
    'Cruce Villa Adela (El Alto)',
    'Villa Adela, El Alto',
    'Cruce Viacha (El Alto)',
    'Ex Tranca Río Seco (El Alto)',
    'Extranca Senkata — Av. 6 de Marzo (El Alto)',
    'Ciudad Satélite — Plaza del Tinku (El Alto)',
    'Ballivián / Faro Murillo (El Alto)',
    'UPEA — Villa Esperanza (El Alto)',
    'Terminal Metropolitana El Alto',
    'Puente Vela / Ventilla (El Alto)',
    'Pérez Velasco / Héroes del Pacífico (La Paz)',
    'Plaza San Francisco (La Paz)',
    'San Pedro — Plaza Sucre (La Paz)',
    'El Prado / Obelisco (La Paz)',
    'UMSA — Monoblock Central (La Paz)',
    'Sopocachi — Plaza Abaroa (La Paz)',
    'Miraflores — Estadio Hernando Siles (La Paz)',
    'Miraflores — Plaza Triangular / Hospital de Clínicas (La Paz)',
    'Terminal de Buses La Paz / Plaza Antofagasta',
    'Cementerio General / Ajayuni (La Paz)',
    'Periférica — Av. Vásquez / Autopista (La Paz)',
    'Chuquiaguillo / Salida Yungas (La Paz)',
    'Villa Fátima — Plaza del Maestro / Minasa (La Paz)',
    'Obrajes — Calle 17 (Zona Sur, La Paz)',
    'Calacoto — Calle 21 (Zona Sur, La Paz)',
    'Chasquipampa — Calle 53 (Zona Sur, La Paz)',
    'Teleférico Línea Roja (Estación Central / 16 de Julio)',
    'Teleférico Línea Amarilla (Mirador / Sopocachi / Libertador)',
    'Teleférico Línea Morada (Faro Murillo / San José)',
    'Teleférico Línea Azul (Río Seco / UPEA / 16 de Julio)',
    'Teleférico Línea Blanca (Plaza Villarroel / Busch)',
  ];

  static const Map<String, ({double lat, double lng})> COORDENADAS_PARADAS = {
    'Oficina Central Diaconía (Av. Juan Pablo II, El Alto)': (lat: -16.50005, lng: -68.17345),
    'Agencia Diaconía Ceja (El Alto)': (lat: -16.5085, lng: -68.1630),
    'Sede Escuela de Líderes (La Paz)': (lat: -16.5042, lng: -68.1315),
    'La Ceja — Calle 1 / Puente Distribuidor (El Alto)': (lat: -16.5088, lng: -68.1627),
    'Cruce Villa Adela (El Alto)': (lat: -16.5245, lng: -68.1885),
    'Villa Adela, El Alto': (lat: -16.5360, lng: -68.1920),
    'Cruce Viacha (El Alto)': (lat: -16.5178, lng: -68.1695),
    'Ex Tranca Río Seco (El Alto)': (lat: -16.4912, lng: -68.2105),
    'Extranca Senkata — Av. 6 de Marzo (El Alto)': (lat: -16.5655, lng: -68.1872),
    'Ciudad Satélite — Plaza del Tinku (El Alto)': (lat: -16.5195, lng: -68.1510),
    'Ballivián / Faro Murillo (El Alto)': (lat: -16.5055, lng: -68.1525),
    'UPEA — Villa Esperanza (El Alto)': (lat: -16.4935, lng: -68.1940),
    'Terminal Metropolitana El Alto': (lat: -16.5152, lng: -68.1720),
    'Puente Vela / Ventilla (El Alto)': (lat: -16.5520, lng: -68.1960),
    'Pérez Velasco / Héroes del Pacífico (La Paz)': (lat: -16.4958, lng: -68.1372),
    'Plaza San Francisco (La Paz)': (lat: -16.4965, lng: -68.1378),
    'San Pedro — Plaza Sucre (La Paz)': (lat: -16.5030, lng: -68.1360),
    'El Prado / Obelisco (La Paz)': (lat: -16.4988, lng: -68.1340),
    'UMSA — Monoblock Central (La Paz)': (lat: -16.5048, lng: -68.1298),
    'Sopocachi — Plaza Abaroa (La Paz)': (lat: -16.5112, lng: -68.1268),
    'Miraflores — Estadio Hernando Siles (La Paz)': (lat: -16.4995, lng: -68.1228),
    'Miraflores — Plaza Triangular / Hospital de Clínicas (La Paz)': (lat: -16.5052, lng: -68.1211),
    'Terminal de Buses La Paz / Plaza Antofagasta': (lat: -16.4895, lng: -68.1415),
    'Cementerio General / Ajayuni (La Paz)': (lat: -16.4920, lng: -68.1515),
    'Periférica — Av. Vásquez / Autopista (La Paz)': (lat: -16.4840, lng: -68.1425),
    'Chuquiaguillo / Salida Yungas (La Paz)': (lat: -16.4620, lng: -68.1050),
    'Villa Fátima — Plaza del Maestro / Minasa (La Paz)': (lat: -16.4815, lng: -68.1189),
    'Obrajes — Calle 17 (Zona Sur, La Paz)': (lat: -16.5275, lng: -68.1085),
    'Calacoto — Calle 21 (Zona Sur, La Paz)': (lat: -16.5398, lng: -68.0865),
    'Chasquipampa — Calle 53 (Zona Sur, La Paz)': (lat: -16.5440, lng: -68.0530),
    'Teleférico Línea Roja (Estación Central / 16 de Julio)': (lat: -16.4918, lng: -68.1452),
    'Teleférico Línea Amarilla (Mirador / Sopocachi / Libertador)': (lat: -16.5172, lng: -68.1338),
    'Teleférico Línea Morada (Faro Murillo / San José)': (lat: -16.5015, lng: -68.1355),
    'Teleférico Línea Azul (Río Seco / UPEA / 16 de Julio)': (lat: -16.4960, lng: -68.1820),
    'Teleférico Línea Blanca (Plaza Villarroel / Busch)': (lat: -16.4930, lng: -68.1195),
  };

  double _calcularDistanciaMetros(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371000;
    final double dLat = (lat2 - lat1) * (math.pi / 180.0);
    final double dLon = (lon2 - lon1) * (math.pi / 180.0);
    final double a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(lat1 * (math.pi / 180.0)) *
            math.cos(lat2 * (math.pi / 180.0)) *
            (math.sin(dLon / 2) * math.sin(dLon / 2));
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  bool get _esSoloIda {
    final usuario = ref.watch(autenticacion_proveedor).usuario;
    final actKey = _tipo_actividad == "Prácticas"
        ? "practicas"
        : _tipo_actividad == "Escuela de Líderes"
            ? "escuela_lideres"
            : "acciones_servicio";
    final cfg = usuario?.configuracion_pasajes_actividades;
    final mod = cfg?[actKey] ?? usuario?.modalidad_pasajes ?? 'ida_y_vuelta';
    return mod == 'solo_ida';
  }

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
    _tipo_actividad = "Escuela de Líderes";
    _cargarTarifas();
    final destino_base =
        (widget.destino_inicial != null && widget.destino_inicial!.isNotEmpty)
            ? widget.destino_inicial!
            : "Oficina Central Diaconía (Av. Juan Pablo II, El Alto)";

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
    _autoDetectarUbicacionInicial();
  }

  Future<void> _autoDetectarUbicacionInicial() async {
    try {
      final habilitado = await Geolocator.isLocationServiceEnabled();
      if (!habilitado) return;
      final permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) return;

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );
      if (!mounted) return;

      final nombre_calle = await _obtenerCalleGps(posicion);
      if (!mounted) return;

      setState(() {
        if (_paradas_ida.isNotEmpty) {
          _paradas_ida[0].posicion_gps = posicion;
          _paradas_ida[0].controlador.text = nombre_calle;
        }
        if (_paradas_vuelta.length > 1) {
          _paradas_vuelta.last.controlador.text = nombre_calle;
        }
      });
    } catch (_) {}
  }

  Future<void> _cargarTarifas() async {
    setState(() => _cargando_tarifas = true);
    final repo = ref.read(pasajes_repositorio_proveedor);
    final resultado = await repo.obtenerTarifas();
    if (mounted) {
      if (resultado.exito && resultado.datos != null && resultado.datos!.isNotEmpty) {
        final lista = List<Map<String, dynamic>>.from(resultado.datos!);
        if (!lista.any((t) => t['nombre'] == "Otro (escribir monto)...")) {
          lista.add({"nombre": "Otro (escribir monto)...", "monto": 0.0});
        }
        setState(() {
          _tarifas = lista;
          _cargando_tarifas = false;
        });
      } else {
        setState(() => _cargando_tarifas = false);
      }
    }
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
              borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
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
      final destino_base =
          (widget.destino_inicial != null && widget.destino_inicial!.isNotEmpty)
              ? widget.destino_inicial!
              : "Oficina Central Diaconía (Av. Juan Pablo II, El Alto)";

      if (origen != null && origen.isNotEmpty && _paradas_ida.isNotEmpty) {
        _paradas_ida[0].controlador.text = origen;
        if (_paradas_vuelta.length > 1) {
          _paradas_vuelta.last.controlador.text = origen;
        }
      }
      if (_paradas_ida.length > 1) {
        if (widget.destino_inicial != null && widget.destino_inicial!.isNotEmpty) {
          _paradas_ida[1].controlador.text = widget.destino_inicial!;
        } else if (destino != null &&
            destino.isNotEmpty &&
            (origen == null || destino.trim().toLowerCase() != origen.trim().toLowerCase())) {
          _paradas_ida[1].controlador.text = destino;
        } else {
          _paradas_ida[1].controlador.text = destino_base;
        }
      }
      if (_paradas_vuelta.isNotEmpty) {
        _paradas_vuelta[0].controlador.text =
            _paradas_ida.length > 1 ? _paradas_ida[1].controlador.text : destino_base;
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

  Future<String> _obtenerCalleGps(Position pos) async {
    // Buscar la parada estratégica más cercana de COORDENADAS_PARADAS
    String parada_ref = "Oficina Central Diaconía (Av. Juan Pablo II, El Alto)";
    double menor_dist = double.infinity;
    COORDENADAS_PARADAS.forEach((nombre, coords) {
      final d = _calcularDistanciaMetros(pos.latitude, pos.longitude, coords.lat, coords.lng);
      if (d < menor_dist) {
        menor_dist = d;
        parada_ref = nombre;
      }
    });

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}&zoom=18&addressdetails=1',
      );
      final respuesta = await http.get(
        uri,
        headers: {'User-Agent': 'BumandMovilApp/1.0', 'Accept-Language': 'es'},
      ).timeout(const Duration(seconds: 4));

      if (respuesta.statusCode == 200) {
        final dynamic datos = jsonDecode(respuesta.body);
        if (datos is Map<String, dynamic>) {
          final direccion = datos['address'] as Map<String, dynamic>?;
          if (direccion != null) {
            final dynamic calle_obj = direccion['road'] ??
                direccion['pedestrian'] ??
                direccion['footway'] ??
                direccion['path'] ??
                direccion['residential'] ??
                direccion['amenity'] ??
                direccion['building'];

            final dynamic barrio_obj = direccion['neighbourhood'] ??
                direccion['quarter'] ??
                direccion['suburb'];

            final dynamic distrito_obj = direccion['city_district'] ??
                direccion['city'] ??
                direccion['town'];

            final calle = calle_obj?.toString().trim();
            final barrio = barrio_obj?.toString().trim();
            final distrito = distrito_obj?.toString().trim();

            if (calle != null && calle.isNotEmpty) {
              if (barrio != null && barrio.isNotEmpty) {
                return '$calle, $barrio';
              } else if (distrito != null && distrito.isNotEmpty) {
                return '$calle, $distrito';
              }
              return calle;
            } else {
              final zona = (barrio != null && barrio.isNotEmpty)
                  ? barrio
                  : (distrito != null && distrito.isNotEmpty)
                      ? distrito
                      : null;
              if (zona != null) {
                return 'Zona $zona · Ref. $parada_ref';
              }
              return 'Ref. $parada_ref';
            }
          }
        }
      }
    } catch (_) {}
    return 'Ubicación GPS (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}) · Ref. $parada_ref';
  }

  Future<void> _capturarGps(
    String identificador,
    _ParadaRuta parada, {
    bool? es_ida,
    int? indice,
  }) async {
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

      // Calcular distancia Haversine a paradas oficiales de COORDENADAS_PARADAS
      String parada_mas_cercana = "Oficina Central Diaconía (Av. Juan Pablo II, El Alto)";
      double menor_distancia = double.infinity;

      COORDENADAS_PARADAS.forEach((nombre, coords) {
        final dist = _calcularDistanciaMetros(
          posicion.latitude,
          posicion.longitude,
          coords.lat,
          coords.lng,
        );
        if (dist < menor_distancia) {
          menor_distancia = dist;
          parada_mas_cercana = nombre;
        }
      });

      if (menor_distancia <= 150) {
        final nombre_asignado = "Parada $parada_mas_cercana";
        setState(() {
          parada.posicion_gps = posicion;
          parada.controlador.text = nombre_asignado;
          parada.confirmada = true;
        });
        _mensaje(
          "📍 Parada oficial detectada: $parada_mas_cercana (a ${menor_distancia.round()} m)",
        );
      } else {
        final calle_detectada = await _obtenerCalleGps(posicion);
        if (!mounted) return;
        setState(() {
          parada.posicion_gps = posicion;
          parada.controlador.text = calle_detectada;
          parada.confirmada = true;
        });
        _mensaje("📍 Ubicación GPS: $calle_detectada");
      }
    } catch (_) {
      if (!mounted) return;
      _mensaje("No se pudo obtener la ubicación GPS", es_error: true);
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

    if (origen.toLowerCase() == destino.toLowerCase()) {
      _mensaje(
        "El punto de partida y llegada no pueden ser la misma ubicación",
        es_error: true,
      );
      return;
    }

    for (int i = 0; i < _paradas_ida.length - 1; i++) {
      final p1 = _paradas_ida[i].controlador.text.trim().toLowerCase();
      final p2 = _paradas_ida[i + 1].controlador.text.trim().toLowerCase();
      if (p1.isNotEmpty && p1 == p2) {
        _mensaje(
          "El punto de partida y llegada no pueden ser la misma ubicación",
          es_error: true,
        );
        return;
      }
    }

    if (_tieneParadasDuplicadas(_paradas_ida)) {
      _mensaje(
        "No puedes elegir dos veces el mismo lugar en el tramo de ida",
        es_error: true,
      );
      return;
    }

    if (!_esSoloIda) {
      final origen_vuelta = _paradas_vuelta.isNotEmpty
          ? _paradas_vuelta.first.controlador.text.trim()
          : "";
      final destino_vuelta = _paradas_vuelta.length > 1
          ? _paradas_vuelta.last.controlador.text.trim()
          : "";

      if (origen_vuelta.isNotEmpty &&
          destino_vuelta.isNotEmpty &&
          origen_vuelta.toLowerCase() == destino_vuelta.toLowerCase()) {
        _mensaje(
          "El punto de partida y llegada no pueden ser la misma ubicación",
          es_error: true,
        );
        return;
      }

      for (int i = 0; i < _paradas_vuelta.length - 1; i++) {
        final p1 = _paradas_vuelta[i].controlador.text.trim().toLowerCase();
        final p2 = _paradas_vuelta[i + 1].controlador.text.trim().toLowerCase();
        if (p1.isNotEmpty && p1 == p2) {
          _mensaje(
            "El punto de partida y llegada no pueden ser la misma ubicación",
            es_error: true,
          );
          return;
        }
      }

      if (_tieneParadasDuplicadas(_paradas_vuelta)) {
        _mensaje(
          "No puedes elegir dos veces el mismo lugar en el tramo de vuelta",
          es_error: true,
        );
        return;
      }
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
    if (!_esSoloIda && total_vuelta > 0 && _paradas_vuelta.isNotEmpty) {
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
      backgroundColor: BumandColores.fondo,
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
                  borderRadius: BorderRadius.circular(16),
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
                  backgroundColor: BumandColores.amarilloRadiante,
                  foregroundColor: BumandColores.azulMarinoSecundario,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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

            if (_tipo_actividad == "Escuela de Líderes") ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RefrigeriosPantalla(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 20,
                    color: BumandColores.AZUL_DIACONIA,
                  ),
                  label: const Text(
                    "Refrigerios de Escuela de Líderes (Confirmar recojo / Rendir)",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: BumandColores.AZUL_DIACONIA,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: BumandColores.AZUL_DIACONIA, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
                  borderRadius: BorderRadius.circular(16),
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
            child: Opacity(
              opacity: _esSoloIda ? 0.45 : 1.0,
              child: GestureDetector(
                onTap: _esSoloIda
                    ? () => _mensaje("Esta actividad está configurada como 'Solo Ida'")
                    : () => setState(() => _paso_activo = 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _paso_activo == 2
                        ? BumandColores.AZUL_DIACONIA
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _esSoloIda
                        ? "2 · Vuelta (Bloqueada)"
                        : "2 · Vuelta (Bs ${subtotal_vuelta.toStringAsFixed(2)})",
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
            child: _esSoloIda
                ? ElevatedButton.icon(
                    onPressed: _guardando ? null : _guardarRecorridoFinal,
                    icon: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _guardando
                          ? "Registrando..."
                          : "Registrar Recorrido (Solo Ida)",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BumandColores.AZUL_DIACONIA,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () {
                      final origen = _paradas_ida.isNotEmpty
                          ? _paradas_ida.first.controlador.text.trim()
                          : "";
                      final destino = _paradas_ida.length > 1
                          ? _paradas_ida.last.controlador.text.trim()
                          : "";
                      if (origen.isNotEmpty &&
                          destino.isNotEmpty &&
                          origen.toLowerCase() == destino.toLowerCase()) {
                        _mensaje(
                          "El punto de partida y llegada no pueden ser la misma ubicación",
                          es_error: true,
                        );
                        return;
                      }
                      for (int i = 0; i < _paradas_ida.length - 1; i++) {
                        final p1 = _paradas_ida[i].controlador.text.trim().toLowerCase();
                        final p2 = _paradas_ida[i + 1].controlador.text.trim().toLowerCase();
                        if (p1.isNotEmpty && p1 == p2) {
                          _mensaje(
                            "El punto de partida y llegada no pueden ser la misma ubicación",
                            es_error: true,
                          );
                          return;
                        }
                      }
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
                        borderRadius: BorderRadius.circular(16),
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
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(16),
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
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: TIPOS_ACTIVIDAD.map((opcion) {
              final seleccionado = _tipo_actividad == opcion;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _tipo_actividad = opcion;
                      if (_esSoloIda && _paso_activo == 2) _paso_activo = 1;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: seleccionado ? BumandColores.AZUL_DIACONIA : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      opcion,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: seleccionado ? FontWeight.bold : FontWeight.w500,
                        color: seleccionado ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (_esSoloIda) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: BumandColores.AZUL_DIACONIA),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Modalidad asignada por Administración: Solo Ida (80% del apoyo)",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: BumandColores.AZUL_DIACONIA,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

          // Pin GPS (TAREA-05: Pin rojo y autoselección)
          IconButton(
            icon: _capturando_gps_id == 'parada_${es_ida ? "ida" : "vuelta"}_$numero'
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFDC2626),
                    ),
                  )
                : Icon(
                    Icons.location_on,
                    color: parada.posicion_gps != null
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                    size: 22,
                  ),
            tooltip: "Detectar parada más cercana por GPS (Pin Rojo)",
            visualDensity: VisualDensity.compact,
            onPressed: _capturando_gps_id != null
                ? null
                : () => _capturarGps(
                      'parada_${es_ida ? "ida" : "vuelta"}_$numero',
                      parada,
                    ),
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

          // Botón Confirmar / ✓ Ubicación fijada / 📍 Fijar aquí
          GestureDetector(
            onTap: () async {
              final indice = numero - 1;
              final anterior = indice > 0
                  ? lista_paradas[indice - 1].controlador.text.trim()
                  : null;
              final siguiente = indice < lista_paradas.length - 1
                  ? lista_paradas[indice + 1].controlador.text.trim()
                  : null;
              final texto_actual = parada.controlador.text.trim();

              if (parada.confirmada) {
                HapticFeedback.selectionClick();
                setState(() {
                  parada.confirmada = false;
                });
                return;
              }

              final es_igual_al_anterior = anterior != null &&
                  anterior.isNotEmpty &&
                  anterior.toLowerCase() == texto_actual.toLowerCase();
              final necesita_gps = parada.lat == null ||
                  texto_actual.isEmpty ||
                  es_igual_al_anterior;

              if (necesita_gps) {
                await _capturarGps(
                  'parada_${es_ida ? "ida" : "vuelta"}_$numero',
                  parada,
                  es_ida: es_ida,
                  indice: indice,
                );
              }

              final texto_final = parada.controlador.text.trim();
              if (texto_final.isEmpty) {
                _mensaje("Ingresa el nombre o fija el GPS de la parada", es_error: true);
                return;
              }

              if (anterior != null &&
                  anterior.isNotEmpty &&
                  anterior.toLowerCase() == texto_final.toLowerCase()) {
                _mensaje(
                  "El punto de partida y llegada no pueden ser la misma ubicación",
                  es_error: true,
                );
                return;
              }

              if (siguiente != null &&
                  siguiente.isNotEmpty &&
                  siguiente.toLowerCase() == texto_final.toLowerCase()) {
                _mensaje(
                  "El punto de partida y llegada no pueden ser la misma ubicación",
                  es_error: true,
                );
                return;
              }

              HapticFeedback.lightImpact();
              setState(() {
                parada.confirmada = true;
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
                parada.confirmada
                    ? "✓ Ubicación fijada"
                    : (parada.controlador.text.trim().isEmpty ||
                            (numero > 1 &&
                                parada.controlador.text.trim().toLowerCase() ==
                                    lista_paradas[numero - 2].controlador.text.trim().toLowerCase()))
                        ? "📍 Fijar aquí"
                        : "Confirmar",
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _tarifas
                            .any((p) => p["nombre"] == tramo.nombre)
                        ? tramo.nombre
                        : null,
                    hint: Text(
                      tramo.nombre != null && tramo.nombre!.isNotEmpty
                          ? (tramo.nombre == "Otro (escribir monto)..."
                              ? "Otro (Bs ${tramo.monto.toStringAsFixed(2)})"
                              : tramo.nombre!)
                          : (_cargando_tarifas ? "Cargando tarifas oficiales..." : "Selecciona una tarifa..."),
                      style: const TextStyle(fontSize: 13),
                    ),
                    isExpanded: true,
                    items: [
                      ..._tarifas.map((p) {
                        final nombre = p["nombre"] as String;
                        final monto = (p["monto"] as num).toDouble();
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
                        final item = _tarifas
                            .firstWhere((p) => p["nombre"] == nuevoNombre, orElse: () => {"nombre": nuevoNombre, "monto": 0.0});
                        final monto = (item["monto"] as num).toDouble();
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
            BumandColores.azulMarinoSecundario,
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
          colors: [
            BumandColores.AZUL_DIACONIA,
            BumandColores.azulMarinoSecundario,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: BumandColores.azulMarinoSecundario.withValues(alpha: 0.2),
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
              borderRadius: BorderRadius.circular(16),
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
    final fondo_paint = Paint()..color = BumandColores.azulMarinoSecundario;
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

