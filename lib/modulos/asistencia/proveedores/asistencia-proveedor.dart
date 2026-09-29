import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositorios/asistencia-repositorio.dart';

final asistencia_repositorio_proveedor = Provider(
  (ref) => AsistenciaRepositorio(),
);

final asistenciaRepositorioProveedor = asistencia_repositorio_proveedor;

final perfil_proveedor = FutureProvider((ref) {
  final repo = ref.read(asistencia_repositorio_proveedor);
  return repo.obtenerPerfil();
});

final perfilProveedor = perfil_proveedor;

final historial_asistencia_proveedor = FutureProvider((ref) {
  final repo = ref.read(asistencia_repositorio_proveedor);
  return repo.obtenerHistorial();
});

final historialAsistenciaProveedor = historial_asistencia_proveedor;

class AsistenciaNotificador extends AsyncNotifier<void> {
  late final AsistenciaRepositorio _repo;

  @override
  FutureOr<void> build() {
    _repo = ref.read(asistencia_repositorio_proveedor);
  }

  Future<String?> registrarIngreso(String tipo) async {
    state = const AsyncLoading();
    try {
      final pos = await _repo.obtenerPosicionActual();
      final res = await _repo.registrarIngreso(tipo, pos);
      if (res.exito) {
        ref.invalidate(historial_asistencia_proveedor);
        state = const AsyncData(null);
        return null;
      }
      state = AsyncError(res.error ?? "Error", StackTrace.current);
      return res.error;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }

  Future<String?> registrarSalida(String tipo) async {
    state = const AsyncLoading();
    try {
      final pos = await _repo.obtenerPosicionActual();
      final res = await _repo.registrarSalida(tipo, pos);
      if (res.exito) {
        ref.invalidate(historial_asistencia_proveedor);
        state = const AsyncData(null);
        return null;
      }
      state = AsyncError(res.error ?? "Error", StackTrace.current);
      return res.error;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }

  Future<String?> actualizarPerfil(Map<String, dynamic> datos) async {
    state = const AsyncLoading();
    try {
      final res = await _repo.actualizarPerfil(datos);
      if (res.exito) {
        ref.invalidate(perfil_proveedor);
        state = const AsyncData(null);
        return null;
      }
      state = AsyncError(res.error ?? "Error", StackTrace.current);
      return res.error;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }

  Future<String?> confirmarDatosPasajes(String periodo) async {
    state = const AsyncLoading();
    try {
      final res = await _repo.confirmarDatosPasajes(periodo);
      if (res.exito) {
        ref.invalidate(perfil_proveedor);
        state = const AsyncData(null);
        return null;
      }
      state = AsyncError(res.error ?? "Error", StackTrace.current);
      return res.error;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return e.toString();
    }
  }
}

final asistencia_notificador_proveedor =
    AsyncNotifierProvider<AsistenciaNotificador, void>(
      () => AsistenciaNotificador(),
    );

final asistenciaNotificadorProveedor = asistencia_notificador_proveedor;
