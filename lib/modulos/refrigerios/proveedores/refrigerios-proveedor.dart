import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        r.fecha.contains(busqueda);

    return coincide_texto;
  }).toList();
});

final refrigerio_activo_hoy_proveedor = Provider<RefrigerioModelo?>((ref) {
  final todos = ref.watch(refrigerios_proveedor);
  if (todos.isEmpty) return null;
  return todos.first;
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
