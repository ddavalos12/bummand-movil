import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../nucleo/constantes/api-constantes.dart';
import '../../../nucleo/errores/error-bumand.dart';
import '../../../nucleo/servicios/cola-offline-servicio.dart';
import '../../../nucleo/utilidades/filtro-mentor.dart';
import '../../../nucleo/utilidades/formato-horas.dart';
import '../../../nucleo/utilidades/resultado.dart';
import '../modelos/registro-auditoria-asistencia-modelo.dart';

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
    double radio_tolerancia_m = 150.0,
  }) {
    if (posicion.isMocked) return false;
    final distancia_m = Geolocator.distanceBetween(
      posicion.latitude,
      posicion.longitude,
      latitud_destino,
      longitud_destino,
    );
    final radio_efectivo = radio_tolerancia_m < 150.0 ? 150.0 : radio_tolerancia_m;
    final margen = posicion.accuracy.clamp(0.0, 120.0);
    return distancia_m <= (radio_efectivo + margen);
  }

  Map<String, dynamic> _cuerpoUbicacion(
    Position posicion,
    String tipo, {
    int? evento_id,
    int? lugar_practica_id,
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
    if (lugar_practica_id != null) {
      mapa["lugar_practica_id"] = lugar_practica_id;
    }
    return mapa;
  }

  Future<Resultado<String>> registrarIngreso(
    String tipo,
    Position posicion, {
    int? evento_id,
    int? lugar_practica_id,
  }) async {
    final cliente_http = _obtenerCliente();
    final cuerpo = _cuerpoUbicacion(
      posicion,
      tipo,
      evento_id: evento_id,
      lugar_practica_id: lugar_practica_id,
    );
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
    int? lugar_practica_id,
  }) async {
    final cliente_http = _obtenerCliente();
    final cuerpo = _cuerpoUbicacion(
      posicion,
      tipo,
      evento_id: evento_id,
      lugar_practica_id: lugar_practica_id,
    );
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

  Future<Resultado<List<Map<String, dynamic>>>> obtenerHistorial({
    bool es_mentor = false,
    bool es_admin = false,
    int? usuario_id,
  }) async {
    final cliente_http = _obtenerCliente();
    try {
      final cabeceras = await _cabeceras();
      if (es_mentor || es_admin) {
        final respuesta_general = await cliente_http.get(
          Uri.parse(
            '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_ASISTENCIA_HISTORIAL}',
          ),
          headers: cabeceras,
        );
        if (respuesta_general.statusCode != 200) {
          final error = ErrorBumand.desdeRespuesta(respuesta_general);
          return Resultado.desdeErrorBumand(error);
        }
        var lista = (jsonDecode(respuesta_general.body) as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (es_mentor && !es_admin && usuario_id != null && lista.isNotEmpty) {
          final ids_asignados = await FiltroMentor.obtenerIdsBecariosAsignados(
            cliente: cliente,
            mentor_id: usuario_id,
          );
          lista = FiltroMentor.filtrarMapasParaMentor(
            lista,
            mentor_id: usuario_id,
            becarios_asignados_ids: ids_asignados,
          );
        }
        return Resultado.exitoso(lista);
      }

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

  /// Obtiene los registros de auditoría institucional (`GET /api/asistencia`).
  /// Si el usuario autenticado es Mentor (`es_mentor == true`), filtra
  /// estrictamente para devolver únicamente sus becarios designados.
  Future<Resultado<List<RegistroAuditoriaAsistencia>>>
      obtenerRegistrosAuditoria({
    bool es_mentor = false,
    int? usuario_id,
  }) async {
    final cliente_http = _obtenerCliente();
    try {
      final cabeceras = await _cabeceras();
      final respuesta = await cliente_http
          .get(
            Uri.parse('${ApiConstantes.RUTA_BASE}/api/asistencia'),
            headers: cabeceras,
          )
          .timeout(const Duration(seconds: 5));

      if (respuesta.statusCode == 200) {
        final decodificado = jsonDecode(respuesta.body);
        if (decodificado is List) {
          var lista = decodificado
              .whereType<Map>()
              .map(
                (e) => RegistroAuditoriaAsistencia.desdeMapa(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList();
          if (es_mentor && usuario_id != null && lista.isNotEmpty) {
            final ids_asignados =
                await FiltroMentor.obtenerIdsBecariosAsignados(
              cliente: cliente,
              mentor_id: usuario_id,
            );
            lista = FiltroMentor.filtrarParaMentor<RegistroAuditoriaAsistencia>(
              lista,
              mentor_id: usuario_id,
              obtenerSupervisorId: (r) => r.supervisor_id,
              obtenerBecarioId: (r) => r.becario_id,
              becarios_asignados_ids: ids_asignados,
            );
          }
          return Resultado.exitoso(lista);
        }
      }
      return Resultado.desdeErrorBumand(ErrorBumand.desdeRespuesta(respuesta));
    } catch (_) {
      return Resultado.desdeErrorBumand(
        ErrorBumand.conexionOffline(
          ruta: '/api/asistencia',
          metodo: 'GET',
        ),
      );
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  /// Aprobación definitiva por Administración:
  /// `PATCH /api/asistencia/:id/aprobar-administracion`.
  Future<Resultado<Map<String, dynamic>>> aprobarAdministracion(
    int id, {
    String? observacion,
  }) async {
    final texto_observacion =
        observacion ?? 'Convalidado y aprobado por Administración';
    return _patchAuditoria(
      '/api/asistencia/$id/aprobar-administracion',
      {
        'estado': 'aprobado_administracion',
        'observacion_admin': texto_observacion,
        'observacion': texto_observacion,
      },
    );
  }

  /// Revisión técnica del supervisor:
  /// `PATCH /api/asistencia/:id/revisar-supervisor`.
  Future<Resultado<Map<String, dynamic>>> revisarSupervisor(
    int id, {
    required String estado,
    String? observacion,
  }) async {
    return _patchAuditoria(
      '/api/asistencia/$id/revisar-supervisor',
      {
        'estado': estado,
        if (observacion != null) ...{
          'observacion_supervisor': observacion,
          'observacion': observacion,
        },
      },
    );
  }

  Future<Resultado<Map<String, dynamic>>> _patchAuditoria(
    String ruta,
    Map<String, dynamic> cuerpo,
  ) async {
    final cliente_http = _obtenerCliente();
    try {
      final cabeceras = await _cabeceras();
      final respuesta = await cliente_http.patch(
        Uri.parse('${ApiConstantes.RUTA_BASE}$ruta'),
        headers: cabeceras,
        body: jsonEncode(cuerpo),
      );
      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        final datos = respuesta.body.isNotEmpty
            ? jsonDecode(respuesta.body)
            : <String, dynamic>{};
        return Resultado.exitoso(
          datos is Map<String, dynamic> ? datos : <String, dynamic>{},
        );
      }
      return Resultado.desdeErrorBumand(ErrorBumand.desdeRespuesta(respuesta));
    } catch (_) {
      return Resultado.desdeErrorBumand(
        ErrorBumand.conexionOffline(ruta: ruta, metodo: 'PATCH'),
      );
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

  static String _mesActualTexto() {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    final ahora = DateTime.now();
    var anio = ahora.year;
    var mes = ahora.month;
    if (ahora.day >= 24) {
      if (mes == 12) {
        anio += 1;
        mes = 1;
      } else {
        mes += 1;
      }
    }
    return '${meses[mes - 1]} $anio';
  }

  /// Consulta el extracto mensual bancario de asistencia desde el backend.
  Future<Resultado<ExtractoMensualAsistencia>> obtenerExtractoMensual({
    String? mes,
  }) async {
    final mes_param = mes ?? _mesActualTexto();
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
          .timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final decodificado = jsonDecode(respuesta.body);
        List<dynamic> listaRaw = [];
        if (decodificado is List) {
          listaRaw = decodificado;
        } else if (decodificado is Map<String, dynamic> && decodificado['extractos'] is List) {
          listaRaw = decodificado['extractos'] as List<dynamic>;
        }
        final lista = listaRaw
            .map((e) => ExtractoMensualAsistencia.desdeMapa(e as Map<String, dynamic>))
            .toList();
        return Resultado.exitoso(lista);
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
          .timeout(const Duration(seconds: 15));

      if (respuesta.statusCode == 200) {
        final decodificado = jsonDecode(respuesta.body);
        if (decodificado is List) {
          final lista = decodificado.cast<Map<String, dynamic>>();
          return Resultado.exitoso(lista);
        }
      }
      return Resultado.desdeErrorBumand(ErrorBumand.desdeRespuesta(respuesta));
    } catch (_) {
      return Resultado.desdeErrorBumand(
        ErrorBumand.conexionOffline(
          ruta: '/api/asistencia/multas/mis-multas',
          metodo: 'GET',
        ),
      );
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }
}

/// Movimiento diario de entrada y salida para el extracto mensual bancario de asistencia.
class MovimientoExtractoAsistencia {
  final DateTime fecha;
  final String fecha_formateada; // "04-05"
  final String dia_semana; // "Lun"
  final String actividad; // "Prácticas Pre-Profesionales"
  final String tipo; // "practicas", "liderazgo", "servicio", "devocional"
  final String lugar; // "Oficina Central Diaconía IFD"
  final String hora_entrada; // "08:00:43"
  final String hora_salida; // "13:50:04" | "En curso"
  final double horas_dia; // 5.82
  final int segundos_dia;
  final double horas_acumuladas; // Saldo progresivo acumulado en el mes
  final int segundos_acumulados;
  final bool es_puntual;
  final bool dentro_geocerca;
  final double distancia_gps;
  final double? lat_ingreso;
  final double? lng_ingreso;
  final bool confirmado_organizador;
  final bool es_manual;
  final String estado;
  final int? registro_id;
  final int? becario_id;
  final String? becario_nombre;
  final String? carrera;
  final int minutos_retraso;
  final double monto_multa_bs;
  final bool confirmacion_presencial;
  final String estado_aprobacion;

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
    int? segundos_dia,
    required this.horas_acumuladas,
    int? segundos_acumulados,
    this.es_puntual = true,
    this.dentro_geocerca = true,
    this.distancia_gps = 0.0,
    this.lat_ingreso,
    this.lng_ingreso,
    this.confirmado_organizador = true,
    this.es_manual = false,
    this.estado = "aprobado",
    this.registro_id,
    this.becario_id,
    this.becario_nombre,
    this.carrera,
    this.minutos_retraso = 0,
    this.monto_multa_bs = 0.0,
    this.confirmacion_presencial = false,
    this.estado_aprobacion = "pendiente",
  })  : segundos_dia = segundos_dia ?? (horas_dia * 3600).round(),
        segundos_acumulados =
            segundos_acumulados ?? (horas_acumuladas * 3600).round();

  bool get es_escuela_lideres =>
      tipo.toLowerCase().contains('escuela') ||
      tipo.toLowerCase().contains('lider');

  bool get esta_en_curso {
    final s = hora_salida.trim().toLowerCase();
    return !es_escuela_lideres &&
        segundos_dia == 0 &&
        (s.isEmpty || s == 'en curso' || s == '--:--' || s == '--:--:--');
  }

  String get horas_dia_hms =>
      esta_en_curso ? 'En curso' : formatearSegundosAHhmmss(segundos_dia);

  String get horas_acumuladas_hms =>
      formatearSegundosAHhmmss(segundos_acumulados);

  factory MovimientoExtractoAsistencia.desdeMapa(
    Map<String, dynamic> mapa, {
    double acumulado_previo = 0.0,
    int? segundos_acumulados_previos,
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

    final h_in_raw =
        (mapa["horaIngreso"] ?? mapa["hora_entrada"] ?? mapa["hora_ingreso"])
            ?.toString();
    final h_out_raw =
        (mapa["horaSalida"] ?? mapa["hora_salida"])?.toString();

    final tipo_str = mapa["tipo"]?.toString().toLowerCase() ?? "practicas";
    final act_str = (mapa["actividad"]?.toString() ??
            mapa["tipo_etiqueta"]?.toString() ??
            mapa["titulo"]?.toString() ??
            "")
        .toLowerCase();
    final es_escuela_lideres = tipo_str.contains("escuela") ||
        tipo_str.contains("lider") ||
        act_str.contains("escuela") ||
        act_str.contains("líder") ||
        act_str.contains("lider");

    final h_in = normalizarHoraConSegundos(
      h_in_raw,
      valor_defecto: '--:--:--',
    );
    final tiene_salida = h_out_raw != null &&
        h_out_raw.trim().isNotEmpty &&
        h_out_raw.trim() != '--:--' &&
        h_out_raw.trim() != '--:--:--' &&
        h_out_raw.trim().toLowerCase() != 'en curso';
    final h_out = tiene_salida
        ? normalizarHoraConSegundos(h_out_raw)
        : (es_escuela_lideres ? '--:--:--' : 'En curso');

    int segs_dia = int.tryParse((mapa["segundos_dia"] ?? "").toString()) ?? -1;
    if (segs_dia < 0) {
      if (es_escuela_lideres) {
        segs_dia = 0;
      } else if (tiene_salida && h_in != '--:--:--') {
        final calc = calcularSegundosEntreHoras(h_in, h_out);
        if (calc > 0) {
          segs_dia = calc;
        }
      }
    }
    if (segs_dia < 0) {
      final h_raw = mapa["horas_dia"] ??
          mapa["horas_trabajadas"] ??
          mapa["horasTrabajadas"];
      final h_num = h_raw == null
          ? null
          : double.tryParse(h_raw.toString().replaceAll("h", "").trim());
      segs_dia = h_num != null && h_num > 0 ? (h_num * 3600).round() : 0;
    }

    final double horas =
        double.parse((segs_dia / 3600.0).toStringAsFixed(2));

    final minutos_retraso =
        int.tryParse((mapa["minutos_retraso"] ?? "0").toString()) ?? 0;
    double monto_multa =
        double.tryParse((mapa["monto_multa_bs"] ?? "0").toString()) ?? 0.0;
    if (monto_multa == 0.0 && es_escuela_lideres && minutos_retraso > 0) {
      monto_multa =
          RegistroAuditoriaAsistencia.calcularMultaEscuelaLideres(minutos_retraso);
    }

    final prev_segs =
        segundos_acumulados_previos ?? (acumulado_previo * 3600).round();
    final int? segs_backend_acum = int.tryParse(
        (mapa["saldo_acumulado_segundos"] ?? "").toString());
    final int segs_acum = es_escuela_lideres
        ? prev_segs
        : (segs_backend_acum ?? (prev_segs + segs_dia));
    final double acum = double.parse((segs_acum / 3600.0).toStringAsFixed(2));

    final distancia_raw = mapa["distancia_metros"] ??
        mapa["distancia_ingreso_m"] ??
        mapa["distancia_gps"] ??
        mapa["distancia"];

    return MovimientoExtractoAsistencia(
      fecha: fecha_dt,
      fecha_formateada: "$dia-$mes",
      dia_semana: dia_sem,
      actividad: mapa["actividad"]?.toString() ??
          mapa["tipo_etiqueta"]?.toString() ??
          mapa["titulo"]?.toString() ??
          "Prácticas Diaconía",
      tipo: es_escuela_lideres
          ? "escuela_lideres"
          : (mapa["tipo"]?.toString().toLowerCase() ?? "practicas"),
      lugar: mapa["lugar"]?.toString() ?? mapa["sede"]?.toString() ?? "Sin sede",
      hora_entrada: h_in,
      hora_salida: h_out,
      horas_dia: horas,
      segundos_dia: segs_dia,
      horas_acumuladas: acum,
      segundos_acumulados: segs_acum,
      es_puntual: mapa["es_puntual"] != false && minutos_retraso == 0,
      dentro_geocerca:
          mapa["dentro_geocerca"] != false && mapa["dentro_de_radio"] != false,
      distancia_gps: double.tryParse(distancia_raw?.toString() ?? "0") ?? 0.0,
      lat_ingreso: double.tryParse(
          (mapa["lat_ingreso"] ?? mapa["latIngreso"] ?? "").toString()),
      lng_ingreso: double.tryParse(
          (mapa["lng_ingreso"] ?? mapa["lngIngreso"] ?? "").toString()),
      confirmado_organizador: mapa["confirmado_organizador"] != false,
      es_manual: mapa["es_registro_manual"] == true,
      estado: mapa["estado"]?.toString() ?? "aprobado",
      registro_id:
          int.tryParse((mapa["id"] ?? mapa["registro_id"] ?? "").toString()),
      becario_id: int.tryParse((mapa["becario_id"] ?? "").toString()),
      becario_nombre: mapa["becario_nombre"]?.toString(),
      carrera: mapa["carrera"]?.toString(),
      minutos_retraso: minutos_retraso,
      monto_multa_bs: monto_multa,
      confirmacion_presencial: mapa["confirmacion_presencial"] == true ||
          mapa["confirmado_organizador"] == true,
      estado_aprobacion: mapa["estado_aprobacion"]?.toString() ?? "pendiente",
    );
  }

  Map<String, dynamic> aMapaRegistro() {
    return {
      "fecha":
          "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}",
      "tipo": tipo,
      "horaIngreso": hora_entrada,
      "horaSalida": hora_salida,
      "horasTrabajadas": horas_dia_hms,
      "lugar": lugar,
      "distancia": distancia_gps.round(),
      "dentro_geocerca": dentro_geocerca,
      "confirmado_organizador": confirmado_organizador,
      "es_registro_manual": es_manual,
      "estado": estado,
    };
  }
}

/// Estado de cuenta / extracto mensual bancario de asistencia consolidado por mes.
class ExtractoMensualAsistencia {
  final String mes_id; // "2026-12"
  final String mes_nombre; // "Diciembre 2026"
  final String mes_corto; // "Diciembre"
  final int anio; // 2026
  final int mes_numero; // 12
  final double horas_totales; // 38.00
  final int segundos_totales;
  final double meta_mensual; // 36.00
  final double diferencia_horas; // +2.00
  final int porcentaje_cumplido; // 106
  final String estado; // "META CUMPLIDA" o "EN PROGRESO"
  final int jornadas_totales;
  final int tasa_puntualidad;
  final double horas_compensadas_permiso;
  final int dias_permiso_aprobado;
  final List<MovimientoExtractoAsistencia> movimientos;

  ExtractoMensualAsistencia({
    required this.mes_id,
    required this.mes_nombre,
    required this.mes_corto,
    required this.anio,
    required this.mes_numero,
    required this.horas_totales,
    int? segundos_totales,
    this.meta_mensual = 36.0,
    required this.diferencia_horas,
    required this.porcentaje_cumplido,
    required this.estado,
    required this.jornadas_totales,
    required this.tasa_puntualidad,
    this.horas_compensadas_permiso = 0.0,
    this.dias_permiso_aprobado = 0,
    required this.movimientos,
  }) : segundos_totales =
            segundos_totales ?? (horas_totales * 3600).round();

  String get horas_totales_hms => formatearSegundosAHhmmss(segundos_totales);

  String get meta_mensual_hms => formatearHorasDecimalAHhmmss(meta_mensual);

  String get diferencia_hms {
    final segs_meta = (meta_mensual * 3600).round();
    final dif = segundos_totales - segs_meta;
    if (dif == 0) return '00:00:00';
    return '${dif < 0 ? '-' : '+'}${formatearSegundosAHhmmss(dif.abs())}';
  }

  String get faltante_hms {
    final segs_meta = (meta_mensual * 3600).round();
    final faltante = (segs_meta - segundos_totales).clamp(0, 9999999);
    return formatearSegundosAHhmmss(faltante);
  }

  factory ExtractoMensualAsistencia.desdeMapa(Map<String, dynamic> mapa) {
    final movimientos_raw = (mapa["movimientos"] as List? ?? []);
    int acum_segs = 0;
    double acum = 0.0;
    final List<MovimientoExtractoAsistencia> movs = [];
    for (final m in movimientos_raw) {
      if (m is Map<String, dynamic>) {
        final mov = MovimientoExtractoAsistencia.desdeMapa(
          m,
          acumulado_previo: acum,
          segundos_acumulados_previos: acum_segs,
        );
        acum = mov.horas_acumuladas;
        acum_segs = mov.segundos_acumulados;
        movs.add(mov);
      }
    }

    final double horas_compensadas = double.tryParse(
          mapa["horas_compensadas_permiso"]?.toString() ?? "",
        ) ??
        0.0;
    final int dias_permiso = int.tryParse(
          mapa["dias_permiso_aprobado"]?.toString() ?? "",
        ) ??
        0;

    final int? segs_backend = int.tryParse(
      (mapa["segundos_acumulados"] ?? mapa["segundos_totales"] ?? "").toString(),
    );
    final int total_segs_movs =
        movs.isNotEmpty ? movs.last.segundos_acumulados : 0;
    int total_segs = segs_backend != null && segs_backend >= total_segs_movs
        ? segs_backend
        : total_segs_movs;

    final double total_movs =
        double.parse((total_segs_movs / 3600.0).toStringAsFixed(2));
    final double? total_backend = double.tryParse(
      (mapa["horas_totales"] ?? mapa["horas_acumuladas"] ?? "").toString(),
    );
    if (segs_backend == null && total_backend != null && total_backend > total_movs) {
      total_segs = (total_backend * 3600).round();
    } else if (segs_backend == null && total_backend == null && horas_compensadas > 0) {
      total_segs += (horas_compensadas * 3600).round();
    }
    final double total =
        double.parse((total_segs / 3600.0).toStringAsFixed(2));

    final double meta =
        double.tryParse(mapa["meta_horas"]?.toString() ?? "") ?? 36.0;
    final double diff = total - meta;
    final int? pct_backend = int.tryParse(
      (mapa["porcentaje_cumplimiento"] ?? mapa["porcentaje_cumplido"] ?? "")
          .toString(),
    );
    final int pct = pct_backend ?? (meta > 0 ? ((total / meta) * 100).round() : 0);

    int tasa_punt =
        int.tryParse(mapa["tasa_puntualidad"]?.toString() ?? "") ?? 100;
    if (mapa["tasa_puntualidad"] == null && movs.isNotEmpty) {
      final puntuales = movs.where((m) {
        final est = m.estado.toLowerCase();
        return m.es_puntual ||
            est.contains('permiso') ||
            est.contains('justificad') ||
            est.contains('convalidad');
      }).length;
      tasa_punt = ((puntuales / movs.length) * 100).round().clamp(0, 100);
    } else if (dias_permiso > 0 && tasa_punt < 100) {
      tasa_punt = 100;
    }

    final ahora_dt = DateTime.now();
    var anio_corte = ahora_dt.year;
    var mes_corte = ahora_dt.month;
    if (ahora_dt.day >= 24) {
      if (mes_corte == 12) {
        anio_corte += 1;
        mes_corte = 1;
      } else {
        mes_corte += 1;
      }
    }
    final mesNom =
        mapa["mes_nombre"]?.toString() ?? AsistenciaRepositorio._mesActualTexto();
    final mesCorto = mapa["mes_corto"]?.toString() ?? mesNom.split(" ")[0];
    final mesIdDefecto =
        '$anio_corte-${mes_corte.toString().padLeft(2, '0')}';

    return ExtractoMensualAsistencia(
      mes_id:
          mapa["mes_id"]?.toString() ?? mapa["periodo"]?.toString() ?? mesIdDefecto,
      mes_nombre: mesNom,
      mes_corto: mesCorto,
      anio: int.tryParse(mapa["anio"]?.toString() ?? "") ??
          (mapa["periodo"] != null
              ? int.tryParse(mapa["periodo"].toString().split("-")[0]) ?? anio_corte
              : anio_corte),
      mes_numero: int.tryParse(mapa["mes_numero"]?.toString() ?? "") ??
          (mapa["periodo"] != null
              ? int.tryParse(mapa["periodo"].toString().split("-")[1]) ?? mes_corte
              : mes_corte),
      horas_totales: total,
      segundos_totales: total_segs,
      meta_mensual: meta,
      diferencia_horas: diff,
      porcentaje_cumplido: pct,
      estado: total >= meta ? "META CUMPLIDA" : "EN PROGRESO",
      jornadas_totales:
          int.tryParse(mapa["jornadas_totales"]?.toString() ?? "") ?? movs.length,
      tasa_puntualidad: tasa_punt,
      horas_compensadas_permiso: horas_compensadas,
      dias_permiso_aprobado: dias_permiso,
      movimientos: movs,
    );
  }
}

