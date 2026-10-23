import 'package:flutter_riverpod/flutter_riverpod.dart';

class PestanaInicioNotificador extends Notifier<int> {
  @override
  int build() => 0;

  void cambiarPestana(int nuevo_indice) {
    state = nuevo_indice;
  }
}

final pestana_inicio_proveedor =
    NotifierProvider<PestanaInicioNotificador, int>(
  PestanaInicioNotificador.new,
);
