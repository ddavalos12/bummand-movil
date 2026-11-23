import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../nucleo/constantes/api-constantes.dart';
import '../../../nucleo/servicios/cola-offline-servicio.dart';
import '../../../nucleo/utilidades/filtro-mentor.dart';
import '../../../nucleo/utilidades/resultado.dart';
import '../../autenticacion/proveedores/autenticacion-proveedor.dart';
import '../modelos/cita-seguimiento-modelo.dart';
import '../modelos/versiculo-diario-modelo.dart';
import '../repositorios/devocionales-repositorio.dart';
import '../servicios/cola-descarga-biblia-servicio.dart';

final becarios_supervisados_proveedor =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final auth = ref.watch(autenticacion_proveedor);
  final usuario = auth.usuario;
  final prefs = await SharedPreferences.getInstance();
  final token = usuario?.token ?? prefs.getString('token');
  if (token == null || token.isEmpty) {
    throw Exception('Sesión no encontrada');
  }

  final resp = await http.get(
    Uri.parse('${ApiConstantes.RUTA_BASE}/api/becarios'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  if (resp.statusCode != 200) {
    throw Exception('Error al cargar becarios supervisados (${resp.statusCode})');
  }
  final decoded = jsonDecode(resp.body);
  if (decoded is! List) return const [];
  var lista = decoded
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .map((m) => <String, dynamic>{
            ...m,
            'id': m['id'] is int ? m['id'] : int.tryParse(m['id']?.toString() ?? '') ?? 0,
            'nombre': (m['nombre'] ??
                    (m['usuario'] is Map ? m['usuario']['nombre'] : null) ??
                    'Sin nombre')
                .toString(),
            'carrera': (m['carrera'] ?? '').toString(),
          })
      .where((m) => (m['id'] as int) > 0)
      .toList();

  final es_mentor = esRolMentor(usuario?.rol) && !esRolAdmin(usuario?.rol);
  if (es_mentor && usuario != null) {
    final ids_asignados = await FiltroMentor.obtenerIdsBecariosAsignados(
      mentor_id: usuario.id,
    );
    lista = FiltroMentor.filtrarMapasParaMentor(
      lista,
      mentor_id: usuario.id,
      becarios_asignados_ids: ids_asignados,
    );
  }
  return lista;
});

final devocionales_repositorio_proveedor =
    Provider<DevocionalesRepositorio>((ref) {
  final cola = ref.watch(cola_offline_servicio_proveedor);
  return DevocionalesRepositorio(cola_offline: cola);
});

final devocionales_lista_proveedor =
    FutureProvider.autoDispose<Resultado<List<DevocionalModelo>>>((ref) async {
  final repo = ref.watch(devocionales_repositorio_proveedor);
  return repo.obtenerDevocionales();
});

final versiculo_diario_proveedor =
    FutureProvider.autoDispose<VersiculoDiarioModelo>((ref) async {
  final servicio = ref.watch(cola_descarga_biblia_proveedor);
  return servicio.obtenerVersiculoHoy();
});

final citas_seguimiento_proveedor =
    FutureProvider.autoDispose<Resultado<List<CitaSeguimientoModelo>>>((ref) async {
  final repo = ref.watch(devocionales_repositorio_proveedor);
  final auth = ref.watch(autenticacion_proveedor);
  final rol = auth.usuario?.rol;
  final es_supervisor = esRolMentor(rol) && !esRolAdmin(rol);
  return repo.obtenerCitasSeguimiento(es_supervisor: es_supervisor);
});

