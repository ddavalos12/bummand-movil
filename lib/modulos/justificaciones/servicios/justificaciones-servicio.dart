import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../nucleo/constantes/api-constantes.dart';
import '../../../nucleo/servicios/cola-offline-servicio.dart';
import '../../../nucleo/utilidades/resultado.dart';

class JustificacionesServicio {
  final http.Client? cliente;
  final ColaOfflineServicio? cola_offline;

  JustificacionesServicio({
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

  Future<Resultado<Map<String, dynamic>>> enviarJustificacion({
    required String tipo_incidencia,
    int? referencia_id,
    required String fecha_incidencia,
    required String motivo,
    required String descripcion,
  }) async {
    final cliente_http = _obtenerCliente();
    final Map<String, dynamic> cuerpo = {
      'tipo_incidencia': tipo_incidencia,
      'fecha_incidencia': fecha_incidencia,
      'motivo': motivo,
      'descripcion': descripcion,
    };
    if (referencia_id != null) {
      cuerpo['referencia_id'] = referencia_id;
    }

    try {
      final cabeceras = await _cabeceras();
      final urls = [
        '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_JUSTIFICACIONES}',
        '${ApiConstantes.RUTA_BASE}/justificaciones',
      ];

      http.Response? respuesta;
      for (final url in urls) {
        try {
          final res = await cliente_http.post(
            Uri.parse(url),
            headers: cabeceras,
            body: jsonEncode(cuerpo),
          );
          if (res.statusCode == 200 || res.statusCode == 201) {
            respuesta = res;
            break;
          }
        } catch (_) {}
      }

      if (respuesta != null &&
          (respuesta.statusCode == 200 || respuesta.statusCode == 201)) {
        final dynamic datos = jsonDecode(respuesta.body);
        return Resultado.exitoso(
          datos is Map<String, dynamic>
              ? datos
              : {'mensaje': 'Justificación registrada'},
        );
      }

      if (cola_offline != null) {
        await cola_offline!.encolar(
          ruta: ApiConstantes.PUNTO_JUSTIFICACIONES,
          metodo: 'POST',
          cuerpo: cuerpo,
          tipo: 'justificacion',
        );
        return Resultado.exitoso({
          'mensaje': 'Justificación guardada en cola offline',
          'offline': true,
        });
      }

      return Resultado.fallido('No se pudo enviar la justificación');
    } catch (e) {
      if (cola_offline != null) {
        await cola_offline!.encolar(
          ruta: ApiConstantes.PUNTO_JUSTIFICACIONES,
          metodo: 'POST',
          cuerpo: cuerpo,
          tipo: 'justificacion',
        );
        return Resultado.exitoso({
          'mensaje': 'Justificación guardada en cola offline',
          'offline': true,
        });
      }
      return Resultado.fallido('Error al registrar justificación: $e');
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }
}

final justificaciones_servicio_proveedor =
    Provider<JustificacionesServicio>((ref) {
  final cola = ref.watch(cola_offline_servicio_proveedor);
  return JustificacionesServicio(cola_offline: cola);
});
