import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../nucleo/constantes/api-constantes.dart';
import '../../../nucleo/errores/error-bumand.dart';
import '../../../nucleo/servicios/cola-offline-servicio.dart';
import '../../../nucleo/utilidades/resultado.dart';

class AsistenciaRepositorio {
  final http.Client? cliente;
  final ColaOfflineServicio? cola_offline;

  AsistenciaRepositorio({
    this.cliente,
    this.cola_offline,
  });

  Future<String?> _obtenerToken() async {
    final preferencias = await SharedPreferences.getInstance();
    return preferencias.getString('token');
  }

  Future<Map<String, String>> _cabeceras() async {
    final token = await _obtenerToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  http.Client _obtenerCliente() => cliente ?? http.Client();

  Future<Resultado<Map<String, dynamic>>> obtenerPerfil() async {
    final cliente_http = _obtenerCliente();
    try {
      final cabeceras = await _cabeceras();
      final respuesta = await cliente_http.get(
        Uri.parse('${ApiConstantes.RUTA_BASE}/api/perfil'),
        headers: cabeceras,
      );

      if (respuesta.statusCode != 200) {
        final error = ErrorBumand.desdeRespuesta(respuesta);
        return Resultado.desdeErrorBumand(error);
      }
      return Resultado.exitoso(
        jsonDecode(respuesta.body) as Map<String, dynamic>,
      );
    } catch (_) {
      final error = ErrorBumand.conexionOffline(
        ruta: '/api/perfil',
        metodo: 'GET',
      );
      return Resultado.desdeErrorBumand(error);
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  Future<Resultado<Map<String, dynamic>>> actualizarPerfil(
    Map<String, dynamic> datos,
  ) async {
    final cliente_http = _obtenerCliente();
    try {
      final cabeceras = await _cabeceras();
      final respuesta = await cliente_http.put(
        Uri.parse('${ApiConstantes.RUTA_BASE}/api/perfil'),
        headers: cabeceras,
        body: jsonEncode(datos),
      );

      if (respuesta.statusCode != 200) {
        final error = ErrorBumand.desdeRespuesta(respuesta);
        return Resultado.desdeErrorBumand(error);
      }
      return Resultado.exitoso(
        jsonDecode(respuesta.body) as Map<String, dynamic>,
      );
    } catch (_) {
      final error = ErrorBumand.conexionOffline(
        ruta: '/api/perfil',
        metodo: 'PUT',
      );
      return Resultado.desdeErrorBumand(error);
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  Future<Position> obtenerPosicionActual() async {
    final servicio_activo = await Geolocator.isLocationServiceEnabled();
    if (!servicio_activo) {
      throw Exception("GPS desactivado.");
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        throw Exception("Permiso denegado.");
      }
    }
    if (permiso == LocationPermission.deniedForever) {
      throw Exception("Permiso bloqueado.");
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  double calcularDistancia({
    required Position posicion,
    required double latitud_destino,
    required double longitud_destino,
  }) {
    return Geolocator.distanceBetween(
      posicion.latitude,
      posicion.longitude,
      latitud_destino,
      longitud_destino,
    );
  }

  bool validarGeocerca({
    required Position posicion,
    required double latitud_destino,
    required double longitud_destino,
    double radio_tolerancia_m = 100,
  }) {
    if (posicion.isMocked) return false;
    final distancia_m = Geolocator.distanceBetween(
      posicion.latitude,
      posicion.longitude,
      latitud_destino,
      longitud_destino,
    );
    final margen = posicion.accuracy.clamp(0.0, 10.0);
    return distancia_m <= (radio_tolerancia_m + margen);
  }

  Map<String, dynamic> _cuerpoUbicacion(
    Position posicion,
    String tipo, {
    int? evento_id,
  }) {
    final mapa = <String, dynamic>{
      "latitud": posicion.latitude,
      "longitud": posicion.longitude,
      "precision": posicion.accuracy,
      "simulada": posicion.isMocked,
      "tipo": tipo,
    };
    if (evento_id != null) {
      mapa["evento_id"] = evento_id;
    }
    return mapa;
  }

  Future<Resultado<String>> registrarIngreso(
    String tipo,
    Position posicion, {
    int? evento_id,
  }) async {
    final cliente_http = _obtenerCliente();
    final cuerpo = _cuerpoUbicacion(posicion, tipo, evento_id: evento_id);
    final ruta = ApiConstantes.PUNTO_ASISTENCIA_INGRESO;

    try {
      final cabeceras = await _cabeceras();
      final respuesta = await cliente_http.post(
        Uri.parse('${ApiConstantes.RUTA_BASE}$ruta'),
        headers: cabeceras,
        body: jsonEncode(cuerpo),
      );

      if (respuesta.statusCode == 201 || respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body);
        return Resultado.exitoso(
          datos["mensaje"]?.toString() ?? "Ingreso registrado",
        );
      }
      final error = ErrorBumand.desdeRespuesta(respuesta);
      return Resultado.desdeErrorBumand(error);
    } catch (_) {
      if (cola_offline != null) {
        await cola_offline!.encolar(
          ruta: ruta,
          metodo: 'POST',
          cuerpo: cuerpo,
          tipo: 'asistencia_ingreso',
        );
        return Resultado.desdeErrorBumand(
          ErrorBumand.encoladoOffline(ruta: ruta, metodo: 'POST'),
        );
      }
      return Resultado.desdeErrorBumand(
        ErrorBumand.conexionOffline(ruta: ruta, metodo: 'POST'),
      );
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  Future<Resultado<String>> registrarSalida(
    String tipo,
    Position posicion, {
    int? evento_id,
  }) async {
    final cliente_http = _obtenerCliente();
    final cuerpo = _cuerpoUbicacion(posicion, tipo, evento_id: evento_id);
    final ruta = ApiConstantes.PUNTO_ASISTENCIA_SALIDA;

    try {
      final cabeceras = await _cabeceras();
      final respuesta = await cliente_http.post(
        Uri.parse('${ApiConstantes.RUTA_BASE}$ruta'),
        headers: cabeceras,
        body: jsonEncode(cuerpo),
      );

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        final datos = jsonDecode(respuesta.body);
        return Resultado.exitoso(
          datos["mensaje"]?.toString() ?? "Salida registrada",
        );
      }
      final error = ErrorBumand.desdeRespuesta(respuesta);
      return Resultado.desdeErrorBumand(error);
    } catch (_) {
      if (cola_offline != null) {
        await cola_offline!.encolar(
          ruta: ruta,
          metodo: 'POST',
          cuerpo: cuerpo,
          tipo: 'asistencia_salida',
        );
        return Resultado.desdeErrorBumand(
          ErrorBumand.encoladoOffline(ruta: ruta, metodo: 'POST'),
        );
      }
      return Resultado.desdeErrorBumand(
        ErrorBumand.conexionOffline(ruta: ruta, metodo: 'POST'),
      );
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  Future<Resultado<List<Map<String, dynamic>>>> obtenerHistorial() async {
    final cliente_http = _obtenerCliente();
    try {
      final cabeceras = await _cabeceras();
      // 1. Intentar endpoint específico de asistencias del becario (/asistencia/mis-asistencias)
      final url_mis_asistencias = Uri.parse(
        '${ApiConstantes.RUTA_BASE}/api/asistencia/mis-asistencias',
      );

      final respuesta_personal = await cliente_http
          .get(url_mis_asistencias, headers: cabeceras)
          .timeout(const Duration(seconds: 4));

      if (respuesta_personal.statusCode == 200) {
        final lista = (jsonDecode(respuesta_personal.body) as List)
            .cast<Map<String, dynamic>>();
        return Resultado.exitoso(lista);
      }

      // 2. Fallback al endpoint canónico de asistencia (/api/asistencia)
      final respuesta = await cliente_http.get(
        Uri.parse(
          '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_ASISTENCIA_HISTORIAL}',
        ),
        headers: cabeceras,
      );

      if (respuesta.statusCode != 200) {
        final error = ErrorBumand.desdeRespuesta(respuesta);
        return Resultado.desdeErrorBumand(error);
      }
      final lista = (jsonDecode(respuesta.body) as List)
          .cast<Map<String, dynamic>>();
      return Resultado.exitoso(lista);
    } catch (_) {
      final error = ErrorBumand.conexionOffline(
        ruta: ApiConstantes.PUNTO_ASISTENCIA_HISTORIAL,
        metodo: 'GET',
      );
      return Resultado.desdeErrorBumand(error);
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  Future<Resultado<String>> confirmarDatosPasajes(String periodo) async {
    final cliente_http = _obtenerCliente();
    try {
      final cabeceras = await _cabeceras();
      final respuesta = await cliente_http.post(
        Uri.parse(
          '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_PASAJES_CONFIRMAR}',
        ),
        headers: cabeceras,
        body: jsonEncode({"periodo": periodo}),
      );

      if (respuesta.statusCode != 200) {
        final error = ErrorBumand.desdeRespuesta(respuesta);
        return Resultado.desdeErrorBumand(error);
      }
      final datos = jsonDecode(respuesta.body);
      return Resultado.exitoso(datos["mensaje"]?.toString() ?? "Datos confirmados");
    } catch (_) {
      final error = ErrorBumand.conexionOffline(
        ruta: ApiConstantes.PUNTO_PASAJES_CONFIRMAR,
        metodo: 'POST',
      );
      return Resultado.desdeErrorBumand(error);
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  /// Consulta el extracto mensual bancario de asistencia con fallback local determinístico
  /// completo de Marzo 2026 a Noviembre 2026.
  Future<Resultado<ExtractoMensualAsistencia>> obtenerExtractoMensual({
    String? mes,
  }) async {
    final mes_param = mes ?? "Mayo 2026";
    final cliente_http = _obtenerCliente();
    try {
      final cabeceras = await _cabeceras();
      final uri = Uri.parse(
        '${ApiConstantes.RUTA_BASE}/api/asistencia/extracto-mensual',
      ).replace(queryParameters: {'mes': mes_param});

      final respuesta = await cliente_http
          .get(uri, headers: cabeceras)
          .timeout(const Duration(seconds: 3));

      if (respuesta.statusCode == 200) {
        final mapa = jsonDecode(respuesta.body) as Map<String, dynamic>;
        final extracto = ExtractoMensualAsistencia.desdeMapa(mapa);
        return Resultado.exitoso(extracto);
      }
    } catch (_) {
      // Fallback transparente al modelo determinístico
    } finally {
      if (cliente == null) cliente_http.close();
    }

    return Resultado.fallido('No se pudo obtener el extracto mensual');
  }

  /// Obtiene la lista completa de extractos mensuales desde el backend
  Future<Resultado<List<ExtractoMensualAsistencia>>> obtenerExtractosMensuales() async {
    final cliente_http = _obtenerCliente();
    try {
      final cabeceras = await _cabeceras();
      final uri = Uri.parse(
        '${ApiConstantes.RUTA_BASE}/api/asistencia/extracto-mensual',
      );

      final respuesta = await cliente_http
          .get(uri, headers: cabeceras)
          .timeout(const Duration(seconds: 4));

      if (respuesta.statusCode == 200) {
        final decodificado = jsonDecode(respuesta.body);
        if (decodificado is List) {
          final lista = decodificado
              .map((e) => ExtractoMensualAsistencia.desdeMapa(e as Map<String, dynamic>))
              .toList();
          return Resultado.exitoso(lista);
        }
      }
      return Resultado.fallido('No se pudieron obtener los extractos mensuales (${respuesta.statusCode})');
    } catch (e) {
      return Resultado.fallido('Error de conexión al obtener extractos: $e');
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  /// Obtiene las multas reales del becario desde el backend
  Future<Resultado<List<Map<String, dynamic>>>> obtenerMisMultas() async {
    final cliente_http = _obtenerCliente();
    try {
      final cabeceras = await _cabeceras();
      final uri = Uri.parse(
        '${ApiConstantes.RUTA_BASE}/api/asistencia/multas/mis-multas',
      );

      final respuesta = await cliente_http
          .get(uri, headers: cabeceras)
          .timeout(const Duration(seconds: 4));

      if (respuesta.statusCode == 200) {
        final decodificado = jsonDecode(respuesta.body);
        if (decodificado is List) {
          final lista = decodificado.cast<Map<String, dynamic>>();
          return Resultado.exitoso(lista);
        }
      }
      return Resultado.exitoso([]);
    } catch (_) {
      return Resultado.exitoso([]);
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  /// Busca un extracto por mes para compatibilidad
  ExtractoMensualAsistencia obtenerExtractoLocalPorMes(String mes_o_periodo) {
    return ExtractoMensualAsistencia(
      mes_id: "2026-05",
      mes_nombre: mes_o_periodo.isNotEmpty ? mes_o_periodo : "Mayo 2026",
      mes_corto: "Mayo",
      anio: 2026,
      mes_numero: 5,
      horas_totales: 0.0,
      meta_mensual: 36.0,
      diferencia_horas: 0.0,
      porcentaje_cumplido: 0,
      estado: "EN PROGRESO",
      jornadas_totales: 0,
      tasa_puntualidad: 100,
      movimientos: const [],
    );
  }

  /// Retorna lista vacía al haberse purgado los datos locales falsos
  List<ExtractoMensualAsistencia> generarExtractosLocales({
    List<Map<String, dynamic>>? registros_reales,
  }) => const <ExtractoMensualAsistencia>[];
}

/// Movimiento diario de entrada y salida para el extracto mensual bancario de asistencia.
class MovimientoExtractoAsistencia {
  final DateTime fecha;
  final String fecha_formateada; // "04-05"
  final String dia_semana; // "Lun"
  final String actividad; // "Prácticas Pre-Profesionales"
  final String tipo; // "practicas", "liderazgo", "servicio", "devocional"
  final String lugar; // "Oficina Central Diaconía IFD"
  final String hora_entrada; // "08:00"
  final String hora_salida; // "12:15"
  final double horas_dia; // 4.25
  final double horas_acumuladas; // Saldo progresivo acumulado en el mes
  final bool es_puntual;
  final bool dentro_geocerca;
  final double distancia_gps;
  final bool confirmado_organizador;
  final bool es_manual;
  final String estado;

  MovimientoExtractoAsistencia({
    required this.fecha,
    required this.fecha_formateada,
    required this.dia_semana,
    required this.actividad,
    required this.tipo,
    required this.lugar,
    required this.hora_entrada,
    required this.hora_salida,
    required this.horas_dia,
    required this.horas_acumuladas,
    this.es_puntual = true,
    this.dentro_geocerca = true,
    this.distancia_gps = 35.0,
    this.confirmado_organizador = true,
    this.es_manual = false,
    this.estado = "aprobado",
  });

  factory MovimientoExtractoAsistencia.desdeMapa(
    Map<String, dynamic> mapa, {
    double acumulado_previo = 0.0,
  }) {
    DateTime fecha_dt = DateTime.now();
    if (mapa["fecha"] != null) {
      final str = mapa["fecha"].toString();
      final parseada = DateTime.tryParse(str);
      if (parseada != null) {
        fecha_dt = parseada;
      }
    }
    final dia = fecha_dt.day.toString().padLeft(2, '0');
    final mes = fecha_dt.month.toString().padLeft(2, '0');
    final dias_semana = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];
    final dia_sem = dias_semana[(fecha_dt.weekday - 1).clamp(0, 6)];

    final h_in =
        mapa["horaIngreso"]?.toString() ?? mapa["hora_entrada"]?.toString() ?? "08:00";
    final h_out =
        mapa["horaSalida"]?.toString() ?? mapa["hora_salida"]?.toString() ?? "12:00";

    double horas = 4.0;
    if (mapa["horas_dia"] != null) {
      horas = double.tryParse(mapa["horas_dia"].toString()) ?? 4.0;
    } else if (mapa["horasTrabajadas"] != null) {
      final h_str = mapa["horasTrabajadas"].toString().replaceAll("h", "").trim();
      horas = double.tryParse(h_str) ?? 4.0;
    }

    final acum = (mapa["horas_acumuladas"] != null)
        ? (double.tryParse(mapa["horas_acumuladas"].toString()) ?? (acumulado_previo + horas))
        : (acumulado_previo + horas);

    return MovimientoExtractoAsistencia(
      fecha: fecha_dt,
      fecha_formateada: "$dia-$mes",
      dia_semana: dia_sem,
      actividad: mapa["actividad"]?.toString() ?? mapa["titulo"]?.toString() ?? "Prácticas Diaconía",
      tipo: mapa["tipo"]?.toString().toLowerCase() ?? "practicas",
      lugar: mapa["lugar"]?.toString() ?? "Oficina Central Diaconía IFD",
      hora_entrada: h_in,
      hora_salida: h_out,
      horas_dia: horas,
      horas_acumuladas: acum,
      es_puntual: mapa["es_puntual"] != false,
      dentro_geocerca: mapa["dentro_geocerca"] != false,
      distancia_gps: double.tryParse(mapa["distancia"]?.toString() ?? "35") ?? 35.0,
      confirmado_organizador: mapa["confirmado_organizador"] != false,
      es_manual: mapa["es_registro_manual"] == true,
      estado: mapa["estado"]?.toString() ?? "aprobado",
    );
  }

  Map<String, dynamic> aMapaRegistro() {
    return {
      "fecha":
          "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}",
      "tipo": tipo,
      "horaIngreso": hora_entrada,
      "horaSalida": hora_salida,
      "horasTrabajadas": "${horas_dia.toStringAsFixed(2)} h",
      "lugar": lugar,
      "distancia": distancia_gps.toInt(),
      "dentro_geocerca": dentro_geocerca,
      "confirmado_organizador": confirmado_organizador,
      "es_registro_manual": es_manual,
      "estado": estado,
    };
  }
}

/// Estado de cuenta / extracto mensual bancario de asistencia consolidado por mes.
class ExtractoMensualAsistencia {
  final String mes_id; // "2026-05"
  final String mes_nombre; // "Mayo 2026"
  final String mes_corto; // "Mayo"
  final int anio; // 2026
  final int mes_numero; // 5
  final double horas_totales; // 38.00
  final double meta_mensual; // 36.00
  final double diferencia_horas; // +2.00
  final int porcentaje_cumplido; // 106
  final String estado; // "META CUMPLIDA" o "EN PROGRESO"
  final int jornadas_totales;
  final int tasa_puntualidad; // e.g. 99
  final List<MovimientoExtractoAsistencia> movimientos;

  ExtractoMensualAsistencia({
    required this.mes_id,
    required this.mes_nombre,
    required this.mes_corto,
    required this.anio,
    required this.mes_numero,
    required this.horas_totales,
    this.meta_mensual = 36.0,
    required this.diferencia_horas,
    required this.porcentaje_cumplido,
    required this.estado,
    required this.jornadas_totales,
    required this.tasa_puntualidad,
    required this.movimientos,
  });

  factory ExtractoMensualAsistencia.desdeMapa(Map<String, dynamic> mapa) {
    final movimientos_raw = (mapa["movimientos"] as List? ?? []);
    double acum = 0.0;
    final List<MovimientoExtractoAsistencia> movs = [];
    for (final m in movimientos_raw) {
      if (m is Map<String, dynamic>) {
        final mov = MovimientoExtractoAsistencia.desdeMapa(m, acumulado_previo: acum);
        acum = mov.horas_acumuladas;
        movs.add(mov);
      }
    }

    final double total = double.tryParse(mapa["horas_totales"]?.toString() ?? "") ??
        (movs.isNotEmpty ? movs.last.horas_acumuladas : 0.0);
    const double meta = 36.0;
    final double diff = total - meta;
    final int pct = ((total / meta) * 100).round();

    return ExtractoMensualAsistencia(
      mes_id: mapa["mes_id"]?.toString() ?? "2026-05",
      mes_nombre: mapa["mes_nombre"]?.toString() ?? "Mayo 2026",
      mes_corto: mapa["mes_corto"]?.toString() ?? "Mayo",
      anio: int.tryParse(mapa["anio"]?.toString() ?? "2026") ?? 2026,
      mes_numero: int.tryParse(mapa["mes_numero"]?.toString() ?? "5") ?? 5,
      horas_totales: total,
      meta_mensual: meta,
      diferencia_horas: diff,
      porcentaje_cumplido: pct,
      estado: total >= meta ? "META CUMPLIDA" : "EN PROGRESO",
      jornadas_totales: movs.length,
      tasa_puntualidad: int.tryParse(mapa["tasa_puntualidad"]?.toString() ?? "100") ?? 100,
      movimientos: movs,
    );
  }
}

