import 'dart:convert';

class UsuarioModelo {
  final int id;
  final String nombre;
  final String correo;
  final String rol;
  final String token;
  final String? correo_alternativo;
  final List<String> correos_adicionales;
  final String modalidad_pasajes;
  final Map<String, dynamic>? configuracion_pasajes_actividades;
  final String? telefono;
  final String? direccion;
  final String? carrera;
  final String? semestre;
  final String? ci;
  final String? universidad;
  final String estado;

  const UsuarioModelo({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.token,
    this.correo_alternativo,
    this.correos_adicionales = const [],
    this.modalidad_pasajes = 'ida_y_vuelta',
    this.configuracion_pasajes_actividades,
    this.telefono,
    this.direccion,
    this.carrera,
    this.semestre,
    this.ci,
    this.universidad,
    this.estado = 'activo',
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

    final correo_alternativo_valor =
        mapa_usuario?['correo_alternativo'] as String? ??
            mapa_usuario?['correoAlternativo'] as String? ??
            json['correo_alternativo'] as String? ??
            json['correoAlternativo'] as String? ??
            carga_jwt?['correo_alternativo'] as String?;

    final lista_correos_raw = mapa_usuario?['correos_adicionales'] ??
        mapa_usuario?['correosAdicionales'] ??
        json['correos_adicionales'] ??
        json['correosAdicionales'] ??
        carga_jwt?['correos_adicionales'];
    final List<String> correos_adicionales_valor = lista_correos_raw is List
        ? lista_correos_raw
            .map((e) => e is Map ? (e['correo']?.toString() ?? '') : e.toString())
            .where((c) => c.isNotEmpty)
            .toList()
        : const [];

    final modalidad_pasajes_valor = (mapa_usuario?['modalidad_pasajes'] ??
            json['modalidad_pasajes'] ??
            carga_jwt?['modalidad_pasajes'] ??
            'ida_y_vuelta')
        .toString();

    final config_pasajes_raw = mapa_usuario?['configuracion_pasajes_actividades'] ??
        json['configuracion_pasajes_actividades'];
    final config_pasajes_valor = config_pasajes_raw is Map<String, dynamic>
        ? config_pasajes_raw
        : null;

    final telefono_valor = mapa_usuario?['telefono'] as String? ??
        mapa_usuario?['celular'] as String? ??
        json['telefono'] as String? ??
        json['celular'] as String?;

    final direccion_valor = mapa_usuario?['direccion'] as String? ??
        json['direccion'] as String?;

    final carrera_valor = mapa_usuario?['carrera'] as String? ??
        json['carrera'] as String?;

    final semestre_valor = mapa_usuario?['semestre'] as String? ??
        json['semestre'] as String?;

    final ci_valor = mapa_usuario?['ci'] as String? ??
        json['ci'] as String?;

    final universidad_valor = mapa_usuario?['universidad'] as String? ??
        json['universidad'] as String?;

    final estado_valor = (mapa_usuario?['estado'] ?? json['estado'] ?? 'activo').toString();

    return UsuarioModelo(
      id: id_valor,
      nombre: nombre_valor,
      correo: correo_valor,
      rol: rol_valor,
      token: token_valor,
      correo_alternativo: correo_alternativo_valor,
      correos_adicionales: correos_adicionales_valor,
      modalidad_pasajes: modalidad_pasajes_valor,
      configuracion_pasajes_actividades: config_pasajes_valor,
      telefono: telefono_valor,
      direccion: direccion_valor,
      carrera: carrera_valor,
      semestre: semestre_valor,
      ci: ci_valor,
      universidad: universidad_valor,
      estado: estado_valor,
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
      'correo_alternativo': correo_alternativo,
      'correos_adicionales': correos_adicionales,
      'modalidad_pasajes': modalidad_pasajes,
      'configuracion_pasajes_actividades': configuracion_pasajes_actividades,
      'telefono': telefono,
      'direccion': direccion,
      'carrera': carrera,
      'semestre': semestre,
      'ci': ci,
      'universidad': universidad,
      'estado': estado,
    };
  }

  UsuarioModelo copiarCon({
    int? id,
    String? nombre,
    String? correo,
    String? rol,
    String? token,
    String? correo_alternativo,
    List<String>? correos_adicionales,
    String? modalidad_pasajes,
    Map<String, dynamic>? configuracion_pasajes_actividades,
    String? telefono,
    String? direccion,
    String? carrera,
    String? semestre,
    String? ci,
    String? universidad,
    String? estado,
  }) {
    return UsuarioModelo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      rol: rol ?? this.rol,
      token: token ?? this.token,
      correo_alternativo: correo_alternativo ?? this.correo_alternativo,
      correos_adicionales: correos_adicionales ?? this.correos_adicionales,
      modalidad_pasajes: modalidad_pasajes ?? this.modalidad_pasajes,
      configuracion_pasajes_actividades: configuracion_pasajes_actividades ?? this.configuracion_pasajes_actividades,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      carrera: carrera ?? this.carrera,
      semestre: semestre ?? this.semestre,
      ci: ci ?? this.ci,
      universidad: universidad ?? this.universidad,
      estado: estado ?? this.estado,
    );
  }

  static bool _listasIguales(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
          token == other.token &&
          correo_alternativo == other.correo_alternativo &&
          _listasIguales(correos_adicionales, other.correos_adicionales);

  @override
  int get hashCode =>
      id.hashCode ^
      nombre.hashCode ^
      correo.hashCode ^
      rol.hashCode ^
      token.hashCode ^
      correo_alternativo.hashCode ^
      Object.hashAll(correos_adicionales);
}
