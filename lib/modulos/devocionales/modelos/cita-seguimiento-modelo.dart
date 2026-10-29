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
    return CitaSeguimientoModelo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      supervisor_id: (json['supervisor_id'] as num?)?.toInt() ??
          (json['supervisorId'] as num?)?.toInt() ??
          0,
      supervisor_nombre: json['supervisor_nombre']?.toString() ??
          json['supervisorNombre']?.toString() ??
          'Supervisor Diaconal',
      becario_id: (json['becario_id'] as num?)?.toInt() ??
          (json['becarioId'] as num?)?.toInt() ??
          0,
      becario_nombre: json['becario_nombre']?.toString() ??
          json['becarioNombre']?.toString() ??
          'Becario Diaconía',
      fecha_cita: json['fecha_cita']?.toString() ??
          json['fechaCita']?.toString() ??
          json['fecha']?.toString() ??
          '',
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

  static List<CitaSeguimientoModelo> semillasBecario() {
    return const [
      CitaSeguimientoModelo(
        id: 101,
        supervisor_id: 1,
        supervisor_nombre: 'Pastor Marcos Quispe',
        becario_id: 10,
        becario_nombre: 'María Catunta Laime',
        fecha_cita: '2026-10-30',
        hora_cita: '15:30',
        modalidad: 'presencial',
        lugar_o_enlace: 'Oficina Central Diaconía - Sala Pastoral',
        motivo_retroalimentacion:
            'Revisión de avance formativo diaconal y balance académico.',
        cita_biblica: 'Jeremías 29:11',
        acuerdos_retroalimentacion: null,
        estado: 'programada',
        created_at: '2026-10-25T10:00:00Z',
      ),
      CitaSeguimientoModelo(
        id: 102,
        supervisor_id: 1,
        supervisor_nombre: 'Pastor Marcos Quispe',
        becario_id: 10,
        becario_nombre: 'María Catunta Laime',
        fecha_cita: '2026-10-15',
        hora_cita: '16:00',
        modalidad: 'virtual',
        lugar_o_enlace: 'https://meet.google.com/dia-past-seg',
        motivo_retroalimentacion:
            'Acompañamiento espiritual y apoyo en práctica preprofesional.',
        cita_biblica: '1 Timoteo 4:12',
        acuerdos_retroalimentacion:
            'Mantener tiempo diario de devocional matutino y coordinar horarios de prácticas con la universidad.',
        estado: 'realizada',
        created_at: '2026-10-10T14:30:00Z',
      ),
    ];
  }

  static List<CitaSeguimientoModelo> semillasSupervisor() {
    return const [
      CitaSeguimientoModelo(
        id: 201,
        supervisor_id: 1,
        supervisor_nombre: 'Pastor Marcos Quispe',
        becario_id: 10,
        becario_nombre: 'María Catunta Laime',
        fecha_cita: '2026-10-30',
        hora_cita: '15:30',
        modalidad: 'presencial',
        lugar_o_enlace: 'Oficina Central Diaconía - Sala Pastoral',
        motivo_retroalimentacion:
            'Revisión de avance formativo diaconal y balance académico.',
        cita_biblica: 'Josué 1:9',
        acuerdos_retroalimentacion: null,
        estado: 'programada',
        created_at: '2026-10-25T10:00:00Z',
      ),
      CitaSeguimientoModelo(
        id: 202,
        supervisor_id: 1,
        supervisor_nombre: 'Pastor Marcos Quispe',
        becario_id: 11,
        becario_nombre: 'Carlos Mamani Choque',
        fecha_cita: '2026-10-31',
        hora_cita: '10:00',
        modalidad: 'virtual',
        lugar_o_enlace: 'https://meet.google.com/seg-carlos-dia',
        motivo_retroalimentacion:
            'Evaluación socioformativa y seguimiento de refrigerios y pasajes.',
        cita_biblica: 'Colosenses 3:23-24',
        acuerdos_retroalimentacion: null,
        estado: 'programada',
        created_at: '2026-10-26T09:00:00Z',
      ),
      CitaSeguimientoModelo(
        id: 203,
        supervisor_id: 1,
        supervisor_nombre: 'Pastor Marcos Quispe',
        becario_id: 12,
        becario_nombre: 'Ana Quispe Condori',
        fecha_cita: '2026-10-18',
        hora_cita: '11:00',
        modalidad: 'presencial',
        lugar_o_enlace: 'Sede Regional El Alto',
        motivo_retroalimentacion:
            'Retroalimentación sobre justificaciones médicas e integración comunitaria.',
        cita_biblica: 'Salmos 23:1',
        acuerdos_retroalimentacion:
            'Presentar descargos de justificaciones a tiempo y participar en la Escuela de Líderes.',
        estado: 'realizada',
        created_at: '2026-10-12T11:00:00Z',
      ),
    ];
  }
}
