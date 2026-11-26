import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../nucleo/constantes/api-constantes.dart';
import '../../../nucleo/utilidades/resultado.dart';
import '../modelos/recorrido-gps-prueba-modelo.dart';

class ExcepcionGpsPrueba implements Exception {
  final String mensaje;

  const ExcepcionGpsPrueba(this.mensaje);

  @override
  String toString() => mensaje;
}

class RecorridoGpsPruebaRepositorio {
  static const String CLAVE_SESION_LOCAL =
      'bumand_recorrido_gps_prueba_sesion_v1';

  final http.Client? cliente_http;

  RecorridoGpsPruebaRepositorio({this.cliente_http});

  http.Client _obtenerCliente() => cliente_http ?? http.Client();

  Future<void> guardarSesionLocal(SesionRecorridoGpsPrueba sesion) async {
    final preferencias = await SharedPreferences.getInstance();
    final contenido_json = jsonEncode(sesion.aMapa());
    await preferencias.setString(CLAVE_SESION_LOCAL, contenido_json);
  }

  Future<SesionRecorridoGpsPrueba?> cargarSesionLocal() async {
    final preferencias = await SharedPreferences.getInstance();
    final contenido_json = preferencias.getString(CLAVE_SESION_LOCAL);
    if (contenido_json == null || contenido_json.trim().isEmpty) {
      return null;
    }

    try {
      final mapa = jsonDecode(contenido_json);
      if (mapa is Map<String, dynamic>) {
        return SesionRecorridoGpsPrueba.desdeMapa(mapa);
      }
      return null;
    } catch (_) {
      await preferencias.remove(CLAVE_SESION_LOCAL);
      return null;
    }
  }

  Future<void> eliminarSesionLocal() async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.remove(CLAVE_SESION_LOCAL);
  }

  Future<Position> capturarPosicionGps({int timeout_segundos = 20}) async {
    final servicio_activo = await Geolocator.isLocationServiceEnabled();
    if (!servicio_activo) {
      throw const ExcepcionGpsPrueba(
        'El GPS del dispositivo está desactivado. Actívalo para iniciar el registro.',
      );
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        throw const ExcepcionGpsPrueba(
          'Permiso de ubicación denegado. Autoriza el acceso GPS para continuar.',
        );
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      throw const ExcepcionGpsPrueba(
        'Permiso de ubicación bloqueado permanentemente. Habilítalo en ajustes del dispositivo.',
      );
    }

    try {
      final duracion_limite = Duration(seconds: timeout_segundos);
      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: duracion_limite,
        ),
      ).timeout(duracion_limite);
    } on TimeoutException {
      throw const ExcepcionGpsPrueba(
        'Tiempo de espera agotado al obtener señal satelital GPS.',
      );
    } catch (error) {
      if (error is ExcepcionGpsPrueba) rethrow;
      throw const ExcepcionGpsPrueba(
        'No se pudo obtener la posición GPS actual. Verifica tu señal.',
      );
    }
  }

  Future<String> detectarModoCaptura() async {
    if (kIsWeb) return 'online';

    try {
      final host_api = Uri.tryParse(ApiConstantes.RUTA_BASE)?.host ?? '';
      final host_consulta = host_api.isNotEmpty ? host_api : 'google.com';
      final resultado = await InternetAddress.lookup(host_consulta)
          .timeout(const Duration(seconds: 2));
      if (resultado.isNotEmpty && resultado.first.rawAddress.isNotEmpty) {
        return 'online';
      }
      return 'offline';
    } catch (_) {
      return 'offline';
    }
  }

  String obtenerInfoDispositivo() {
    if (kIsWeb) return 'Web';
    final info = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}'
        .trim();
    return info.length > 120 ? info.substring(0, 120) : info;
  }

  Future<Resultado<Map<String, dynamic>>> subirRecorridoPrueba(
    SesionRecorridoGpsPrueba sesion,
  ) async {
    final cliente = _obtenerCliente();
    final url = Uri.parse(
      '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_RECORRIDOS_GPS_PRUEBA}',
    );

    try {
      final respuesta = await cliente
          .post(
            url,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(sesion.aPayloadApi()),
          )
          .timeout(const Duration(seconds: 25));

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        Map<String, dynamic> cuerpo = <String, dynamic>{};
        if (respuesta.body.trim().isNotEmpty) {
          final decodificado = jsonDecode(respuesta.body);
          if (decodificado is Map<String, dynamic>) {
            cuerpo = decodificado;
          }
        }
        return Resultado.exitoso(cuerpo);
      }

      String mensaje_servidor =
          'El servidor rechazó la carga (código ${respuesta.statusCode}).';
      if (respuesta.body.trim().isNotEmpty) {
        try {
          final decodificado = jsonDecode(respuesta.body);
          if (decodificado is Map<String, dynamic>) {
            final msg = decodificado['mensaje'] ?? decodificado['message'];
            if (msg is String && msg.trim().isNotEmpty) {
              mensaje_servidor = msg.trim();
            } else if (msg is List && msg.isNotEmpty) {
              mensaje_servidor = msg.join(', ');
            }
          }
        } catch (_) {}
      }
      return Resultado.fallido(mensaje_servidor);
    } on TimeoutException {
      return Resultado.fallido(
        'Tiempo agotado al conectar con el servidor. Tus datos siguen guardados en el dispositivo; intenta nuevamente.',
      );
    } on SocketException {
      return Resultado.fallido(
        'Sin conexión a internet. Tus datos siguen guardados localmente; presiona Reintentar cuando tengas señal.',
      );
    } catch (_) {
      return Resultado.fallido(
        'No se pudo subir el recorrido. Tus datos permanecen seguros localmente para reintentar.',
      );
    } finally {
      if (cliente_http == null) {
        cliente.close();
      }
    }
  }
}
