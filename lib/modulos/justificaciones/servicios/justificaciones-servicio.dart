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

  Future<Resultado<Map<String, dynamic>>> subirArchivoJustificativo(
    List<int> bytes,
    String nombre_archivo,
  ) =>
      subirComprobante(bytes: bytes, nombre_archivo: nombre_archivo);

  Future<Resultado<Map<String, dynamic>>> subirComprobante({
    required List<int> bytes,
    required String nombre_archivo,
  }) async {
    final token = await _obtenerToken();
    final urls = [
      '${ApiConstantes.RUTA_BASE}/api/justificaciones/subir-comprobante',
      '${ApiConstantes.RUTA_BASE}/justificaciones/subir-comprobante',
    ];

    for (final url in urls) {
      try {
        final peticion = http.MultipartRequest('POST', Uri.parse(url));
        if (token != null) {
          peticion.headers['Authorization'] = 'Bearer $token';
        }
        peticion.files.add(
          http.MultipartFile.fromBytes(
            'archivo',
            bytes,
            filename: nombre_archivo,
          ),
        );

        final respuesta_enviada = await peticion.send();
        final cuerpo = await respuesta_enviada.stream.bytesToString();

        if (respuesta_enviada.statusCode == 200 ||
            respuesta_enviada.statusCode == 201) {
          final dynamic datos = jsonDecode(cuerpo);
          if (datos is Map<String, dynamic>) {
            return Resultado.exitoso(datos);
          }
          return Resultado.exitoso({
            'archivo_prueba_url': datos.toString(),
            'nombre_archivo_prueba': nombre_archivo,
          });
        }
      } catch (_) {}
    }

    return Resultado.fallido('No se pudo subir el archivo probatorio al servidor');
  }

  Future<Resultado<Map<String, dynamic>>> enviarJustificacion({
    required String tipo_incidencia,
    int? referencia_id,
    required String fecha_incidencia,
    required String motivo,
    required String descripcion,
    String? archivo_prueba_url,
    String? nombre_archivo_prueba,
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
    if (archivo_prueba_url != null) {
      cuerpo['archivo_prueba_url'] = archivo_prueba_url;
    }
    if (nombre_archivo_prueba != null) {
      cuerpo['nombre_archivo_prueba'] = nombre_archivo_prueba;
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

  Future<Resultado<List<Map<String, dynamic>>>> obtenerMisJustificaciones() async {
    final cliente_http = _obtenerCliente();
    try {
      final cabeceras = await _cabeceras();
      final urls = [
        '${ApiConstantes.RUTA_BASE}/api/justificaciones/mis-justificaciones',
        '${ApiConstantes.RUTA_BASE}/justificaciones/mis-justificaciones',
      ];

      for (final url in urls) {
        try {
          final res = await cliente_http.get(Uri.parse(url), headers: cabeceras);
          if (res.statusCode == 200) {
            final dynamic datos = jsonDecode(res.body);
            if (datos is List) {
              final lista = datos
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
              return Resultado.exitoso(lista);
            }
          }
        } catch (_) {}
      }

      return Resultado.exitoso([]);
    } catch (e) {
      return Resultado.fallido('Error al obtener justificaciones: $e');
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

final mis_justificaciones_proveedor =
    FutureProvider<Resultado<List<Map<String, dynamic>>>>((ref) {
  final servicio = ref.watch(justificaciones_servicio_proveedor);
  return servicio.obtenerMisJustificaciones();
});
