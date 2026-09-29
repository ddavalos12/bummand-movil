import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../nucleo/constantes/api-constantes.dart';
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
    this.codigo,
    this.periodo,
  });

  factory ResultadoPasaje.exitoso(T datos) =>
      ResultadoPasaje(exito: true, datos: datos);
  factory ResultadoPasaje.fallido(
    String error, {
    String? codigo,
    String? periodo,
  }) => ResultadoPasaje(
    exito: false,
    error: error,
    codigo: codigo,
    periodo: periodo,
  );
}

class PasajesRepositorio {
  final AutenticacionRepositorio _autenticacion_repositorio = AutenticacionRepositorio();

  Future<Map<String, String>> _cabeceras() async {
    final token = await _autenticacion_repositorio.obtenerToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Uri _url(String ruta) =>
      Uri.parse('${ApiConstantes.RUTA_BASE}/api/pasajes$ruta');

  Future<ResultadoPasaje<List<SolicitudPasajeModelo>>> misSolicitudes() async {
    try {
      final respuesta = await http.get(
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
        return ResultadoPasaje.fallido('Error al obtener solicitudes');
      }
    } catch (e) {
      return ResultadoPasaje.fallido('No se pudo conectar: $e');
    }
  }

  Future<ResultadoPasaje<void>> confirmarDatos(String periodo) async {
    try {
      final respuesta = await http.post(
        _url('/confirmar-datos'),
        headers: await _cabeceras(),
        body: jsonEncode({'periodo': periodo}),
      );

      if (respuesta.statusCode == 200) {
        return ResultadoPasaje.exitoso(null);
      } else {
        return ResultadoPasaje.fallido('No se pudieron confirmar los datos');
      }
    } catch (e) {
      return ResultadoPasaje.fallido('Error: $e');
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
    try {
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

      final respuesta = await http.post(
        _url('/recorridos'),
        headers: await _cabeceras(),
        body: jsonEncode(cuerpo),
      );

      final datos = jsonDecode(respuesta.body) as Map<String, dynamic>?;

      if (respuesta.statusCode == 201 || respuesta.statusCode == 200) {
        return ResultadoPasaje.exitoso(null);
      } else {
        return ResultadoPasaje.fallido(
          datos?['error'] ?? 'No se pudo registrar el recorrido',
          codigo: datos?['codigo'] as String?,
          periodo: datos?['periodo'] as String?,
        );
      }
    } catch (e) {
      return ResultadoPasaje.fallido('Error: $e');
    }
  }

  Future<ResultadoPasaje<void>> eliminarRecorrido(int recorrido_id) async {
    try {
      final respuesta = await http.delete(
        _url('/recorridos/$recorrido_id'),
        headers: await _cabeceras(),
      );

      if (respuesta.statusCode == 200) {
        return ResultadoPasaje.exitoso(null);
      } else {
        return ResultadoPasaje.fallido('No se pudo eliminar el recorrido');
      }
    } catch (e) {
      return ResultadoPasaje.fallido('Error: $e');
    }
  }

  Future<ResultadoPasaje<void>> enviar(int solicitud_id) async {
    try {
      final respuesta = await http.post(
        _url('/$solicitud_id/enviar'),
        headers: await _cabeceras(),
      );

      if (respuesta.statusCode == 200) {
        return ResultadoPasaje.exitoso(null);
      } else {
        return ResultadoPasaje.fallido('No se pudo enviar la solicitud');
      }
    } catch (e) {
      return ResultadoPasaje.fallido('Error: $e');
    }
  }
}
