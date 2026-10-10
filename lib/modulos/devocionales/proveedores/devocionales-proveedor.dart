import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/servicios/cola-offline-servicio.dart';
import '../../../nucleo/utilidades/resultado.dart';
import '../repositorios/devocionales-repositorio.dart';

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
