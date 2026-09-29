import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../nucleo/constantes/api-constantes.dart';
import '../../../nucleo/utilidades/resultado.dart';
import '../modelos/usuario-modelo.dart';

class AutenticacionRepositorio {
  static const String _CLAVE_TOKEN = 'token';
  static const String _CLAVE_USUARIO_ID = 'usuario_id';
  static const String _CLAVE_USUARIO_NOMBRE = 'usuario_nombre';
  static const String _CLAVE_USUARIO_ROL = 'usuario_rol';

  Future<Resultado<UsuarioModelo>> iniciarSesion(
    String correo,
    String contrasena,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_INICIO_SESION}',
      );
      final respuesta = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': correo, 'contrasena': contrasena}),
      );

      final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;

      if (respuesta.statusCode != 200 && respuesta.statusCode != 201) {
        return Resultado.fallido(datos['error'] ?? datos['message'] ?? 'Error al iniciar sesión');
      }

      final usuario = UsuarioModelo.desdeJson(datos);
      await _guardarSesion(usuario);
      return Resultado.exitoso(usuario);
    } catch (e) {
      return Resultado.fallido('No se pudo conectar con el servidor: $e');
    }
  }

  Future<Resultado<UsuarioModelo>> registrar(
    String ci,
    String correo,
    String contrasena,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_REGISTRO}',
      );
      final respuesta = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ci': ci,
          'correo': correo,
          'contrasena': contrasena,
        }),
      );

      final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;

      if (respuesta.statusCode != 201 && respuesta.statusCode != 200) {
        return Resultado.fallido(
          datos['error'] ?? datos['message'] ?? 'No se pudo crear la cuenta',
        );
      }

      final usuario = UsuarioModelo.desdeJson(datos);
      await _guardarSesion(usuario);
      return Resultado.exitoso(usuario);
    } catch (e) {
      return Resultado.fallido('No se pudo conectar con el servidor: $e');
    }
  }

  Future<void> _guardarSesion(UsuarioModelo usuario) async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setString(_CLAVE_TOKEN, usuario.token);
    await preferencias.setInt(_CLAVE_USUARIO_ID, usuario.id);
    await preferencias.setString(_CLAVE_USUARIO_NOMBRE, usuario.nombre);
    await preferencias.setString(_CLAVE_USUARIO_ROL, usuario.rol);
  }

  Future<void> cerrarSesion() async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.remove(_CLAVE_TOKEN);
    await preferencias.remove(_CLAVE_USUARIO_ID);
    await preferencias.remove(_CLAVE_USUARIO_NOMBRE);
    await preferencias.remove(_CLAVE_USUARIO_ROL);
  }

  Future<String?> obtenerToken() async {
    final preferencias = await SharedPreferences.getInstance();
    return preferencias.getString(_CLAVE_TOKEN);
  }
}
