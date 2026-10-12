import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../nucleo/constantes/api-constantes.dart';
import '../modelos/versiculo-diario-modelo.dart';

final cola_descarga_biblia_proveedor = Provider<ColaDescargaBibliaServicio>((ref) {
  return ColaDescargaBibliaServicio();
});

class ColaDescargaBibliaServicio {
  static const String _CLAVE_CACHE_BIBLIA = 'bumand_biblia_paquete_offline';
  static const String _CLAVE_ULTIMO_VERSICULO = 'bumand_biblia_ultimo_versiculo';
  static const String _CLAVE_FECHA_DESCARGA = 'bumand_biblia_fecha_descarga';

  final http.Client _cliente_http;

  ColaDescargaBibliaServicio({http.Client? cliente})
      : _cliente_http = cliente ?? http.Client();

  static const List<VersiculoDiarioModelo> _CATALOGO_PRECARGADO_BASE = [
    VersiculoDiarioModelo(
      cita: 'Filipenses 4:13',
      libro: 'Filipenses',
      capitulo: 4,
      versiculo: 13,
      texto: 'Todo lo puedo en Cristo que me fortalece.',
      version: 'Reina-Valera 1960 (RVR60)',
      tema: 'Fortaleza y Servicio',
      reflexion_diaconal:
          'En cada labor y apoyo formativo dentro de Diaconía, Cristo es quien renueva nuestras capacidades para servir con excelencia.',
    ),
    VersiculoDiarioModelo(
      cita: 'Proverbios 3:5-6',
      libro: 'Proverbios',
      capitulo: 3,
      versiculo: 5,
      texto:
          'Fíate de Jehová de todo tu corazón, y no te apoyes en tu propia prudencia. Reconócelo en todos tus caminos, y él enderezará tus veredas.',
      version: 'Reina-Valera 1960 (RVR60)',
      tema: 'Confianza y Sabiduría',
      reflexion_diaconal:
          'Encomienda tus metas profesionales y tu vocación al Señor; Él dirige nuestros pasos ante cada desafío institucional.',
    ),
    VersiculoDiarioModelo(
      cita: 'Colosenses 3:23-24',
      libro: 'Colosenses',
      capitulo: 3,
      versiculo: 23,
      texto:
          'Y todo lo que hagáis, hacedlo de corazón, como para el Señor y no para los hombres; sabiendo que del Señor recibiréis la recompensa de la herencia.',
      version: 'Reina-Valera 1960 (RVR60)',
      tema: 'Integridad y Esfuerzo',
      reflexion_diaconal:
          'Cada tarea asignada en tu sede o agencia es un testimonio vivo del amor de Cristo expresado en el trabajo honesto.',
    ),
    VersiculoDiarioModelo(
      cita: 'Josué 1:9',
      libro: 'Josué',
      capitulo: 1,
      versiculo: 9,
      texto:
          'Mira que te mando que te esfuerces y seas valiente; no temas ni desmayes, porque Jehová tu Dios estará contigo en dondequiera que vayas.',
      version: 'Reina-Valera 1960 (RVR60)',
      tema: 'Valentía Diaconal',
      reflexion_diaconal:
          'Da pasos de fe firmes en tu desarrollo académico y liderazgo espiritual, sabiendo que la gracia divina te acompaña siempre.',
    ),
    VersiculoDiarioModelo(
      cita: 'Gálatas 6:9',
      libro: 'Gálatas',
      capitulo: 6,
      versiculo: 9,
      texto:
          'No nos cansemos, pues, de hacer bien; porque a su tiempo segaremos, si no desmayamos.',
      version: 'Reina-Valera 1960 (RVR60)',
      tema: 'Perseverancia en el Bien',
      reflexion_diaconal:
          'Cada gesto solidario y cada hora de práctica dedicada al servicio rinde frutos duraderos en el Reino de Dios.',
    ),
    VersiculoDiarioModelo(
      cita: 'Isaías 40:31',
      libro: 'Isaías',
      capitulo: 40,
      versiculo: 31,
      texto:
          'Pero los que esperan a Jehová tendrán nuevas fuerzas; levantarán alas como las águilas; correrán, y no se cansarán; caminarán, y no se fatigarán.',
      version: 'Reina-Valera 1960 (RVR60)',
      tema: 'Renovación Espiritual',
      reflexion_diaconal:
          'Cuando sientas agotamiento en tus prácticas o estudios, busca al Señor en oración para recibir nuevas energías.',
    ),
    VersiculoDiarioModelo(
      cita: 'Miqueas 6:8',
      libro: 'Miqueas',
      capitulo: 6,
      versiculo: 8,
      texto:
          'Oh hombre, él te ha declarado lo que es bueno, y qué pide Jehová de ti: solamente hacer justicia, y amar misericordia, y humillarte ante tu Dios.',
      version: 'Reina-Valera 1960 (RVR60)',
      tema: 'Justicia y Humildad',
      reflexion_diaconal:
          'El corazón del ministerio diaconal se fundamenta en la justicia compasiva y el servicio humilde hacia nuestra comunidad.',
    ),
    VersiculoDiarioModelo(
      cita: 'Salmos 119:105',
      libro: 'Salmos',
      capitulo: 119,
      versiculo: 105,
      texto: 'Lámpara es a mis pies tu palabra, y lumbrera a mi camino.',
      version: 'Reina-Valera 1960 (RVR60)',
      tema: 'Guía Bíblica',
      reflexion_diaconal:
          'La lectura diaria de las Sagradas Escrituras es la brújula confiable que orienta nuestras decisiones cotidianas.',
    ),
  ];

  Future<void> sincronizarColaDescarga() async {
    try {
      final respuesta = await _cliente_http.get(
        Uri.parse('${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_BIBLIA_OFFLINE}'),
      ).timeout(const Duration(seconds: 4));

      if (respuesta.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_CLAVE_CACHE_BIBLIA, respuesta.body);
        await prefs.setString(_CLAVE_FECHA_DESCARGA, DateTime.now().toIso8601String());
      }
    } catch (_) {}
  }

  Future<VersiculoDiarioModelo> obtenerVersiculoHoy() async {
    // 1. Intentar cargar desde la API en línea
    try {
      final respuesta = await _cliente_http.get(
        Uri.parse('${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_BIBLIA_VERSICULO}'),
      ).timeout(const Duration(seconds: 3));

      if (respuesta.statusCode == 200) {
        final mapa = jsonDecode(respuesta.body) as Map<String, dynamic>;
        final versiculo = VersiculoDiarioModelo.desdeJson(mapa);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_CLAVE_ULTIMO_VERSICULO, jsonEncode(versiculo.aJson()));
        // Sincronizar paquete completo en segundo plano
        sincronizarColaDescarga();
        return versiculo;
      }
    } catch (_) {}

    // 2. Si no hay conexión, cargar desde la caché pre-descargada
    final prefs = await SharedPreferences.getInstance();
    final cache_cruda = prefs.getString(_CLAVE_CACHE_BIBLIA);

    if (cache_cruda != null && cache_cruda.isNotEmpty) {
      try {
        final lista = jsonDecode(cache_cruda) as List<dynamic>;
        if (lista.isNotEmpty) {
          final indice = (DateTime.now().day - 1) % lista.length;
          return VersiculoDiarioModelo.desdeJson(
            lista[indice] as Map<String, dynamic>,
          );
        }
      } catch (_) {}
    }

    // 3. Fallback al último versículo guardado exitosamente
    final ultimo_crudo = prefs.getString(_CLAVE_ULTIMO_VERSICULO);
    if (ultimo_crudo != null && ultimo_crudo.isNotEmpty) {
      try {
        final mapa = jsonDecode(ultimo_crudo) as Map<String, dynamic>;
        return VersiculoDiarioModelo.desdeJson(mapa);
      } catch (_) {}
    }

    // 4. Fallback garantizado: catálogo precargado en memoria
    final dia = DateTime.now().day;
    final indice = (dia - 1) % _CATALOGO_PRECARGADO_BASE.length;
    return _CATALOGO_PRECARGADO_BASE[indice];
  }
}
