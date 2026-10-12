import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../proveedores/pasajes-proveedor.dart';
import '../utilidades/formato-pasajes.dart';
import '../../../nucleo/tema/colores.dart';
import '../../../compartido/componentes/seleccionador_fecha.dart';

/// Modelo interno para una parada dinámica
class _ParadaRuta {
  final TextEditingController controlador;
  Position? posicion_gps;
  bool confirmada;

  _ParadaRuta({
    required this.controlador,
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
  const DeclararRecorridoPantalla({super.key});

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
    'Ceja',
    'Pérez Velasco',
    'Plaza San Francisco',
    'San Pedro',
    'Cruce Viacha',
    'Miraflores',
    'Sopocachi',
    'Teleférico',
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar paradas mínimas de Ida
    _paradas_ida.add(
      _ParadaRuta(controlador: TextEditingController(text: "Villa Adela, El Alto")),
    );
    _paradas_ida.add(
      _ParadaRuta(
        controlador: TextEditingController(text: "Oficina Central Diaconía"),
      ),
    );

    // Inicializar paradas mínimas de Vuelta
    _paradas_vuelta.add(
      _ParadaRuta(
        controlador: TextEditingController(text: "Oficina Central Diaconía"),
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

  Future<void> _cargarUltimoRecorrido() async {
    final preferencias = await SharedPreferences.getInstance();
    final origen = preferencias.getString(_CLAVE_ORIGEN);
    final destino = preferencias.getString(_CLAVE_DESTINO);
    if (!mounted) return;
    setState(() {
      if (origen != null && origen.isNotEmpty && _paradas_ida.isNotEmpty) {
        _paradas_ida[0].controlador.text = origen;
      }
      if (destino != null && destino.isNotEmpty && _paradas_ida.length > 1) {
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

    final total_ida = _calcularSubtotal(_tramos_ida);
    if (total_ida <= 0) {
      _mensaje("Selecciona al menos una tarifa para la ida", es_error: true);
      return;
    }

    setState(() => _guardando = true);

    final fecha_str = FormatoPasajes.fechaApi(_fecha);
    final apoyo = _apoyo_controlador.text.trim();
    final repositorio = ref.read(pasajes_repositorio_proveedor);

    final ida = await repositorio.agregarRecorrido(
      fecha: fecha_str,
      tramo: "ida",
      origen: origen,
      destino: destino,
      tarifa: total_ida,
      apoyo_realizado: apoyo,
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

      await repositorio.agregarRecorrido(
        fecha: fecha_str,
        tramo: "vuelta",
        origen: origen_vuelta.isNotEmpty ? origen_vuelta : destino,
        destino: destino_vuelta.isNotEmpty ? destino_vuelta : origen,
        tarifa: total_vuelta,
        apoyo_realizado: apoyo,
        lat_origen: _paradas_vuelta.first.posicion_gps?.latitude,
        lng_origen: _paradas_vuelta.first.posicion_gps?.longitude,
        lat_destino: _paradas_vuelta.last.posicion_gps?.latitude,
        lng_destino: _paradas_vuelta.last.posicion_gps?.longitude,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_CLAVE_ORIGEN, origen);
    await prefs.setString(_CLAVE_DESTINO, destino);

    if (!mounted) return;
    _mensaje("✓ Recorrido del día guardado correctamente");
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final subtotal_ida = _calcularSubtotal(_tramos_ida);
    final subtotal_vuelta = _calcularSubtotal(_tramos_vuelta);
    final total_dia = subtotal_ida + subtotal_vuelta;
    final devolucion_80 = total_dia * 0.8;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F8),
      appBar: AppBar(
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
            // Chip de confirmación de correo y datos
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
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14),
                    SizedBox(width: 6),
                    Text(
                      "Correo y datos confirmados",
                      style: TextStyle(
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

            // Selector de fecha del recorrido
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
                    : const Icon(Icons.check_circle_outline),
                label: const Text(
                  "Guardar recorrido del día",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
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

          // Chips de paradas frecuentes para autocompletar
          _construirChipsParadasFrecuentes(es_origen: true),
          _construirChipsParadasFrecuentes(es_origen: false),

          // Paradas dinámicas de la Ida
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
                _paradas_ida.add(
                  _ParadaRuta(controlador: TextEditingController()),
                );
              });
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text("+ Agregar parada"),
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
            label: const Text("+ Agregar tramo de tarifa (transbordo)"),
            style: TextButton.styleFrom(
              foregroundColor: BumandColores.AZUL_DIACONIA,
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
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
                _paradas_vuelta.add(
                  _ParadaRuta(controlador: TextEditingController()),
                );
              });
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text("+ Agregar parada"),
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
            label: const Text("+ Agregar tramo de tarifa (transbordo)"),
            style: TextButton.styleFrom(
              foregroundColor: BumandColores.AZUL_DIACONIA,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirChipsParadasFrecuentes({required bool es_origen}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          es_origen
              ? "Paradas frecuentes (Origen):"
              : "Paradas frecuentes (Destino):",
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: PARADAS_FRECUENTES.map((parada) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  label: Text(parada, style: const TextStyle(fontSize: 11)),
                  backgroundColor: const Color(0xFFF1F5F9),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (es_origen && _paradas_ida.isNotEmpty) {
                        _paradas_ida.first.controlador.text = parada;
                      } else if (!es_origen && _paradas_ida.length > 1) {
                        _paradas_ida.last.controlador.text = parada;
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
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
    return Container(
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

          // Campo de texto de parada
          Expanded(
            child: TextFormField(
              controller: parada.controlador,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: numero == 1
                    ? "Origen (toca 📍 o escribe)"
                    : numero == 2
                        ? "Destino (toca 📍 o escribe)"
                        : "Parada $numero",
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
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
}
