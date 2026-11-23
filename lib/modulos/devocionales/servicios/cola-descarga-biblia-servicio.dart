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

    throw Exception('No hay conexión ni versículos almacenados del servidor.');
  }

  Future<List<VersiculoDiarioModelo>> obtenerCatalogoVersiculos() async {
    try {
      final respuesta = await _cliente_http.get(
        Uri.parse('${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_BIBLIA_OFFLINE}'),
      ).timeout(const Duration(seconds: 4));

      if (respuesta.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_CLAVE_CACHE_BIBLIA, respuesta.body);
        await prefs.setString(_CLAVE_FECHA_DESCARGA, DateTime.now().toIso8601String());
        final lista = jsonDecode(respuesta.body) as List<dynamic>;
        if (lista.isNotEmpty) {
          return lista
              .map((e) => VersiculoDiarioModelo.desdeJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final cache_cruda = prefs.getString(_CLAVE_CACHE_BIBLIA);
    if (cache_cruda != null && cache_cruda.isNotEmpty) {
      try {
        final lista = jsonDecode(cache_cruda) as List<dynamic>;
        if (lista.isNotEmpty) {
          return lista
              .map((e) => VersiculoDiarioModelo.desdeJson(e as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }

    final hoy = await obtenerVersiculoHoy();
    return [hoy];
  }
}
