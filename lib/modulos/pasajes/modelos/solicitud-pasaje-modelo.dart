import 'recorrido-modelo.dart';

class SolicitudPasajeModelo {
  final int id;
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

    return SolicitudPasajeModelo(
      id: json['id'] as int,
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
