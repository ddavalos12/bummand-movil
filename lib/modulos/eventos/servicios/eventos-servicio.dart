import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../nucleo/constantes/api-constantes.dart';
import '../../../nucleo/servicios/cola-offline-servicio.dart';
import '../../../nucleo/utilidades/resultado.dart';
import '../modelos/evento.dart';

class EventosServicio {
  final http.Client? cliente;
  final ColaOfflineServicio? cola_offline;

  EventosServicio({
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
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  http.Client _obtenerCliente() => cliente ?? http.Client();

  Future<Resultado<List<Evento>>> obtenerEventos() async {
    final cliente_http = _obtenerCliente();
    try {
      final cabeceras = await _cabeceras();
      // Intentar primero con PUNTO_EVENTOS (/api/eventos), con respaldo a /eventos
      final urls = [
        '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_EVENTOS}',
        '${ApiConstantes.RUTA_BASE}/eventos',
      ];

      http.Response? respuesta;
      for (final url in urls) {
        try {
          final res = await cliente_http.get(Uri.parse(url), headers: cabeceras);
          if (res.statusCode == 200) {
            respuesta = res;
            break;
          }
        } catch (_) {}
      }

      if (respuesta == null || respuesta.statusCode != 200) {
        return Resultado.fallido('No se pudo cargar la agenda de eventos');
      }

      final dynamic cuerpo = jsonDecode(respuesta.body);
      final List<dynamic> lista_cruda = cuerpo is List ? cuerpo : [];
      final eventos = lista_cruda
          .map((item) => Evento.desdeMapa(item as Map<String, dynamic>))
          .toList();

      return Resultado.exitoso(eventos);
    } catch (e) {
      return Resultado.fallido('Error de conexión al obtener eventos: $e');
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  Future<Resultado<Evento>> obtenerEventoPorId(int id) async {
    final cliente_http = _obtenerCliente();
    try {
      final cabeceras = await _cabeceras();
      final urls = [
        '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_EVENTOS}/$id',
        '${ApiConstantes.RUTA_BASE}/eventos/$id',
      ];

      http.Response? respuesta;
      for (final url in urls) {
        try {
          final res = await cliente_http.get(Uri.parse(url), headers: cabeceras);
          if (res.statusCode == 200) {
            respuesta = res;
            break;
          }
        } catch (_) {}
      }

      if (respuesta == null || respuesta.statusCode != 200) {
        return Resultado.fallido('Evento no encontrado');
      }

      final dynamic cuerpo = jsonDecode(respuesta.body);
      final evento = Evento.desdeMapa(cuerpo as Map<String, dynamic>);
      return Resultado.exitoso(evento);
    } catch (e) {
      return Resultado.fallido('Error de conexión: $e');
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  Future<Resultado<AsistenciaEvento>> marcarAsistencia({
    required int evento_id,
    required double latitud,
    required double longitud,
    String? observaciones,
  }) async {
    final cliente_http = _obtenerCliente();
    final cuerpo = {
      'latitud': latitud,
      'longitud': longitud,
      if (observaciones != null && observaciones.isNotEmpty)
        'observaciones': observaciones,
    };

    try {
      final cabeceras = await _cabeceras();
      final ruta_primaria =
          '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_EVENTOS}/$evento_id/asistencia';
      final ruta_alterna =
          '${ApiConstantes.RUTA_BASE}/eventos/$evento_id/asistencia';

      http.Response? respuesta;
      for (final url in [ruta_primaria, ruta_alterna]) {
        try {
          final res = await cliente_http.post(
            Uri.parse(url),
            headers: cabeceras,
            body: jsonEncode(cuerpo),
          );
          if (res.statusCode == 200 ||
              res.statusCode == 201 ||
              res.statusCode == 409) {
            respuesta = res;
            break;
          }
        } catch (_) {}
      }

      if (respuesta != null) {
        final dynamic datos = jsonDecode(respuesta.body);
        if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
          final asistencia =
              AsistenciaEvento.desdeMapa(datos as Map<String, dynamic>);
          return Resultado.exitoso(asistencia);
        } else if (respuesta.statusCode == 409) {
          return Resultado.fallido(
            'Ya registraste tu asistencia para este evento previamente',
          );
        } else {
          final mensaje = datos is Map
              ? (datos['message'] ?? datos['error'] ?? 'Error al registrar')
              : 'Error al registrar';
          return Resultado.fallido(mensaje.toString());
        }
      }

      // Si no hubo respuesta del servidor (modo offline o falla de red)
      if (cola_offline != null) {
        await cola_offline!.encolar(
          ruta: '${ApiConstantes.PUNTO_EVENTOS}/$evento_id/asistencia',
          metodo: 'POST',
          cuerpo: cuerpo,
          tipo: 'asistencia_evento',
        );
        // Creamos una asistencia temporal representativa
        final asistencia_local = AsistenciaEvento(
          id: 0,
          evento_id: evento_id,
          becario_id: 0,
          hora_marcacion: DateTime.now().toIso8601String().substring(11, 19),
          latitud: latitud,
          longitud: longitud,
          distancia_m: 0.0,
          dentro_de_radio: true,
          estado: 'presente',
          observaciones: 'Guardado offline para sincronización posterior',
          created_at: DateTime.now(),
        );
        return Resultado.exitoso(asistencia_local);
      }

      return Resultado.fallido('No se pudo conectar con el servidor');
    } catch (e) {
      if (cola_offline != null) {
        await cola_offline!.encolar(
          ruta: '${ApiConstantes.PUNTO_EVENTOS}/$evento_id/asistencia',
          metodo: 'POST',
          cuerpo: cuerpo,
          tipo: 'asistencia_evento',
        );
        final asistencia_local = AsistenciaEvento(
          id: 0,
          evento_id: evento_id,
          becario_id: 0,
          hora_marcacion: DateTime.now().toIso8601String().substring(11, 19),
          latitud: latitud,
          longitud: longitud,
          distancia_m: 0.0,
          dentro_de_radio: true,
          estado: 'presente',
          observaciones: 'Guardado offline para sincronización posterior',
          created_at: DateTime.now(),
        );
        return Resultado.exitoso(asistencia_local);
      }
      return Resultado.fallido('Error al registrar asistencia: $e');
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }
}

final eventos_servicio_proveedor = Provider<EventosServicio>((ref) {
  final cola = ref.watch(cola_offline_servicio_proveedor);
  return EventosServicio(cola_offline: cola);
});

final eventos_lista_proveedor =
    FutureProvider.autoDispose<Resultado<List<Evento>>>((ref) async {
  final servicio = ref.watch(eventos_servicio_proveedor);
  return servicio.obtenerEventos();
});
