class RefrigerioModelo {
  final int id;
  final String fecha;
  final String evento_o_jornada;
  final String menu_detalle;
  final String sede_nombre;
  final String bloque;
  final String responsable_entrega;
  final String horario_distribucion;
  final bool recogido;
  final String? hora_recojo;
  final String? codigo_constancia;
  final String? observaciones;

  const RefrigerioModelo({
    required this.id,
    required this.fecha,
    required this.evento_o_jornada,
    required this.menu_detalle,
    required this.sede_nombre,
    required this.bloque,
    required this.responsable_entrega,
    required this.horario_distribucion,
    required this.recogido,
    this.hora_recojo,
    this.codigo_constancia,
    this.observaciones,
  });

  RefrigerioModelo copiarCon({
    int? id,
    String? fecha,
    String? evento_o_jornada,
    String? menu_detalle,
    String? sede_nombre,
    String? bloque,
    String? responsable_entrega,
    String? horario_distribucion,
    bool? recogido,
    String? hora_recojo,
    String? codigo_constancia,
    String? observaciones,
  }) {
    return RefrigerioModelo(
      id: id ?? this.id,
      fecha: fecha ?? this.fecha,
      evento_o_jornada: evento_o_jornada ?? this.evento_o_jornada,
      menu_detalle: menu_detalle ?? this.menu_detalle,
      sede_nombre: sede_nombre ?? this.sede_nombre,
      bloque: bloque ?? this.bloque,
      responsable_entrega: responsable_entrega ?? this.responsable_entrega,
      horario_distribucion: horario_distribucion ?? this.horario_distribucion,
      recogido: recogido ?? this.recogido,
      hora_recojo: hora_recojo ?? this.hora_recojo,
      codigo_constancia: codigo_constancia ?? this.codigo_constancia,
      observaciones: observaciones ?? this.observaciones,
    );
  }

  factory RefrigerioModelo.deJson(Map<String, dynamic> json) {
    return RefrigerioModelo(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      fecha: json['fecha']?.toString() ?? '',
      evento_o_jornada: json['evento_o_jornada']?.toString() ?? 'Escuela de Líderes',
      menu_detalle: json['menu_detalle']?.toString() ?? 'Refrigerio institucional',
      sede_nombre: json['sede_nombre']?.toString() ?? 'Oficina Central El Alto',
      bloque: json['bloque']?.toString() ?? 'Bloque B (Auditorio)',
      responsable_entrega: json['responsable_entrega']?.toString() ?? 'Angel Javier Ali Paz',
      horario_distribucion: json['horario_distribucion']?.toString() ?? '16:00 - 17:30',
      recogido: json['recogido'] == true,
      hora_recojo: json['hora_recojo']?.toString(),
      codigo_constancia: json['codigo_constancia']?.toString(),
      observaciones: json['observaciones']?.toString(),
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'fecha': fecha,
      'evento_o_jornada': evento_o_jornada,
      'menu_detalle': menu_detalle,
      'sede_nombre': sede_nombre,
      'bloque': bloque,
      'responsable_entrega': responsable_entrega,
      'horario_distribucion': horario_distribucion,
      'recogido': recogido,
      'hora_recojo': hora_recojo,
      'codigo_constancia': codigo_constancia,
      'observaciones': observaciones,
    };
  }
}

const List<RefrigerioModelo> REFRIGERIOS_HISTORIAL_BECARIO = [
  RefrigerioModelo(
    id: 1,
    fecha: '2026-10-23',
    evento_o_jornada: 'Viernes Formativo - Escuela de Líderes',
    menu_detalle: 'Empanadas de queso horneadas y yogurt probiótico natural.',
    sede_nombre: 'Oficina Central El Alto',
    bloque: 'Bloque B (Auditorio)',
    responsable_entrega: 'Angel Javier Ali Paz',
    horario_distribucion: '16:00 - 17:30',
    recogido: false,
    observaciones: 'Presentar credencial digital o confirmar recepción en la aplicación móvil.',
  ),
  RefrigerioModelo(
    id: 2,
    fecha: '2026-10-16',
    evento_o_jornada: 'Viernes Formativo - Escuela de Líderes',
    menu_detalle: 'Sándwich de pavo con vegetales frescos y jugo de naranja natural.',
    sede_nombre: 'Oficina Central El Alto',
    bloque: 'Bloque A (Administración)',
    responsable_entrega: 'Claudia Cabrera',
    horario_distribucion: '16:00 - 17:30',
    recogido: true,
    hora_recojo: '16:24 hrs',
    codigo_constancia: 'CR-2026-1016-02',
    observaciones: 'Recepción conforme registrada por el becario.',
  ),
  RefrigerioModelo(
    id: 3,
    fecha: '2026-10-09',
    evento_o_jornada: 'Viernes Formativo - Escuela de Líderes',
    menu_detalle: 'Cuñapé cruceño horneado con chocolatada caliente y fruta de estación.',
    sede_nombre: 'Oficina Central El Alto',
    bloque: 'Bloque B (Auditorio)',
    responsable_entrega: 'Angel Javier Ali Paz',
    horario_distribucion: '16:00 - 17:30',
    recogido: true,
    hora_recojo: '16:15 hrs',
    codigo_constancia: 'CR-2026-1009-03',
    observaciones: 'Recepción conforme registrada por el becario.',
  ),
  RefrigerioModelo(
    id: 4,
    fecha: '2026-10-02',
    evento_o_jornada: 'Viernes Formativo - Escuela de Líderes',
    menu_detalle: 'Salteña de carne tradicional y néctar de durazno.',
    sede_nombre: 'Oficina Central El Alto',
    bloque: 'Bloque B (Auditorio)',
    responsable_entrega: 'Angel Javier Ali Paz',
    horario_distribucion: '16:00 - 17:30',
    recogido: true,
    hora_recojo: '16:32 hrs',
    codigo_constancia: 'CR-2026-1002-04',
    observaciones: 'Recepción conforme registrada por el becario.',
  ),
];
