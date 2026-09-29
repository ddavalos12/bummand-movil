class RecorridoModelo {
  final int id;
  final DateTime fecha;
  final String tramo;
  final String origen;
  final String destino;
  final double tarifa;
  final String? apoyo_realizado;
  final double? lat_origen;
  final double? lng_origen;
  final double? lat_destino;
  final double? lng_destino;

  RecorridoModelo({
    required this.id,
    required this.fecha,
    required this.tramo,
    required this.origen,
    required this.destino,
    required this.tarifa,
    this.apoyo_realizado,
    this.lat_origen,
    this.lng_origen,
    this.lat_destino,
    this.lng_destino,
  });

  // Getters para retrocompatibilidad
  String? get apoyoRealizado => apoyo_realizado;
  double? get latOrigen => lat_origen;
  double? get lngOrigen => lng_origen;
  double? get latDestino => lat_destino;
  double? get lngDestino => lng_destino;

  factory RecorridoModelo.desdeJson(Map<String, dynamic> json) {
    return RecorridoModelo(
      id: json['id'] as int,
      fecha: DateTime.parse(json['fecha'] as String),
      tramo: json['tramo'] as String,
      origen: json['origen'] as String,
      destino: json['destino'] as String,
      tarifa: (json['tarifa'] as num).toDouble(),
      apoyo_realizado: (json['apoyo_realizado'] ?? json['apoyoRealizado']) as String?,
      lat_origen: (json['lat_origen'] ?? json['latOrigen']) != null
          ? ((json['lat_origen'] ?? json['latOrigen']) as num).toDouble()
          : null,
      lng_origen: (json['lng_origen'] ?? json['lngOrigen']) != null
          ? ((json['lng_origen'] ?? json['lngOrigen']) as num).toDouble()
          : null,
      lat_destino: (json['lat_destino'] ?? json['latDestino']) != null
          ? ((json['lat_destino'] ?? json['latDestino']) as num).toDouble()
          : null,
      lng_destino: (json['lng_destino'] ?? json['lngDestino']) != null
          ? ((json['lng_destino'] ?? json['lngDestino']) as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'tramo': tramo,
      'origen': origen,
      'destino': destino,
      'tarifa': tarifa,
      'apoyo_realizado': apoyo_realizado,
      'lat_origen': lat_origen,
      'lng_origen': lng_origen,
      'lat_destino': lat_destino,
      'lng_destino': lng_destino,
    };
  }
}
