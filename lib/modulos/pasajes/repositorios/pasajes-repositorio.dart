import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../nucleo/constantes/api-constantes.dart';
import '../../../nucleo/errores/codigos-error.dart';
import '../../../nucleo/errores/error-bumand.dart';
import '../../../nucleo/servicios/cola-offline-servicio.dart';
import '../../../nucleo/utilidades/resultado.dart';
import '../../autenticacion/repositorios/autenticacion-repositorio.dart';
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
      Uri.parse('${ApiConstantes.RUTA_BASE}/pasajes$ruta');

  Future<ResultadoPasaje<List<SolicitudPasajeModelo>>> misSolicitudes() async {
    final cliente_http = _obtenerCliente();
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
        return ResultadoPasaje.exitoso(solicitudes);
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

  Future<ResultadoPasaje<void>> confirmarDatos(String periodo) async {
    final cliente_http = _obtenerCliente();
    try {
      final respuesta = await cliente_http.post(
        _url('/confirmar-datos'),
        headers: await _cabeceras(),
        body: jsonEncode({'periodo': periodo}),
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
        ruta: '/pasajes/confirmar-datos',
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

  Future<ResultadoPasaje<void>> agregarRecorrido({
    required String fecha,
    required String tramo,
    required String origen,
    required String destino,
    required double tarifa,
    required String apoyo_realizado,
    double? lat_origen,
    double? lng_origen,
    double? lat_destino,
    double? lng_destino,
  }) async {
    final cliente_http = _obtenerCliente();
    final cuerpo = {
      'fecha': fecha,
      'tramo': tramo,
      'origen': origen,
      'destino': destino,
      'tarifa': tarifa,
      'apoyoRealizado': apoyo_realizado,
    };
    if (lat_origen != null) cuerpo['latOrigen'] = lat_origen;
    if (lng_origen != null) cuerpo['lngOrigen'] = lng_origen;
    if (lat_destino != null) cuerpo['latDestino'] = lat_destino;
    if (lng_destino != null) cuerpo['lngDestino'] = lng_destino;

    try {
      final respuesta = await cliente_http.post(
        _url('/recorridos'),
        headers: await _cabeceras(),
        body: jsonEncode(cuerpo),
      );

      final datos = jsonDecode(respuesta.body) as Map<String, dynamic>?;

      if (respuesta.statusCode == 201 || respuesta.statusCode == 200) {
        return ResultadoPasaje.exitoso(null);
      } else {
        final error = ErrorBumand.desdeRespuesta(respuesta);
        return ResultadoPasaje.fallido(
          error.mensaje,
          codigo: error.codigo_error,
          periodo: datos?['periodo'] as String?,
          error_bumand: error,
        );
      }
    } catch (_) {
      if (cola_offline != null) {
        await cola_offline!.encolar(
          ruta: '/pasajes/recorridos',
          metodo: 'POST',
          cuerpo: cuerpo,
          tipo: 'pasajes_recorrido',
        );
        final error_encolado = ErrorBumand.encoladoOffline(
          ruta: '/pasajes/recorridos',
          metodo: 'POST',
        );
        return ResultadoPasaje.fallido(
          error_encolado.mensaje,
          codigo: CodigosError.ERR_5003,
          error_bumand: error_encolado,
        );
      }
      final error = ErrorBumand.conexionOffline(
        ruta: '/pasajes/recorridos',
        metodo: 'POST',
      );
      return ResultadoPasaje.fallido(
        error.mensaje,
        codigo: CodigosError.ERR_5001,
        error_bumand: error,
      );
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
        final datos = jsonDecode(respuesta.body) as List<dynamic>;
        final tarifas = datos.map((e) {
          final m = e as Map<String, dynamic>;
          return {
            'nombre': m['medio_transporte'] ?? 'Transporte',
            'monto': (m['costo_bs'] as num?)?.toDouble() ?? 2.60,
          };
        }).toList();
        return ResultadoPasaje.exitoso(tarifas);
      }
    } catch (_) {}
    return ResultadoPasaje.exitoso([
      {'nombre': 'Minibús Directo', 'monto': 2.60},
      {'nombre': 'Minibús El Alto', 'monto': 3.50},
      {'nombre': 'Micro / Colectivo', 'monto': 2.00},
      {'nombre': 'Mi Teleférico', 'monto': 3.00},
      {'nombre': 'Trufi', 'monto': 4.00},
    ]);
  }
}
