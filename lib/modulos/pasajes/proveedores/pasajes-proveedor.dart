import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modelos/solicitud-pasaje-modelo.dart';
import '../repositorios/pasajes-repositorio.dart';

final pasajes_repositorio_proveedor = Provider((ref) => PasajesRepositorio());
final pasajesRepositorioProveedor = pasajes_repositorio_proveedor;

final solicitudes_pasajes_proveedor =
    AsyncNotifierProvider<
      SolicitudesPasajesNotificador,
      List<SolicitudPasajeModelo>
    >(() {
      return SolicitudesPasajesNotificador();
    });

final solicitudesPasajesProveedor = solicitudes_pasajes_proveedor;

class SolicitudesPasajesNotificador
    extends AsyncNotifier<List<SolicitudPasajeModelo>> {
  late final PasajesRepositorio _repositorio;

  @override
  Future<List<SolicitudPasajeModelo>> build() async {
    _repositorio = ref.watch(pasajes_repositorio_proveedor);
    return await _cargarSolicitudesInterno();
  }

  Future<List<SolicitudPasajeModelo>> _cargarSolicitudesInterno() async {
    final resultado = await _repositorio.misSolicitudes();
    if (resultado.exito && resultado.datos != null) {
      return resultado.datos!;
    } else {
      throw Exception(resultado.error ?? 'Error desconocido');
    }
  }

  Future<void> cargarSolicitudes() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _cargarSolicitudesInterno());
  }

  Future<ResultadoPasaje<void>> eliminarRecorrido(int id) async {
    final resultado = await _repositorio.eliminarRecorrido(id);
    if (resultado.exito) {
      await cargarSolicitudes();
    }
    return resultado;
  }

  Future<ResultadoPasaje<void>> enviarSolicitud(int solicitud_id) async {
    final resultado = await _repositorio.enviar(solicitud_id);
    if (resultado.exito) {
      await cargarSolicitudes();
    }
    return resultado;
  }
}

typedef SolicitudesPasajesNotifier = SolicitudesPasajesNotificador;
