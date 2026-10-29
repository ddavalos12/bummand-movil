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
  static const String _CLAVE_USUARIO_CORREO_ALTERNATIVO =
      'usuario_correo_alternativo';
  static const String _CLAVE_USUARIO_CORREOS_ADICIONALES =
      'usuario_correos_adicionales';
  static const String _CLAVE_USUARIO_TELEFONO = 'usuario_telefono';
  static const String _CLAVE_USUARIO_DIRECCION = 'usuario_direccion';
  static const String _CLAVE_USUARIO_CARRERA = 'usuario_carrera';
  static const String _CLAVE_USUARIO_SEMESTRE = 'usuario_semestre';
  static const String _CLAVE_USUARIO_CI = 'usuario_ci';
  static const String _CLAVE_USUARIO_UNIVERSIDAD = 'usuario_universidad';
  static const String _CLAVE_USUARIO_ESTADO = 'usuario_estado';

  static const List<String> _ROLES_PERMITIDOS_MOVIL = [
    'becario',
    'supervisor',
    'administrador',
  ];

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
      final rol_normalizado = usuario.rol.toLowerCase().trim();
      if (!_ROLES_PERMITIDOS_MOVIL.contains(rol_normalizado)) {
        return Resultado.fallido(
          'Tu rol actual no tiene permisos para acceder a la aplicación móvil.',
        );
      }
      await _guardarSesion(usuario);
      return Resultado.exitoso(usuario);
    } catch (error_capturado) {
      return Resultado.fallido('No se pudo conectar con el servidor: $error_capturado');
    }
  }

  Future<Resultado<Map<String, dynamic>>> verificarCi(String ci) async {
    final ci_limpio = ci.trim();
    if (ci_limpio.isEmpty) {
      return Resultado.fallido('El documento de identidad es requerido');
    }

    try {
      final url = Uri.parse(
        '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_VERIFICAR_CI}/$ci_limpio',
      );
      final respuesta = await _cliente_http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
      if (respuesta.statusCode != 200) {
        final mensaje_error =
            datos['mensaje'] ?? datos['error'] ?? datos['message'] ?? 'Error al verificar el C.I.';
        return Resultado.fallido(mensaje_error.toString());
      }

      return Resultado.exitoso(datos);
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
    if (usuario.correo_alternativo != null &&
        usuario.correo_alternativo!.isNotEmpty) {
      await preferencias.setString(
        _CLAVE_USUARIO_CORREO_ALTERNATIVO,
        usuario.correo_alternativo!,
      );
    } else {
      await preferencias.remove(_CLAVE_USUARIO_CORREO_ALTERNATIVO);
    }
    await preferencias.setStringList(
      _CLAVE_USUARIO_CORREOS_ADICIONALES,
      usuario.correos_adicionales,
    );
    if (usuario.telefono != null) {
      await preferencias.setString(_CLAVE_USUARIO_TELEFONO, usuario.telefono!);
    }
    if (usuario.direccion != null) {
      await preferencias.setString(_CLAVE_USUARIO_DIRECCION, usuario.direccion!);
    }
    if (usuario.carrera != null) {
      await preferencias.setString(_CLAVE_USUARIO_CARRERA, usuario.carrera!);
    }
    if (usuario.semestre != null) {
      await preferencias.setString(_CLAVE_USUARIO_SEMESTRE, usuario.semestre!);
    }
    if (usuario.ci != null) {
      await preferencias.setString(_CLAVE_USUARIO_CI, usuario.ci!);
    }
    if (usuario.universidad != null) {
      await preferencias.setString(_CLAVE_USUARIO_UNIVERSIDAD, usuario.universidad!);
    }
    await preferencias.setString(_CLAVE_USUARIO_ESTADO, usuario.estado);
  }

  Future<void> cerrarSesion() async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.remove(_CLAVE_TOKEN);
    await preferencias.remove(_CLAVE_USUARIO_ID);
    await preferencias.remove(_CLAVE_USUARIO_NOMBRE);
    await preferencias.remove(_CLAVE_USUARIO_CORREO);
    await preferencias.remove(_CLAVE_USUARIO_ROL);
    await preferencias.remove(_CLAVE_USUARIO_CORREO_ALTERNATIVO);
    await preferencias.remove(_CLAVE_USUARIO_CORREOS_ADICIONALES);
    await preferencias.remove(_CLAVE_USUARIO_TELEFONO);
    await preferencias.remove(_CLAVE_USUARIO_DIRECCION);
    await preferencias.remove(_CLAVE_USUARIO_CARRERA);
    await preferencias.remove(_CLAVE_USUARIO_SEMESTRE);
    await preferencias.remove(_CLAVE_USUARIO_CI);
    await preferencias.remove(_CLAVE_USUARIO_UNIVERSIDAD);
    await preferencias.remove(_CLAVE_USUARIO_ESTADO);
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

    final rol_normalizado = rol.toLowerCase().trim();
    if (!_ROLES_PERMITIDOS_MOVIL.contains(rol_normalizado)) {
      await cerrarSesion();
      return null;
    }

    final id = preferencias.getInt(_CLAVE_USUARIO_ID) ?? 0;
    final nombre = preferencias.getString(_CLAVE_USUARIO_NOMBRE) ?? '';
    final correo = preferencias.getString(_CLAVE_USUARIO_CORREO) ?? '';
    final correo_alternativo =
        preferencias.getString(_CLAVE_USUARIO_CORREO_ALTERNATIVO);
    final correos_adicionales =
        preferencias.getStringList(_CLAVE_USUARIO_CORREOS_ADICIONALES) ??
            const [];
    final telefono = preferencias.getString(_CLAVE_USUARIO_TELEFONO);
    final direccion = preferencias.getString(_CLAVE_USUARIO_DIRECCION);
    final carrera = preferencias.getString(_CLAVE_USUARIO_CARRERA);
    final semestre = preferencias.getString(_CLAVE_USUARIO_SEMESTRE);
    final ci = preferencias.getString(_CLAVE_USUARIO_CI);
    final universidad = preferencias.getString(_CLAVE_USUARIO_UNIVERSIDAD);
    final estado = preferencias.getString(_CLAVE_USUARIO_ESTADO) ?? 'activo';

    return UsuarioModelo(
      id: id,
      nombre: nombre,
      correo: correo,
      rol: rol,
      token: token,
      correo_alternativo: correo_alternativo,
      correos_adicionales: correos_adicionales,
      telefono: telefono,
      direccion: direccion,
      carrera: carrera,
      semestre: semestre,
      ci: ci,
      universidad: universidad,
      estado: estado,
    );
  }

  Future<Resultado<UsuarioModelo>> actualizarMiPerfil({
    required String nombre,
    String? telefono,
    String? direccion,
    String? carrera,
    String? semestre,
  }) async {
    final nombre_limpio = nombre.trim();
    if (nombre_limpio.isEmpty) {
      return Resultado.fallido('El nombre completo es obligatorio');
    }

    final token = await obtenerToken();
    final sesion_actual = await obtenerSesionActual();

    // Actualización local resiliente en preferencias siempre
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setString(_CLAVE_USUARIO_NOMBRE, nombre_limpio);
    if (telefono != null) await preferencias.setString(_CLAVE_USUARIO_TELEFONO, telefono.trim());
    if (direccion != null) await preferencias.setString(_CLAVE_USUARIO_DIRECCION, direccion.trim());
    if (carrera != null) await preferencias.setString(_CLAVE_USUARIO_CARRERA, carrera.trim());
    if (semestre != null) await preferencias.setString(_CLAVE_USUARIO_SEMESTRE, semestre.trim());

    final usuario_actualizado = (sesion_actual ?? UsuarioModelo(
      id: 0,
      nombre: nombre_limpio,
      correo: '',
      rol: 'becario',
      token: token ?? '',
    )).copiarCon(
      nombre: nombre_limpio,
      telefono: telefono?.trim(),
      direccion: direccion?.trim(),
      carrera: carrera?.trim(),
      semestre: semestre?.trim(),
    );

    if (token != null && token.isNotEmpty) {
      try {
        final encabezados = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };
        final cuerpo = jsonEncode({
          'nombre': nombre_limpio,
          if (telefono != null) 'telefono': telefono.trim(),
          if (direccion != null) 'direccion': direccion.trim(),
          if (carrera != null) 'carrera': carrera.trim(),
          if (semestre != null) 'semestre': semestre.trim(),
        });

        // Intentar PATCH /api/usuarios/mi-perfil
        final url_patch = Uri.parse('${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_USUARIOS_MI_PERFIL}');
        final resp = await _cliente_http.patch(url_patch, headers: encabezados, body: cuerpo);

        if (resp.statusCode == 200 || resp.statusCode == 201) {
          final datos = jsonDecode(resp.body) as Map<String, dynamic>;
          final usuario_servidor = UsuarioModelo.desdeJson(datos).copiarCon(token: token);
          await _guardarSesion(usuario_servidor);
          return Resultado.exitoso(usuario_servidor);
        } else if (resp.statusCode == 404) {
          // Fallback
          final url_alt = Uri.parse('${ApiConstantes.RUTA_BASE}/usuarios/mi-perfil');
          await _cliente_http.patch(url_alt, headers: encabezados, body: cuerpo);
        }
      } catch (_) {
        // Fallback local resiliente: persiste localmente si el servidor no responde
      }
    }

    return Resultado.exitoso(usuario_actualizado);
  }

  Future<Resultado<Map<String, dynamic>>> listarMisCorreos() async {
    final token = await obtenerToken();
    final usuario = await obtenerSesionActual();

    if (token != null && token.isNotEmpty) {
      try {
        final encabezados = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };
        final url = Uri.parse('${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_USUARIOS_MI_PERFIL_CORREOS}');
        final resp = await _cliente_http.get(url, headers: encabezados);

        if (resp.statusCode == 200) {
          final datos = jsonDecode(resp.body) as Map<String, dynamic>;
          return Resultado.exitoso(datos);
        }
      } catch (_) {
        // Fallback offline
      }
    }

    final mapa_local = {
      'correo_principal': usuario?.correo ?? '',
      'correo_alternativo': usuario?.correo_alternativo,
      'correos_adicionales': (usuario?.correos_adicionales ?? [])
          .asMap()
          .entries
          .map((e) => {'id': e.key + 1, 'correo': e.value, 'etiqueta': 'Personal'})
          .toList(),
    };
    return Resultado.exitoso(mapa_local);
  }

  Future<Resultado<Map<String, dynamic>>> vincularCorreoAlternativo({
    required String correo,
    String etiqueta = 'Personal',
  }) async {
    final correo_limpio = correo.trim().toLowerCase();
    if (!correo_limpio.contains('@') || !correo_limpio.contains('.')) {
      return Resultado.fallido('Ingresa un correo electrónico válido');
    }

    final token = await obtenerToken();
    final usuario = await obtenerSesionActual();

    // Actualizar preferencias locales
    final preferencias = await SharedPreferences.getInstance();
    final actuales = List<String>.from(
      preferencias.getStringList(_CLAVE_USUARIO_CORREOS_ADICIONALES) ?? const [],
    );
    if (!actuales.contains(correo_limpio)) {
      actuales.add(correo_limpio);
      await preferencias.setStringList(_CLAVE_USUARIO_CORREOS_ADICIONALES, actuales);
    }
    if (usuario?.correo_alternativo == null || usuario!.correo_alternativo!.isEmpty) {
      await preferencias.setString(_CLAVE_USUARIO_CORREO_ALTERNATIVO, correo_limpio);
    }

    if (token != null && token.isNotEmpty) {
      try {
        final encabezados = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };
        final url = Uri.parse('${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_USUARIOS_MI_PERFIL_CORREOS}');
        final resp = await _cliente_http.post(
          url,
          headers: encabezados,
          body: jsonEncode({'correo': correo_limpio, 'etiqueta': etiqueta}),
        );
        if (resp.statusCode == 200 || resp.statusCode == 201) {
          final datos = jsonDecode(resp.body) as Map<String, dynamic>;
          return Resultado.exitoso(datos);
        } else {
          final datos = jsonDecode(resp.body);
          final mensaje = datos['mensaje'] ?? datos['message'] ?? 'Error al vincular correo';
          return Resultado.fallido(mensaje.toString());
        }
      } catch (_) {
        // Fallback local exitoso si no hay red
      }
    }

    return Resultado.exitoso({
      'correo_principal': usuario?.correo ?? '',
      'correo_alternativo': correo_limpio,
      'correos_adicionales': actuales.asMap().entries.map((e) => {'id': e.key + 1, 'correo': e.value, 'etiqueta': etiqueta}).toList(),
    });
  }

  Future<Resultado<Map<String, dynamic>>> desvincularCorreoAlternativo({
    required int correo_id,
    required String correo,
  }) async {
    final correo_limpio = correo.trim().toLowerCase();
    final token = await obtenerToken();

    final preferencias = await SharedPreferences.getInstance();
    final actuales = List<String>.from(
      preferencias.getStringList(_CLAVE_USUARIO_CORREOS_ADICIONALES) ?? const [],
    );
    actuales.remove(correo_limpio);
    await preferencias.setStringList(_CLAVE_USUARIO_CORREOS_ADICIONALES, actuales);

    final alt_actual = preferencias.getString(_CLAVE_USUARIO_CORREO_ALTERNATIVO);
    if (alt_actual == correo_limpio) {
      if (actuales.isNotEmpty) {
        await preferencias.setString(_CLAVE_USUARIO_CORREO_ALTERNATIVO, actuales.first);
      } else {
        await preferencias.remove(_CLAVE_USUARIO_CORREO_ALTERNATIVO);
      }
    }

    if (token != null && token.isNotEmpty && correo_id > 0) {
      try {
        final encabezados = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };
        final url = Uri.parse('${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_USUARIOS_MI_PERFIL_CORREOS}/$correo_id');
        await _cliente_http.delete(url, headers: encabezados);
      } catch (_) {}
    }

    return listarMisCorreos();
  }

  Future<Resultado<String>> cambiarMiContrasena({
    required String contrasena_actual,
    required String nueva_contrasena,
  }) async {
    if (nueva_contrasena.length < 6) {
      return Resultado.fallido('La nueva contraseña debe tener al menos 6 caracteres');
    }

    final token = await obtenerToken();
    if (token == null || token.isEmpty) {
      return Resultado.fallido('Sesión no encontrada');
    }

    try {
      final encabezados = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final url = Uri.parse('${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_USUARIOS_MI_PERFIL_CONTRASENA}');
      final resp = await _cliente_http.patch(
        url,
        headers: encabezados,
        body: jsonEncode({
          'contrasena_actual': contrasena_actual,
          'nueva_contrasena': nueva_contrasena,
        }),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return Resultado.exitoso('Contraseña actualizada exitosamente');
      } else {
        final datos = jsonDecode(resp.body);
        final mensaje = datos['mensaje'] ?? datos['message'] ?? 'Error al actualizar contraseña';
        return Resultado.fallido(mensaje.toString());
      }
    } catch (e) {
      return Resultado.fallido('Error de conexión con el servidor: $e');
    }
  }

  Future<Resultado<String>> actualizarCorreoAlternativo(
    String correo_alternativo,
  ) async {
    final correo_limpio = correo_alternativo.trim().toLowerCase();
    if (correo_limpio.isEmpty ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(correo_limpio)) {
      return Resultado.fallido(
        'Ingresa un correo electrónico alternativo válido',
      );
    }

    final preferencias = await SharedPreferences.getInstance();
    final token = preferencias.getString(_CLAVE_TOKEN);

    if (token != null && token.isNotEmpty) {
      try {
        final encabezados = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };
        final url_patch = Uri.parse(
          '${ApiConstantes.RUTA_BASE}/usuarios/mi-perfil/correo-alternativo',
        );
        final resp_patch = await _cliente_http.patch(
          url_patch,
          headers: encabezados,
          body: jsonEncode({'correo_alternativo': correo_limpio}),
        );

        final url_post = Uri.parse(
          '${ApiConstantes.RUTA_BASE}/usuarios/mi-perfil/correos',
        );
        await _cliente_http.post(
          url_post,
          headers: encabezados,
          body: jsonEncode({'correo': correo_limpio}),
        );

        if (resp_patch.statusCode >= 400 && resp_patch.statusCode != 404) {
          final cuerpo = jsonDecode(resp_patch.body);
          final mensaje_err = cuerpo['mensaje'] ??
              cuerpo['message'] ??
              'No se pudo actualizar el correo alternativo';
          return Resultado.fallido(mensaje_err.toString());
        }
      } catch (_) {
        // Permite persistencia local si el servidor no responde
      }
    }

    await preferencias.setString(
      _CLAVE_USUARIO_CORREO_ALTERNATIVO,
      correo_limpio,
    );
    final actuales = List<String>.from(
      preferencias.getStringList(_CLAVE_USUARIO_CORREOS_ADICIONALES) ?? const [],
    );
    if (!actuales.contains(correo_limpio)) {
      actuales.add(correo_limpio);
    }
    await preferencias.setStringList(
      _CLAVE_USUARIO_CORREOS_ADICIONALES,
      actuales,
    );

    return Resultado.exitoso('Correo alternativo actualizado correctamente');
  }

  // --- MÉTODOS DE ADMINISTRACIÓN DE USUARIOS ---

  Future<Resultado<List<Map<String, dynamic>>>> listarUsuariosInstitucionales({String? rol}) async {
    final token = await obtenerToken();
    if (token == null || token.isEmpty) {
      return Resultado.fallido('Sesión no encontrada');
    }

    try {
      final url_str = rol != null && rol.isNotEmpty
          ? '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_USUARIOS}?rol=$rol'
          : '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_USUARIOS}';
      final resp = await _cliente_http.get(
        Uri.parse(url_str),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (resp.statusCode == 200) {
        final lista = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
        return Resultado.exitoso(lista);
      } else {
        final datos = jsonDecode(resp.body);
        return Resultado.fallido(datos['mensaje']?.toString() ?? 'Error al listar usuarios');
      }
    } catch (e) {
      return Resultado.fallido('Error al conectar con el servidor: $e');
    }
  }

  Future<Resultado<Map<String, dynamic>>> crearUsuarioInstitucional({
    required String nombre,
    required String correo,
    required String contrasena,
    required String rol,
  }) async {
    final token = await obtenerToken();
    if (token == null || token.isEmpty) {
      return Resultado.fallido('Sesión no encontrada');
    }

    try {
      final url = Uri.parse('${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_USUARIOS}');
      final resp = await _cliente_http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nombre': nombre.trim(),
          'correo': correo.trim().toLowerCase(),
          'contrasena': contrasena,
          'rol': rol.trim().toLowerCase(),
        }),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final datos = jsonDecode(resp.body) as Map<String, dynamic>;
        return Resultado.exitoso(datos);
      } else {
        final datos = jsonDecode(resp.body);
        return Resultado.fallido(datos['mensaje']?.toString() ?? 'Error al crear usuario');
      }
    } catch (e) {
      return Resultado.fallido('Error de conexión: $e');
    }
  }

  Future<Resultado<Map<String, dynamic>>> actualizarUsuarioPorAdmin(
    int id, {
    String? nombre,
    String? correo,
    String? rol,
    String? estado,
    String? nueva_contrasena,
  }) async {
    final token = await obtenerToken();
    if (token == null || token.isEmpty) {
      return Resultado.fallido('Sesión no encontrada');
    }

    try {
      final url = Uri.parse('${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_USUARIOS}/$id');
      final resp = await _cliente_http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (nombre != null) 'nombre': nombre.trim(),
          if (correo != null) 'correo': correo.trim().toLowerCase(),
          if (rol != null) 'rol': rol.trim().toLowerCase(),
          if (estado != null) 'estado': estado.trim().toLowerCase(),
          if (nueva_contrasena != null && nueva_contrasena.isNotEmpty)
            'nueva_contrasena': nueva_contrasena,
        }),
      );

      if (resp.statusCode == 200) {
        final datos = jsonDecode(resp.body) as Map<String, dynamic>;
        return Resultado.exitoso(datos);
      } else {
        final datos = jsonDecode(resp.body);
        return Resultado.fallido(datos['mensaje']?.toString() ?? 'Error al actualizar usuario');
      }
    } catch (e) {
      return Resultado.fallido('Error de conexión: $e');
    }
  }

  Future<Resultado<String>> restablecerContrasenaPorAdmin(
    int id, {
    required String nueva_contrasena,
  }) async {
    if (nueva_contrasena.length < 6) {
      return Resultado.fallido('La contraseña debe tener al menos 6 caracteres');
    }

    final token = await obtenerToken();
    if (token == null || token.isEmpty) {
      return Resultado.fallido('Sesión no encontrada');
    }

    try {
      final url = Uri.parse('${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_USUARIOS}/$id/contrasena');
      final resp = await _cliente_http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'nueva_contrasena': nueva_contrasena}),
      );

      if (resp.statusCode == 200) {
        final datos = jsonDecode(resp.body);
        return Resultado.exitoso(datos['mensaje']?.toString() ?? 'Contraseña restablecida exitosamente');
      } else {
        final datos = jsonDecode(resp.body);
        return Resultado.fallido(datos['mensaje']?.toString() ?? 'Error al restablecer contraseña');
      }
    } catch (e) {
      return Resultado.fallido('Error de conexión: $e');
    }
  }

  Future<bool> estaAutenticado() async {
    final sesion = await obtenerSesionActual();
    return sesion != null;
  }

  Future<Resultado<Map<String, dynamic>>> consultarEstadoConfirmacion() async {
    final token = await obtenerToken();
    if (token == null) return Resultado.fallido('Sesión no encontrada');

    try {
      final url = Uri.parse(
        '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_BECARIOS_ESTADO_CONFIRMACION}',
      );
      final respuesta = await _cliente_http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (respuesta.statusCode != 200) {
        return Resultado.fallido('No se pudo consultar el estado de confirmación');
      }

      final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
      return Resultado.exitoso(datos);
    } catch (e) {
      return Resultado.fallido('Error de conexión con el servidor: $e');
    }
  }

  Future<Resultado<String>> confirmarDatosPropios() async {
    final token = await obtenerToken();
    if (token == null) return Resultado.fallido('Sesión no encontrada');

    try {
      final url = Uri.parse(
        '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_BECARIOS_CONFIRMAR_DATOS}',
      );
      final respuesta = await _cliente_http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (respuesta.statusCode != 200 && respuesta.statusCode != 201) {
        final cuerpo = jsonDecode(respuesta.body);
        return Resultado.fallido(cuerpo['mensaje']?.toString() ?? 'Error al confirmar datos');
      }

      final cuerpo = jsonDecode(respuesta.body);
      return Resultado.exitoso(cuerpo['mensaje']?.toString() ?? 'Confirmado exitosamente');
    } catch (e) {
      return Resultado.fallido('Error al conectar con el servidor: $e');
    }
  }
}
