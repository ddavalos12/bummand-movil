import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modelos/notificacion-modelo.dart';
import '../repositorios/notificaciones-repositorio.dart';

final notificaciones_repositorio_proveedor = Provider<NotificacionesRepositorio>(
  (ref) => NotificacionesRepositorio(),
);

final notificaciones_proveedor = FutureProvider<List<NotificacionModelo>>((ref) async {
  final repo = ref.watch(notificaciones_repositorio_proveedor);
  final resultado = await repo.obtenerMisNotificaciones();
  if (resultado.exito && resultado.datos != null) {
    return resultado.datos!;
  }
  return <NotificacionModelo>[];
});

final notificaciones_conteo_proveedor = FutureProvider<int>((ref) async {
  final repo = ref.watch(notificaciones_repositorio_proveedor);
  final resultado = await repo.contarNoLeidas();
  if (resultado.exito && resultado.datos != null) {
    return resultado.datos!;
  }
  return 0;
});

class NotificacionesNotificador extends AsyncNotifier<List<NotificacionModelo>> {
  late final NotificacionesRepositorio _repo;

  @override
  FutureOr<List<NotificacionModelo>> build() async {
    _repo = ref.read(notificaciones_repositorio_proveedor);
    return _cargarNotificaciones();
  }

  Future<List<NotificacionModelo>> _cargarNotificaciones() async {
    final res = await _repo.obtenerMisNotificaciones();
    if (res.exito && res.datos != null) {
      return res.datos!;
    }
    return <NotificacionModelo>[];
  }

  Future<void> recargar() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final res = await _cargarNotificaciones();
      ref.invalidate(notificaciones_conteo_proveedor);
      return res;
    });
  }

  Future<bool> marcarComoLeida(int id) async {
    final res = await _repo.marcarLeida(id);
    if (res.exito) {
      final lista_actual = state.value ?? [];
      state = AsyncData(
        lista_actual
            .map((n) => n.id == id ? n.copiarCon(leido: true) : n)
            .toList(),
      );
      ref.invalidate(notificaciones_conteo_proveedor);
      return true;
    }
    return false;
  }
}

final notificaciones_notificador_proveedor =
    AsyncNotifierProvider<NotificacionesNotificador, List<NotificacionModelo>>(
      () => NotificacionesNotificador(),
    );
