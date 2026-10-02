import 'dart:convert';

class UsuarioModelo {
  final int id;
  final String nombre;
  final String correo;
  final String rol;
  final String token;

  const UsuarioModelo({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.token,
  });

  factory UsuarioModelo.desdeJson(Map<String, dynamic> json) {
    final mapa_usuario = json['usuario'] as Map<String, dynamic>? ??
        json['user'] as Map<String, dynamic>?;
    final token_valor = (json['token'] ?? json['access_token'] ?? '') as String;

    Map<String, dynamic>? carga_jwt;
    if (token_valor.isNotEmpty) {
      carga_jwt = _decodificarJwt(token_valor);
    }

    final id_valor = mapa_usuario?['id'] as int? ??
        json['id'] as int? ??
        carga_jwt?['sub'] as int? ??
        0;

    final correo_valor = mapa_usuario?['correo'] as String? ??
        json['correo'] as String? ??
        carga_jwt?['correo'] as String? ??
        '';

    final nombre_valor = mapa_usuario?['nombre'] as String? ??
        json['nombre'] as String? ??
        (correo_valor.isNotEmpty ? correo_valor.split('@').first : '');

    final rol_valor = mapa_usuario?['rol'] as String? ??
        json['rol'] as String? ??
        carga_jwt?['rol'] as String? ??
        'becario';

    return UsuarioModelo(
      id: id_valor,
      nombre: nombre_valor,
      correo: correo_valor,
      rol: rol_valor,
      token: token_valor,
    );
  }

  static Map<String, dynamic>? _decodificarJwt(String token) {
    try {
      final partes = token.split('.');
      if (partes.length != 3) return null;
      final normalizado = base64Url.normalize(partes[1]);
      final decodificado = utf8.decode(base64Url.decode(normalizado));
      return jsonDecode(decodificado) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'token': token,
    };
  }

  UsuarioModelo copiarCon({
    int? id,
    String? nombre,
    String? correo,
    String? rol,
    String? token,
  }) {
    return UsuarioModelo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      rol: rol ?? this.rol,
      token: token ?? this.token,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsuarioModelo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nombre == other.nombre &&
          correo == other.correo &&
          rol == other.rol &&
          token == other.token;

  @override
  int get hashCode =>
      id.hashCode ^
      nombre.hashCode ^
      correo.hashCode ^
      rol.hashCode ^
      token.hashCode;
}
