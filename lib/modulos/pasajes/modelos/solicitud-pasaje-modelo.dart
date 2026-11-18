import 'recorrido-modelo.dart';

class SolicitudPasajeModelo {
  final int id;
  final int? becario_id;
  final String? becario_nombre;
  final int? supervisor_id;
  final String periodo;
  final String estado;
  final double monto_total;
  final double monto_devolucion;
  final double multas_asistencia_bs;
  final double monto_liquido_pagable;
  final String? observaciones;
  final DateTime? datos_confirmados_en;
  final List<RecorridoModelo> recorridos;

  SolicitudPasajeModelo({
    required this.id,
    this.becario_id,
    this.becario_nombre,
    this.supervisor_id,
    required this.periodo,
    required this.estado,
    required this.monto_total,
    required this.monto_devolucion,
    this.multas_asistencia_bs = 0.0,
    double? monto_liquido_pagable,
    this.observaciones,
    this.datos_confirmados_en,
    required this.recorridos,
  }) : monto_liquido_pagable = monto_liquido_pagable ??
            (monto_devolucion - multas_asistencia_bs)
                .clamp(0.0, double.infinity);

  // Getters para compatibilidad
  double get montoTotal => monto_total;
  double get montoDevolucion => monto_devolucion;
  double get multasAsistenciaBs => multas_asistencia_bs;
  double get montoLiquidoPagable => monto_liquido_pagable;
  DateTime? get datosConfirmadosEn => datos_confirmados_en;

  static double _parsearMonto(dynamic valor) {
    if (valor == null) return 0.0;
    if (valor is num) return valor.toDouble();
    if (valor is String) return double.tryParse(valor) ?? 0.0;
    return 0.0;
  }

  factory SolicitudPasajeModelo.desdeJson(Map<String, dynamic> json) {
    final monto_dev =
        _parsearMonto(json['monto_devolucion'] ?? json['montoDevolucion']);
    final multas = _parsearMonto(
      json['multas_asistencia_bs'] ??
          json['multasAsistenciaBs'] ??
          json['monto_multa_descontada'],
    );
    final raw_liquido =
        json['monto_liquido_pagable'] ??
        json['montoLiquidoPagable'] ??
        json['monto_neto_pagar'];
    final liquido = raw_liquido != null
        ? _parsearMonto(raw_liquido)
        : (monto_dev - multas).clamp(0.0, double.infinity);

    final becario_mapa = json['becario'] is Map
        ? Map<String, dynamic>.from(json['becario'] as Map)
        : null;
    final usuario_becario = becario_mapa?['usuario'] is Map
        ? Map<String, dynamic>.from(becario_mapa!['usuario'] as Map)
        : null;
    final sup_raw = json['supervisor_id'] ??
        json['supervisorId'] ??
        json['mentor_id'] ??
        becario_mapa?['supervisor_id'] ??
        (becario_mapa?['supervisor'] is Map
            ? (becario_mapa!['supervisor'] as Map)['id']
            : null);
    final bec_id_raw = json['becario_id'] ?? becario_mapa?['id'];
    final bec_nom_raw = json['becario_nombre'] ??
        becario_mapa?['nombre'] ??
        usuario_becario?['nombre'];

    return SolicitudPasajeModelo(
      id: json['id'] as int,
      becario_id: bec_id_raw is int
          ? bec_id_raw
          : int.tryParse(bec_id_raw?.toString() ?? ''),
      becario_nombre: bec_nom_raw?.toString(),
      supervisor_id: sup_raw is int
          ? sup_raw
          : int.tryParse(sup_raw?.toString() ?? ''),
      periodo: json['periodo'] as String,
      estado: json['estado'] as String,
      monto_total: _parsearMonto(json['monto_total'] ?? json['montoTotal']),
      monto_devolucion: monto_dev,
      multas_asistencia_bs: multas,
      monto_liquido_pagable: liquido,
      observaciones: json['observaciones'] as String?,
      datos_confirmados_en: (json['datos_confirmados_en'] ?? json['datosConfirmadosEn']) != null
          ? DateTime.parse((json['datos_confirmados_en'] ?? json['datosConfirmadosEn']) as String)
          : null,
      recorridos:
          (json['recorridos'] as List<dynamic>?)
              ?.map((r) => RecorridoModelo.desdeJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      if (becario_id != null) 'becario_id': becario_id,
      if (becario_nombre != null) 'becario_nombre': becario_nombre,
      if (supervisor_id != null) 'supervisor_id': supervisor_id,
      'periodo': periodo,
      'estado': estado,
      'monto_total': monto_total,
      'monto_devolucion': monto_devolucion,
      'multas_asistencia_bs': multas_asistencia_bs,
      'monto_liquido_pagable': monto_liquido_pagable,
      'observaciones': observaciones,
      'datos_confirmados_en': datos_confirmados_en?.toIso8601String(),
      'recorridos': recorridos.map((r) => r.aJson()).toList(),
    };
  }
}
