import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../nucleo/constantes/api-constantes.dart';
import '../../../nucleo/utilidades/resultado.dart';
import '../modelos/usuario-modelo.dart';

class AutenticacionRepositorio {
  final http.Client _cliente_http;

  AutenticacionRepositorio({http.Client? cliente_http})
      : _cliente_http = cliente_http ?? http.Client();

  static const String _CLAVE_TOKEN = 'token';
  static const String _CLAVE_USUARIO_ID = 'usuario_id';
  static const String _CLAVE_USUARIO_NOMBRE = 'usuario_nombre';
  static const String _CLAVE_USUARIO_CORREO = 'usuario_correo';
  static const String _CLAVE_USUARIO_ROL = 'usuario_rol';

  Future<Resultado<UsuarioModelo>> iniciarSesion(
    String correo,
    String contrasena,
  ) async {
    final correo_limpio = correo.trim();
    if (correo_limpio.isEmpty) {
      return Resultado.fallido('El correo electrónico es requerido');
    }
    if (contrasena.isEmpty) {
      return Resultado.fallido('La contraseña es requerida');
    }

    try {
      final url = Uri.parse(
        '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_INICIO_SESION}',
      );
      final respuesta = await _cliente_http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo_limpio, 'contrasena': contrasena}),
      );

      final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;

      if (respuesta.statusCode != 200 && respuesta.statusCode != 201) {
        final mensaje_error =
            datos['mensaje'] ?? datos['error'] ?? datos['message'] ?? 'Credenciales inválidas';
        return Resultado.fallido(mensaje_error.toString());
      }

      final usuario = UsuarioModelo.desdeJson(datos);
      await _guardarSesion(usuario);
      return Resultado.exitoso(usuario);
    } catch (error_capturado) {
      return Resultado.fallido('No se pudo conectar con el servidor: $error_capturado');
    }
  }

  Future<Resultado<UsuarioModelo>> registrar(
    String ci,
    String correo,
    String contrasena,
  ) async {
    final ci_limpio = ci.trim();
    final correo_limpio = correo.trim();

    if (ci_limpio.isEmpty) {
      return Resultado.fallido('El documento de identidad es requerido');
    }
    if (correo_limpio.isEmpty) {
      return Resultado.fallido('El correo electrónico es requerido');
    }
    if (contrasena.length < 6) {
      return Resultado.fallido('La contraseña debe tener al menos 6 caracteres');
    }

    try {
      final url = Uri.parse(
        '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_REGISTRO}',
      );
      final respuesta = await _cliente_http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ci': ci_limpio,
          'correo': correo_limpio,
          'contrasena': contrasena,
        }),
      );

      final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;

      if (respuesta.statusCode != 201 && respuesta.statusCode != 200) {
        final mensaje_error =
            datos['mensaje'] ?? datos['error'] ?? datos['message'] ?? 'No se pudo crear la cuenta';
        return Resultado.fallido(mensaje_error.toString());
      }

      final usuario = UsuarioModelo.desdeJson(datos);
      await _guardarSesion(usuario);
      return Resultado.exitoso(usuario);
    } catch (error_capturado) {
      return Resultado.fallido('No se pudo conectar con el servidor: $error_capturado');
    }
  }

  Future<void> _guardarSesion(UsuarioModelo usuario) async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setString(_CLAVE_TOKEN, usuario.token);
    await preferencias.setInt(_CLAVE_USUARIO_ID, usuario.id);
    await preferencias.setString(_CLAVE_USUARIO_NOMBRE, usuario.nombre);
    await preferencias.setString(_CLAVE_USUARIO_CORREO, usuario.correo);
    await preferencias.setString(_CLAVE_USUARIO_ROL, usuario.rol);
  }

  Future<void> cerrarSesion() async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.remove(_CLAVE_TOKEN);
    await preferencias.remove(_CLAVE_USUARIO_ID);
    await preferencias.remove(_CLAVE_USUARIO_NOMBRE);
    await preferencias.remove(_CLAVE_USUARIO_CORREO);
    await preferencias.remove(_CLAVE_USUARIO_ROL);
  }

  Future<String?> obtenerToken() async {
    final preferencias = await SharedPreferences.getInstance();
    return preferencias.getString(_CLAVE_TOKEN);
  }

  Future<String?> obtenerRol() async {
    final preferencias = await SharedPreferences.getInstance();
    return preferencias.getString(_CLAVE_USUARIO_ROL);
  }

  Future<UsuarioModelo?> obtenerSesionActual() async {
    final preferencias = await SharedPreferences.getInstance();
    final token = preferencias.getString(_CLAVE_TOKEN);
    final rol = preferencias.getString(_CLAVE_USUARIO_ROL);

    if (token == null || token.isEmpty || rol == null || rol.isEmpty) {
      return null;
    }

    final id = preferencias.getInt(_CLAVE_USUARIO_ID) ?? 0;
    final nombre = preferencias.getString(_CLAVE_USUARIO_NOMBRE) ?? '';
    final correo = preferencias.getString(_CLAVE_USUARIO_CORREO) ?? '';

    return UsuarioModelo(
      id: id,
      nombre: nombre,
      correo: correo,
      rol: rol,
      token: token,
    );
  }

  Future<bool> estaAutenticado() async {
    final token = await obtenerToken();
    return token != null && token.isNotEmpty;
  }
}
