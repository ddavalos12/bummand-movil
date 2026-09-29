import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modelos/usuario-modelo.dart';
import '../repositorios/autenticacion-repositorio.dart';

final autenticacion_repositorio_proveedor = Provider<AutenticacionRepositorio>((ref) {
  return AutenticacionRepositorio();
});

// Alias
final authRepositorioProveedor = autenticacion_repositorio_proveedor;

class AutenticacionEstado {
  final bool cargando;
  final UsuarioModelo? usuario;
  final String? error;

  AutenticacionEstado({this.cargando = false, this.usuario, this.error});

  AutenticacionEstado copiarCon({
    bool? cargando,
    UsuarioModelo? usuario,
    String? error,
    bool limpiar_error = false,
  }) {
    return AutenticacionEstado(
      cargando: cargando ?? this.cargando,
      usuario: usuario ?? this.usuario,
      error: limpiar_error ? null : (error ?? this.error),
    );
  }
}

typedef AuthEstado = AutenticacionEstado;

class AutenticacionNotificador extends Notifier<AutenticacionEstado> {
  late final AutenticacionRepositorio _repositorio;

  @override
  AutenticacionEstado build() {
    _repositorio = ref.watch(autenticacion_repositorio_proveedor);
    return AutenticacionEstado();
  }

  Future<bool> iniciarSesion(String correo, String contrasena) async {
    state = state.copiarCon(cargando: true, limpiar_error: true);

    final resultado = await _repositorio.iniciarSesion(correo, contrasena);

    if (resultado.exito && resultado.datos != null) {
      state = state.copiarCon(cargando: false, usuario: resultado.datos);
      return true;
    } else {
      state = state.copiarCon(cargando: false, error: resultado.error);
      return false;
    }
  }

  Future<bool> registrar(String ci, String correo, String contrasena) async {
    state = state.copiarCon(cargando: true, limpiar_error: true);

    final resultado = await _repositorio.registrar(ci, correo, contrasena);

    if (resultado.exito && resultado.datos != null) {
      state = state.copiarCon(cargando: false, usuario: resultado.datos);
      return true;
    } else {
      state = state.copiarCon(cargando: false, error: resultado.error);
      return false;
    }
  }

  Future<void> cerrarSesion() async {
    await _repositorio.cerrarSesion();
    state = AutenticacionEstado();
  }
}

typedef AuthNotificador = AutenticacionNotificador;

final autenticacion_proveedor = NotifierProvider<AutenticacionNotificador, AutenticacionEstado>(() {
  return AutenticacionNotificador();
});

final authProveedor = autenticacion_proveedor;
