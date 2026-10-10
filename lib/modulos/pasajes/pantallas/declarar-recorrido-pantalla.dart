import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../proveedores/pasajes-proveedor.dart';
import '../utilidades/formato-pasajes.dart';
import '../../../nucleo/tema/colores.dart';
import '../../../compartido/componentes/seleccionador_fecha.dart';
class DeclararRecorridoPantalla extends ConsumerStatefulWidget {
  const DeclararRecorridoPantalla({super.key});

  @override
  ConsumerState<DeclararRecorridoPantalla> createState() =>
      _DeclararRecorridoPantallaState();
}

class _DeclararRecorridoPantallaState
    extends ConsumerState<DeclararRecorridoPantalla> {
  static const double _TARIFA_MAXIMA = 50;
  static const _CLAVE_ORIGEN = "pasajes_ultimo_origen";
  static const _CLAVE_DESTINO = "pasajes_ultimo_destino";
  static const _CLAVE_TARIFA_IDA = "pasajes_ultima_tarifa_ida";
  static const _CLAVE_TARIFA_VUELTA = "pasajes_ultima_tarifa_vuelta";

  final _clave_formulario = GlobalKey<FormState>();

  final _apoyo_controlador = TextEditingController();
  final _origen_controlador = TextEditingController();
  final _destino_controlador = TextEditingController();
  final _tarifa_ida_controlador = TextEditingController();
  final _tarifa_vuelta_controlador = TextEditingController();

  DateTime _fecha = DateTime.now();
  bool _incluir_vuelta = true;
  bool _guardando = false;
  Position? _gps_origen;
  Position? _gps_destino;
  String? _capturando_gps;

  @override
  void initState() {
    super.initState();
    _cargarUltimoRecorrido();
    for (final c in [
      _origen_controlador,
      _destino_controlador,
      _tarifa_ida_controlador,
      _tarifa_vuelta_controlador,
    ]) {
      c.addListener(_refrescar);
    }
  }

  void _refrescar() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _apoyo_controlador.dispose();
    _origen_controlador.dispose();
    _destino_controlador.dispose();
    _tarifa_ida_controlador.dispose();
    _tarifa_vuelta_controlador.dispose();
    super.dispose();
  }

  Future<void> _cargarUltimoRecorrido() async {
    final preferencias = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _origen_controlador.text = preferencias.getString(_CLAVE_ORIGEN) ?? "";
      _destino_controlador.text = preferencias.getString(_CLAVE_DESTINO) ?? "";
      _tarifa_ida_controlador.text = preferencias.getString(_CLAVE_TARIFA_IDA) ?? "";
      _tarifa_vuelta_controlador.text = preferencias.getString(_CLAVE_TARIFA_VUELTA) ?? "";
    });
  }

  Future<void> _guardarUltimoRecorrido() async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setString(_CLAVE_ORIGEN, _origen_controlador.text.trim());
    await preferencias.setString(_CLAVE_DESTINO, _destino_controlador.text.trim());
    await preferencias.setString(_CLAVE_TARIFA_IDA, _tarifa_ida_controlador.text.trim());
    if (_incluir_vuelta) {
      await preferencias.setString(_CLAVE_TARIFA_VUELTA, _tarifa_vuelta_controlador.text.trim());
    }
  }

  double? _leerTarifa(String texto) =>
      double.tryParse(texto.trim().replaceAll(",", "."));

  String? _validarTarifa(String? valor) {
    final t = _leerTarifa(valor ?? "");
    if (t == null) {
      return "Ingresa el monto (ej. 2.50)";
    }
    if (t <= 0) {
      return "Debe ser mayor a 0";
    }
    if (t > _TARIFA_MAXIMA) {
      return "Máximo Bs ${_TARIFA_MAXIMA.toStringAsFixed(0)} por tramo";
    }
    return null;
  }

  String? _validarTexto(String? valor) {
    final v = valor?.trim() ?? "";
    if (v.isEmpty) {
      return "Campo obligatorio";
    }
    if (v.length > 150) {
      return "Máximo 150 caracteres";
    }
    return null;
  }



  Future<void> _capturarGps(String punto) async {
    setState(() => _capturando_gps = punto);
    try {
      bool servicio_activo = await Geolocator.isLocationServiceEnabled();
      if (!servicio_activo) {
        _mensaje("Los servicios de ubicación están desactivados.", es_error: true);
        return;
      }
      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          _mensaje("Permiso de ubicación denegado.", es_error: true);
          return;
        }
      }
      if (permiso == LocationPermission.deniedForever) {
        _mensaje(
          "Permiso de ubicación denegado permanentemente.",
          es_error: true,
        );
        return;
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (posicion.isMocked) {
        _mensaje(
          "Se detectó una ubicación simulada; no se guardó.",
          es_error: true,
        );
        return;
      }
      setState(() {
        if (punto == "origen") {
          _gps_origen = posicion;
        } else {
          _gps_destino = posicion;
        }
      });
      _mensaje(
        "📍 PIN GPS de $punto fijado: ${posicion.latitude.toStringAsFixed(5)}, ${posicion.longitude.toStringAsFixed(5)} (±${posicion.accuracy.round()} m)",
      );
    } catch (e) {
      _mensaje(e.toString().replaceFirst("Exception: ", ""), es_error: true);
    } finally {
      if (mounted) setState(() => _capturando_gps = null);
    }
  }

  void _mensaje(String texto, {bool es_error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: es_error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_clave_formulario.currentState!.validate()) return;
    setState(() => _guardando = true);

    final fecha = FormatoPasajes.fechaApi(_fecha);
    final origen = _origen_controlador.text.trim();
    final destino = _destino_controlador.text.trim();
    final apoyo = _apoyo_controlador.text.trim();

    final repositorio = ref.read(pasajes_repositorio_proveedor);

    final ida = await repositorio.agregarRecorrido(
      fecha: fecha,
      tramo: "ida",
      origen: origen,
      destino: destino,
      tarifa: _leerTarifa(_tarifa_ida_controlador.text)!,
      apoyo_realizado: apoyo,
      lat_origen: _gps_origen?.latitude,
      lng_origen: _gps_origen?.longitude,
      lat_destino: _gps_destino?.latitude,
      lng_destino: _gps_destino?.longitude,
    );

    if (!mounted) return;

    if (!ida.exito) {
      setState(() => _guardando = false);
      if (ida.codigo == "DATOS_NO_CONFIRMADOS" && ida.periodo != null) {
        await repositorio.confirmarDatos(ida.periodo!);
        if (mounted) _guardar();
        return;
      }
      _mensaje(ida.error ?? "Error al guardar ida", es_error: true);
      return;
    }

    if (_incluir_vuelta) {
      final vuelta = await repositorio.agregarRecorrido(
        fecha: fecha,
        tramo: "vuelta",
        origen: destino,
        destino: origen,
        tarifa: _leerTarifa(_tarifa_vuelta_controlador.text)!,
        apoyo_realizado: apoyo,
        lat_origen: _gps_destino?.latitude,
        lng_origen: _gps_destino?.longitude,
        lat_destino: _gps_origen?.latitude,
        lng_destino: _gps_origen?.longitude,
      );
      if (!mounted) return;
      if (!vuelta.exito) {
        setState(() => _guardando = false);
        _mensaje(
          "La ida se guardó, pero la vuelta no: ${vuelta.error}",
          es_error: true,
        );
        Navigator.of(context).pop(true);
        return;
      }
    }

    await _guardarUltimoRecorrido();
    if (!mounted) return;
    _mensaje(_incluir_vuelta ? "Ida y vuelta registradas" : "Ida registrada");
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final origen = _origen_controlador.text.trim();
    final destino = _destino_controlador.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text("Declarar recorrido")),
      body: Form(
        key: _clave_formulario,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "● Datos confirmados",
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _apoyo_controlador,
              decoration: const InputDecoration(
                labelText: "Apoyo realizado",
                hintText: "Ej. Envío de reportes, control CAEDEC",
                prefixIcon: Icon(Icons.assignment_outlined),
                border: OutlineInputBorder(),
              ),
              maxLength: 255,
              minLines: 1,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                final t = v?.trim() ?? "";
                if (t.length < 3) {
                  return "Describe brevemente el apoyo que realizaste";
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            SeleccionadorFecha(
              fecha: _fecha,
              onCambiada: _guardando ? (v) {} : (v) => setState(() => _fecha = v),
              primeraFecha: DateTime(DateTime.now().year, DateTime.now().month - 2, 1),
              ultimaFecha: DateTime.now(),
              etiqueta: "Fecha del recorrido",
            ),
            const SizedBox(height: 16),
            Text("1. Ida", style: tema.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _origen_controlador,
              decoration: InputDecoration(
                labelText: "Origen",
                hintText: "Ej. Villa Adela, El Alto",
                prefixIcon: const Icon(Icons.trip_origin),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.pin_drop, color: BumandColores.AZUL_DIACONIA),
                  tooltip: "Capturar PIN GPS de origen",
                  onPressed: _capturando_gps != null || _guardando
                      ? null
                      : () => _capturarGps("origen"),
                ),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: _validarTexto,
            ),
            _SelectorParadasRapidas(
              etiqueta: "Origen",
              onSeleccionar: (parada) {
                setState(() {
                  _origen_controlador.text = parada;
                });
              },
            ),
            _BotonGps(
              etiqueta: "origen",
              posicion: _gps_origen,
              cargando: _capturando_gps == "origen",
              onPressed: _capturando_gps != null || _guardando
                  ? null
                  : () => _capturarGps("origen"),
              onQuitar: () => setState(() => _gps_origen = null),
            ),
            TextFormField(
              controller: _destino_controlador,
              decoration: InputDecoration(
                labelText: "Destino",
                hintText: "Ej. Oficina Central Diaconía",
                prefixIcon: const Icon(Icons.place),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.pin_drop, color: BumandColores.AZUL_DIACONIA),
                  tooltip: "Capturar PIN GPS de destino",
                  onPressed: _capturando_gps != null || _guardando
                      ? null
                      : () => _capturarGps("destino"),
                ),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: _validarTexto,
            ),
            _SelectorParadasRapidas(
              etiqueta: "Destino",
              onSeleccionar: (parada) {
                setState(() {
                  _destino_controlador.text = parada;
                });
              },
            ),
            _BotonGps(
              etiqueta: "destino",
              posicion: _gps_destino,
              cargando: _capturando_gps == "destino",
              onPressed: _capturando_gps != null || _guardando
                  ? null
                  : () => _capturarGps("destino"),
              onQuitar: () => setState(() => _gps_destino = null),
            ),
            TextFormField(
              controller: _tarifa_ida_controlador,
              decoration: const InputDecoration(
                labelText: "Pasaje de ida (Bs)",
                prefixIcon: Icon(Icons.payments_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: _validarTarifa,
            ),
            _SelectorTarifaRapida(
              tarifa_seleccionada: _leerTarifa(_tarifa_ida_controlador.text),
              onSeleccionar: (monto) {
                setState(() {
                  _tarifa_ida_controlador.text = monto.toStringAsFixed(2);
                });
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text("2. Vuelta", style: tema.textTheme.titleMedium),
              subtitle: Text(
                origen.isEmpty || destino.isEmpty
                    ? "Mismo trayecto al revés"
                    : "$destino → $origen",
              ),
              value: _incluir_vuelta,
              onChanged: _guardando
                  ? null
                  : (v) => setState(() => _incluir_vuelta = v),
            ),
            if (_incluir_vuelta) ...[
              TextFormField(
                controller: _tarifa_vuelta_controlador,
                decoration: const InputDecoration(
                  labelText: "Pasaje de vuelta (Bs)",
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _validarTarifa,
              ),
              _SelectorTarifaRapida(
                tarifa_seleccionada: _leerTarifa(_tarifa_vuelta_controlador.text),
                onSeleccionar: (monto) {
                  setState(() {
                    _tarifa_vuelta_controlador.text = monto.toStringAsFixed(2);
                  });
                },
              ),
            ],
            const SizedBox(height: 16),
            _ResumenDevolucion(
              tarifa_ida: _leerTarifa(_tarifa_ida_controlador.text),
              tarifa_vuelta: _incluir_vuelta
                  ? _leerTarifa(_tarifa_vuelta_controlador.text)
                  : 0.0,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(
                _incluir_vuelta ? "Guardar ida y vuelta" : "Guardar ida",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonGps extends StatelessWidget {
  final String etiqueta;
  final Position? posicion;
  final bool cargando;
  final VoidCallback? onPressed;
  final VoidCallback onQuitar;

  const _BotonGps({
    required this.etiqueta,
    required this.posicion,
    required this.cargando,
    required this.onPressed,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: posicion == null
            ? OutlinedButton.icon(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: BumandColores.AZUL_DIACONIA,
                  side: const BorderSide(color: BumandColores.AZUL_DIACONIA),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: cargando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("📍", style: TextStyle(fontSize: 16)),
                label: Text(
                  "Fijar PIN GPS de $etiqueta actual",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("📍", style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      "PIN $etiqueta: ${posicion!.latitude.toStringAsFixed(5)}, ${posicion!.longitude.toStringAsFixed(5)} (±${posicion!.accuracy.round()} m)",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF065F46),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onQuitar,
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ResumenDevolucion extends StatelessWidget {
  final double? tarifa_ida;
  final double? tarifa_vuelta;
  const _ResumenDevolucion({
    required this.tarifa_ida,
    required this.tarifa_vuelta,
  });

  @override
  Widget build(BuildContext context) {
    final total = (tarifa_ida ?? 0) + (tarifa_vuelta ?? 0);
    final devolucion = (total * 0.8 * 100).round() / 100;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.calculate_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Total del día: Bs ${total.toStringAsFixed(2)}  ·  Devolución 80%: Bs ${devolucion.toStringAsFixed(2)}",
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorTarifaRapida extends StatelessWidget {
  final ValueChanged<double> onSeleccionar;
  final double? tarifa_seleccionada;

  const _SelectorTarifaRapida({
    required this.onSeleccionar,
    this.tarifa_seleccionada,
  });

  static const List<Map<String, dynamic>> TARIFAS_OFICIALES = [
    {"nombre": "Minibús Directo", "monto": 2.60},
    {"nombre": "Minibús El Alto", "monto": 3.50},
    {"nombre": "Micro / Colectivo", "monto": 2.00},
    {"nombre": "Mi Teleférico", "monto": 3.00},
    {"nombre": "Trufi", "monto": 4.00},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tarifas oficiales reguladas:",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TARIFAS_OFICIALES.map((t) {
                final monto = t["monto"] as double;
                final es_activa = (tarifa_seleccionada != null &&
                    (tarifa_seleccionada! - monto).abs() < 0.01);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: es_activa
                        ? BumandColores.AZUL_DIACONIA.withValues(alpha: 0.15)
                        : null,
                    side: BorderSide(
                      color: es_activa
                          ? BumandColores.AZUL_DIACONIA
                          : Colors.grey.shade300,
                    ),
                    label: Text(
                      "${t["nombre"]} (Bs ${monto.toStringAsFixed(2)})",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            es_activa ? FontWeight.bold : FontWeight.normal,
                        color: es_activa
                            ? BumandColores.AZUL_DIACONIA
                            : Colors.black87,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onSeleccionar(monto);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorParadasRapidas extends StatelessWidget {
  final String etiqueta;
  final ValueChanged<String> onSeleccionar;

  const _SelectorParadasRapidas({
    required this.etiqueta,
    required this.onSeleccionar,
  });

  static const List<String> PARADAS_EMBLEMATICAS = [
    "Ceja",
    "Pérez Velasco",
    "Plaza San Francisco",
    "San Pedro",
    "Cruce Viacha",
    "Miraflores",
    "Sopocachi",
    "Teleférico",
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Paradas frecuentes ($etiqueta):",
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PARADAS_EMBLEMATICAS.map((parada) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(
                      Icons.directions_bus,
                      size: 14,
                      color: BumandColores.AZUL_DIACONIA,
                    ),
                    label: Text(
                      parada,
                      style: const TextStyle(fontSize: 11),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onSeleccionar(parada);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
