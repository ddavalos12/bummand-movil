import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/utilidades/resultado.dart';
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

  const AutenticacionEstado({this.cargando = false, this.usuario, this.error});

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
  AutenticacionRepositorio get _repositorio =>
      ref.read(autenticacion_repositorio_proveedor);

  @override
  AutenticacionEstado build() {
    return const AutenticacionEstado();
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

  Future<Resultado<Map<String, dynamic>>> verificarCi(String ci) async {
    return _repositorio.verificarCi(ci);
  }

  Future<void> verificarSesionExistente() async {
    final usuario_guardado = await _repositorio.obtenerSesionActual();
    if (usuario_guardado != null) {
      state = state.copiarCon(usuario: usuario_guardado);
    }
  }

  Future<Resultado<UsuarioModelo>> actualizarMiPerfil({
    required String nombre,
    String? telefono,
    String? direccion,
    String? carrera,
    String? semestre,
  }) async {
    state = state.copiarCon(cargando: true, limpiar_error: true);
    final resultado = await _repositorio.actualizarMiPerfil(
      nombre: nombre,
      telefono: telefono,
      direccion: direccion,
      carrera: carrera,
      semestre: semestre,
    );
    if (resultado.exito && resultado.datos != null) {
      state = state.copiarCon(cargando: false, usuario: resultado.datos);
    } else {
      state = state.copiarCon(cargando: false, error: resultado.error);
    }
    return resultado;
  }

  Future<Resultado<String>> actualizarCorreoAlternativo(
    String correo_alternativo,
  ) async {
    final resultado = await _repositorio.actualizarCorreoAlternativo(
      correo_alternativo,
    );
    if (resultado.exito) {
      await verificarSesionExistente();
      if (state.usuario != null) {
        final correo_limpio = correo_alternativo.trim().toLowerCase();
        final lista_actual = List<String>.from(
          state.usuario!.correos_adicionales,
        );
        if (!lista_actual.contains(correo_limpio)) {
          lista_actual.add(correo_limpio);
        }
        state = state.copiarCon(
          usuario: state.usuario!.copiarCon(
            correo_alternativo: correo_limpio,
            correos_adicionales: lista_actual,
          ),
        );
      }
    }
    return resultado;
  }

  Future<Resultado<Map<String, dynamic>>> vincularCorreoAlternativo({
    required String correo,
    String etiqueta = 'Personal',
  }) async {
    final resultado = await _repositorio.vincularCorreoAlternativo(
      correo: correo,
      etiqueta: etiqueta,
    );
    if (resultado.exito && state.usuario != null) {
      final correo_limpio = correo.trim().toLowerCase();
      final lista_actual = List<String>.from(state.usuario!.correos_adicionales);
      if (!lista_actual.contains(correo_limpio)) {
        lista_actual.add(correo_limpio);
      }
      state = state.copiarCon(
        usuario: state.usuario!.copiarCon(
          correo_alternativo: state.usuario!.correo_alternativo ?? correo_limpio,
          correos_adicionales: lista_actual,
        ),
      );
    }
    return resultado;
  }

  Future<Resultado<Map<String, dynamic>>> desvincularCorreoAlternativo({
    required int correo_id,
    required String correo,
  }) async {
    final resultado = await _repositorio.desvincularCorreoAlternativo(
      correo_id: correo_id,
      correo: correo,
    );
    if (resultado.exito && state.usuario != null) {
      final correo_limpio = correo.trim().toLowerCase();
      final lista_actual = List<String>.from(state.usuario!.correos_adicionales);
      lista_actual.remove(correo_limpio);
      final alt = state.usuario!.correo_alternativo == correo_limpio
          ? (lista_actual.isNotEmpty ? lista_actual.first : null)
          : state.usuario!.correo_alternativo;
      state = state.copiarCon(
        usuario: state.usuario!.copiarCon(
          correo_alternativo: alt,
          correos_adicionales: lista_actual,
        ),
      );
    }
    return resultado;
  }

  Future<Resultado<String>> cambiarMiContrasena({
    required String contrasena_actual,
    required String nueva_contrasena,
  }) async {
    return _repositorio.cambiarMiContrasena(
      contrasena_actual: contrasena_actual,
      nueva_contrasena: nueva_contrasena,
    );
  }

  void limpiarError() {
    state = state.copiarCon(limpiar_error: true);
  }

  Future<void> cerrarSesion() async {
    await _repositorio.cerrarSesion();
    state = const AutenticacionEstado();
  }
}

typedef AuthNotificador = AutenticacionNotificador;

final autenticacion_proveedor = NotifierProvider<AutenticacionNotificador, AutenticacionEstado>(() {
  return AutenticacionNotificador();
});

final authProveedor = autenticacion_proveedor;

final usuarios_admin_proveedor = FutureProvider.autoDispose.family<Resultado<List<Map<String, dynamic>>>, String?>((ref, rol) {
  final repo = ref.watch(autenticacion_repositorio_proveedor);
  return repo.listarUsuariosInstitucionales(rol: rol);
});
