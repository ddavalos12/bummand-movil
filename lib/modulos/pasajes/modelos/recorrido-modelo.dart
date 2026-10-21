class RecorridoModelo {
  final int id;
  final DateTime fecha;
  final String tramo;
  final String origen;
  final String destino;
  final double tarifa;
  final String? apoyo_realizado;
  final String? calles_declaradas;
  final String? medio_transporte;
  final String? detalle_tramos_json;
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
    this.calles_declaradas,
    this.medio_transporte,
    this.detalle_tramos_json,
    this.lat_origen,
    this.lng_origen,
    this.lat_destino,
    this.lng_destino,
  });

  // Getters para retrocompatibilidad
  String? get apoyoRealizado => apoyo_realizado;
  String? get callesDeclaradas => calles_declaradas;
  String? get medioTransporte => medio_transporte;
  String? get detalleTramosJson => detalle_tramos_json;
  double? get latOrigen => lat_origen;
  double? get lngOrigen => lng_origen;
  double? get latDestino => lat_destino;
  double? get lngDestino => lng_destino;

  static double _parsearDouble(dynamic valor, [double porDefecto = 0.0]) {
    if (valor == null) return porDefecto;
    if (valor is num) return valor.toDouble();
    if (valor is String) return double.tryParse(valor) ?? porDefecto;
    return porDefecto;
  }

  static double? _parsearDoubleOpcional(dynamic valor) {
    if (valor == null) return null;
    if (valor is num) return valor.toDouble();
    if (valor is String) return double.tryParse(valor);
    return null;
  }

  factory RecorridoModelo.desdeJson(Map<String, dynamic> json) {
    return RecorridoModelo(
      id: json['id'] as int,
      fecha: DateTime.parse(json['fecha'] as String),
      tramo: json['tramo'] as String,
      origen: json['origen'] as String,
      destino: json['destino'] as String,
      tarifa: _parsearDouble(json['tarifa']),
      apoyo_realizado: (json['apoyo_realizado'] ?? json['apoyoRealizado']) as String?,
      calles_declaradas: (json['calles_declaradas'] ?? json['callesDeclaradas']) as String?,
      medio_transporte: (json['medio_transporte'] ?? json['medioTransporte']) as String?,
      detalle_tramos_json: (json['detalle_tramos_json'] ?? json['detalleTramosJson']) as String?,
      lat_origen: _parsearDoubleOpcional(json['lat_origen'] ?? json['latOrigen']),
      lng_origen: _parsearDoubleOpcional(json['lng_origen'] ?? json['lngOrigen']),
      lat_destino: _parsearDoubleOpcional(json['lat_destino'] ?? json['latDestino']),
      lng_destino: _parsearDoubleOpcional(json['lng_destino'] ?? json['lngDestino']),
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
      'calles_declaradas': calles_declaradas,
      'medio_transporte': medio_transporte,
      'detalle_tramos_json': detalle_tramos_json,
      'lat_origen': lat_origen,
      'lng_origen': lng_origen,
      'lat_destino': lat_destino,
      'lng_destino': lng_destino,
    };
  }
}
