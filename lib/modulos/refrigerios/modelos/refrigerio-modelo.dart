class IngredienteRefrigerioModelo {
  final String insumo;
  final String cantidad;
  final double costo_bs;
  final int? pagado_por_becario_id;
  final String? pagado_por_nombre;

  const IngredienteRefrigerioModelo({
    required this.insumo,
    this.cantidad = '',
    required this.costo_bs,
    this.pagado_por_becario_id,
    this.pagado_por_nombre,
  });

  IngredienteRefrigerioModelo copiarCon({
    String? insumo,
    String? cantidad,
    double? costo_bs,
    int? pagado_por_becario_id,
    String? pagado_por_nombre,
  }) {
    return IngredienteRefrigerioModelo(
      insumo: insumo ?? this.insumo,
      cantidad: cantidad ?? this.cantidad,
      costo_bs: costo_bs ?? this.costo_bs,
      pagado_por_becario_id: pagado_por_becario_id ?? this.pagado_por_becario_id,
      pagado_por_nombre: pagado_por_nombre ?? this.pagado_por_nombre,
    );
  }

  factory IngredienteRefrigerioModelo.deJson(Map<String, dynamic> json) {
    return IngredienteRefrigerioModelo(
      insumo: json['insumo']?.toString() ?? '',
      cantidad: json['cantidad']?.toString() ?? '',
      costo_bs: (json['costo_bs'] as num?)?.toDouble() ??
          double.tryParse(json['costo_bs']?.toString() ?? '0') ??
          0.0,
      pagado_por_becario_id: json['pagado_por_becario_id'] is int
          ? json['pagado_por_becario_id']
          : int.tryParse(json['pagado_por_becario_id']?.toString() ?? ''),
      pagado_por_nombre: json['pagado_por_nombre']?.toString(),
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'insumo': insumo,
      'cantidad': cantidad,
      'costo_bs': costo_bs,
      'pagado_por_becario_id': pagado_por_becario_id,
      'pagado_por_nombre': pagado_por_nombre,
    };
  }
}

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

  // Nuevos atributos de Dupla del Viernes y Devolución 100% (TAREA-15)
  final int? becario_encargado_1_id;
  final String? becario_encargado_1_nombre;
  final int? becario_encargado_2_id;
  final String? becario_encargado_2_nombre;
  final String modalidad_preparacion; // 'cocina_diaconia' | 'traido_de_casa' | 'compra_directa'
  final List<IngredienteRefrigerioModelo> ingredientes;
  final int cantidad_raciones;
  final double costo_unitario_bs;
  final double costo_total_bs;
  final int porcentaje_devolucion; // Siempre 100%
  final double monto_devolucion_bs;
  final String estado; // 'sorteado' | 'rendido_pendiente' | 'revisado_supervisor' | 'aprobado_administracion'
  final int? becario_receptor_devolucion_id;
  final String? becario_receptor_devolucion_nombre;
  final String? fecha_entrega_devolucion;

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
    this.becario_encargado_1_id,
    this.becario_encargado_1_nombre,
    this.becario_encargado_2_id,
    this.becario_encargado_2_nombre,
    this.modalidad_preparacion = 'cocina_diaconia',
    this.ingredientes = const [],
    this.cantidad_raciones = 23,
    this.costo_unitario_bs = 6.0,
    this.costo_total_bs = 138.0,
    this.porcentaje_devolucion = 100,
    this.monto_devolucion_bs = 138.0,
    this.estado = 'sorteado',
    this.becario_receptor_devolucion_id,
    this.becario_receptor_devolucion_nombre,
    this.fecha_entrega_devolucion,
  });

  bool esParteDeLaDupla({int? becario_id, String? nombre}) {
    if (becario_id != null) {
      if (becario_encargado_1_id == becario_id || becario_encargado_2_id == becario_id) {
        return true;
      }
    }
    if (nombre != null && nombre.trim().isNotEmpty) {
      final buscado = nombre.trim().toLowerCase();
      if ((becario_encargado_1_nombre?.trim().toLowerCase() == buscado) ||
          (becario_encargado_2_nombre?.trim().toLowerCase() == buscado)) {
        return true;
      }
    }
    return false;
  }

  String? obtenerCompaneroDupla({int? becario_id, String? nombre}) {
    if (becario_id != null) {
      if (becario_encargado_1_id == becario_id) return becario_encargado_2_nombre;
      if (becario_encargado_2_id == becario_id) return becario_encargado_1_nombre;
    }
    if (nombre != null && nombre.trim().isNotEmpty) {
      final buscado = nombre.trim().toLowerCase();
      if (becario_encargado_1_nombre?.trim().toLowerCase() == buscado) {
        return becario_encargado_2_nombre;
      }
      if (becario_encargado_2_nombre?.trim().toLowerCase() == buscado) {
        return becario_encargado_1_nombre;
      }
    }
    return null;
  }

  double gastoPorBecario({int? becario_id, String? nombre}) {
    double total = 0.0;
    for (final ing in ingredientes) {
      final coincide_id = becario_id != null && ing.pagado_por_becario_id == becario_id;
      final coincide_nombre = nombre != null &&
          ing.pagado_por_nombre != null &&
          ing.pagado_por_nombre!.trim().toLowerCase() == nombre.trim().toLowerCase();
      if (coincide_id || coincide_nombre) {
        total += ing.costo_bs;
      }
    }
    return total;
  }

  String get modalidadLegible {
    switch (modalidad_preparacion) {
      case 'cocina_diaconia':
        return 'Preparado en Cocina de Diaconía';
      case 'traido_de_casa':
        return 'Elaborado en Casa';
      case 'compra_directa':
        return 'Compra Directa';
      default:
        return 'Cocina de Diaconía';
    }
  }

  String get estadoLegible {
    switch (estado) {
      case 'sorteado':
        return 'Sorteado / Programado';
      case 'rendido_pendiente':
        return 'Rendido (Pendiente Revisión)';
      case 'revisado_supervisor':
        return 'Revisado por Supervisor';
      case 'aprobado_administracion':
        return 'Aprobado por Administración (Devolución 100%)';
      default:
        return estado;
    }
  }

  bool get tieneDupla =>
      becario_encargado_1_nombre != null && becario_encargado_2_nombre != null;

  bool get devolucionEntregada =>
      estado == 'aprobado_administracion' && becario_receptor_devolucion_nombre != null;

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
    int? becario_encargado_1_id,
    String? becario_encargado_1_nombre,
    int? becario_encargado_2_id,
    String? becario_encargado_2_nombre,
    String? modalidad_preparacion,
    List<IngredienteRefrigerioModelo>? ingredientes,
    int? cantidad_raciones,
    double? costo_unitario_bs,
    double? costo_total_bs,
    int? porcentaje_devolucion,
    double? monto_devolucion_bs,
    String? estado,
    int? becario_receptor_devolucion_id,
    String? becario_receptor_devolucion_nombre,
    String? fecha_entrega_devolucion,
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
      becario_encargado_1_id: becario_encargado_1_id ?? this.becario_encargado_1_id,
      becario_encargado_1_nombre:
          becario_encargado_1_nombre ?? this.becario_encargado_1_nombre,
      becario_encargado_2_id: becario_encargado_2_id ?? this.becario_encargado_2_id,
      becario_encargado_2_nombre:
          becario_encargado_2_nombre ?? this.becario_encargado_2_nombre,
      modalidad_preparacion: modalidad_preparacion ?? this.modalidad_preparacion,
      ingredientes: ingredientes ?? this.ingredientes,
      cantidad_raciones: cantidad_raciones ?? this.cantidad_raciones,
      costo_unitario_bs: costo_unitario_bs ?? this.costo_unitario_bs,
      costo_total_bs: costo_total_bs ?? this.costo_total_bs,
      porcentaje_devolucion: porcentaje_devolucion ?? this.porcentaje_devolucion,
      monto_devolucion_bs: monto_devolucion_bs ?? this.monto_devolucion_bs,
      estado: estado ?? this.estado,
      becario_receptor_devolucion_id:
          becario_receptor_devolucion_id ?? this.becario_receptor_devolucion_id,
      becario_receptor_devolucion_nombre:
          becario_receptor_devolucion_nombre ?? this.becario_receptor_devolucion_nombre,
      fecha_entrega_devolucion:
          fecha_entrega_devolucion ?? this.fecha_entrega_devolucion,
    );
  }

  factory RefrigerioModelo.deJson(Map<String, dynamic> json) {
    final lista_ingredientes_raw = json['ingredientes'] as List<dynamic>? ??
        json['detalle_ingredientes'] as List<dynamic>? ??
        [];

    final lista_ingredientes = lista_ingredientes_raw
        .map((elem) => IngredienteRefrigerioModelo.deJson(elem as Map<String, dynamic>))
        .toList();

    final costo_total = (json['costo_total_bs'] as num?)?.toDouble() ??
        double.tryParse(json['costo_total_bs']?.toString() ?? '138.0') ??
        138.0;

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
      becario_encargado_1_id: json['becario_encargado_1_id'] is int
          ? json['becario_encargado_1_id']
          : int.tryParse(json['becario_encargado_1_id']?.toString() ?? ''),
      becario_encargado_1_nombre: json['becario_encargado_1_nombre']?.toString(),
      becario_encargado_2_id: json['becario_encargado_2_id'] is int
          ? json['becario_encargado_2_id']
          : int.tryParse(json['becario_encargado_2_id']?.toString() ?? ''),
      becario_encargado_2_nombre: json['becario_encargado_2_nombre']?.toString(),
      modalidad_preparacion:
          json['modalidad_preparacion']?.toString() ?? 'cocina_diaconia',
      ingredientes: lista_ingredientes,
      cantidad_raciones: json['cantidad_raciones'] is int
          ? json['cantidad_raciones']
          : int.tryParse(json['cantidad_raciones']?.toString() ?? '23') ?? 23,
      costo_unitario_bs: (json['costo_unitario_bs'] as num?)?.toDouble() ??
          double.tryParse(json['costo_unitario_bs']?.toString() ?? '6.0') ??
          6.0,
      costo_total_bs: costo_total,
      porcentaje_devolucion: json['porcentaje_devolucion'] is int
          ? json['porcentaje_devolucion']
          : int.tryParse(json['porcentaje_devolucion']?.toString() ?? '100') ?? 100,
      monto_devolucion_bs: (json['monto_devolucion_bs'] as num?)?.toDouble() ??
          double.tryParse(json['monto_devolucion_bs']?.toString() ?? costo_total.toString()) ??
          costo_total,
      estado: json['estado']?.toString() ?? 'sorteado',
      becario_receptor_devolucion_id: json['becario_receptor_devolucion_id'] is int
          ? json['becario_receptor_devolucion_id']
          : int.tryParse(json['becario_receptor_devolucion_id']?.toString() ?? ''),
      becario_receptor_devolucion_nombre:
          json['becario_receptor_devolucion_nombre']?.toString(),
      fecha_entrega_devolucion: json['fecha_entrega_devolucion']?.toString(),
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
      'becario_encargado_1_id': becario_encargado_1_id,
      'becario_encargado_1_nombre': becario_encargado_1_nombre,
      'becario_encargado_2_id': becario_encargado_2_id,
      'becario_encargado_2_nombre': becario_encargado_2_nombre,
      'modalidad_preparacion': modalidad_preparacion,
      'ingredientes': ingredientes.map((i) => i.aJson()).toList(),
      'cantidad_raciones': cantidad_raciones,
      'costo_unitario_bs': costo_unitario_bs,
      'costo_total_bs': costo_total_bs,
      'porcentaje_devolucion': porcentaje_devolucion,
      'monto_devolucion_bs': monto_devolucion_bs,
      'estado': estado,
      'becario_receptor_devolucion_id': becario_receptor_devolucion_id,
      'becario_receptor_devolucion_nombre': becario_receptor_devolucion_nombre,
      'fecha_entrega_devolucion': fecha_entrega_devolucion,
    };
  }
}

const List<RefrigerioModelo> REFRIGERIOS_HISTORIAL_BECARIO = [
  RefrigerioModelo(
    id: 1,
    fecha: '2026-10-30',
    evento_o_jornada: 'Viernes Formativo - Escuela de Líderes',
    menu_detalle: 'Sándwich de huevo tibio y café/té caliente con pan casero.',
    sede_nombre: 'Oficina Central El Alto',
    bloque: 'Bloque B (Auditorio / Cocina Diaconía)',
    responsable_entrega: 'Angel Javier Ali Paz',
    horario_distribucion: '16:00 - 17:30',
    recogido: false,
    becario_encargado_1_id: 1,
    becario_encargado_1_nombre: 'María Catunta Laime',
    becario_encargado_2_id: 2,
    becario_encargado_2_nombre: 'Juan Carlos Quispe',
    modalidad_preparacion: 'cocina_diaconia',
    cantidad_raciones: 23,
    costo_unitario_bs: 6.00,
    costo_total_bs: 138.00,
    porcentaje_devolucion: 100,
    monto_devolucion_bs: 138.00,
    estado: 'sorteado',
    ingredientes: [
      IngredienteRefrigerioModelo(
        insumo: 'Maple de huevos frescos (30 unidades)',
        cantidad: '1 maple',
        costo_bs: 38.0,
        pagado_por_becario_id: 1,
        pagado_por_nombre: 'María Catunta Laime',
      ),
      IngredienteRefrigerioModelo(
        insumo: 'Pan surtido de batalla',
        cantidad: '50 unidades',
        costo_bs: 40.0,
        pagado_por_becario_id: 1,
        pagado_por_nombre: 'María Catunta Laime',
      ),
      IngredienteRefrigerioModelo(
        insumo: 'Té con canela, café soluble y azúcar',
        cantidad: '1 paquete',
        costo_bs: 30.0,
        pagado_por_becario_id: 2,
        pagado_por_nombre: 'Juan Carlos Quispe',
      ),
      IngredienteRefrigerioModelo(
        insumo: 'Servilletas, mantequilla y tomate',
        cantidad: 'Varios',
        costo_bs: 30.0,
        pagado_por_becario_id: 2,
        pagado_por_nombre: 'Juan Carlos Quispe',
      ),
    ],
    observaciones:
      'Turno sorteado para la dupla María Catunta y Juan Carlos Quispe. Preparación en la cocinita de Diaconía.',
  ),
  RefrigerioModelo(
    id: 2,
    fecha: '2026-10-23',
    evento_o_jornada: 'Viernes Formativo - Escuela de Líderes',
    menu_detalle: 'Empanadas de queso horneadas y yogurt probiótico natural.',
    sede_nombre: 'Oficina Central El Alto',
    bloque: 'Bloque B (Auditorio)',
    responsable_entrega: 'Angel Javier Ali Paz',
    horario_distribucion: '16:00 - 17:30',
    recogido: true,
    hora_recojo: '16:20 hrs',
    codigo_constancia: 'CR-2026-1023-01',
    becario_encargado_1_id: 3,
    becario_encargado_1_nombre: 'Claudia Cabrera',
    becario_encargado_2_id: 4,
    becario_encargado_2_nombre: 'Marco Antonio Ramos',
    modalidad_preparacion: 'traido_de_casa',
    cantidad_raciones: 23,
    costo_unitario_bs: 6.00,
    costo_total_bs: 145.00,
    porcentaje_devolucion: 100,
    monto_devolucion_bs: 145.00,
    estado: 'aprobado_administracion',
    becario_receptor_devolucion_id: 3,
    becario_receptor_devolucion_nombre: 'Claudia Cabrera',
    fecha_entrega_devolucion: '2026-10-23 17:40',
    ingredientes: [
      IngredienteRefrigerioModelo(
        insumo: 'Queso criollo y harina para empanadas',
        cantidad: '3 kg queso, 4 kg harina',
        costo_bs: 85.0,
        pagado_por_becario_id: 3,
        pagado_por_nombre: 'Claudia Cabrera',
      ),
      IngredienteRefrigerioModelo(
        insumo: 'Yogurt probiótico embotellado (2 litros)',
        cantidad: '4 botellas',
        costo_bs: 60.0,
        pagado_por_becario_id: 4,
        pagado_por_nombre: 'Marco Antonio Ramos',
      ),
    ],
    observaciones:
      'Reembolso del 100% (Bs 145.00) entregado en su totalidad a Claudia Cabrera. Arreglo interno con Marco Antonio Ramos.',
  ),
  RefrigerioModelo(
    id: 3,
    fecha: '2026-10-16',
    evento_o_jornada: 'Viernes Formativo - Escuela de Líderes',
    menu_detalle: 'Sándwich de pollo con vegetales frescos y néctar de fruta.',
    sede_nombre: 'Oficina Central El Alto',
    bloque: 'Bloque A (Administración)',
    responsable_entrega: 'Angel Javier Ali Paz',
    horario_distribucion: '16:00 - 17:30',
    recogido: true,
    hora_recojo: '16:24 hrs',
    codigo_constancia: 'CR-2026-1016-02',
    becario_encargado_1_id: 5,
    becario_encargado_1_nombre: 'Angel Javier Ali Paz',
    becario_encargado_2_id: 6,
    becario_encargado_2_nombre: 'Ruth Condori Mamani',
    modalidad_preparacion: 'cocina_diaconia',
    cantidad_raciones: 23,
    costo_unitario_bs: 6.00,
    costo_total_bs: 150.00,
    porcentaje_devolucion: 100,
    monto_devolucion_bs: 150.00,
    estado: 'aprobado_administracion',
    becario_receptor_devolucion_id: 5,
    becario_receptor_devolucion_nombre: 'Angel Javier Ali Paz',
    fecha_entrega_devolucion: '2026-10-16 17:35',
    ingredientes: [
      IngredienteRefrigerioModelo(
        insumo: 'Pechuga de pollo cocida y desmenuzada',
        cantidad: '2.5 kg',
        costo_bs: 90.0,
        pagado_por_becario_id: 5,
        pagado_por_nombre: 'Angel Javier Ali Paz',
      ),
      IngredienteRefrigerioModelo(
        insumo: 'Pan, lechuga, tomate y néctares de durazno',
        cantidad: 'Varios',
        costo_bs: 60.0,
        pagado_por_becario_id: 6,
        pagado_por_nombre: 'Ruth Condori Mamani',
      ),
    ],
    observaciones:
      'Devolución íntegra del 100% efectuada a Angel Javier Ali Paz por Bs 150.00.',
  ),
  RefrigerioModelo(
    id: 4,
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
    becario_encargado_1_id: 7,
    becario_encargado_1_nombre: 'Samuel Mamani',
    becario_encargado_2_id: 8,
    becario_encargado_2_nombre: 'Abigail Flores',
    modalidad_preparacion: 'compra_directa',
    cantidad_raciones: 23,
    costo_unitario_bs: 5.50,
    costo_total_bs: 135.00,
    porcentaje_devolucion: 100,
    monto_devolucion_bs: 135.00,
    estado: 'aprobado_administracion',
    becario_receptor_devolucion_id: 7,
    becario_receptor_devolucion_nombre: 'Samuel Mamani',
    fecha_entrega_devolucion: '2026-10-09 17:30',
    ingredientes: [
      IngredienteRefrigerioModelo(
        insumo: 'Cuñapés horneados tradicionales (50 piezas)',
        cantidad: '50 unidades',
        costo_bs: 85.0,
        pagado_por_becario_id: 7,
        pagado_por_nombre: 'Samuel Mamani',
      ),
      IngredienteRefrigerioModelo(
        insumo: 'Leche entera chocolatada caliente y mandarinas',
        cantidad: '5 litros leche + fruta',
        costo_bs: 50.0,
        pagado_por_becario_id: 8,
        pagado_por_nombre: 'Abigail Flores',
      ),
    ],
    observaciones:
      'Devolución íntegra del 100% efectuada a Samuel Mamani por Bs 135.00.',
  ),
];
