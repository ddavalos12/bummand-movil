import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../nucleo/constantes/api-constantes.dart';
import '../../../nucleo/utilidades/resultado.dart';

class AsistenciaRepositorio {
  Future<String?> _obtenerToken() async {
    final preferencias = await SharedPreferences.getInstance();
    return preferencias.getString('token');
  }

  Future<Map<String, String>> _cabeceras() async {
    final token = await _obtenerToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  Future<Resultado<Map<String, dynamic>>> obtenerPerfil() async {
    try {
      final cabeceras = await _cabeceras();
      final respuesta = await http.get(
        Uri.parse('${ApiConstantes.RUTA_BASE}/api/perfil'),
        headers: cabeceras,
      );

      if (respuesta.statusCode != 200) {
        return Resultado.fallido("No se pudo obtener el perfil");
      }
      return Resultado.exitoso(
        jsonDecode(respuesta.body) as Map<String, dynamic>,
      );
    } catch (e) {
      return Resultado.fallido("Error de conexión: $e");
    }
  }

  Future<Resultado<Map<String, dynamic>>> actualizarPerfil(
    Map<String, dynamic> datos,
  ) async {
    try {
      final cabeceras = await _cabeceras();
      final respuesta = await http.put(
        Uri.parse('${ApiConstantes.RUTA_BASE}/api/perfil'),
        headers: cabeceras,
        body: jsonEncode(datos),
      );

      if (respuesta.statusCode != 200) {
        return Resultado.fallido("No se pudo actualizar el perfil");
      }
      return Resultado.exitoso(
        jsonDecode(respuesta.body) as Map<String, dynamic>,
      );
    } catch (e) {
      return Resultado.fallido("Error de conexión: $e");
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
    try {
      final cabeceras = await _cabeceras();
      final respuesta = await http.post(
        Uri.parse(
          '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_ASISTENCIA_INGRESO}',
        ),
        headers: cabeceras,
        body: jsonEncode(_cuerpoUbicacion(posicion, tipo)),
      );

      final datos = jsonDecode(respuesta.body);
      if (respuesta.statusCode != 201 && respuesta.statusCode != 200) {
        return Resultado.fallido(datos["error"] ?? datos["message"] ?? "Error");
      }
      return Resultado.exitoso(datos["mensaje"] ?? "Ingreso registrado");
    } catch (e) {
      return Resultado.fallido("Error: $e");
    }
  }

  Future<Resultado<String>> registrarSalida(
    String tipo,
    Position posicion,
  ) async {
    try {
      final cabeceras = await _cabeceras();
      final respuesta = await http.post(
        Uri.parse(
          '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_ASISTENCIA_SALIDA}',
        ),
        headers: cabeceras,
        body: jsonEncode(_cuerpoUbicacion(posicion, tipo)),
      );

      final datos = jsonDecode(respuesta.body);
      if (respuesta.statusCode != 200) {
        return Resultado.fallido(datos["error"] ?? datos["message"] ?? "Error");
      }
      return Resultado.exitoso(datos["mensaje"] ?? "Salida registrada");
    } catch (e) {
      return Resultado.fallido("Error: $e");
    }
  }

  Future<Resultado<List<Map<String, dynamic>>>> obtenerHistorial() async {
    try {
      final cabeceras = await _cabeceras();
      final respuesta = await http.get(
        Uri.parse(
          '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_ASISTENCIA_HISTORIAL}',
        ),
        headers: cabeceras,
      );

      if (respuesta.statusCode != 200) {
        return Resultado.fallido("Error al obtener historial");
      }
      final lista = (jsonDecode(respuesta.body) as List)
          .cast<Map<String, dynamic>>();
      return Resultado.exitoso(lista);
    } catch (e) {
      return Resultado.fallido("Error: $e");
    }
  }

  Future<Resultado<String>> confirmarDatosPasajes(String periodo) async {
    try {
      final cabeceras = await _cabeceras();
      final respuesta = await http.post(
        Uri.parse(
          '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_PASAJES_CONFIRMAR}',
        ),
        headers: cabeceras,
        body: jsonEncode({"periodo": periodo}),
      );

      final datos = jsonDecode(respuesta.body);
      if (respuesta.statusCode != 200) {
        return Resultado.fallido(datos["error"] ?? datos["message"] ?? "Error");
      }
      return Resultado.exitoso(datos["mensaje"] ?? "Datos confirmados");
    } catch (e) {
      return Resultado.fallido("Error: $e");
    }
  }
}
