class CitaSeguimientoModelo {
  final int id;
  final int supervisor_id;
  final String supervisor_nombre;
  final int becario_id;
  final String becario_nombre;
  final String fecha_cita;
  final String hora_cita;
  final String modalidad; // 'presencial' | 'virtual'
  final String lugar_o_enlace;
  final String motivo_retroalimentacion;
  final String? cita_biblica;
  final String? acuerdos_retroalimentacion;
  final String estado; // 'programada' | 'realizada' | 'reprogramada' | 'cancelada'
  final String? created_at;

  const CitaSeguimientoModelo({
    required this.id,
    required this.supervisor_id,
    required this.supervisor_nombre,
    required this.becario_id,
    required this.becario_nombre,
    required this.fecha_cita,
    required this.hora_cita,
    required this.modalidad,
    required this.lugar_o_enlace,
    required this.motivo_retroalimentacion,
    this.cita_biblica,
    this.acuerdos_retroalimentacion,
    this.estado = 'programada',
    this.created_at,
  });

  bool get es_presencial => modalidad.toLowerCase().trim() == 'presencial';
  bool get es_virtual => modalidad.toLowerCase().trim() == 'virtual';
  bool get esta_programada => estado.toLowerCase().trim() == 'programada';
  bool get esta_realizada => estado.toLowerCase().trim() == 'realizada';
  bool get esta_reprogramada => estado.toLowerCase().trim() == 'reprogramada';
  bool get esta_cancelada => estado.toLowerCase().trim() == 'cancelada';

  factory CitaSeguimientoModelo.desdeJson(Map<String, dynamic> json) {
    final supervisor_obj = json['supervisor'];
    final becario_obj = json['becario'];
    final becario_usuario_obj =
        becario_obj is Map ? becario_obj['usuario'] : null;

    final supervisor_nombre = json['supervisor_nombre']?.toString() ??
        json['supervisorNombre']?.toString() ??
        json['nombre_supervisor']?.toString() ??
        (supervisor_obj is Map ? supervisor_obj['nombre']?.toString() : null) ??
        'Mentor Diaconal';

    final becario_nombre = json['becario_nombre']?.toString() ??
        json['becarioNombre']?.toString() ??
        json['nombre_becario']?.toString() ??
        (becario_usuario_obj is Map
            ? becario_usuario_obj['nombre']?.toString()
            : null) ??
        (becario_obj is Map ? becario_obj['nombre']?.toString() : null) ??
        'Becario Diaconía';

    return CitaSeguimientoModelo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      supervisor_id: (json['supervisor_id'] as num?)?.toInt() ??
          (json['supervisorId'] as num?)?.toInt() ??
          0,
      supervisor_nombre: supervisor_nombre,
      becario_id: (json['becario_id'] as num?)?.toInt() ??
          (json['becarioId'] as num?)?.toInt() ??
          0,
      becario_nombre: becario_nombre,
      fecha_cita: (json['fecha_cita']?.toString() ??
              json['fechaCita']?.toString() ??
              json['fecha']?.toString() ??
              '')
          .split('T')
          .first,
      hora_cita: json['hora_cita']?.toString() ??
          json['horaCita']?.toString() ??
          json['hora']?.toString() ??
          '09:00',
      modalidad: json['modalidad']?.toString() ?? 'presencial',
      lugar_o_enlace: json['lugar_o_enlace']?.toString() ??
          json['lugarOEnlace']?.toString() ??
          '',
      motivo_retroalimentacion: json['motivo_retroalimentacion']?.toString() ??
          json['motivoRetroalimentacion']?.toString() ??
          '',
      cita_biblica: json['cita_biblica']?.toString() ??
          json['citaBiblica']?.toString(),
      acuerdos_retroalimentacion: json['acuerdos_retroalimentacion']?.toString() ??
          json['acuerdosRetroalimentacion']?.toString(),
      estado: json['estado']?.toString() ?? 'programada',
      created_at: json['created_at']?.toString() ??
          json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'supervisor_id': supervisor_id,
      'supervisor_nombre': supervisor_nombre,
      'becario_id': becario_id,
      'becario_nombre': becario_nombre,
      'fecha_cita': fecha_cita,
      'hora_cita': hora_cita,
      'modalidad': modalidad,
      'lugar_o_enlace': lugar_o_enlace,
      'motivo_retroalimentacion': motivo_retroalimentacion,
      'cita_biblica': cita_biblica,
      'acuerdos_retroalimentacion': acuerdos_retroalimentacion,
      'estado': estado,
      'created_at': created_at,
    };
  }

  CitaSeguimientoModelo copiarCon({
    int? id,
    int? supervisor_id,
    String? supervisor_nombre,
    int? becario_id,
    String? becario_nombre,
    String? fecha_cita,
    String? hora_cita,
    String? modalidad,
    String? lugar_o_enlace,
    String? motivo_retroalimentacion,
    String? cita_biblica,
    String? acuerdos_retroalimentacion,
    String? estado,
    String? created_at,
  }) {
    return CitaSeguimientoModelo(
      id: id ?? this.id,
      supervisor_id: supervisor_id ?? this.supervisor_id,
      supervisor_nombre: supervisor_nombre ?? this.supervisor_nombre,
      becario_id: becario_id ?? this.becario_id,
      becario_nombre: becario_nombre ?? this.becario_nombre,
      fecha_cita: fecha_cita ?? this.fecha_cita,
      hora_cita: hora_cita ?? this.hora_cita,
      modalidad: modalidad ?? this.modalidad,
      lugar_o_enlace: lugar_o_enlace ?? this.lugar_o_enlace,
      motivo_retroalimentacion:
          motivo_retroalimentacion ?? this.motivo_retroalimentacion,
      cita_biblica: cita_biblica ?? this.cita_biblica,
      acuerdos_retroalimentacion:
          acuerdos_retroalimentacion ?? this.acuerdos_retroalimentacion,
      estado: estado ?? this.estado,
      created_at: created_at ?? this.created_at,
    );
  }

  static List<CitaSeguimientoModelo> semillasBecario() => const [];

  static List<CitaSeguimientoModelo> semillasSupervisor() => const [];
}
