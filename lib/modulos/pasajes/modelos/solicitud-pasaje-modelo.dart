import 'recorrido-modelo.dart';

class SolicitudPasajeModelo {
  final int id;
  final String periodo;
  final String estado;
  final double monto_total;
  final double monto_devolucion;
  final String? observaciones;
  final DateTime? datos_confirmados_en;
  final List<RecorridoModelo> recorridos;

  SolicitudPasajeModelo({
    required this.id,
    required this.periodo,
    required this.estado,
    required this.monto_total,
    required this.monto_devolucion,
    this.observaciones,
    this.datos_confirmados_en,
    required this.recorridos,
  });

  // Getters para compatibilidad
  double get montoTotal => monto_total;
  double get montoDevolucion => monto_devolucion;
  DateTime? get datosConfirmadosEn => datos_confirmados_en;

  factory SolicitudPasajeModelo.desdeJson(Map<String, dynamic> json) {
    return SolicitudPasajeModelo(
      id: json['id'] as int,
      periodo: json['periodo'] as String,
      estado: json['estado'] as String,
      monto_total: ((json['monto_total'] ?? json['montoTotal']) as num).toDouble(),
      monto_devolucion: ((json['monto_devolucion'] ?? json['montoDevolucion']) as num).toDouble(),
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
      'observaciones': observaciones,
      'datos_confirmados_en': datos_confirmados_en?.toIso8601String(),
      'recorridos': recorridos.map((r) => r.aJson()).toList(),
    };
  }
}
