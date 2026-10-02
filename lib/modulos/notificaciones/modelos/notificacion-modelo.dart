class NotificacionModelo {
  final int id;
  final int usuario_id;
  final String tipo;
  final String mensaje;
  final bool leido;
  final DateTime fecha_envio;

  const NotificacionModelo({
    required this.id,
    required this.usuario_id,
    required this.tipo,
    required this.mensaje,
    required this.leido,
    required this.fecha_envio,
  });

  factory NotificacionModelo.desdeJson(Map<String, dynamic> json) {
    return NotificacionModelo(
      id: json['id'] as int? ?? 0,
      usuario_id: json['usuario_id'] as int? ?? json['usuarioId'] as int? ?? 0,
      tipo: json['tipo'] as String? ?? 'general',
      mensaje: json['mensaje'] as String? ?? '',
      leido: json['leido'] as bool? ?? false,
      fecha_envio: json['fecha_envio'] != null
          ? DateTime.tryParse(json['fecha_envio'].toString()) ?? DateTime.now()
          : json['fechaEnvio'] != null
              ? DateTime.tryParse(json['fechaEnvio'].toString()) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> aJson() => {
    'id': id,
    'usuario_id': usuario_id,
    'tipo': tipo,
    'mensaje': mensaje,
    'leido': leido,
    'fecha_envio': fecha_envio.toIso8601String(),
  };

  NotificacionModelo copiarCon({
    int? id,
    int? usuario_id,
    String? tipo,
    String? mensaje,
    bool? leido,
    DateTime? fecha_envio,
  }) {
    return NotificacionModelo(
      id: id ?? this.id,
      usuario_id: usuario_id ?? this.usuario_id,
      tipo: tipo ?? this.tipo,
      mensaje: mensaje ?? this.mensaje,
      leido: leido ?? this.leido,
      fecha_envio: fecha_envio ?? this.fecha_envio,
    );
  }

  bool get esRecordatorioSalida {
    final t = tipo.toLowerCase();
    return t.contains('salida') || t.contains('recordatorio');
  }

  bool get esPasajeObservado {
    final t = tipo.toLowerCase();
    return t.contains('pasaje') || t.contains('observad');
  }

  bool get esEvaluacion {
    final t = tipo.toLowerCase();
    return t.contains('evalua');
  }

  String get etiquetaTipo {
    if (esRecordatorioSalida) return 'Recordatorio de salida';
    if (esPasajeObservado) return 'Pasaje observado';
    if (esEvaluacion) return 'Evaluación';
    return 'Aviso';
  }
}
