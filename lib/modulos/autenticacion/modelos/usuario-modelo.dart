class UsuarioModelo {
  final int id;
  final String nombre;
  final String rol;
  final String token;

  UsuarioModelo({
    required this.id,
    required this.nombre,
    required this.rol,
    required this.token,
  });

  factory UsuarioModelo.desdeJson(Map<String, dynamic> json) {
    return UsuarioModelo(
      id: json['usuario']['id'] as int,
      nombre: json['usuario']['nombre'] as String,
      rol: json['usuario']['rol'] as String,
      token: json['token'] as String,
    );
  }
}
