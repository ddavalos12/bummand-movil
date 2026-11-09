double _parsearDouble(dynamic val, [double def = 0.0]) {
  if (val == null) return def;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? def;
}

int _parsearInt(dynamic val, [int def = 0]) {
  if (val == null) return def;
  if (val is int) return val;
  if (val is num) return val.toInt();
  final d = double.tryParse(val.toString());
  return d != null ? d.toInt() : def;
}

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

  factory IngredienteRefrigerioModelo.desdeJson(Map<String, dynamic> json) {
    return IngredienteRefrigerioModelo(
      insumo: json['insumo']?.toString() ?? '',
      cantidad: json['cantidad']?.toString() ?? '',
      costo_bs: _parsearDouble(json['costo_bs'], 0.0),
      pagado_por_becario_id: json['pagado_por_becario_id'] != null
          ? _parsearInt(json['pagado_por_becario_id'])
          : null,
      pagado_por_nombre: json['pagado_por_nombre']?.toString(),
    );
  }

  factory IngredienteRefrigerioModelo.deJson(Map<String, dynamic> json) =>
      IngredienteRefrigerioModelo.desdeJson(json);

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

  // Dupla del Viernes y Devolución 100%
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
  final List<Map<String, dynamic>> firmas_conformidad;

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
    this.costo_unitario_bs = 5.0,
    this.costo_total_bs = 115.0,
    this.porcentaje_devolucion = 100,
    this.monto_devolucion_bs = 115.0,
    this.estado = 'sorteado',
    this.becario_receptor_devolucion_id,
    this.becario_receptor_devolucion_nombre,
    this.fecha_entrega_devolucion,
    this.firmas_conformidad = const [],
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

  bool estaRecogidoPor({int? becario_id, String? nombre}) {
    if (recogido) return true;
    for (final firma in firmas_conformidad) {
      if (becario_id != null && firma['becario_id'] == becario_id) {
        return true;
      }
      if (nombre != null && firma['becario_nombre'] != null) {
        if (firma['becario_nombre'].toString().trim().toLowerCase() ==
            nombre.trim().toLowerCase()) {
          return true;
        }
      }
    }
    return false;
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
      case 'sorteado_programado':
      case 'programado':
        return 'Sorteado / Programado';
      case 'rendido_pendiente':
      case 'rendido':
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
      (becario_encargado_1_nombre != null && becario_encargado_1_nombre!.isNotEmpty) &&
      (becario_encargado_2_nombre != null && becario_encargado_2_nombre!.isNotEmpty);

  bool get devolucionEntregada =>
      (estado == 'aprobado_administracion' || estado == 'aprobado') &&
      becario_receptor_devolucion_nombre != null &&
      becario_receptor_devolucion_nombre!.isNotEmpty;

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
    List<Map<String, dynamic>>? firmas_conformidad,
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
      firmas_conformidad: firmas_conformidad ?? this.firmas_conformidad,
    );
  }

  factory RefrigerioModelo.desdeJson(Map<String, dynamic> json) {
    final lista_ingredientes_raw = json['ingredientes'] as List<dynamic>? ??
        json['detalle_ingredientes'] as List<dynamic>? ??
        [];

    final lista_ingredientes = lista_ingredientes_raw
        .whereType<Map>()
        .map((elem) => IngredienteRefrigerioModelo.desdeJson(Map<String, dynamic>.from(elem)))
        .toList();

    final firmas_raw = json['firmas_conformidad'] as List<dynamic>? ?? [];
    final lista_firmas = firmas_raw
        .whereType<Map>()
        .map((f) => Map<String, dynamic>.from(f))
        .toList();

    final cantidad = _parsearInt(json['cantidad_raciones'], 23);
    final unitario = _parsearDouble(json['costo_unitario_bs'], 5.0);
    final costo_total = _parsearDouble(json['costo_total_bs'], (cantidad * unitario));

    // Mapear fecha en formato YYYY-MM-DD
    String fecha_limpia = json['fecha']?.toString() ?? '';
    if (fecha_limpia.contains('T')) {
      fecha_limpia = fecha_limpia.split('T')[0];
    }

    final evento_o_jornada = json['actividad_viernes']?.toString() ??
        json['evento_vinculado']?.toString() ??
        json['evento_o_jornada']?.toString() ??
        json['descripcion']?.toString() ??
        'Escuela de Líderes (Viernes Formativo)';

    final menu_detalle = json['menu_descripcion']?.toString() ??
        json['menu_detalle']?.toString() ??
        json['observaciones']?.toString() ??
        'Refrigerio institucional oficial';

    final sede_nombre = json['sede']?.toString() ??
        json['sede_nombre']?.toString() ??
        'Oficina Central El Alto';

    final bloque = json['bloque']?.toString() ?? 'Bloque B (Auditorio)';

    final responsable = json['responsable_entrega']?.toString() ??
        'Coordinación General BUMAND';

    final estado = json['estado_reposicion']?.toString() ??
        json['estado']?.toString() ??
        'sorteado';

    final bool fue_recogido = json['recogido'] == true || lista_firmas.isNotEmpty;

    String? hora_rec;
    String? constancia_rec;
    if (json['hora_recojo'] != null) {
      hora_rec = json['hora_recojo'].toString();
    } else if (lista_firmas.isNotEmpty && lista_firmas.first['hora_recojo'] != null) {
      hora_rec = lista_firmas.first['hora_recojo'].toString();
    }

    if (json['codigo_constancia'] != null) {
      constancia_rec = json['codigo_constancia'].toString();
    } else if (lista_firmas.isNotEmpty && lista_firmas.first['codigo_constancia'] != null) {
      constancia_rec = lista_firmas.first['codigo_constancia'].toString();
    }

    return RefrigerioModelo(
      id: _parsearInt(json['id']),
      fecha: fecha_limpia,
      evento_o_jornada: evento_o_jornada,
      menu_detalle: menu_detalle,
      sede_nombre: sede_nombre,
      bloque: bloque,
      responsable_entrega: responsable,
      horario_distribucion: json['horario_distribucion']?.toString() ?? '16:00 - 17:30',
      recogido: fue_recogido,
      hora_recojo: hora_rec,
      codigo_constancia: constancia_rec,
      observaciones: json['observaciones']?.toString(),
      becario_encargado_1_id: json['becario_encargado_1_id'] != null
          ? _parsearInt(json['becario_encargado_1_id'])
          : null,
      becario_encargado_1_nombre: json['becario_encargado_1_nombre']?.toString(),
      becario_encargado_2_id: json['becario_encargado_2_id'] != null
          ? _parsearInt(json['becario_encargado_2_id'])
          : null,
      becario_encargado_2_nombre: json['becario_encargado_2_nombre']?.toString(),
      modalidad_preparacion:
          json['modalidad_preparacion']?.toString() ?? 'cocina_diaconia',
      ingredientes: lista_ingredientes,
      cantidad_raciones: cantidad,
      costo_unitario_bs: unitario,
      costo_total_bs: costo_total,
      porcentaje_devolucion: _parsearInt(json['porcentaje_devolucion'], 100),
      monto_devolucion_bs: _parsearDouble(json['monto_devolucion_bs'], costo_total),
      estado: estado,
      becario_receptor_devolucion_id: json['becario_receptor_devolucion_id'] != null
          ? _parsearInt(json['becario_receptor_devolucion_id'])
          : null,
      becario_receptor_devolucion_nombre:
          json['becario_receptor_devolucion_nombre']?.toString(),
      fecha_entrega_devolucion: json['fecha_entrega_devolucion']?.toString(),
      firmas_conformidad: lista_firmas,
    );
  }

  factory RefrigerioModelo.deJson(Map<String, dynamic> json) =>
      RefrigerioModelo.desdeJson(json);

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'fecha': fecha,
      'evento_o_jornada': evento_o_jornada,
      'evento_vinculado': evento_o_jornada,
      'actividad_viernes': evento_o_jornada,
      'descripcion': evento_o_jornada,
      'menu_detalle': menu_detalle,
      'menu_descripcion': menu_detalle,
      'sede_nombre': sede_nombre,
      'sede': sede_nombre,
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
      'detalle_ingredientes': ingredientes.map((i) => i.aJson()).toList(),
      'cantidad_raciones': cantidad_raciones,
      'costo_unitario_bs': costo_unitario_bs,
      'costo_total_bs': costo_total_bs,
      'presupuesto_referencial_bs': 115.0,
      'porcentaje_devolucion': porcentaje_devolucion,
      'monto_devolucion_bs': monto_devolucion_bs,
      'estado': estado,
      'estado_reposicion': estado,
      'becario_receptor_devolucion_id': becario_receptor_devolucion_id,
      'becario_receptor_devolucion_nombre': becario_receptor_devolucion_nombre,
      'fecha_entrega_devolucion': fecha_entrega_devolucion,
      'firmas_conformidad': firmas_conformidad,
    };
  }
}
