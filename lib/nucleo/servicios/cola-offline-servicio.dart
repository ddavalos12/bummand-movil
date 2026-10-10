import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constantes/api-constantes.dart';

class PeticionEncolada {
  final String id;
  final String ruta;
  final String metodo;
  final Map<String, dynamic> cuerpo;
  final DateTime fecha_creacion;
  final int intentos;
  final String tipo;

  const PeticionEncolada({
    required this.id,
    required this.ruta,
    required this.metodo,
    required this.cuerpo,
    required this.fecha_creacion,
    this.intentos = 0,
    required this.tipo,
  });

  factory PeticionEncolada.desdeMapa(Map<String, dynamic> mapa) {
    return PeticionEncolada(
      id: mapa['id'] as String,
      ruta: mapa['ruta'] as String,
      metodo: mapa['metodo'] as String,
      cuerpo: Map<String, dynamic>.from(mapa['cuerpo'] as Map),
      fecha_creacion: DateTime.parse(mapa['fecha_creacion'] as String),
      intentos: (mapa['intentos'] as num?)?.toInt() ?? 0,
      tipo: mapa['tipo'] as String? ?? 'general',
    );
  }

  Map<String, dynamic> aMapa() {
    return {
      'id': id,
      'ruta': ruta,
      'metodo': metodo,
      'cuerpo': cuerpo,
      'fecha_creacion': fecha_creacion.toIso8601String(),
      'intentos': intentos,
      'tipo': tipo,
    };
  }

  PeticionEncolada copiarCon({int? intentos}) {
    return PeticionEncolada(
      id: id,
      ruta: ruta,
      metodo: metodo,
      cuerpo: cuerpo,
      fecha_creacion: fecha_creacion,
      intentos: intentos ?? this.intentos,
      tipo: tipo,
    );
  }
}

class ColaOfflineServicio {
  static const String CLAVE_ALMACENAMIENTO = 'bumand_cola_peticiones_offline';

  ColaOfflineServicio();

  Future<SharedPreferences> _obtenerPreferencias() async {
    return SharedPreferences.getInstance();
  }

  Future<String?> _obtenerToken() async {
    final prefs = await _obtenerPreferencias();
    return prefs.getString('token');
  }

  Future<List<PeticionEncolada>> obtenerPendientes() async {
    final prefs = await _obtenerPreferencias();
    final datos_crudos = prefs.getStringList(CLAVE_ALMACENAMIENTO) ?? [];
    return datos_crudos.map((e) {
      final mapa = jsonDecode(e) as Map<String, dynamic>;
      return PeticionEncolada.desdeMapa(mapa);
    }).toList();
  }

  Future<void> encolar({
    required String ruta,
    required String metodo,
    required Map<String, dynamic> cuerpo,
    required String tipo,
  }) async {
    final prefs = await _obtenerPreferencias();
    final pendientes = await obtenerPendientes();

    final nueva_peticion = PeticionEncolada(
      id: '${DateTime.now().millisecondsSinceEpoch}_${pendientes.length}',
      ruta: ruta,
      metodo: metodo.toUpperCase(),
      cuerpo: cuerpo,
      fecha_creacion: DateTime.now(),
      intentos: 0,
      tipo: tipo,
    );

    pendientes.add(nueva_peticion);
    final lista_serializada =
        pendientes.map((p) => jsonEncode(p.aMapa())).toList();
    await prefs.setStringList(CLAVE_ALMACENAMIENTO, lista_serializada);
  }

  Future<void> eliminarPeticion(String id) async {
    final prefs = await _obtenerPreferencias();
    final pendientes = await obtenerPendientes();
    pendientes.removeWhere((p) => p.id == id);
    final lista_serializada =
        pendientes.map((p) => jsonEncode(p.aMapa())).toList();
    await prefs.setStringList(CLAVE_ALMACENAMIENTO, lista_serializada);
  }

  Future<void> limpiarCola() async {
    final prefs = await _obtenerPreferencias();
    await prefs.remove(CLAVE_ALMACENAMIENTO);
  }

  Future<int> sincronizarPendientes({http.Client? cliente_personalizado}) async {
    final pendientes = await obtenerPendientes();
    if (pendientes.isEmpty) return 0;

    final token = await _obtenerToken();
    final cabeceras = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final cliente = cliente_personalizado ?? http.Client();
    int sincronizados = 0;
    final List<PeticionEncolada> no_sincronizados = [];

    for (final peticion in pendientes) {
      try {
        final url_completa = peticion.ruta.startsWith('http')
            ? peticion.ruta
            : '${ApiConstantes.RUTA_BASE}${peticion.ruta}';

        final uri = Uri.parse(url_completa);
        http.Response respuesta;

        switch (peticion.metodo) {
          case 'POST':
            respuesta = await cliente.post(
              uri,
              headers: cabeceras,
              body: jsonEncode(peticion.cuerpo),
            );
            break;
          case 'PUT':
            respuesta = await cliente.put(
              uri,
              headers: cabeceras,
              body: jsonEncode(peticion.cuerpo),
            );
            break;
          case 'PATCH':
            respuesta = await cliente.patch(
              uri,
              headers: cabeceras,
              body: jsonEncode(peticion.cuerpo),
            );
            break;
          default:
            respuesta = await cliente.post(
              uri,
              headers: cabeceras,
              body: jsonEncode(peticion.cuerpo),
            );
        }

        if (respuesta.statusCode >= 200 && respuesta.statusCode < 300) {
          sincronizados++;
        } else if (respuesta.statusCode >= 400 && respuesta.statusCode < 500) {
          // Error del cliente: se descarta para evitar bloqueos continuos
          sincronizados++;
        } else {
          no_sincronizados.add(peticion.copiarCon(intentos: peticion.intentos + 1));
        }
      } catch (_) {
        no_sincronizados.add(peticion.copiarCon(intentos: peticion.intentos + 1));
      }
    }

    if (cliente_personalizado == null) {
      cliente.close();
    }

    final prefs = await _obtenerPreferencias();
    final lista_serializada =
        no_sincronizados.map((p) => jsonEncode(p.aMapa())).toList();
    await prefs.setStringList(CLAVE_ALMACENAMIENTO, lista_serializada);

    return sincronizados;
  }
}

final cola_offline_servicio_proveedor = Provider<ColaOfflineServicio>((ref) {
  return ColaOfflineServicio();
});

final cola_offline_conteo_proveedor = FutureProvider<int>((ref) async {
  final servicio = ref.watch(cola_offline_servicio_proveedor);
  final lista = await servicio.obtenerPendientes();
  return lista.length;
});

final hay_conexion_red_proveedor = Provider<bool>((ref) {
  return true;
});
