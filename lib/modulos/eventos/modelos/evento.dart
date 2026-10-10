import 'dart:math' as math;

class Evento {
  final int id;
  final int? creador_id;
  final String titulo;
  final String descripcion;
  final String tipo_evento;
  final String fecha;
  final String hora_inicio;
  final String hora_fin;
  final double latitud;
  final double longitud;
  final double radio_tolerancia_m;
  final String direccion_referencia;
  final String estado;
  final DateTime? created_at;
  final DateTime? updated_at;
  final AsistenciaEvento? mi_asistencia;

  const Evento({
    required this.id,
    this.creador_id,
    required this.titulo,
    required this.descripcion,
    required this.tipo_evento,
    required this.fecha,
    required this.hora_inicio,
    required this.hora_fin,
    required this.latitud,
    required this.longitud,
    required this.radio_tolerancia_m,
    required this.direccion_referencia,
    required this.estado,
    this.created_at,
    this.updated_at,
    this.mi_asistencia,
  });

  factory Evento.desdeMapa(Map<String, dynamic> mapa) {
    return Evento(
      id: (mapa['id'] as num).toInt(),
      creador_id: (mapa['creador_id'] as num?)?.toInt(),
      titulo: (mapa['titulo'] as String?) ?? '',
      descripcion: (mapa['descripcion'] as String?) ?? '',
      tipo_evento: (mapa['tipo_evento'] as String?) ?? 'reunion',
      fecha: mapa['fecha'] != null ? mapa['fecha'].toString().split('T')[0] : '',
      hora_inicio: (mapa['hora_inicio'] as String?) ?? '08:00',
      hora_fin: (mapa['hora_fin'] as String?) ?? '12:00',
      latitud: double.tryParse(mapa['latitud']?.toString() ?? '0') ?? 0.0,
      longitud: double.tryParse(mapa['longitud']?.toString() ?? '0') ?? 0.0,
      radio_tolerancia_m: double.tryParse(
            (mapa['radio_tolerancia_m'] ?? mapa['radioToleranciaM'] ?? 100)
                .toString(),
          ) ??
          100.0,
      direccion_referencia:
          (mapa['direccion_referencia'] as String?) ?? 'La Paz, Bolivia',
      estado: (mapa['estado'] as String?) ?? 'programado',
      created_at: mapa['created_at'] != null
          ? DateTime.tryParse(mapa['created_at'].toString())
          : null,
      updated_at: mapa['updated_at'] != null
          ? DateTime.tryParse(mapa['updated_at'].toString())
          : null,
      mi_asistencia: mapa['mi_asistencia'] != null
          ? AsistenciaEvento.desdeMapa(
              mapa['mi_asistencia'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> aMapa() {
    return {
      'id': id,
      'creador_id': creador_id,
      'titulo': titulo,
      'descripcion': descripcion,
      'tipo_evento': tipo_evento,
      'fecha': fecha,
      'hora_inicio': hora_inicio,
      'hora_fin': hora_fin,
      'latitud': latitud,
      'longitud': longitud,
      'radio_tolerancia_m': radio_tolerancia_m,
      'direccion_referencia': direccion_referencia,
      'estado': estado,
      if (created_at != null) 'created_at': created_at!.toIso8601String(),
      if (updated_at != null) 'updated_at': updated_at!.toIso8601String(),
      if (mi_asistencia != null) 'mi_asistencia': mi_asistencia!.aMapa(),
    };
  }

  /// Calcula la distancia geodésica mediante la fórmula de Haversine en metros
  double calcularDistanciaMetros(double lat_usuario, double lng_usuario) {
    const radio_tierra_m = 6371000.0;
    final d_lat = (lat_usuario - latitud) * (math.pi / 180.0);
    final d_lng = (lng_usuario - longitud) * (math.pi / 180.0);

    final a = math.sin(d_lat / 2.0) * math.sin(d_lat / 2.0) +
        math.cos(latitud * (math.pi / 180.0)) *
            math.cos(lat_usuario * (math.pi / 180.0)) *
            math.sin(d_lng / 2.0) *
            math.sin(d_lng / 2.0);

    final c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a));
    return radio_tierra_m * c;
  }

  /// Verifica si una fecha y hora está dentro del rango permitido (con tolerancia de 45 min antes)
  bool estaEnHorario([DateTime? referencia]) {
    final ahora = referencia ?? DateTime.now();
    final partes_fecha = fecha.split('-');
    if (partes_fecha.length != 3) return true;

    final anio = int.tryParse(partes_fecha[0]) ?? ahora.year;
    final mes = int.tryParse(partes_fecha[1]) ?? ahora.month;
    final dia = int.tryParse(partes_fecha[2]) ?? ahora.day;

    final partes_inicio = hora_inicio.split(':');
    final partes_fin = hora_fin.split(':');

    final hora_i = int.tryParse(partes_inicio[0]) ?? 8;
    final min_i = partes_inicio.length > 1 ? (int.tryParse(partes_inicio[1]) ?? 0) : 0;

    final hora_f = int.tryParse(partes_fin[0]) ?? 18;
    final min_f = partes_fin.length > 1 ? (int.tryParse(partes_fin[1]) ?? 0) : 0;

    final inicio = DateTime(anio, mes, dia, hora_i, min_i)
        .subtract(const Duration(minutes: 45));
    final fin = DateTime(anio, mes, dia, hora_f, min_f)
        .add(const Duration(minutes: 30));

    return ahora.isAfter(inicio) && ahora.isBefore(fin);
  }

  bool estaDentroDeRadio(double lat_usuario, double lng_usuario) {
    final distancia = calcularDistanciaMetros(lat_usuario, lng_usuario);
    return distancia <= radio_tolerancia_m;
  }
}

class AsistenciaEvento {
  final int id;
  final int evento_id;
  final int becario_id;
  final String hora_marcacion;
  final double latitud;
  final double longitud;
  final double distancia_m;
  final bool dentro_de_radio;
  final String estado;
  final String? observaciones;
  final DateTime? created_at;

  const AsistenciaEvento({
    required this.id,
    required this.evento_id,
    required this.becario_id,
    required this.hora_marcacion,
    required this.latitud,
    required this.longitud,
    required this.distancia_m,
    required this.dentro_de_radio,
    required this.estado,
    this.observaciones,
    this.created_at,
  });

  factory AsistenciaEvento.desdeMapa(Map<String, dynamic> mapa) {
    return AsistenciaEvento(
      id: (mapa['id'] as num?)?.toInt() ?? 0,
      evento_id: (mapa['evento_id'] as num?)?.toInt() ?? 0,
      becario_id: (mapa['becario_id'] as num?)?.toInt() ?? 0,
      hora_marcacion: (mapa['hora_marcacion'] as String?) ?? '',
      latitud: double.tryParse(mapa['latitud']?.toString() ?? '0') ?? 0.0,
      longitud: double.tryParse(mapa['longitud']?.toString() ?? '0') ?? 0.0,
      distancia_m: double.tryParse(mapa['distancia_m']?.toString() ?? '0') ?? 0.0,
      dentro_de_radio: mapa['dentro_de_radio'] == true ||
          mapa['dentro_de_radio'] == 1 ||
          mapa['dentro_de_radio'] == 'true',
      estado: (mapa['estado'] as String?) ?? 'presente',
      observaciones: mapa['observaciones'] as String?,
      created_at: mapa['created_at'] != null
          ? DateTime.tryParse(mapa['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> aMapa() {
    return {
      'id': id,
      'evento_id': evento_id,
      'becario_id': becario_id,
      'hora_marcacion': hora_marcacion,
      'latitud': latitud,
      'longitud': longitud,
      'distancia_m': distancia_m,
      'dentro_de_radio': dentro_de_radio,
      'estado': estado,
      'observaciones': observaciones,
      if (created_at != null) 'created_at': created_at!.toIso8601String(),
    };
  }
}
