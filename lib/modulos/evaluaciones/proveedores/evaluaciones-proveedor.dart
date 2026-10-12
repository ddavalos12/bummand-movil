import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/utilidades/resultado.dart';
import '../../autenticacion/proveedores/autenticacion-proveedor.dart';
import '../modelos/evaluacion-modelo.dart';
import '../repositorios/evaluaciones-repositorio.dart';

final evaluaciones_repositorio_proveedor =
    Provider<EvaluacionesRepositorio>((ref) {
  return EvaluacionesRepositorio();
});

final evaluacion_consolidada_proveedor =
    FutureProvider.autoDispose<Resultado<EvaluacionConsolidadaModelo>>((ref) async {
  final repo = ref.watch(evaluaciones_repositorio_proveedor);
  final auth = ref.watch(autenticacion_proveedor);
  final becario_id = auth.usuario?.id ?? 1;

  return repo.obtenerEvaluacionConsolidada(becario_id: becario_id);
});
