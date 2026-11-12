import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../nucleo/servicios/cola-offline-servicio.dart';
import '../modelos/orden-confirmacion-modelo.dart';
import '../modelos/registro-auditoria-asistencia-modelo.dart';
import '../repositorios/asistencia-repositorio.dart';

final asistencia_repositorio_proveedor = Provider(
  (ref) {
    final cola = ref.watch(cola_offline_servicio_proveedor);
    return AsistenciaRepositorio(cola_offline: cola);
  },
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

final extractos_mensuales_proveedor =
    FutureProvider<List<ExtractoMensualAsistencia>>((ref) async {
  final repo = ref.read(asistencia_repositorio_proveedor);
  final resultado = await repo.obtenerExtractosMensuales();
  if (resultado.exito && resultado.datos != null) {
    return resultado.datos!;
  }
  return repo.generarExtractosLocales();
});

final extractosMensualesProveedor = extractos_mensuales_proveedor;

final extracto_mensual_proveedor =
    FutureProvider.family<ExtractoMensualAsistencia, String>((ref, mes) async {
  final repo = ref.read(asistencia_repositorio_proveedor);
  final resultado = await repo.obtenerExtractoMensual(mes: mes);
  if (resultado.exito && resultado.datos != null) {
    return resultado.datos!;
  }
  return repo.obtenerExtractoLocalPorMes(mes);
});

final extractoMensualProveedor = extracto_mensual_proveedor;

class AsistenciaNotificador extends AsyncNotifier<void> {
  AsistenciaRepositorio get _repo => ref.read(asistencia_repositorio_proveedor);

  @override
  FutureOr<void> build() {}

  Future<String?> registrarIngreso(
    String tipo, {
    Position? posicion,
    Map<String, dynamic>? lugar,
    int? evento_id,
    int? lugar_practica_id,
  }) async {
    state = const AsyncLoading();
    try {
      final pos = posicion ?? await _repo.obtenerPosicionActual();
      if (lugar != null && lugar["latitud"] != null && lugar["longitud"] != null) {
        final latitud = double.tryParse(lugar["latitud"].toString()) ?? 0.0;
        final longitud = double.tryParse(lugar["longitud"].toString()) ?? 0.0;
        final radio = double.tryParse(
          (lugar["radio_tolerancia_m"] ?? lugar["radioToleranciaM"] ?? 100).toString(),
        ) ?? 100.0;
        final dentro = _repo.validarGeocerca(
          posicion: pos,
          latitud_destino: latitud,
          longitud_destino: longitud,
          radio_tolerancia_m: radio,
        );
        if (!dentro) {
          state = const AsyncError("Fuera de rango", StackTrace.empty);
          return "Estás fuera del radio permitido para marcar ingreso";
        }
      }
      final id_lugar = lugar_practica_id ??
          (lugar?["id"] is int
              ? lugar!["id"] as int
              : int.tryParse((lugar?["id"] ?? lugar?["lugar_practica_id"] ?? '').toString()));
      final res = await _repo.registrarIngreso(
        tipo,
        pos,
        evento_id: evento_id,
        lugar_practica_id: id_lugar,
      );
      if (res.exito || res.error_bumand?.fueEncolado == true) {
        ref.invalidate(historial_asistencia_proveedor);
        ref.invalidate(cola_offline_conteo_proveedor);
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

  Future<String?> registrarSalida(
    String tipo, {
    Position? posicion,
    Map<String, dynamic>? lugar,
    int? evento_id,
    int? lugar_practica_id,
  }) async {
    state = const AsyncLoading();
    try {
      final pos = posicion ?? await _repo.obtenerPosicionActual();
      if (lugar != null && lugar["latitud"] != null && lugar["longitud"] != null) {
        final latitud = double.tryParse(lugar["latitud"].toString()) ?? 0.0;
        final longitud = double.tryParse(lugar["longitud"].toString()) ?? 0.0;
        final radio = double.tryParse(
          (lugar["radio_tolerancia_m"] ?? lugar["radioToleranciaM"] ?? 100).toString(),
        ) ?? 100.0;
        final dentro = _repo.validarGeocerca(
          posicion: pos,
          latitud_destino: latitud,
          longitud_destino: longitud,
          radio_tolerancia_m: radio,
        );
        if (!dentro) {
          state = const AsyncError("Fuera de rango", StackTrace.empty);
          return "Estás fuera del radio permitido para marcar salida";
        }
      }
      final id_lugar = lugar_practica_id ??
          (lugar?["id"] is int
              ? lugar!["id"] as int
              : int.tryParse((lugar?["id"] ?? lugar?["lugar_practica_id"] ?? '').toString()));
      final res = await _repo.registrarSalida(
        tipo,
        pos,
        evento_id: evento_id,
        lugar_practica_id: id_lugar,
      );
      if (res.exito || res.error_bumand?.fueEncolado == true) {
        ref.invalidate(historial_asistencia_proveedor);
        ref.invalidate(cola_offline_conteo_proveedor);
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
/// Registros de auditoría institucional de asistencia (paridad con
/// `AuditoriaAsistencia` de Web). Soporta aprobación por Administración,
/// revisión de Supervisor y refresco tras justificar.
class AuditoriaAsistenciaNotificador
    extends AsyncNotifier<List<RegistroAuditoriaAsistencia>> {
  AsistenciaRepositorio get _repo => ref.read(asistencia_repositorio_proveedor);

  @override
  Future<List<RegistroAuditoriaAsistencia>> build() async {
    final resultado = await _repo.obtenerRegistrosAuditoria();
    return resultado.datos ?? RegistroAuditoriaAsistencia.semillas();
  }

  Future<void> recargar() async {
    state = await AsyncValue.guard(() => build());
  }

  /// Actualiza tras radicar una justificación para el registro indicado.
  Future<void> actualizarTrasJustificar() async {
    // Los registros semilla viven solo en memoria: recargar descartaría las
    // aprobaciones locales, por lo que se conserva el estado actual.
    final actual = state.value;
    if (actual != null && actual.any((r) => r.es_semilla)) return;
    await recargar();
  }

  void _reemplazar(
    int id,
    RegistroAuditoriaAsistencia Function(RegistroAuditoriaAsistencia) cambio,
  ) {
    final actual = state.value;
    if (actual == null) return;
    state = AsyncData([
      for (final r in actual) r.id == id ? cambio(r) : r,
    ]);
  }

  /// Aprueba por Administración: elimina la multa (0 Bs) y deja el registro
  /// convalidado. Devuelve `null` si tuvo éxito o el mensaje de error.
  Future<String?> aprobarAdministracion(
    RegistroAuditoriaAsistencia registro, {
    String? observacion,
    String? nombre_administrador,
  }) async {
    final texto_observacion =
        observacion ?? 'Convalidado y aprobado por Administración';
    if (!registro.es_semilla) {
      final res = await _repo.aprobarAdministracion(
        registro.id,
        observacion: texto_observacion,
      );
      if (!res.exito) {
        return res.error ?? 'No se pudo aprobar por Administración';
      }
    }
    _reemplazar(
      registro.id,
      (r) => r.copiarCon(
        estado: RegistroAuditoriaAsistencia.ESTADO_CONVALIDADO,
        estado_aprobacion:
            RegistroAuditoriaAsistencia.ESTADO_APROBADO_ADMINISTRACION,
        monto_multa_bs: 0,
        convalidado_por: nombre_administrador ?? 'Administración Central',
        observacion_admin: texto_observacion,
      ),
    );
    return null;
  }

  /// Marca el registro como revisado por Supervisor (paso previo a Administración).
  Future<String?> revisarSupervisor(
    RegistroAuditoriaAsistencia registro, {
    String? observacion,
  }) async {
    if (!registro.es_semilla) {
      final res = await _repo.revisarSupervisor(
        registro.id,
        estado: RegistroAuditoriaAsistencia.ESTADO_REVISADO_SUPERVISOR,
        observacion: observacion,
      );
      if (!res.exito) {
        return res.error ?? 'No se pudo registrar la revisión del supervisor';
      }
    }
    _reemplazar(
      registro.id,
      (r) => r.copiarCon(
        estado: RegistroAuditoriaAsistencia.ESTADO_REVISADO_SUPERVISOR,
        estado_aprobacion:
            RegistroAuditoriaAsistencia.ESTADO_REVISADO_SUPERVISOR,
      ),
    );
    return null;
  }
}

final auditoria_asistencia_proveedor = AsyncNotifierProvider<
    AuditoriaAsistenciaNotificador, List<RegistroAuditoriaAsistencia>>(
  () => AuditoriaAsistenciaNotificador(),
);

final auditoriaAsistenciaProveedor = auditoria_asistencia_proveedor;

class OrdenConfirmacionNotificador extends Notifier<OrdenConfirmacionModelo> {
  @override
  OrdenConfirmacionModelo build() {
    return const OrdenConfirmacionModelo(
      activa: true,
      confirmada_este_mes: false,
      periodo: 'Octubre 2026',
      mensaje_admin:
          'Administración central requiere la confirmación mensual de tus datos de contacto.',
    );
  }

  void marcarConfirmado() {
    state = state.copiarCon(confirmada_este_mes: true);
  }

  void desactivarOrden() {
    state = state.copiarCon(activa: false);
  }

  void activarOrden(String periodo, String mensaje) {
    state = OrdenConfirmacionModelo(
      activa: true,
      confirmada_este_mes: false,
      periodo: periodo,
      mensaje_admin: mensaje,
    );
  }
}

final orden_confirmacion_proveedor =
    NotifierProvider<OrdenConfirmacionNotificador, OrdenConfirmacionModelo>(
  () => OrdenConfirmacionNotificador(),
);

final ordenConfirmacionProveedor = orden_confirmacion_proveedor;
