import 'dart:convert';
import 'package:http/http.dart' as http;
import 'codigos-error.dart';

class ErrorBumand implements Exception {
  final String codigo_error;
  final String tipo;
  final String mensaje;
  final List<String> detalles;
  final DateTime? marca_tiempo;
  final String? ruta;
  final String? metodo;
  final int? estado_http;

  const ErrorBumand({
    required this.codigo_error,
    required this.tipo,
    required this.mensaje,
    this.detalles = const [],
    this.marca_tiempo,
    this.ruta,
    this.metodo,
    this.estado_http,
  });

  factory ErrorBumand.desdeJson(
    Map<String, dynamic> json, {
    int? estado_http,
    String? ruta_solicitud,
    String? metodo_solicitud,
  }) {
    final codigo = json['codigo_error']?.toString() ??
        json['codigo']?.toString() ??
        _inferirCodigoDesdeEstado(estado_http);

    final tipo = json['tipo']?.toString() ?? CodigosError.obtenerDominio(codigo);

    String mensaje_extraido = json['mensaje']?.toString() ??
        json['message']?.toString() ??
        json['error']?.toString() ??
        CodigosError.obtenerDescripcion(codigo);

    List<String> detalles_extraidos = [];
    final detalles_crudos = json['detalles'] ?? json['errors'];
    if (detalles_crudos is List) {
      detalles_extraidos = detalles_crudos.map((d) => d.toString()).toList();
    } else if (detalles_crudos is String && detalles_crudos.isNotEmpty) {
      detalles_extraidos = [detalles_crudos];
    }

    DateTime? marca;
    final marca_cruda = json['marca_tiempo'] ?? json['timestamp'];
    if (marca_cruda is String) {
      marca = DateTime.tryParse(marca_cruda);
    }

    return ErrorBumand(
      codigo_error: codigo,
      tipo: tipo,
      mensaje: mensaje_extraido,
      detalles: detalles_extraidos,
      marca_tiempo: marca ?? DateTime.now(),
      ruta: json['ruta']?.toString() ?? ruta_solicitud,
      metodo: json['metodo']?.toString() ?? metodo_solicitud,
      estado_http: estado_http,
    );
  }

  factory ErrorBumand.desdeRespuesta(http.Response respuesta) {
    try {
      final decodificado = jsonDecode(respuesta.body);
      if (decodificado is Map<String, dynamic>) {
        return ErrorBumand.desdeJson(
          decodificado,
          estado_http: respuesta.statusCode,
          ruta_solicitud: respuesta.request?.url.path,
          metodo_solicitud: respuesta.request?.method,
        );
      }
    } catch (_) {}

    final codigo = _inferirCodigoDesdeEstado(respuesta.statusCode);
    return ErrorBumand(
      codigo_error: codigo,
      tipo: CodigosError.obtenerDominio(codigo),
      mensaje: CodigosError.obtenerDescripcion(codigo),
      detalles: [
        if (respuesta.body.isNotEmpty && respuesta.body.length < 200)
          respuesta.body,
      ],
      marca_tiempo: DateTime.now(),
      ruta: respuesta.request?.url.path,
      metodo: respuesta.request?.method,
      estado_http: respuesta.statusCode,
    );
  }

  factory ErrorBumand.conexionOffline({String? ruta, String? metodo}) {
    return ErrorBumand(
      codigo_error: CodigosError.ERR_5001,
      tipo: CodigosError.DOMINIOS[CodigosError.ERR_5001]!,
      mensaje: CodigosError.obtenerDescripcion(CodigosError.ERR_5001),
      detalles: const ['Sin conexión a internet o el servidor no responde'],
      marca_tiempo: DateTime.now(),
      ruta: ruta,
      metodo: metodo,
      estado_http: 0,
    );
  }

  factory ErrorBumand.encoladoOffline({String? ruta, String? metodo}) {
    return ErrorBumand(
      codigo_error: CodigosError.ERR_5003,
      tipo: CodigosError.DOMINIOS[CodigosError.ERR_5003]!,
      mensaje: CodigosError.obtenerDescripcion(CodigosError.ERR_5003),
      detalles: const ['Operación guardada en almacenamiento local para sincronización'],
      marca_tiempo: DateTime.now(),
      ruta: ruta,
      metodo: metodo,
      estado_http: 0,
    );
  }

  static String _inferirCodigoDesdeEstado(int? estado) {
    switch (estado) {
      case 401:
        return CodigosError.ERR_1001;
      case 403:
        return CodigosError.ERR_1003;
      case 404:
        return CodigosError.ERR_9002;
      case 409:
        return CodigosError.ERR_2003;
      case 400:
        return CodigosError.ERR_5002;
      case 500:
      case 502:
      case 503:
        return CodigosError.ERR_9001;
      default:
        return CodigosError.ERR_5001;
    }
  }

  bool get esErrorConexion => codigo_error == CodigosError.ERR_5001;
  bool get fueEncolado => codigo_error == CodigosError.ERR_5003;
  String get sugerencia => CodigosError.obtenerSugerencia(codigo_error);

  Map<String, dynamic> aMapa() {
    return {
      'codigo_error': codigo_error,
      'tipo': tipo,
      'mensaje': mensaje,
      'detalles': detalles,
      'marca_tiempo': marca_tiempo?.toIso8601String(),
      'ruta': ruta,
      'metodo': metodo,
      'estado_http': estado_http,
    };
  }

  @override
  String toString() => 'ErrorBumand($codigo_error): $mensaje';
}
