import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../nucleo/tema/colores.dart';
import '../modelos/recorrido-gps-prueba-modelo.dart';
import '../repositorios/recorrido-gps-prueba-repositorio.dart';
import '../utilidades/hash-sha256.dart';

class RecorridoGpsPruebaPantalla extends StatefulWidget {
  const RecorridoGpsPruebaPantalla({super.key});

  @override
  State<RecorridoGpsPruebaPantalla> createState() =>
      _RecorridoGpsPruebaPantallaState();
}

class _RecorridoGpsPruebaPantallaState extends State<RecorridoGpsPruebaPantalla>
    with WidgetsBindingObserver {
  static const int _INTERVALO_CAPTURA_SEG = 300;
  static const Color _COLOR_VERDE = Color(0xFF16A34A);
  static const Color _COLOR_ROJO = Color(0xFFEF4444);

  final RecorridoGpsPruebaRepositorio _repositorio =
      RecorridoGpsPruebaRepositorio();
  final TextEditingController _etiqueta_controlador = TextEditingController();
  final Stopwatch _cronometro = Stopwatch();

  Timer? _temporizador_ui;
  SesionRecorridoGpsPrueba _sesion = SesionRecorridoGpsPrueba.inicial();

  bool _cargando_estado_inicial = true;
  bool _iniciando_sesion = false;
  bool _capturando_punto = false;
  bool _finalizando_sesion = false;
  bool _subiendo_sesion = false;
  bool _error_subida_previo = false;

  int _desfase_monotonico_base_ms = 0;
  int _reloj_ultima_captura_ms = 0;
  String? _mensaje_error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restaurarSesionLocal();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _temporizador_ui?.cancel();
    _cronometro.stop();
    _etiqueta_controlador.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _sesion.estado == EstadoRecorridoGpsPrueba.en_curso &&
        !_finalizando_sesion &&
        !_capturando_punto &&
        _sesion.puntos.isNotEmpty) {
      final ultimo_punto = _sesion.puntos.last;
      final ahora_utc = DateTime.now().toUtc();
      final fecha_ultimo = DateTime.tryParse(ultimo_punto.hora_dispositivo_iso);
      final delta_utc_seg = fecha_ultimo != null
          ? ahora_utc.difference(fecha_ultimo).inSeconds
          : 0;

      if (delta_utc_seg > _segundosDesdeUltimaCaptura) {
        final diferencia_ms =
            (delta_utc_seg * 1000) -
            ((_ahoraMonotonicoMs() - _reloj_ultima_captura_ms));
        if (diferencia_ms > 0) {
          _desfase_monotonico_base_ms += diferencia_ms;
        }
      }

      if (_segundosDesdeUltimaCaptura >= _INTERVALO_CAPTURA_SEG ||
          delta_utc_seg >= _INTERVALO_CAPTURA_SEG) {
        _capturarPuntoAutomatico();
      } else {
        setState(() {});
      }
    }
  }

  int _ahoraMonotonicoMs() {
    return _desfase_monotonico_base_ms + _cronometro.elapsedMilliseconds;
  }

  int get _segundosTranscurridosTotales {
    if (_sesion.estado == EstadoRecorridoGpsPrueba.finalizado) {
      return _sesion.duracion_monotonica_seg;
    }
    return math.max(0, _ahoraMonotonicoMs() ~/ 1000);
  }

  int get _segundosDesdeUltimaCaptura {
    final delta_ms = _ahoraMonotonicoMs() - _reloj_ultima_captura_ms;
    return math.max(0, delta_ms ~/ 1000);
  }

  int get _segundosRestantesProximaCaptura {
    return (_INTERVALO_CAPTURA_SEG - _segundosDesdeUltimaCaptura).clamp(
      0,
      _INTERVALO_CAPTURA_SEG,
    );
  }

  Future<void> _restaurarSesionLocal() async {
    final sesion_guardada = await _repositorio.cargarSesionLocal();
    if (!mounted) return;

    if (sesion_guardada != null &&
        sesion_guardada.estado != EstadoRecorridoGpsPrueba.inactivo &&
        sesion_guardada.puntos.isNotEmpty) {
      _etiqueta_controlador.text = sesion_guardada.etiqueta_prueba ?? '';

      if (sesion_guardada.estado == EstadoRecorridoGpsPrueba.en_curso) {
        final ahora_utc = DateTime.now().toUtc();
        final inicio_utc = DateTime.tryParse(
          sesion_guardada.hora_inicio_dispositivo ?? '',
        );
        final transcurrido_ms = inicio_utc != null
            ? math.max(0, ahora_utc.difference(inicio_utc).inMilliseconds)
            : sesion_guardada.puntos.last.reloj_monotonico_ms;

        _desfase_monotonico_base_ms = transcurrido_ms;
        _reloj_ultima_captura_ms =
            sesion_guardada.puntos.last.reloj_monotonico_ms;
        _cronometro
          ..reset()
          ..start();
        _iniciarTemporizadorUi();
      }

      setState(() {
        _sesion = sesion_guardada;
        _cargando_estado_inicial = false;
      });

      if (sesion_guardada.estado == EstadoRecorridoGpsPrueba.en_curso &&
          _segundosDesdeUltimaCaptura >= _INTERVALO_CAPTURA_SEG) {
        _capturarPuntoAutomatico();
      }
    } else {
      setState(() {
        _sesion = SesionRecorridoGpsPrueba.inicial();
        _cargando_estado_inicial = false;
      });
    }
  }

  void _iniciarTemporizadorUi() {
    _temporizador_ui?.cancel();
    _temporizador_ui = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _sesion.estado != EstadoRecorridoGpsPrueba.en_curso) {
        return;
      }

      if (_segundosDesdeUltimaCaptura >= _INTERVALO_CAPTURA_SEG &&
          !_capturando_punto &&
          !_finalizando_sesion) {
        _capturarPuntoAutomatico();
      } else {
        setState(() {});
      }
    });
  }

  PuntoGpsPruebaModelo _construirPunto({
    required String uuid_sesion,
    required int secuencia,
    required Position posicion,
    required int reloj_monotonico_ms,
    required String modo_captura,
    required String? hash_anterior,
  }) {
    final ahora_utc = DateTime.now().toUtc();
    final hora_dispositivo_iso = ahora_utc.toIso8601String();
    final fecha_gps_utc = posicion.timestamp.toUtc();
    final hora_gps_iso = fecha_gps_utc.toIso8601String();
    final desfase_reloj_seg = ahora_utc.difference(fecha_gps_utc).inSeconds;

    final hash_punto = calcularHashPunto(
      uuid_sesion: uuid_sesion,
      secuencia: secuencia,
      latitud: posicion.latitude,
      longitud: posicion.longitude,
      precision_m: posicion.accuracy,
      hora_gps_iso: hora_gps_iso,
      hora_dispositivo_iso: hora_dispositivo_iso,
      reloj_monotonico_ms: reloj_monotonico_ms,
      es_ubicacion_simulada: posicion.isMocked,
      hash_anterior: hash_anterior,
    );

    return PuntoGpsPruebaModelo(
      secuencia: secuencia,
      latitud: posicion.latitude,
      longitud: posicion.longitude,
      precision_m: posicion.accuracy,
      altitud_m: posicion.altitude,
      velocidad_mps: posicion.speed >= 0 ? posicion.speed : null,
      rumbo_grados: posicion.heading >= 0 ? posicion.heading : null,
      hora_dispositivo_iso: hora_dispositivo_iso,
      hora_gps_iso: hora_gps_iso,
      desfase_reloj_seg: desfase_reloj_seg,
      reloj_monotonico_ms: reloj_monotonico_ms,
      es_ubicacion_simulada: posicion.isMocked,
      modo_captura: modo_captura,
      hash_punto: hash_punto,
      hash_anterior: hash_anterior,
    );
  }

  Future<void> _iniciarRecorrido() async {
    if (_iniciando_sesion ||
        _sesion.estado != EstadoRecorridoGpsPrueba.inactivo) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _iniciando_sesion = true;
      _mensaje_error = null;
      _error_subida_previo = false;
    });

    try {
      final posicion = await _repositorio.capturarPosicionGps(
        timeout_segundos: 20,
      );
      final modo_captura = await _repositorio.detectarModoCaptura();
      final uuid_nuevo = generarUuidV4();
      final etiqueta_limpia = _etiqueta_controlador.text.trim();

      final punto_inicial = _construirPunto(
        uuid_sesion: uuid_nuevo,
        secuencia: 1,
        posicion: posicion,
        reloj_monotonico_ms: 0,
        modo_captura: modo_captura,
        hash_anterior: null,
      );

      final sesion_iniciada = SesionRecorridoGpsPrueba(
        uuid_sesion: uuid_nuevo,
        estado: EstadoRecorridoGpsPrueba.en_curso,
        etiqueta_prueba: etiqueta_limpia.isNotEmpty ? etiqueta_limpia : null,
        dispositivo_info: _repositorio.obtenerInfoDispositivo(),
        hora_inicio_dispositivo: punto_inicial.hora_dispositivo_iso,
        hora_inicio_gps: punto_inicial.hora_gps_iso,
        zona_horaria_offset_min: DateTime.now().timeZoneOffset.inMinutes,
        duracion_monotonica_seg: 0,
        intervalo_minutos: 5,
        puntos: List.unmodifiable([punto_inicial]),
      );

      await _repositorio.guardarSesionLocal(sesion_iniciada);
      if (!mounted) return;

      _desfase_monotonico_base_ms = 0;
      _reloj_ultima_captura_ms = 0;
      _cronometro
        ..reset()
        ..start();
      _iniciarTemporizadorUi();

      setState(() {
        _sesion = sesion_iniciada;
        _iniciando_sesion = false;
      });
    } on ExcepcionGpsPrueba catch (error) {
      if (!mounted) return;
      setState(() {
        _iniciando_sesion = false;
        _mensaje_error = error.mensaje;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _iniciando_sesion = false;
        _mensaje_error =
            'No se pudo iniciar la captura GPS. Verifica permisos y señal.';
      });
    }
  }

  Future<void> _capturarPuntoAutomatico() async {
    if (_capturando_punto ||
        _finalizando_sesion ||
        _sesion.estado != EstadoRecorridoGpsPrueba.en_curso) {
      return;
    }

    setState(() {
      _capturando_punto = true;
    });

    try {
      final posicion = await _repositorio.capturarPosicionGps(
        timeout_segundos: 20,
      );
      final modo_captura = await _repositorio.detectarModoCaptura();
      if (!mounted || _sesion.estado != EstadoRecorridoGpsPrueba.en_curso) {
        return;
      }

      final reloj_ms = _ahoraMonotonicoMs();
      final ultimo_punto = _sesion.puntos.isNotEmpty
          ? _sesion.puntos.last
          : null;
      final nuevo_punto = _construirPunto(
        uuid_sesion: _sesion.uuid_sesion,
        secuencia: _sesion.puntos.length + 1,
        posicion: posicion,
        reloj_monotonico_ms: reloj_ms,
        modo_captura: modo_captura,
        hash_anterior: ultimo_punto?.hash_punto,
      );

      final lista_actualizada = [..._sesion.puntos, nuevo_punto];
      final sesion_actualizada = _sesion.copiarCon(
        duracion_monotonica_seg: math.max(0, reloj_ms ~/ 1000),
        puntos: lista_actualizada,
      );

      await _repositorio.guardarSesionLocal(sesion_actualizada);
      if (!mounted) return;

      _reloj_ultima_captura_ms = reloj_ms;
      setState(() {
        _sesion = sesion_actualizada;
        _capturando_punto = false;
        _mensaje_error = null;
      });
    } on ExcepcionGpsPrueba catch (error) {
      if (!mounted) return;
      _reloj_ultima_captura_ms = _ahoraMonotonicoMs();
      setState(() {
        _capturando_punto = false;
        _mensaje_error =
            'Captura automática omitida (${error.mensaje}). Se reintentará en el próximo ciclo.';
      });
    } catch (_) {
      if (!mounted) return;
      _reloj_ultima_captura_ms = _ahoraMonotonicoMs();
      setState(() {
        _capturando_punto = false;
      });
    }
  }

  Future<void> _finalizarRecorrido() async {
    if (_finalizando_sesion ||
        _sesion.estado != EstadoRecorridoGpsPrueba.en_curso ||
        _sesion.puntos.isEmpty) {
      return;
    }

    _temporizador_ui?.cancel();
    _cronometro.stop();
    final duracion_final_seg = math.max(0, _ahoraMonotonicoMs() ~/ 1000);

    setState(() {
      _finalizando_sesion = true;
      _mensaje_error = null;
    });

    List<PuntoGpsPruebaModelo> puntos_finales = List.of(_sesion.puntos);

    try {
      final posicion_cierre = await _repositorio.capturarPosicionGps(
        timeout_segundos: 8,
      );
      final modo_captura = await _repositorio.detectarModoCaptura();
      final ultimo_punto = puntos_finales.last;
      final punto_cierre = _construirPunto(
        uuid_sesion: _sesion.uuid_sesion,
        secuencia: puntos_finales.length + 1,
        posicion: posicion_cierre,
        reloj_monotonico_ms: _ahoraMonotonicoMs(),
        modo_captura: modo_captura,
        hash_anterior: ultimo_punto.hash_punto,
      );
      puntos_finales.add(punto_cierre);
    } catch (_) {
      // Si el cierre rápido de GPS falla o expira, se sella con los puntos ya capturados.
    }

    final punto_final = puntos_finales.last;
    final hora_fin_dispositivo = DateTime.now().toUtc().toIso8601String();
    String? hora_fin_gps;
    for (int i = puntos_finales.length - 1; i >= 0; i--) {
      if (puntos_finales[i].hora_gps_iso != null) {
        hora_fin_gps = puntos_finales[i].hora_gps_iso;
        break;
      }
    }

    final hash_integridad = calcularHashSesion(
      uuid_sesion: _sesion.uuid_sesion,
      total_puntos: puntos_finales.length,
      ultimo_hash_punto: punto_final.hash_punto,
      duracion_monotonica_seg: duracion_final_seg,
    );

    final sesion_finalizada = _sesion.copiarCon(
      estado: EstadoRecorridoGpsPrueba.finalizado,
      hora_fin_dispositivo: hora_fin_dispositivo,
      hora_fin_gps: hora_fin_gps,
      duracion_monotonica_seg: duracion_final_seg,
      hash_integridad_cliente: hash_integridad,
      puntos: puntos_finales,
    );

    await _repositorio.guardarSesionLocal(sesion_finalizada);
    if (!mounted) return;

    setState(() {
      _sesion = sesion_finalizada;
      _finalizando_sesion = false;
      _error_subida_previo = false;
    });
  }

  Future<void> _subirRecorrido() async {
    if (_subiendo_sesion ||
        _sesion.estado != EstadoRecorridoGpsPrueba.finalizado) {
      return;
    }

    setState(() {
      _subiendo_sesion = true;
      _mensaje_error = null;
    });

    final resultado = await _repositorio.subirRecorridoPrueba(_sesion);
    if (!mounted) return;

    if (resultado.exito) {
      await _reiniciarAPantallaInicial(
        mensaje_confirmacion: 'Recorrido GPS de prueba subido con éxito.',
      );
    } else {
      setState(() {
        _subiendo_sesion = false;
        _error_subida_previo = true;
        _mensaje_error =
            resultado.error ?? 'Error al subir recorrido. Intenta nuevamente.';
      });
    }
  }

  Future<void> _confirmarYEliminarRecorrido() async {
    if (_subiendo_sesion) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (contexto_dialogo) {
        return AlertDialog(
          backgroundColor: BumandColores.blanco,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Eliminar prueba capturada',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: BumandColores.negro,
            ),
          ),
          content: Text(
            'Se descartarán permanentemente los ${_sesion.puntos.length} puntos capturados en el dispositivo sin subirlos al servidor.',
            style: GoogleFonts.montserrat(
              fontSize: 13.5,
              color: BumandColores.grisMedio,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(contexto_dialogo).pop(false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: BumandColores.grisMedio,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(contexto_dialogo).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _COLOR_ROJO,
                foregroundColor: BumandColores.blanco,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Eliminar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true && mounted) {
      await _reiniciarAPantallaInicial(
        mensaje_confirmacion: 'Registro de prueba eliminado del dispositivo.',
      );
    }
  }

  Future<void> _reiniciarAPantallaInicial({
    required String mensaje_confirmacion,
  }) async {
    _temporizador_ui?.cancel();
    _cronometro.stop();
    _cronometro.reset();
    _desfase_monotonico_base_ms = 0;
    _reloj_ultima_captura_ms = 0;
    _etiqueta_controlador.clear();

    await _repositorio.eliminarSesionLocal();
    if (!mounted) return;

    setState(() {
      _sesion = SesionRecorridoGpsPrueba.inicial();
      _subiendo_sesion = false;
      _error_subida_previo = false;
      _mensaje_error = null;
      _iniciando_sesion = false;
      _capturando_punto = false;
      _finalizando_sesion = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje_confirmacion,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w500,
            color: BumandColores.blanco,
          ),
        ),
        backgroundColor: BumandColores.negro,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  String _formatearDuracion(int total_segundos) {
    final horas = total_segundos ~/ 3600;
    final minutos = (total_segundos % 3600) ~/ 60;
    final segundos = total_segundos % 60;
    return '${horas.toString().padLeft(2, '0')}:'
        '${minutos.toString().padLeft(2, '0')}:'
        '${segundos.toString().padLeft(2, '0')}';
  }

  String _formatearCuentaRegresiva(int total_segundos) {
    final minutos = total_segundos ~/ 60;
    final segundos = total_segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:'
        '${segundos.toString().padLeft(2, '0')}';
  }

  String _formatearHoraLocalCorta(String? iso_utc) {
    if (iso_utc == null || iso_utc.isEmpty) return '--:--:--';
    final dt = DateTime.tryParse(iso_utc)?.toLocal();
    if (dt == null) return '--:--:--';
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  String _formatearDistancia(double metros) {
    if (metros >= 1000) {
      return '${(metros / 1000).toStringAsFixed(2)} km';
    }
    return '${metros.toStringAsFixed(0)} m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BumandColores.fondo,
      body: SafeArea(
        child: Column(
          children: [
            _construirEncabezado(),
            Expanded(
              child: _cargando_estado_inicial
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: BumandColores.azulMarinoProfundo,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_mensaje_error != null) _construirBannerError(),
                          if (_sesion.estado ==
                              EstadoRecorridoGpsPrueba.inactivo)
                            _construirVistaInactivo(),
                          if (_sesion.estado ==
                              EstadoRecorridoGpsPrueba.en_curso)
                            _construirVistaEnCurso(),
                          if (_sesion.estado ==
                              EstadoRecorridoGpsPrueba.finalizado)
                            _construirVistaFinalizado(),
                        ],
                      ),
                    ),
            ),
            if (!_cargando_estado_inicial) _construirBarraAccionesInferior(),
          ],
        ),
      ),
    );
  }

  Widget _construirEncabezado() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: BumandColores.blanco,
        border: Border(
          bottom: BorderSide(color: BumandColores.grisClaro, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Volver al login',
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: BumandColores.azulMarinoSecundario,
              size: 20,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: BumandColores.negro,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: BumandColores.azulCieloSuave,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/logos/logo-gps-cpp.svg',
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Prueba GPS C++',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            color: BumandColores.blanco,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Sin sesión estudiantil',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            color: BumandColores.azulCieloSuave,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: BumandColores.amarilloRadiante,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'PRUEBA TEMPORAL',
                      style: GoogleFonts.poppins(
                        color: BumandColores.negro,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirBannerError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _COLOR_ROJO.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _COLOR_ROJO.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: _COLOR_ROJO, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _mensaje_error!,
              style: GoogleFonts.montserrat(
                color: BumandColores.negro,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirVistaInactivo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BumandColores.blanco,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BumandColores.grisClaro),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BumandColores.azulCieloSuave.withValues(
                        alpha: 0.14,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.satellite_alt_rounded,
                      color: BumandColores.azulMarinoSecundario,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Muestreo GPS de campo (cada 5 min)',
                      style: GoogleFonts.montserrat(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: BumandColores.negro,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Al presionar INICIAR se capturará inmediatamente el Punto #1 con coordenadas satelitales, sello SHA-256 y respaldo local offline. El botón FINALIZAR permanecerá bloqueado hasta confirmar la primera lectura GPS.',
                style: GoogleFonts.montserrat(
                  fontSize: 12.5,
                  height: 1.45,
                  color: BumandColores.grisMedio,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BumandColores.blanco,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BumandColores.grisClaro),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Referencia de prueba',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: BumandColores.azulMarinoSecundario,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _etiqueta_controlador,
                enabled: !_iniciando_sesion,
                maxLength: 80,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: BumandColores.negro,
                ),
                decoration: InputDecoration(
                  hintText: 'Nombre o referencia de prueba (opcional)',
                  counterText: '',
                  prefixIcon: const Icon(
                    Icons.label_outline_rounded,
                    color: BumandColores.azulMarinoProfundo,
                  ),
                  filled: true,
                  fillColor: BumandColores.fondo,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: BumandColores.grisClaro,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: BumandColores.grisClaro,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: BumandColores.azulMarinoProfundo,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _construirVistaEnCurso() {
    final distancia_m = _sesion.calcularDistanciaTotalMetros();
    final cuenta_regresiva = _formatearCuentaRegresiva(
      _segundosRestantesProximaCaptura,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BumandColores.negro,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BumandColores.azulCieloSuave, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: _COLOR_VERDE,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'RECORRIDO EN CURSO',
                      style: GoogleFonts.poppins(
                        color: BumandColores.azulCieloSuave,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  if (_capturando_punto)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: BumandColores.amarilloRadiante,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Capturando...',
                          style: GoogleFonts.poppins(
                            color: BumandColores.amarilloRadiante,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (_sesion.etiqueta_prueba != null &&
                  _sesion.etiqueta_prueba!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _sesion.etiqueta_prueba!,
                  style: GoogleFonts.montserrat(
                    color: BumandColores.blanco,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _construirMetricaOscura(
                      etiqueta: 'Tiempo monótono',
                      valor: _formatearDuracion(_segundosTranscurridosTotales),
                      color_valor: BumandColores.blanco,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _construirMetricaOscura(
                      etiqueta: 'Próxima captura',
                      valor: cuenta_regresiva,
                      color_valor: BumandColores.amarilloRadiante,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _construirMetricaOscura(
                      etiqueta: 'Puntos capturados',
                      valor: '${_sesion.puntos.length}',
                      color_valor: BumandColores.azulCieloSuave,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _construirMetricaOscura(
                      etiqueta: 'Distancia acum.',
                      valor: _formatearDistancia(distancia_m),
                      color_valor: BumandColores.blanco,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _construirListaPuntosSoloLectura(),
      ],
    );
  }

  Widget _construirVistaFinalizado() {
    final distancia_m = _sesion.calcularDistanciaTotalMetros();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: BumandColores.azulMarinoProfundo.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BumandColores.azulMarinoProfundo.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: BumandColores.azulMarinoSecundario,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Datos capturados (solo lectura · no modificables)',
                      style: GoogleFonts.montserrat(
                        color: BumandColores.azulMarinoSecundario,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_sesion.etiqueta_prueba != null &&
                  _sesion.etiqueta_prueba!.isNotEmpty) ...[
                Text(
                  'Referencia: ${_sesion.etiqueta_prueba}',
                  style: GoogleFonts.montserrat(
                    color: BumandColores.negro,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _construirDatoResumen(
                    'Inicio',
                    _formatearHoraLocalCorta(_sesion.hora_inicio_dispositivo),
                  ),
                  _construirDatoResumen(
                    'Fin',
                    _formatearHoraLocalCorta(_sesion.hora_fin_dispositivo),
                  ),
                  _construirDatoResumen(
                    'Duración',
                    _formatearDuracion(_sesion.duracion_monotonica_seg),
                  ),
                  _construirDatoResumen(
                    'Distancia',
                    _formatearDistancia(distancia_m),
                  ),
                  _construirDatoResumen(
                    'Puntos',
                    '${_sesion.puntos.length}',
                  ),
                ],
              ),
              if (_sesion.hash_integridad_cliente != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Sello SHA-256: ${_sesion.hash_integridad_cliente!.substring(0, 16)}...',
                  style: GoogleFonts.poppins(
                    color: BumandColores.azulPetroleo,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _construirListaPuntosSoloLectura(),
      ],
    );
  }

  Widget _construirMetricaOscura({
    required String etiqueta,
    required String valor,
    required Color color_valor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              color: BumandColores.grisClaro,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: GoogleFonts.poppins(
                color: color_valor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirDatoResumen(String etiqueta, String valor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: BumandColores.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BumandColores.grisClaro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            etiqueta,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              color: BumandColores.grisMedio,
            ),
          ),
          Text(
            valor,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: BumandColores.negro,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirListaPuntosSoloLectura() {
    final puntos = _sesion.puntos.reversed.toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BumandColores.blanco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BumandColores.grisClaro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.route_rounded,
                color: BumandColores.azulMarinoProfundo,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Puntos capturados (${_sesion.puntos.length})',
                  style: GoogleFonts.montserrat(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: BumandColores.negro,
                  ),
                ),
              ),
              Text(
                'Solo lectura',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: BumandColores.grisMedio,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: puntos.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, indice) {
              final punto = puntos[indice];
              final es_online = punto.modo_captura == 'online';
              return Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: BumandColores.fondo,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: punto.es_ubicacion_simulada
                        ? _COLOR_ROJO.withValues(alpha: 0.6)
                        : BumandColores.grisClaro,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: BumandColores.azulMarinoSecundario,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '#${punto.secuencia}',
                            style: GoogleFonts.poppins(
                              color: BumandColores.blanco,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatearHoraLocalCorta(punto.hora_dispositivo_iso),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: BumandColores.negro,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (es_online
                                    ? _COLOR_VERDE
                                    : BumandColores.amarilloRadiante)
                                .withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            es_online ? 'Online' : 'Offline',
                            style: GoogleFonts.poppins(
                              color: es_online
                                  ? _COLOR_VERDE
                                  : BumandColores.negro,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Lat: ${punto.latitud.toStringAsFixed(6)} · Lng: ${punto.longitud.toStringAsFixed(6)}',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: BumandColores.negro,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Precisión: ${punto.precision_m.toStringAsFixed(1)} m · T+${punto.reloj_monotonico_ms ~/ 1000}s',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: BumandColores.grisMedio,
                            ),
                          ),
                        ),
                        if (punto.es_ubicacion_simulada)
                          Text(
                            'SIMULADA',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _COLOR_ROJO,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _construirBarraAccionesInferior() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: BumandColores.blanco,
        border: Border(
          top: BorderSide(color: BumandColores.grisClaro, width: 1),
        ),
      ),
      child: _sesion.estado == EstadoRecorridoGpsPrueba.finalizado
          ? _construirBotonesFinalizado()
          : _construirBotonesCaptura(),
    );
  }

  Widget _construirBotonesCaptura() {
    final esta_inactivo = _sesion.estado == EstadoRecorridoGpsPrueba.inactivo;
    final esta_en_curso = _sesion.estado == EstadoRecorridoGpsPrueba.en_curso;
    final puede_finalizar =
        esta_en_curso && _sesion.puntos.isNotEmpty && !_finalizando_sesion;

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: (esta_inactivo && !_iniciando_sesion)
                  ? _iniciarRecorrido
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _COLOR_VERDE,
                disabledBackgroundColor: _COLOR_VERDE.withValues(alpha: 0.35),
                foregroundColor: BumandColores.blanco,
                disabledForegroundColor: BumandColores.blanco.withValues(
                  alpha: 0.75,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _iniciando_sesion
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: BumandColores.blanco,
                      ),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'INICIAR',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: BumandColores.blanco,
                        ),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: puede_finalizar ? _finalizarRecorrido : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _COLOR_ROJO,
                disabledBackgroundColor: BumandColores.grisClaro,
                foregroundColor: BumandColores.blanco,
                disabledForegroundColor: BumandColores.grisMedio,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _finalizando_sesion
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: BumandColores.blanco,
                      ),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'FINALIZAR',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirBotonesFinalizado() {
    final etiqueta_subida = _error_subida_previo ? 'Reintentar' : 'Subir';

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _subiendo_sesion
                  ? null
                  : _confirmarYEliminarRecorrido,
              style: OutlinedButton.styleFrom(
                foregroundColor: _COLOR_ROJO,
                side: const BorderSide(color: _COLOR_ROJO, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Eliminar',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _subiendo_sesion ? null : _subirRecorrido,
              style: ElevatedButton.styleFrom(
                backgroundColor: _error_subida_previo
                    ? BumandColores.amarilloRadiante
                    : BumandColores.azulMarinoProfundo,
                foregroundColor: _error_subida_previo
                    ? BumandColores.negro
                    : BumandColores.blanco,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _subiendo_sesion
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: _error_subida_previo
                            ? BumandColores.negro
                            : BumandColores.blanco,
                      ),
                    )
                  : Icon(
                      _error_subida_previo
                          ? Icons.refresh_rounded
                          : Icons.cloud_upload_outlined,
                      size: 20,
                    ),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _subiendo_sesion ? 'Subiendo...' : etiqueta_subida,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
