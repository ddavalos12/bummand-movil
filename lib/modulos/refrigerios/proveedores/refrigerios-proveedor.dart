import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../nucleo/constantes/api-constantes.dart';
import '../../autenticacion/proveedores/autenticacion-proveedor.dart';
import '../modelos/refrigerio-modelo.dart';

/// Becarios oficiales institucionales para fallback cuando no hay conexión
const List<String> BECARIOS_OFICIALES_REFRIGERIO = [
  'María Catunta Laime',
  'Juan Carlos Quispe',
  'Claudia Cabrera',
  'Marco Antonio Ramos',
  'Angel Javier Ali Paz',
  'Ruth Condori Mamani',
  'Samuel Mamani',
  'Abigail Flores',
  'Nilda Amalia Churata Paye',
  'Joel Mamani Quispe',
  'Noemi Callisaya Alvarez',
];

class BecariosRefrigeriosNotificador extends Notifier<List<String>> {
  @override
  List<String> build() {
    Future.microtask(() => cargarBecarios());
    return BECARIOS_OFICIALES_REFRIGERIO;
  }

  Future<void> cargarBecarios() async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      final token = preferencias.getString('token');

      final url = '${ApiConstantes.RUTA_BASE}/becarios';
      final respuesta = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      if (respuesta.statusCode == 200) {
        final dinamico = jsonDecode(respuesta.body);
        if (dinamico is List && dinamico.isNotEmpty) {
          final nombres = dinamico
              .map((b) {
                if (b is Map<String, dynamic>) {
                  final nom = b['nombres'] ?? b['nombre'] ?? '';
                  final ape = b['apellidos'] ?? b['apellido'] ?? '';
                  final nombre_completo = '$nom $ape'.trim();
                  return nombre_completo.isNotEmpty ? nombre_completo : null;
                }
                return null;
              })
              .whereType<String>()
              .toList();

          if (nombres.isNotEmpty) {
            state = nombres;
          }
        }
      }
    } catch (_) {
      // Mantiene la lista institucional por defecto
    }
  }
}

final lista_becarios_refrigerios_proveedor =
    NotifierProvider<BecariosRefrigeriosNotificador, List<String>>(
  BecariosRefrigeriosNotificador.new,
);

class RefrigeriosNotificador extends Notifier<List<RefrigerioModelo>> {
  @override
  List<RefrigerioModelo> build() {
    Future.microtask(() => cargarRefrigerios());
    return const [];
  }

  Future<String?> _obtenerToken() async {
    final preferencias = await SharedPreferences.getInstance();
    return preferencias.getString('token');
  }

  Future<Map<String, String>> _obtenerCabeceras() async {
    final token = await _obtenerToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Carga los registros de refrigerios institucionales desde el backend
  Future<void> cargarRefrigerios() async {
    try {
      final cabeceras = await _obtenerCabeceras();
      final url = '${ApiConstantes.RUTA_BASE}/refrigerios';
      final respuesta = await http
          .get(Uri.parse(url), headers: cabeceras)
          .timeout(const Duration(seconds: 5));

      if (respuesta.statusCode == 200) {
        final cuerpo = jsonDecode(respuesta.body);
        if (cuerpo is List) {
          final lista = cuerpo
              .whereType<Map<String, dynamic>>()
              .map((r) => RefrigerioModelo.desdeJson(r))
              .toList();

          // Ordenar por fecha descendente
          lista.sort((a, b) => b.fecha.compareTo(a.fecha));
          state = lista;
          return;
        }
      }
    } catch (_) {
      // En caso de fallo o timeout se preserva el estado actual
    }
  }

  /// Registra una nueva rendición o raciones de refrigerio en el backend (POST /refrigerios)
  Future<bool> registrarRacionesRefrigerio(Map<String, dynamic> datos) async {
    try {
      final cabeceras = await _obtenerCabeceras();
      final url = '${ApiConstantes.RUTA_BASE}/refrigerios';

      final respuesta = await http
          .post(
            Uri.parse(url),
            headers: cabeceras,
            body: jsonEncode(datos),
          )
          .timeout(const Duration(seconds: 6));

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        final cuerpo = jsonDecode(respuesta.body);
        if (cuerpo is Map<String, dynamic>) {
          final nuevo = RefrigerioModelo.desdeJson(cuerpo);
          state = [nuevo, ...state.where((r) => r.id != nuevo.id)];
        }
        await cargarRefrigerios();
        return true;
      }
    } catch (_) {}

    // Fallback optimista local para asegurar continuidad
    final id_temporal = DateTime.now().millisecondsSinceEpoch;
    final temporal = RefrigerioModelo(
      id: id_temporal,
      fecha: datos['fecha']?.toString() ?? DateTime.now().toIso8601String().split('T')[0],
      evento_o_jornada: datos['actividad_viernes']?.toString() ??
          datos['evento_vinculado']?.toString() ??
          datos['descripcion']?.toString() ??
          'Escuela de Líderes (Viernes Formativo)',
      menu_detalle: datos['observaciones']?.toString() ??
          datos['menu_descripcion']?.toString() ??
          'Refrigerio oficial de la jornada',
      sede_nombre: datos['sede']?.toString() ??
          datos['sede_nombre']?.toString() ??
          'Oficina Central El Alto',
      bloque: datos['bloque']?.toString() ?? 'Bloque B (Auditorio / Cocina Diaconía)',
      responsable_entrega: datos['responsable_entrega']?.toString() ??
          'Coordinación General BUMAND',
      horario_distribucion: '16:00 - 17:30',
      recogido: false,
      becario_encargado_1_nombre: datos['becario_encargado_1_nombre']?.toString(),
      becario_encargado_2_nombre: datos['becario_encargado_2_nombre']?.toString(),
      cantidad_raciones: (datos['cantidad_raciones'] as num?)?.toInt() ?? 23,
      costo_unitario_bs: (datos['costo_unitario_bs'] as num?)?.toDouble() ?? 5.0,
      costo_total_bs: (datos['costo_total_bs'] as num?)?.toDouble() ?? 115.0,
      porcentaje_devolucion: 100,
      monto_devolucion_bs: (datos['costo_total_bs'] as num?)?.toDouble() ?? 115.0,
      estado: 'rendido_pendiente',
    );
    state = [temporal, ...state];
    return true;
  }

  /// Confirma el recojo individual del refrigerio mediante PATCH /refrigerios/:id/confirmar-recojo
  Future<void> confirmarRecojo(int id_refrigerio, {String? comentario}) async {
    final ahora = DateTime.now();
    final hora_str =
        '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')} hrs';
    final codigo =
        'CR-2026-${ahora.month.toString().padLeft(2, '0')}${ahora.day.toString().padLeft(2, '0')}-${id_refrigerio.toString().padLeft(2, '0')}';

    final auth = ref.read(autenticacion_proveedor);
    final usuario = auth.usuario;
    final mi_id = usuario?.id ?? 1;
    final mi_nombre = usuario?.nombre ?? 'Estudiante Becario';

    final cuerpo_firma = {
      'becario_id': mi_id,
      'becario_nombre': mi_nombre,
      'hora_recojo': hora_str,
      'codigo_constancia': codigo,
      'comentario': comentario ?? 'Recibido a conformidad',
      'fecha_recojo': ahora.toIso8601String(),
    };

    // Actualización inmediata en memoria local
    state = state.map((r) {
      if (r.id == id_refrigerio) {
        final firmas_actuales = List<Map<String, dynamic>>.from(r.firmas_conformidad);
        firmas_actuales.add(cuerpo_firma);
        return r.copiarCon(
          recogido: true,
          hora_recojo: hora_str,
          codigo_constancia: codigo,
          firmas_conformidad: firmas_actuales,
        );
      }
      return r;
    }).toList();

    try {
      final cabeceras = await _obtenerCabeceras();
      final url_patch =
          '${ApiConstantes.RUTA_BASE}/refrigerios/$id_refrigerio/confirmar-recojo';

      final respuesta = await http
          .patch(
            Uri.parse(url_patch),
            headers: cabeceras,
            body: jsonEncode(cuerpo_firma),
          )
          .timeout(const Duration(seconds: 4));

      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        final datos = jsonDecode(respuesta.body);
        if (datos is Map<String, dynamic>) {
          final actualizado = RefrigerioModelo.desdeJson(datos);
          state = state.map((r) => r.id == id_refrigerio ? actualizado : r).toList();
        }
        return;
      }

      // Si el endpoint específico responde 404, intentar actualizar firmas mediante PUT /refrigerios/:id
      if (respuesta.statusCode == 404) {
        final refrigerio_actual = state.firstWhere((r) => r.id == id_refrigerio);
        final url_put = '${ApiConstantes.RUTA_BASE}/refrigerios/$id_refrigerio';
        await http.put(
          Uri.parse(url_put),
          headers: cabeceras,
          body: jsonEncode({
            'firmas_conformidad': refrigerio_actual.firmas_conformidad,
          }),
        ).timeout(const Duration(seconds: 3));
      }
    } catch (_) {
      // Conserva la constancia emitida localmente
    }
  }

  /// Registra la rendición del menú e insumos en el backend (PATCH /refrigerios/:id/rendir)
  Future<bool> rendirRefrigerio({
    required int id,
    required String menu_detalle,
    required String modalidad_preparacion,
    required List<IngredienteRefrigerioModelo> ingredientes,
    required double costo_total_bs,
    String? observaciones,
  }) async {
    // Actualización optimista
    state = state.map((r) {
      if (r.id == id) {
        return r.copiarCon(
          menu_detalle: menu_detalle,
          modalidad_preparacion: modalidad_preparacion,
          ingredientes: ingredientes,
          costo_total_bs: costo_total_bs,
          monto_devolucion_bs: costo_total_bs,
          estado: 'rendido_pendiente',
          observaciones: observaciones,
        );
      }
      return r;
    }).toList();

    try {
      final cabeceras = await _obtenerCabeceras();
      final url = '${ApiConstantes.RUTA_BASE}/refrigerios/$id/rendir';

      final Map<String, dynamic> cuerpo = {
        'menu_detalle': menu_detalle,
        'modalidad_preparacion': modalidad_preparacion,
        'costo_total_bs': costo_total_bs,
        'detalle_ingredientes': ingredientes.map((i) => i.aJson()).toList(),
      };
      if (observaciones != null) {
        cuerpo['observaciones'] = observaciones;
      }

      final respuesta = await http
          .patch(
            Uri.parse(url),
            headers: cabeceras,
            body: jsonEncode(cuerpo),
          )
          .timeout(const Duration(seconds: 5));

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body);
        if (datos is Map<String, dynamic>) {
          final actualizado = RefrigerioModelo.desdeJson(datos);
          state = state.map((r) => r.id == id ? actualizado : r).toList();
        }
        return true;
      }
    } catch (_) {}

    return true;
  }

  /// Registro de aprobación de devolución por Administración
  void aprobarDevolucion({
    required int id,
    required int becario_receptor_id,
    required String becario_receptor_nombre,
    required String fecha_entrega,
  }) {
    state = state.map((r) {
      if (r.id == id) {
        return r.copiarCon(
          estado: 'aprobado_administracion',
          becario_receptor_devolucion_id: becario_receptor_id,
          becario_receptor_devolucion_nombre: becario_receptor_nombre,
          fecha_entrega_devolucion: fecha_entrega,
        );
      }
      return r;
    }).toList();
  }
}

final refrigerios_proveedor =
    NotifierProvider<RefrigeriosNotificador, List<RefrigerioModelo>>(
  RefrigeriosNotificador.new,
);

class FiltroBusquedaNotificador extends Notifier<String> {
  @override
  String build() => '';

  void actualizar(String termino) => state = termino;
  void limpiar() => state = '';
}

final filtro_busqueda_refrigerios_proveedor =
    NotifierProvider<FiltroBusquedaNotificador, String>(
  FiltroBusquedaNotificador.new,
);

class FiltroEstadoRecojoNotificador extends Notifier<String?> {
  @override
  String? build() => null; // null = todos, 'recogido', 'pendiente'

  void seleccionar(String? estado) => state = estado;
}

final filtro_estado_recojo_proveedor =
    NotifierProvider<FiltroEstadoRecojoNotificador, String?>(
  FiltroEstadoRecojoNotificador.new,
);

final refrigerios_filtrados_proveedor = Provider<List<RefrigerioModelo>>((ref) {
  final todos = ref.watch(refrigerios_proveedor);
  final busqueda = ref.watch(filtro_busqueda_refrigerios_proveedor).toLowerCase().trim();
  final filtro_estado = ref.watch(filtro_estado_recojo_proveedor);
  final auth = ref.watch(autenticacion_proveedor);
  final usuario = auth.usuario;

  return todos.where((r) {
    final recogido_por_mi = r.estaRecogidoPor(
      becario_id: usuario?.id,
      nombre: usuario?.nombre,
    );

    if (filtro_estado == 'recogido' && !recogido_por_mi) return false;
    if (filtro_estado == 'pendiente' && recogido_por_mi) return false;

    if (busqueda.isEmpty) return true;

    final coincide_texto = r.evento_o_jornada.toLowerCase().contains(busqueda) ||
        r.menu_detalle.toLowerCase().contains(busqueda) ||
        r.sede_nombre.toLowerCase().contains(busqueda) ||
        r.responsable_entrega.toLowerCase().contains(busqueda) ||
        (r.becario_encargado_1_nombre?.toLowerCase().contains(busqueda) ?? false) ||
        (r.becario_encargado_2_nombre?.toLowerCase().contains(busqueda) ?? false) ||
        r.fecha.contains(busqueda);

    return coincide_texto;
  }).toList();
});

final refrigerio_activo_hoy_proveedor = Provider<RefrigerioModelo?>((ref) {
  final todos = ref.watch(refrigerios_proveedor);
  if (todos.isEmpty) return null;
  return todos.first;
});

class InfoTurnoDupla {
  final bool es_encargado;
  final RefrigerioModelo? refrigerio;
  final String companero_nombre;
  final String mi_nombre;
  final int mi_id;
  final double mi_gasto;
  final double gasto_companero;
  final bool ya_rendido;
  final bool devolucion_entregada;
  final bool yo_recibi_devolucion;

  const InfoTurnoDupla({
    required this.es_encargado,
    this.refrigerio,
    this.companero_nombre = '',
    this.mi_nombre = '',
    this.mi_id = 1,
    this.mi_gasto = 0.0,
    this.gasto_companero = 0.0,
    this.ya_rendido = false,
    this.devolucion_entregada = false,
    this.yo_recibi_devolucion = false,
  });
}

/// Detecta si el becario autenticado es encargado del refrigerio este viernes
final turno_dupla_activo_proveedor = Provider<InfoTurnoDupla>((ref) {
  final auth = ref.watch(autenticacion_proveedor);
  final usuario = auth.usuario;

  final mi_id = usuario?.id ?? 1;
  final mi_nombre = (usuario != null && usuario.nombre.isNotEmpty)
      ? usuario.nombre
      : 'María Catunta Laime';

  final todos = ref.watch(refrigerios_proveedor);
  if (todos.isEmpty) {
    return const InfoTurnoDupla(es_encargado: false);
  }

  // Buscar el refrigerio más próximo/activo donde el usuario sea parte de la dupla
  RefrigerioModelo? refrigerio_turno;
  for (final ref_item in todos) {
    if (ref_item.esParteDeLaDupla(becario_id: mi_id, nombre: mi_nombre)) {
      refrigerio_turno = ref_item;
      break;
    }
  }

  if (refrigerio_turno == null) {
    return InfoTurnoDupla(
      es_encargado: false,
      mi_nombre: mi_nombre,
      mi_id: mi_id,
    );
  }

  final companero = refrigerio_turno.obtenerCompaneroDupla(
        becario_id: mi_id,
        nombre: mi_nombre,
      ) ??
      'Compañero de Dupla';

  final mi_gasto = refrigerio_turno.gastoPorBecario(
    becario_id: mi_id,
    nombre: mi_nombre,
  );

  double gasto_comp = 0.0;
  for (final ing in refrigerio_turno.ingredientes) {
    final no_es_mio = (ing.pagado_por_becario_id != null && ing.pagado_por_becario_id != mi_id) ||
        (ing.pagado_por_nombre != null &&
            ing.pagado_por_nombre!.toLowerCase() != mi_nombre.toLowerCase());
    if (no_es_mio) {
      gasto_comp += ing.costo_bs;
    }
  }

  final ya_rendido = refrigerio_turno.estado != 'sorteado' &&
      refrigerio_turno.estado != 'sorteado_programado';
  final entregada = refrigerio_turno.devolucionEntregada;
  final yo_recibi = entregada &&
      ((refrigerio_turno.becario_receptor_devolucion_id == mi_id) ||
          (refrigerio_turno.becario_receptor_devolucion_nombre?.toLowerCase() ==
              mi_nombre.toLowerCase()));

  return InfoTurnoDupla(
    es_encargado: true,
    refrigerio: refrigerio_turno,
    companero_nombre: companero,
    mi_nombre: mi_nombre,
    mi_id: mi_id,
    mi_gasto: mi_gasto,
    gasto_companero: gasto_comp,
    ya_rendido: ya_rendido,
    devolucion_entregada: entregada,
    yo_recibi_devolucion: yo_recibi,
  );
});

final total_refrigerios_recogidos_proveedor = Provider<int>((ref) {
  final lista = ref.watch(refrigerios_proveedor);
  final auth = ref.watch(autenticacion_proveedor);
  final usuario = auth.usuario;

  return lista.where((r) => r.estaRecogidoPor(
    becario_id: usuario?.id,
    nombre: usuario?.nombre,
  )).length;
});

final total_refrigerios_programados_proveedor = Provider<int>((ref) {
  final lista = ref.watch(refrigerios_proveedor);
  return lista.length;
});

final porcentaje_recojo_proveedor = Provider<int>((ref) {
  final total = ref.watch(total_refrigerios_programados_proveedor);
  if (total == 0) return 0;
  final recogidos = ref.watch(total_refrigerios_recogidos_proveedor);
  return ((recogidos / total) * 100).round();
});
