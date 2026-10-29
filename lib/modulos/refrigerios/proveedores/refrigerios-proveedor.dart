import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../autenticacion/proveedores/autenticacion-proveedor.dart';
import '../modelos/refrigerio-modelo.dart';

class RefrigeriosNotificador extends Notifier<List<RefrigerioModelo>> {
  @override
  List<RefrigerioModelo> build() {
    return REFRIGERIOS_HISTORIAL_BECARIO;
  }

  void confirmarRecojo(int id, {String? hora_personalizada}) {
    final ahora = DateTime.now();
    final hora_str = hora_personalizada ??
        '${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')} hrs';
    final codigo =
        'CR-2026-${ahora.month.toString().padLeft(2, '0')}${ahora.day.toString().padLeft(2, '0')}-${id.toString().padLeft(2, '0')}';

    state = state.map((r) {
      if (r.id == id) {
        return r.copiarCon(
          recogido: true,
          hora_recojo: hora_str,
          codigo_constancia: codigo,
        );
      }
      return r;
    }).toList();
  }

  /// Registra la rendición del menú e ingredientes por parte de la dupla de becarios
  void rendirRefrigerio({
    required int id,
    required String menu_detalle,
    required String modalidad_preparacion,
    required List<IngredienteRefrigerioModelo> ingredientes,
    required double costo_total_bs,
  }) {
    state = state.map((r) {
      if (r.id == id) {
        return r.copiarCon(
          menu_detalle: menu_detalle,
          modalidad_preparacion: modalidad_preparacion,
          ingredientes: ingredientes,
          costo_total_bs: costo_total_bs,
          monto_devolucion_bs: costo_total_bs, // Devolución del 100% íntegra
          estado: 'rendido_pendiente',
        );
      }
      return r;
    }).toList();
  }

  /// Simula la aprobación administrativa con desembolso del 100% al receptor único
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

  return todos.where((r) {
    if (filtro_estado == 'recogido' && !r.recogido) return false;
    if (filtro_estado == 'pendiente' && r.recogido) return false;

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

/// Detecta si el becario autenticado (o demo María Catunta Laime) es encargado del refrigerio este viernes
final turno_dupla_activo_proveedor = Provider<InfoTurnoDupla>((ref) {
  final auth = ref.watch(autenticacion_proveedor);
  final usuario = auth.usuario;

  // Por defecto, María Catunta Laime (ID 1) en vista institucional demo
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

  final ya_rendido = refrigerio_turno.estado != 'sorteado';
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
  return lista.where((r) => r.recogido).length;
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
