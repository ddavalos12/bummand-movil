import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constantes/api-constantes.dart';

/// Retorna `true` cuando el rol corresponde a un Mentor / Supervisor institucional.
bool esRolMentor(String? rol) {
  final normalizado = (rol ?? '').toLowerCase().trim();
  return normalizado.contains('supervisor') || normalizado.contains('mentor');
}

/// Retorna `true` cuando el rol corresponde a Administración.
bool esRolAdmin(String? rol) {
  final normalizado = (rol ?? '').toLowerCase().trim();
  return normalizado == 'admin' ||
      normalizado == 'administrador' ||
      normalizado.contains('admin');
}

/// Retorna `true` cuando el rol es Mentor/Supervisor o Administrador.
bool esRolMentorOAdmin(String? rol) => esRolMentor(rol) || esRolAdmin(rol);

/// Utilidades centralizadas para restringir los listados de la APK únicamente
/// a los becarios designados al Mentor autenticado (`supervisor_id == mentor_id`).
class FiltroMentor {
  const FiltroMentor._();

  static int? _parsearEntero(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    return int.tryParse(valor.toString());
  }

  /// Extrae el `supervisor_id` / `mentor_id` desde un mapa JSON heterogéneo.
  static int? extraerSupervisorId(Map<String, dynamic> mapa) {
    final directo = _parsearEntero(
      mapa['supervisor_id'] ??
          mapa['supervisorId'] ??
          mapa['mentor_id'] ??
          mapa['mentorId'],
    );
    if (directo != null) return directo;

    final supervisor = mapa['supervisor'];
    if (supervisor is Map) {
      final id_sup = _parsearEntero(supervisor['id']);
      if (id_sup != null) return id_sup;
    }

    final becario = mapa['becario'];
    if (becario is Map) {
      final sup_becario = _parsearEntero(
        becario['supervisor_id'] ??
            becario['supervisorId'] ??
            becario['mentor_id'] ??
            becario['mentorId'],
      );
      if (sup_becario != null) return sup_becario;
      if (becario['supervisor'] is Map) {
        return _parsearEntero((becario['supervisor'] as Map)['id']);
      }
    }
    return null;
  }

  /// Extrae el `becario_id` (o `usuario_id` del becario) desde un mapa JSON.
  static int? extraerBecarioId(Map<String, dynamic> mapa) {
    final directo = _parsearEntero(
      mapa['becario_id'] ?? mapa['becarioId'] ?? mapa['usuario_id'],
    );
    if (directo != null) return directo;

    final becario = mapa['becario'];
    if (becario is Map) {
      return _parsearEntero(
        becario['id'] ?? becario['becario_id'] ?? becario['usuario_id'],
      );
    }
    return null;
  }

  /// Extrae el nombre legible del becario desde un mapa JSON.
  static String? extraerBecarioNombre(Map<String, dynamic> mapa) {
    final directo = mapa['becario_nombre'] ??
        mapa['becarioNombre'] ??
        mapa['estudiante_nombre'];
    if (directo != null && directo.toString().trim().isNotEmpty) {
      return directo.toString().trim();
    }
    final becario = mapa['becario'];
    if (becario is Map) {
      final nom = becario['nombre'] ??
          (becario['usuario'] is Map
              ? (becario['usuario'] as Map)['nombre']
              : null);
      if (nom != null && nom.toString().trim().isNotEmpty) {
        return nom.toString().trim();
      }
    }
    return null;
  }

  /// Determina si un registro pertenece al Mentor autenticado.
  ///
  /// Prioriza la verificación explícita por `supervisor_id`. Si el registro no
  /// incluye `supervisor_id`, valida contra el conjunto de IDs de becarios
  /// designados al Mentor (`becarios_asignados_ids`). Si ninguno está disponible,
  /// retorna `false` para evitar exponer la nómina completa del sistema.
  static bool perteneceAMentor({
    required int mentor_id,
    int? supervisor_id,
    int? becario_id,
    Set<int>? becarios_asignados_ids,
  }) {
    if (supervisor_id != null) {
      return supervisor_id == mentor_id;
    }
    if (becarios_asignados_ids != null) {
      return becario_id != null && becarios_asignados_ids.contains(becario_id);
    }
    return false;
  }

  /// Filtra una lista genérica para un Mentor usando extractores de IDs.
  static List<T> filtrarParaMentor<T>(
    List<T> lista, {
    required int mentor_id,
    required int? Function(T) obtenerSupervisorId,
    required int? Function(T) obtenerBecarioId,
    Set<int>? becarios_asignados_ids,
  }) {
    return lista.where((item) {
      return perteneceAMentor(
        mentor_id: mentor_id,
        supervisor_id: obtenerSupervisorId(item),
        becario_id: obtenerBecarioId(item),
        becarios_asignados_ids: becarios_asignados_ids,
      );
    }).toList();
  }

  /// Filtra una lista de mapas JSON para un Mentor autenticado.
  static List<Map<String, dynamic>> filtrarMapasParaMentor(
    List<Map<String, dynamic>> lista, {
    required int mentor_id,
    Set<int>? becarios_asignados_ids,
  }) {
    return filtrarParaMentor<Map<String, dynamic>>(
      lista,
      mentor_id: mentor_id,
      obtenerSupervisorId: extraerSupervisorId,
      obtenerBecarioId: extraerBecarioId,
      becarios_asignados_ids: becarios_asignados_ids,
    );
  }

  /// Consulta los IDs de becarios designados al Mentor autenticado desde el
  /// backend (`GET /becarios` con respaldo en `/evaluaciones/modulo-3/becarios-asignados`).
  ///
  /// Retorna `null` únicamente cuando no fue posible conectar con el servidor.
  static Future<Set<int>?> obtenerIdsBecariosAsignados({
    http.Client? cliente,
    required int mentor_id,
  }) async {
    final cliente_http = cliente ?? http.Client();
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final cabeceras = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final urls = [
        '${ApiConstantes.RUTA_BASE}/becarios',
        '${ApiConstantes.RUTA_BASE}/evaluaciones/modulo-3/becarios-asignados',
      ];

      for (final url in urls) {
        try {
          final resp = await cliente_http
              .get(Uri.parse(url), headers: cabeceras)
              .timeout(const Duration(seconds: 4));

          if (resp.statusCode == 200) {
            final cuerpo = jsonDecode(resp.body);
            if (cuerpo is List) {
              final ids = <int>{};
              for (final item in cuerpo) {
                if (item is! Map) continue;
                final mapa = Map<String, dynamic>.from(item);
                final sup_id = extraerSupervisorId(mapa);
                if (sup_id != null && sup_id != mentor_id) continue;

                final b_id = _parsearEntero(mapa['id']);
                final bec_id = _parsearEntero(mapa['becario_id']);
                final usr_id = _parsearEntero(
                  mapa['usuario_id'] ??
                      (mapa['usuario'] is Map
                          ? (mapa['usuario'] as Map)['id']
                          : null),
                );
                if (b_id != null) ids.add(b_id);
                if (bec_id != null) ids.add(bec_id);
                if (usr_id != null) ids.add(usr_id);
              }
              return ids;
            }
          }
        } catch (_) {}
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      if (cliente == null) cliente_http.close();
    }
  }
}
