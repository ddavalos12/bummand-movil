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

  Map<String, dynamic> _cuerpoUbicacion(Position posicion, String tipo) => {
    "latitud": posicion.latitude,
    "longitud": posicion.longitude,
    "precision": posicion.accuracy,
    "simulada": posicion.isMocked,
    "tipo": tipo,
  };

  Future<Resultado<String>> registrarIngreso(
    String tipo,
    Position posicion,
  ) async {
    final cliente_http = _obtenerCliente();
    final cuerpo = _cuerpoUbicacion(posicion, tipo);
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
    Position posicion,
  ) async {
    final cliente_http = _obtenerCliente();
    final cuerpo = _cuerpoUbicacion(posicion, tipo);
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
}
