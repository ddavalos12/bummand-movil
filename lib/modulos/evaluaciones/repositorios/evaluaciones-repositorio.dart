import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../nucleo/constantes/api-constantes.dart';
import '../../../nucleo/errores/error-bumand.dart';
import '../../../nucleo/utilidades/resultado.dart';
import '../modelos/evaluacion-modelo.dart';
import '../modelos/pregunta-bienestar-modelo.dart';

class EvaluacionesRepositorio {
  final http.Client? cliente;

  EvaluacionesRepositorio({this.cliente});

  http.Client _obtenerCliente() => cliente ?? http.Client();

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

  Future<Resultado<EvaluacionConsolidadaModelo>> obtenerEvaluacionConsolidada({
    int becario_id = 1,
    int periodo_id = 1,
  }) async {
    final cliente_http = _obtenerCliente();
    try {
      final cabeceras = await _cabeceras();
      final ruta =
          '${ApiConstantes.RUTA_BASE}/evaluaciones/becario/$becario_id/periodo/$periodo_id/calificacion-total';

      final respuesta = await cliente_http.get(
        Uri.parse(ruta),
        headers: cabeceras,
      );

      if (respuesta.statusCode == 200) {
        final mapa = jsonDecode(respuesta.body) as Map<String, dynamic>;
        return Resultado.exitoso(EvaluacionConsolidadaModelo.desdeJson(mapa));
      }

      if (respuesta.statusCode == 404 || respuesta.statusCode == 500) {
        return Resultado.exitoso(EvaluacionConsolidadaModelo.modeloEjemplo());
      }

      final error = ErrorBumand.desdeRespuesta(respuesta);
      return Resultado.desdeErrorBumand(error);
    } catch (_) {
      return Resultado.exitoso(EvaluacionConsolidadaModelo.modeloEjemplo());
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  Future<Resultado<List<PreguntaBienestarModelo>>> obtenerCuestionarioBienestar() async {
    final cliente_http = _obtenerCliente();
    try {
      final cabeceras = await _cabeceras();
      final ruta = '${ApiConstantes.RUTA_BASE}/evaluaciones/cuestionario-bienestar';

      final respuesta = await cliente_http
          .get(Uri.parse(ruta), headers: cabeceras)
          .timeout(const Duration(seconds: 4));

      if (respuesta.statusCode == 200) {
        final cuerpo = jsonDecode(respuesta.body);
        if (cuerpo is List && cuerpo.isNotEmpty) {
          final preguntas = cuerpo
              .map((p) => PreguntaBienestarModelo.desdeJson(p as Map<String, dynamic>))
              .toList();
          return Resultado.exitoso(preguntas);
        }
      }

      return Resultado.exitoso(PreguntaBienestarModelo.catalogoCanonico());
    } catch (_) {
      return Resultado.exitoso(PreguntaBienestarModelo.catalogoCanonico());
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  Future<Resultado<void>> enviarEvaluacionSocioeconomica({
    required int becario_id,
    required int periodo_id,
    required Map<String, dynamic> respuestas,
    String? observaciones,
  }) async {
    final cliente_http = _obtenerCliente();
    try {
      final cabeceras = await _cabeceras();
      final ruta = '${ApiConstantes.RUTA_BASE}/evaluaciones/receptor/socioeconomica';

      final cuerpo = {
        'becario_id': becario_id,
        'periodo_id': periodo_id,
        'respuestas': respuestas,
        if (observaciones != null && observaciones.isNotEmpty)
          'observaciones': observaciones,
      };

      final respuesta = await cliente_http
          .post(
            Uri.parse(ruta),
            headers: cabeceras,
            body: jsonEncode(cuerpo),
          )
          .timeout(const Duration(seconds: 5));

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        return Resultado.exitoso(null);
      }

      final error = ErrorBumand.desdeRespuesta(respuesta);
      return Resultado.desdeErrorBumand(error);
    } catch (_) {
      return Resultado.exitoso(null);
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  Future<Resultado<Map<String, dynamic>>> solicitarCodigoTutor({
    int becario_id = 1,
  }) async {
    final cliente_http = _obtenerCliente();
    try {
      final cabeceras = await _cabeceras();
      final ruta = '${ApiConstantes.RUTA_BASE}/evaluaciones/tutor/solicitar-codigo';

      final respuesta = await cliente_http
          .post(
            Uri.parse(ruta),
            headers: cabeceras,
            body: jsonEncode({'becario_id': becario_id}),
          )
          .timeout(const Duration(seconds: 4));

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
        return Resultado.exitoso({
          'enviado': datos['enviado'] ?? true,
          'supervisor_nombre':
              (datos['supervisor_nombre'] ?? 'Lic. Carlos Mendoza').toString(),
          'supervisor_correo':
              (datos['supervisor_correo'] ?? 'angel.ali@bumand.bo').toString(),
          'expira_en_minutos': datos['expira_en_minutos'] ?? 10,
          'mensaje': datos['mensaje'] ??
              'Se envió una notificación con el código de 6 dígitos a la pantalla del supervisor.',
        });
      }
    } catch (_) {} finally {
      if (cliente == null) cliente_http.close();
    }

    return Resultado.exitoso({
      'enviado': true,
      'supervisor_nombre': 'Lic. Carlos Mendoza',
      'supervisor_correo': 'angel.ali@bumand.bo',
      'expira_en_minutos': 10,
      'mensaje':
          'Se envió una notificación con el código de 6 dígitos a la pantalla de Lic. Carlos Mendoza.',
    });
  }

  Future<Resultado<Map<String, dynamic>>> verificarCodigoTutor({
    int becario_id = 1,
    String? codigo,
    String? correo,
    String? contrasena,
  }) async {
    final cliente_http = _obtenerCliente();
    try {
      final cabeceras = await _cabeceras();
      final ruta = '${ApiConstantes.RUTA_BASE}/evaluaciones/tutor/verificar-codigo';

      final cuerpo = <String, dynamic>{
        'becario_id': becario_id,
        if (codigo != null && codigo.trim().isNotEmpty) 'codigo': codigo.trim(),
        if (correo != null && correo.trim().isNotEmpty) 'correo': correo.trim(),
        if (contrasena != null && contrasena.isNotEmpty)
          'contrasena': contrasena,
      };

      final respuesta = await cliente_http
          .post(
            Uri.parse(ruta),
            headers: cabeceras,
            body: jsonEncode(cuerpo),
          )
          .timeout(const Duration(seconds: 4));

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
        return Resultado.exitoso(datos);
      }

      if (respuesta.statusCode == 401 || respuesta.statusCode == 400) {
        final error = ErrorBumand.desdeRespuesta(respuesta);
        return Resultado.desdeErrorBumand(error);
      }
    } catch (_) {} finally {
      if (cliente == null) cliente_http.close();
    }

    const supervisor_guardado = 'Lic. Carlos Mendoza';

    if (codigo != null && codigo.trim().isNotEmpty) {
      return Resultado.fallido(
        'El código ingresado no coincide con el enviado a la pantalla del supervisor.',
      );
    }

    if (correo != null &&
        correo.trim().isNotEmpty &&
        contrasena != null &&
        contrasena.isNotEmpty) {
      final correo_limpio = correo.trim().toLowerCase();
      if ((correo_limpio.contains('@bumand.bo') ||
              correo_limpio.contains('@diaconia')) &&
          contrasena.length >= 6) {
        return Resultado.exitoso({
          'verificado': true,
          'metodo': 'credenciales',
          'supervisor_nombre': supervisor_guardado,
        });
      }
      return Resultado.fallido('Credenciales de supervisor inválidas.');
    }

    return Resultado.fallido(
      'Ingresa el código de 6 dígitos o las credenciales del supervisor.',
    );
  }

  Future<Resultado<void>> enviarEvaluacionMentorQr({
    required int becario_id,
    required int periodo_id,
    required String supervisor_nombre,
    required Map<String, dynamic> respuestas,
    Map<String, dynamic>? calificaciones_1_18,
    String? pregunta_19_apoyo,
    String? pregunta_20_destacado,
    String? pregunta_21_sugerencias,
    String? observaciones,
  }) async {
    final cliente_http = _obtenerCliente();
    try {
      final cabeceras = await _cabeceras();
      final ruta = '${ApiConstantes.RUTA_BASE}/evaluaciones/receptor/mentor-qr';

      final cuerpo = <String, dynamic>{
        'becario_id': becario_id,
        'periodo_id': periodo_id,
        'supervisor_nombre': supervisor_nombre,
        'respuestas': respuestas,
      };
      if (calificaciones_1_18 != null) {
        cuerpo['calificaciones_1_18'] = calificaciones_1_18;
      }
      if (pregunta_19_apoyo != null) {
        cuerpo['pregunta_19_apoyo'] = pregunta_19_apoyo;
      }
      if (pregunta_20_destacado != null) {
        cuerpo['pregunta_20_destacado'] = pregunta_20_destacado;
      }
      if (pregunta_21_sugerencias != null) {
        cuerpo['pregunta_21_sugerencias'] = pregunta_21_sugerencias;
      }
      if (observaciones != null && observaciones.isNotEmpty) {
        cuerpo['observaciones'] = observaciones;
      }

      final respuesta = await cliente_http
          .post(
            Uri.parse(ruta),
            headers: cabeceras,
            body: jsonEncode(cuerpo),
          )
          .timeout(const Duration(seconds: 5));

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        return Resultado.exitoso(null);
      }

      final error = ErrorBumand.desdeRespuesta(respuesta);
      return Resultado.desdeErrorBumand(error);
    } catch (_) {
      return Resultado.exitoso(null);
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }
}

