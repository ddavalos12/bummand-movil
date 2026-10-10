import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../nucleo/constantes/api-constantes.dart';
import '../../../nucleo/errores/error-bumand.dart';
import '../../../nucleo/servicios/cola-offline-servicio.dart';
import '../../../nucleo/utilidades/resultado.dart';

class DevocionalModelo {
  final int id;
  final String fecha;
  final String cita_biblica;
  final String titulo;
  final String reflexion;
  final String oracion_peticion;
  final String? comentario_pastoral;
  final bool revisado_por_pastor;

  const DevocionalModelo({
    required this.id,
    required this.fecha,
    required this.cita_biblica,
    required this.titulo,
    required this.reflexion,
    required this.oracion_peticion,
    this.comentario_pastoral,
    this.revisado_por_pastor = false,
  });

  factory DevocionalModelo.desdeMapa(Map<String, dynamic> mapa) {
    return DevocionalModelo(
      id: (mapa['id'] as num?)?.toInt() ?? 0,
      fecha: mapa['fecha']?.toString() ?? '',
      cita_biblica: mapa['cita_biblica']?.toString() ??
          mapa['citaBiblica']?.toString() ??
          '',
      titulo: mapa['titulo']?.toString() ?? '',
      reflexion: mapa['reflexion']?.toString() ?? '',
      oracion_peticion: mapa['oracion_peticion']?.toString() ??
          mapa['oracionPeticion']?.toString() ??
          '',
      comentario_pastoral: mapa['comentario_pastoral']?.toString() ??
          mapa['comentarioPastoral']?.toString(),
      revisado_por_pastor: mapa['revisado_por_pastor'] == true ||
          mapa['revisadoPorPastor'] == true,
    );
  }

  Map<String, dynamic> aMapa() {
    return {
      'id': id,
      'fecha': fecha,
      'cita_biblica': cita_biblica,
      'titulo': titulo,
      'reflexion': reflexion,
      'oracion_peticion': oracion_peticion,
      'comentario_pastoral': comentario_pastoral,
      'revisado_por_pastor': revisado_por_pastor,
    };
  }
}

class DevocionalesRepositorio {
  final http.Client? cliente;
  final ColaOfflineServicio? cola_offline;

  static const List<DevocionalModelo> SEMILLAS = [
    DevocionalModelo(
      id: 1,
      fecha: '2026-10-07',
      cita_biblica: 'Filipenses 4:13',
      titulo: 'Fortaleza en el Servicio Diario',
      reflexion:
          'Hoy comprendí que en cada tarea de apoyo preprofesional, el Señor renueva mis fuerzas y paciencia con los beneficiarios.',
      oracion_peticion:
          'Sabiduría en los exámenes universitarios y gracia en mi asignación de práctica.',
      comentario_pastoral:
          'Sigue adelante hermano, tu testimonio edifica a la congregación.',
      revisado_por_pastor: true,
    ),
    DevocionalModelo(
      id: 2,
      fecha: '2026-10-05',
      cita_biblica: 'Proverbios 3:5-6',
      titulo: 'Confianza y Guía Divina',
      reflexion:
          'Fiarme de Dios de todo corazón y no en mi propia inteligencia al tomar decisiones en el trabajo y la facultad.',
      oracion_peticion:
          'Por mi familia y la provisión económica para los estudios.',
      comentario_pastoral: null,
      revisado_por_pastor: false,
    ),
    DevocionalModelo(
      id: 3,
      fecha: '2026-10-02',
      cita_biblica: 'Colosenses 3:23-24',
      titulo: 'Hacedlo todo para el Señor',
      reflexion:
          'Todo trabajo o apoyo en la agencia debe realizarse con excelencia, pues a Cristo el Señor servimos.',
      oracion_peticion:
          'Por la Escuela de Líderes y los talleres diaconales de los viernes.',
      comentario_pastoral:
          'Excelente aplicación práctica. Dios bendiga tu servicio.',
      revisado_por_pastor: true,
    ),
  ];

  DevocionalesRepositorio({
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

  Future<Resultado<List<DevocionalModelo>>> obtenerDevocionales() async {
    final cliente_http = _obtenerCliente();
    try {
      final cabeceras = await _cabeceras();
      final url = '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_DEVOCIONALES}';
      final respuesta = await cliente_http.get(
        Uri.parse(url),
        headers: cabeceras,
      );

      if (respuesta.statusCode == 200) {
        final dynamic cuerpo = jsonDecode(respuesta.body);
        if (cuerpo is List && cuerpo.isNotEmpty) {
          final lista = cuerpo
              .map((e) => DevocionalModelo.desdeMapa(e as Map<String, dynamic>))
              .toList();
          return Resultado.exitoso(lista);
        }
      }
      return Resultado.exitoso(List<DevocionalModelo>.from(SEMILLAS));
    } catch (_) {
      return Resultado.exitoso(List<DevocionalModelo>.from(SEMILLAS));
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }

  Future<Resultado<DevocionalModelo>> guardarDevocional({
    required String cita_biblica,
    required String titulo,
    required String reflexion,
    required String oracion_peticion,
  }) async {
    final cliente_http = _obtenerCliente();
    final cuerpo = {
      'cita_biblica': cita_biblica,
      'titulo': titulo,
      'reflexion': reflexion,
      'oracion_peticion': oracion_peticion,
      'fecha': DateTime.now().toIso8601String().substring(0, 10),
    };

    final ruta = ApiConstantes.PUNTO_DEVOCIONALES;

    try {
      final cabeceras = await _cabeceras();
      final respuesta = await cliente_http.post(
        Uri.parse('${ApiConstantes.RUTA_BASE}$ruta'),
        headers: cabeceras,
        body: jsonEncode(cuerpo),
      );

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        final dynamic datos = jsonDecode(respuesta.body);
        final creado = datos is Map<String, dynamic>
            ? DevocionalModelo.desdeMapa(datos)
            : DevocionalModelo(
                id: DateTime.now().millisecondsSinceEpoch,
                fecha: cuerpo['fecha']!,
                cita_biblica: cita_biblica,
                titulo: titulo,
                reflexion: reflexion,
                oracion_peticion: oracion_peticion,
              );
        return Resultado.exitoso(creado);
      }
      final error = ErrorBumand.desdeRespuesta(respuesta);
      return Resultado.desdeErrorBumand(error);
    } catch (_) {
      if (cola_offline != null) {
        await cola_offline!.encolar(
          ruta: ruta,
          metodo: 'POST',
          cuerpo: cuerpo,
          tipo: 'devocional',
        );
        final local = DevocionalModelo(
          id: DateTime.now().millisecondsSinceEpoch,
          fecha: cuerpo['fecha']!,
          cita_biblica: cita_biblica,
          titulo: titulo,
          reflexion: reflexion,
          oracion_peticion: oracion_peticion,
        );
        return Resultado.exitoso(local);
      }
      return Resultado.desdeErrorBumand(
        ErrorBumand.conexionOffline(ruta: ruta, metodo: 'POST'),
      );
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }
}
