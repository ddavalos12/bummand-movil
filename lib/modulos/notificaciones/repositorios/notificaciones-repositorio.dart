import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../nucleo/constantes/api-constantes.dart';
import '../../../nucleo/utilidades/resultado.dart';
import '../../autenticacion/repositorios/autenticacion-repositorio.dart';
import '../modelos/notificacion-modelo.dart';

class NotificacionesRepositorio {
  final AutenticacionRepositorio _autenticacion_repositorio;

  NotificacionesRepositorio({AutenticacionRepositorio? autenticacion_repositorio})
      : _autenticacion_repositorio =
            autenticacion_repositorio ?? AutenticacionRepositorio();

  Future<Map<String, String>> _cabeceras() async {
    final token = await _autenticacion_repositorio.obtenerToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Resultado<List<NotificacionModelo>>> obtenerMisNotificaciones() async {
    try {
      final respuesta = await http.get(
        Uri.parse(
          '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_NOTIFICACIONES}',
        ),
        headers: await _cabeceras(),
      );

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body) as List<dynamic>;
        final lista = datos
            .map((e) => NotificacionModelo.desdeJson(e as Map<String, dynamic>))
            .toList();
        return Resultado.exitoso(lista);
      }
      return Resultado.fallido('Error al obtener notificaciones');
    } catch (e) {
      return Resultado.fallido('Error de conexión: $e');
    }
  }

  Future<Resultado<int>> contarNoLeidas() async {
    try {
      final respuesta = await http.get(
        Uri.parse(
          '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_NOTIFICACIONES_CONTEO}',
        ),
        headers: await _cabeceras(),
      );

      if (respuesta.statusCode == 200) {
        final cuerpo = jsonDecode(respuesta.body);
        if (cuerpo is int) {
          return Resultado.exitoso(cuerpo);
        } else if (cuerpo is Map<String, dynamic> && cuerpo['conteo'] != null) {
          return Resultado.exitoso(cuerpo['conteo'] as int);
        }
        return Resultado.exitoso(int.tryParse(cuerpo.toString()) ?? 0);
      }
      return Resultado.fallido('Error al contar no leídas');
    } catch (e) {
      return Resultado.fallido('Error de conexión: $e');
    }
  }

  Future<Resultado<void>> marcarLeida(int id) async {
    try {
      final respuesta = await http.patch(
        Uri.parse('${ApiConstantes.RUTA_BASE}/notificaciones/$id/leer'),
        headers: await _cabeceras(),
      );

      if (respuesta.statusCode == 200) {
        return Resultado.exitoso(null);
      }
      return Resultado.fallido('Error al marcar notificación como leída');
    } catch (e) {
      return Resultado.fallido('Error de conexión: $e');
    }
  }
}
