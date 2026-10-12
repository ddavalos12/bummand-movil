import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/servicios/cola-offline-servicio.dart';
import '../../../nucleo/utilidades/resultado.dart';
import '../modelos/versiculo-diario-modelo.dart';
import '../repositorios/devocionales-repositorio.dart';
import '../servicios/cola-descarga-biblia-servicio.dart';

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

