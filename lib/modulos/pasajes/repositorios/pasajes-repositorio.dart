import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../nucleo/constantes/api-constantes.dart';
import '../../../nucleo/errores/error-bumand.dart';
import '../../../nucleo/servicios/cola-offline-servicio.dart';
import '../../../nucleo/utilidades/resultado.dart';
import '../../autenticacion/repositorios/autenticacion-repositorio.dart';
import '../modelos/recorrido-modelo.dart';
import '../modelos/solicitud-pasaje-modelo.dart';

class ResultadoPasaje<T> extends Resultado<T> {
  final String? codigo;
  final String? periodo;

  ResultadoPasaje({
    required super.exito,
    super.datos,
    super.error,
    super.error_bumand,
    this.codigo,
    this.periodo,
  });

  factory ResultadoPasaje.exitoso(T datos) =>
      ResultadoPasaje(exito: true, datos: datos);
  factory ResultadoPasaje.fallido(
    String error, {
    String? codigo,
    String? periodo,
    ErrorBumand? error_bumand,
  }) => ResultadoPasaje(
    exito: false,
    error: error,
    codigo: codigo,
    periodo: periodo,
    error_bumand: error_bumand,
  );
}

class PasajesRepositorio {
  static const _CLAVE_RECORRIDOS_LOCALES = 'pasajes_recorridos_locales_v1';

  final http.Client? cliente;
  final ColaOfflineServicio? cola_offline;
  final AutenticacionRepositorio _autenticacion_repositorio = AutenticacionRepositorio();

  PasajesRepositorio({
    this.cliente,
    this.cola_offline,
  });

  Future<Map<String, String>> _cabeceras() async {
    final token = await _autenticacion_repositorio.obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  http.Client _obtenerCliente() => cliente ?? http.Client();

  Uri _url(String ruta) =>
      Uri.parse('${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_PASAJES}$ruta');

  Future<List<RecorridoModelo>> _obtenerRecorridosLocales() async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      final texto = preferencias.getString(_CLAVE_RECORRIDOS_LOCALES);
      if (texto == null || texto.isEmpty) return [];
      final lista = jsonDecode(texto) as List<dynamic>;
      return lista
          .map((e) => RecorridoModelo.desdeJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _guardarRecorridoLocal(Map<String, dynamic> cuerpo) async {
    try {
      final actuales = await _obtenerRecorridosLocales();
      final nuevo = RecorridoModelo(
        id: DateTime.now().millisecondsSinceEpoch,
        fecha: DateTime.tryParse(cuerpo['fecha']?.toString() ?? '') ??
            DateTime.now(),
        tramo: (cuerpo['tramo'] ?? 'ida').toString(),
        origen: (cuerpo['origen'] ?? '').toString(),
        destino: (cuerpo['destino'] ?? '').toString(),
        tarifa: (cuerpo['tarifa'] as num?)?.toDouble() ?? 0.0,
        apoyo_realizado: cuerpo['apoyo_realizado']?.toString(),
        calles_declaradas: cuerpo['calles_declaradas']?.toString(),
        medio_transporte: cuerpo['medio_transporte']?.toString(),
        detalle_tramos_json: cuerpo['detalle_tramos_json']?.toString(),
        lat_origen: (cuerpo['lat_origen'] as num?)?.toDouble(),
        lng_origen: (cuerpo['lng_origen'] as num?)?.toDouble(),
        lat_destino: (cuerpo['lat_destino'] as num?)?.toDouble(),
        lng_destino: (cuerpo['lng_destino'] as num?)?.toDouble(),
      );
      actuales.insert(0, nuevo);
      final preferencias = await SharedPreferences.getInstance();
      await preferencias.setString(
        _CLAVE_RECORRIDOS_LOCALES,
        jsonEncode(actuales.map((r) => r.aJson()).toList()),
      );
    } catch (_) {}
  }

  List<SolicitudPasajeModelo> _combinarConRecorridosLocales(
    List<SolicitudPasajeModelo> remotas,
    List<RecorridoModelo> locales,
  ) {
    if (locales.isEmpty) return remotas;
    final ahora = DateTime.now();
    final periodo_actual =
        '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}';

    final resultado = List<SolicitudPasajeModelo>.from(remotas);
    final idx = resultado.indexWhere((s) => s.periodo == periodo_actual);

    if (idx >= 0) {
      final existente = resultado[idx];
      final combinados = [...locales, ...existente.recorridos];
      final total = combinados.fold<double>(0.0, (s, r) => s + r.tarifa);
      resultado[idx] = SolicitudPasajeModelo(
        id: existente.id,
        periodo: existente.periodo,
        estado: existente.estado,
        monto_total: total,
        monto_devolucion: total * 0.8,
        observaciones: existente.observaciones,
        datos_confirmados_en: existente.datos_confirmados_en ?? ahora,
        recorridos: combinados,
      );
    } else {
      final total = locales.fold<double>(0.0, (s, r) => s + r.tarifa);
      resultado.insert(
        0,
        SolicitudPasajeModelo(
          id: 1,
          periodo: periodo_actual,
          estado: 'borrador',
          monto_total: total,
          monto_devolucion: total * 0.8,
          datos_confirmados_en: ahora,
          recorridos: locales,
        ),
      );
    }
    return resultado;
  }

  Future<ResultadoPasaje<List<SolicitudPasajeModelo>>> misSolicitudes() async {
    final cliente_http = _obtenerCliente();
    final locales = await _obtenerRecorridosLocales();
    try {
      final respuesta = await cliente_http.get(
        _url('/mis-solicitudes'),
        headers: await _cabeceras(),
      );

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body) as List<dynamic>;
        final solicitudes = datos
            .map(
              (e) => SolicitudPasajeModelo.desdeJson(e as Map<String, dynamic>),
            )
            .toList();
        return ResultadoPasaje.exitoso(
          _combinarConRecorridosLocales(solicitudes, locales),
        );
      } else {
        if (locales.isNotEmpty || respuesta.statusCode == 403) {
          return ResultadoPasaje.exitoso(
            _combinarConRecorridosLocales([], locales),
          );
        }
        final error = ErrorBumand.desdeRespuesta(respuesta);
        return ResultadoPasaje.fallido(
          error.mensaje,
          codigo: error.codigo_error,
          error_bumand: error,
        );
      }
    } catch (_) {
      if (locales.isNotEmpty) {
        return ResultadoPasaje.exitoso(
          _combinarConRecorridosLocales([], locales),
        );
      }
      final error = ErrorBumand.conexionOffline(
        ruta: '/pasajes/mis-solicitudes',
        metodo: 'GET',
      );
      return ResultadoPasaje.fallido(
        error.mensaje,
        codigo: error.codigo_error,
        error_bumand: error,
      );
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  Future<ResultadoPasaje<SolicitudPasajeModelo>> obtenerSolicitudPorId(
    int id,
  ) async {
    final cliente_http = _obtenerCliente();
    try {
      final respuesta = await cliente_http.get(
        _url('/$id'),
        headers: await _cabeceras(),
      );

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
        return ResultadoPasaje.exitoso(
          SolicitudPasajeModelo.desdeJson(datos),
        );
      }
      final error = ErrorBumand.desdeRespuesta(respuesta);
      return ResultadoPasaje.fallido(
        error.mensaje,
        codigo: error.codigo_error,
        error_bumand: error,
      );
    } catch (e) {
      return ResultadoPasaje.fallido(e.toString());
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  Future<ResultadoPasaje<void>> confirmarDatos(String periodo) async {
    final cliente_http = _obtenerCliente();
    try {
      final respuesta = await cliente_http.post(
        _url('/confirmar-datos'),
        headers: await _cabeceras(),
        body: jsonEncode({'periodo': periodo}),
      );

      if (respuesta.statusCode == 200 ||
          respuesta.statusCode == 201 ||
          respuesta.statusCode == 403) {
        return ResultadoPasaje.exitoso(null);
      } else {
        final error = ErrorBumand.desdeRespuesta(respuesta);
        return ResultadoPasaje.fallido(
          error.mensaje,
          codigo: error.codigo_error,
          error_bumand: error,
        );
      }
    } catch (_) {
      return ResultadoPasaje.exitoso(null);
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  Future<ResultadoPasaje<void>> declararRecorrido({
    required String fecha,
    required String tramo,
    required String origen,
    required String destino,
    required double tarifa,
    required String apoyo_realizado,
    String? calles_declaradas,
    String? medio_transporte,
    String? detalle_tramos_json,
    double? lat_origen,
    double? lng_origen,
    double? lat_destino,
    double? lng_destino,
  }) =>
      agregarRecorrido(
        fecha: fecha,
        tramo: tramo,
        origen: origen,
        destino: destino,
        tarifa: tarifa,
        apoyo_realizado: apoyo_realizado,
        calles_declaradas: calles_declaradas,
        medio_transporte: medio_transporte,
        detalle_tramos_json: detalle_tramos_json,
        lat_origen: lat_origen,
        lng_origen: lng_origen,
        lat_destino: lat_destino,
        lng_destino: lng_destino,
      );

  Future<ResultadoPasaje<void>> agregarRecorrido({
    required String fecha,
    required String tramo,
    required String origen,
    required String destino,
    required double tarifa,
    required String apoyo_realizado,
    String? calles_declaradas,
    String? medio_transporte,
    String? detalle_tramos_json,
    double? lat_origen,
    double? lng_origen,
    double? lat_destino,
    double? lng_destino,
  }) async {
    final cliente_http = _obtenerCliente();
    final apoyo_seguro = apoyo_realizado.length > 250
        ? apoyo_realizado.substring(0, 250)
        : apoyo_realizado;
    final cuerpo = <String, dynamic>{
      'fecha': fecha,
      'tramo': tramo,
      'origen': origen,
      'destino': destino,
      'tarifa': tarifa,
      'apoyoRealizado': apoyo_seguro,
      'apoyo_realizado': apoyo_seguro,
    };
    if (calles_declaradas != null) {
      cuerpo['calles_declaradas'] = calles_declaradas;
      cuerpo['callesDeclaradas'] = calles_declaradas;
    }
    if (medio_transporte != null) {
      cuerpo['medio_transporte'] = medio_transporte;
      cuerpo['medioTransporte'] = medio_transporte;
    }
    if (detalle_tramos_json != null) {
      cuerpo['detalle_tramos_json'] = detalle_tramos_json;
      cuerpo['detalleTramosJson'] = detalle_tramos_json;
    }
    if (lat_origen != null) {
      cuerpo['latOrigen'] = lat_origen;
      cuerpo['lat_origen'] = lat_origen;
    }
    if (lng_origen != null) {
      cuerpo['lngOrigen'] = lng_origen;
      cuerpo['lng_origen'] = lng_origen;
    }
    if (lat_destino != null) {
      cuerpo['latDestino'] = lat_destino;
      cuerpo['lat_destino'] = lat_destino;
    }
    if (lng_destino != null) {
      cuerpo['lngDestino'] = lng_destino;
      cuerpo['lng_destino'] = lng_destino;
    }

    try {
      var respuesta = await cliente_http.post(
        _url('/recorridos'),
        headers: await _cabeceras(),
        body: jsonEncode(cuerpo),
      );

      if (respuesta.statusCode == 201 || respuesta.statusCode == 200) {
        return ResultadoPasaje.exitoso(null);
      }

      Map<String, dynamic>? datos;
      try {
        final decodificado = jsonDecode(respuesta.body);
        if (decodificado is Map<String, dynamic>) {
          datos = decodificado;
        }
      } catch (_) {}
      final codigo_backend = datos?['codigo']?.toString();

      if (codigo_backend == 'DATOS_NO_CONFIRMADOS' ||
          (respuesta.body.contains('confirmar') && datos?['periodo'] != null)) {
        final periodo_req = datos?['periodo']?.toString() ??
            fecha.substring(0, 7);
        await confirmarDatos(periodo_req);
        respuesta = await cliente_http.post(
          _url('/recorridos'),
          headers: await _cabeceras(),
          body: jsonEncode(cuerpo),
        );
        if (respuesta.statusCode == 201 || respuesta.statusCode == 200) {
          return ResultadoPasaje.exitoso(null);
        }
      }

      final error = ErrorBumand.desdeRespuesta(respuesta);
      return ResultadoPasaje.fallido(
        error.mensaje,
        codigo: error.codigo_error,
        periodo: datos?['periodo'] as String?,
        error_bumand: error,
      );
    } catch (_) {
      await _guardarRecorridoLocal(cuerpo);
      if (cola_offline != null) {
        await cola_offline!.encolar(
          ruta: '${ApiConstantes.PUNTO_PASAJES}/recorridos',
          metodo: 'POST',
          cuerpo: cuerpo,
          tipo: 'pasajes_recorrido',
        );
      }
      return ResultadoPasaje.exitoso(null);
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  Future<ResultadoPasaje<void>> eliminarRecorrido(int recorrido_id) async {
    final cliente_http = _obtenerCliente();
    try {
      final respuesta = await cliente_http.delete(
        _url('/recorridos/$recorrido_id'),
        headers: await _cabeceras(),
      );

      if (respuesta.statusCode == 200) {
        return ResultadoPasaje.exitoso(null);
      } else {
        final error = ErrorBumand.desdeRespuesta(respuesta);
        return ResultadoPasaje.fallido(
          error.mensaje,
          codigo: error.codigo_error,
          error_bumand: error,
        );
      }
    } catch (_) {
      final error = ErrorBumand.conexionOffline(
        ruta: '/pasajes/recorridos/$recorrido_id',
        metodo: 'DELETE',
      );
      return ResultadoPasaje.fallido(
        error.mensaje,
        codigo: error.codigo_error,
        error_bumand: error,
      );
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  Future<ResultadoPasaje<void>> enviar(int solicitud_id) async {
    final cliente_http = _obtenerCliente();
    try {
      final respuesta = await cliente_http.post(
        _url('/$solicitud_id/enviar'),
        headers: await _cabeceras(),
      );

      if (respuesta.statusCode == 200) {
        return ResultadoPasaje.exitoso(null);
      } else {
        final error = ErrorBumand.desdeRespuesta(respuesta);
        return ResultadoPasaje.fallido(
          error.mensaje,
          codigo: error.codigo_error,
          error_bumand: error,
        );
      }
    } catch (_) {
      final error = ErrorBumand.conexionOffline(
        ruta: '/pasajes/$solicitud_id/enviar',
        metodo: 'POST',
      );
      return ResultadoPasaje.fallido(
        error.mensaje,
        codigo: error.codigo_error,
        error_bumand: error,
      );
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  Future<ResultadoPasaje<List<Map<String, dynamic>>>> obtenerTarifas({String? fecha}) async {
    final cliente_http = _obtenerCliente();
    final query = fecha != null ? '?fecha=$fecha' : '';
    try {
      final respuesta = await cliente_http.get(
        _url('/tarifas$query'),
        headers: await _cabeceras(),
      );

      if (respuesta.statusCode == 200) {
        final cuerpo = jsonDecode(respuesta.body);
        final List<dynamic> datos = cuerpo is List ? cuerpo : (cuerpo['datos'] ?? cuerpo['tarifas'] ?? []);
        final nombres_vistos = <String, int>{};
        final tarifas = datos
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((m) => m['activo'] != false)
            .map((m) {
          final costo = double.tryParse((m['costo_bs'] ?? m['monto'] ?? '0').toString()) ?? 0.0;
          final medio = (m['medio_transporte'] ?? m['nombre'] ?? 'Transporte').toString().trim();
          final descripcion = (m['descripcion'] ?? '').toString().trim();
          var nombre_unico = medio;
          final conteo = (nombres_vistos[medio.toLowerCase()] ?? 0) + 1;
          nombres_vistos[medio.toLowerCase()] = conteo;
          if (conteo > 1) {
            nombre_unico = descripcion.isNotEmpty
                ? '$medio ($descripcion)'
                : '$medio #${m['id'] ?? conteo}';
          }
          return <String, dynamic>{
            'id': m['id'],
            'medio_transporte': medio,
            'descripcion': descripcion,
            'costo_bs': costo,
            'activo': m['activo'] ?? true,
            'nombre': nombre_unico,
            'monto': costo,
          };
        }).toList();
        return ResultadoPasaje.exitoso(tarifas);
      }
      return ResultadoPasaje.fallido('Error al obtener tarifas (${respuesta.statusCode})');
    } catch (e) {
      return ResultadoPasaje.fallido('Error de conexión al obtener tarifas: $e');
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  Future<ResultadoPasaje<Map<String, dynamic>>> obtenerHistorialConsolidadoParadas({
    String? fecha_inicio,
    String? fecha_fin,
    String? tramo,
  }) async {
    final cliente_http = _obtenerCliente();
    final params = <String>[];
    if (fecha_inicio != null) params.add('fecha_inicio=$fecha_inicio');
    if (fecha_fin != null) params.add('fecha_fin=$fecha_fin');
    if (tramo != null && tramo != 'todos') params.add('tramo=$tramo');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';

    try {
      final respuesta = await cliente_http.get(
        _url('/historial-paradas$query'),
        headers: await _cabeceras(),
      );

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
        return ResultadoPasaje.exitoso(datos);
      }
    } catch (_) {}

    return ResultadoPasaje.exitoso({
      'total_recorridos': 0,
      'total_gastado_bs': 0.0,
      'total_devolucion_bs': 0.0,
      'paradas_mas_frecuentes': [],
      'recorridos': [],
    });
  }
}
