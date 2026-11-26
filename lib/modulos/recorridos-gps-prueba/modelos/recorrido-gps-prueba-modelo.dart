import 'dart:math';

import 'package:geolocator/geolocator.dart';

enum EstadoRecorridoGpsPrueba {
  inactivo,
  en_curso,
  finalizado,
}

String generarUuidV4() {
  final aleatorio = Random.secure();
  final bytes = List<int>.generate(16, (_) => aleatorio.nextInt(256));
  bytes[6] = (bytes[6] & 0x0F) | 0x40;
  bytes[8] = (bytes[8] & 0x3F) | 0x80;

  String hexByte(int valor) => valor.toRadixString(16).padLeft(2, '0');
  final partes = bytes.map(hexByte).toList();
  return '${partes.sublist(0, 4).join()}-'
      '${partes.sublist(4, 6).join()}-'
      '${partes.sublist(6, 8).join()}-'
      '${partes.sublist(8, 10).join()}-'
      '${partes.sublist(10, 16).join()}';
}

class PuntoGpsPruebaModelo {
  final int secuencia;
  final double latitud;
  final double longitud;
  final double precision_m;
  final double? altitud_m;
  final double? velocidad_mps;
  final double? rumbo_grados;
  final String hora_dispositivo_iso;
  final String? hora_gps_iso;
  final int? desfase_reloj_seg;
  final int reloj_monotonico_ms;
  final bool es_ubicacion_simulada;
  final String modo_captura;
  final String hash_punto;
  final String? hash_anterior;

  const PuntoGpsPruebaModelo({
    required this.secuencia,
    required this.latitud,
    required this.longitud,
    required this.precision_m,
    this.altitud_m,
    this.velocidad_mps,
    this.rumbo_grados,
    required this.hora_dispositivo_iso,
    this.hora_gps_iso,
    this.desfase_reloj_seg,
    required this.reloj_monotonico_ms,
    required this.es_ubicacion_simulada,
    required this.modo_captura,
    required this.hash_punto,
    this.hash_anterior,
  });

  static double? _parsearDoubleOpcional(dynamic valor) {
    if (valor == null) return null;
    if (valor is num) return valor.toDouble();
    if (valor is String) return double.tryParse(valor);
    return null;
  }

  static int? _parsearEnteroOpcional(dynamic valor) {
    if (valor == null) return null;
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    if (valor is String) return int.tryParse(valor);
    return null;
  }

  factory PuntoGpsPruebaModelo.desdeMapa(Map<String, dynamic> mapa) {
    return PuntoGpsPruebaModelo(
      secuencia: _parsearEnteroOpcional(mapa['secuencia']) ?? 1,
      latitud: _parsearDoubleOpcional(mapa['latitud']) ?? 0.0,
      longitud: _parsearDoubleOpcional(mapa['longitud']) ?? 0.0,
      precision_m: _parsearDoubleOpcional(mapa['precision_m']) ?? 0.0,
      altitud_m: _parsearDoubleOpcional(mapa['altitud_m']),
      velocidad_mps: _parsearDoubleOpcional(mapa['velocidad_mps']),
      rumbo_grados: _parsearDoubleOpcional(mapa['rumbo_grados']),
      hora_dispositivo_iso: (mapa['hora_dispositivo_iso'] ?? '') as String,
      hora_gps_iso: mapa['hora_gps_iso'] as String?,
      desfase_reloj_seg: _parsearEnteroOpcional(mapa['desfase_reloj_seg']),
      reloj_monotonico_ms:
          _parsearEnteroOpcional(mapa['reloj_monotonico_ms']) ?? 0,
      es_ubicacion_simulada: mapa['es_ubicacion_simulada'] == true,
      modo_captura: (mapa['modo_captura'] ?? 'offline') as String,
      hash_punto: (mapa['hash_punto'] ?? '') as String,
      hash_anterior: mapa['hash_anterior'] as String?,
    );
  }

  Map<String, dynamic> aMapa() {
    return {
      'secuencia': secuencia,
      'latitud': latitud,
      'longitud': longitud,
      'precision_m': precision_m,
      'altitud_m': altitud_m,
      'velocidad_mps': velocidad_mps,
      'rumbo_grados': rumbo_grados,
      'hora_dispositivo_iso': hora_dispositivo_iso,
      'hora_gps_iso': hora_gps_iso,
      'desfase_reloj_seg': desfase_reloj_seg,
      'reloj_monotonico_ms': reloj_monotonico_ms,
      'es_ubicacion_simulada': es_ubicacion_simulada,
      'modo_captura': modo_captura,
      'hash_punto': hash_punto,
      'hash_anterior': hash_anterior,
    };
  }
}

class SesionRecorridoGpsPrueba {
  final String uuid_sesion;
  final EstadoRecorridoGpsPrueba estado;
  final String? etiqueta_prueba;
  final String? dispositivo_info;
  final String? hora_inicio_dispositivo;
  final String? hora_fin_dispositivo;
  final String? hora_inicio_gps;
  final String? hora_fin_gps;
  final int zona_horaria_offset_min;
  final int duracion_monotonica_seg;
  final int intervalo_minutos;
  final String? hash_integridad_cliente;
  final List<PuntoGpsPruebaModelo> puntos;

  const SesionRecorridoGpsPrueba({
    required this.uuid_sesion,
    required this.estado,
    this.etiqueta_prueba,
    this.dispositivo_info,
    this.hora_inicio_dispositivo,
    this.hora_fin_dispositivo,
    this.hora_inicio_gps,
    this.hora_fin_gps,
    required this.zona_horaria_offset_min,
    required this.duracion_monotonica_seg,
    this.intervalo_minutos = 5,
    this.hash_integridad_cliente,
    required this.puntos,
  });

  factory SesionRecorridoGpsPrueba.inicial() {
    return SesionRecorridoGpsPrueba(
      uuid_sesion: generarUuidV4(),
      estado: EstadoRecorridoGpsPrueba.inactivo,
      zona_horaria_offset_min: DateTime.now().timeZoneOffset.inMinutes,
      duracion_monotonica_seg: 0,
      intervalo_minutos: 5,
      puntos: const [],
    );
  }

  SesionRecorridoGpsPrueba copiarCon({
    String? uuid_sesion,
    EstadoRecorridoGpsPrueba? estado,
    String? etiqueta_prueba,
    String? dispositivo_info,
    String? hora_inicio_dispositivo,
    String? hora_fin_dispositivo,
    String? hora_inicio_gps,
    String? hora_fin_gps,
    int? zona_horaria_offset_min,
    int? duracion_monotonica_seg,
    int? intervalo_minutos,
    String? hash_integridad_cliente,
    List<PuntoGpsPruebaModelo>? puntos,
  }) {
    return SesionRecorridoGpsPrueba(
      uuid_sesion: uuid_sesion ?? this.uuid_sesion,
      estado: estado ?? this.estado,
      etiqueta_prueba: etiqueta_prueba ?? this.etiqueta_prueba,
      dispositivo_info: dispositivo_info ?? this.dispositivo_info,
      hora_inicio_dispositivo:
          hora_inicio_dispositivo ?? this.hora_inicio_dispositivo,
      hora_fin_dispositivo: hora_fin_dispositivo ?? this.hora_fin_dispositivo,
      hora_inicio_gps: hora_inicio_gps ?? this.hora_inicio_gps,
      hora_fin_gps: hora_fin_gps ?? this.hora_fin_gps,
      zona_horaria_offset_min:
          zona_horaria_offset_min ?? this.zona_horaria_offset_min,
      duracion_monotonica_seg:
          duracion_monotonica_seg ?? this.duracion_monotonica_seg,
      intervalo_minutos: intervalo_minutos ?? this.intervalo_minutos,
      hash_integridad_cliente:
          hash_integridad_cliente ?? this.hash_integridad_cliente,
      puntos: puntos != null ? List.unmodifiable(puntos) : this.puntos,
    );
  }

  double calcularDistanciaTotalMetros() {
    if (puntos.length < 2) return 0.0;
    double acumulado = 0.0;
    for (int i = 1; i < puntos.length; i++) {
      final anterior = puntos[i - 1];
      final actual = puntos[i];
      acumulado += Geolocator.distanceBetween(
        anterior.latitud,
        anterior.longitud,
        actual.latitud,
        actual.longitud,
      );
    }
    return acumulado;
  }

  static EstadoRecorridoGpsPrueba _parsearEstado(String? valor) {
    switch (valor) {
      case 'en_curso':
        return EstadoRecorridoGpsPrueba.en_curso;
      case 'finalizado':
        return EstadoRecorridoGpsPrueba.finalizado;
      default:
        return EstadoRecorridoGpsPrueba.inactivo;
    }
  }

  factory SesionRecorridoGpsPrueba.desdeMapa(Map<String, dynamic> mapa) {
    final lista_cruda = mapa['puntos'] as List<dynamic>? ?? const [];
    final puntos_parseados = lista_cruda
        .whereType<Map<String, dynamic>>()
        .map(PuntoGpsPruebaModelo.desdeMapa)
        .toList();

    return SesionRecorridoGpsPrueba(
      uuid_sesion: (mapa['uuid_sesion'] ?? generarUuidV4()) as String,
      estado: _parsearEstado(mapa['estado'] as String?),
      etiqueta_prueba: mapa['etiqueta_prueba'] as String?,
      dispositivo_info: mapa['dispositivo_info'] as String?,
      hora_inicio_dispositivo: mapa['hora_inicio_dispositivo'] as String?,
      hora_fin_dispositivo: mapa['hora_fin_dispositivo'] as String?,
      hora_inicio_gps: mapa['hora_inicio_gps'] as String?,
      hora_fin_gps: mapa['hora_fin_gps'] as String?,
      zona_horaria_offset_min:
          (mapa['zona_horaria_offset_min'] as num?)?.toInt() ??
              DateTime.now().timeZoneOffset.inMinutes,
      duracion_monotonica_seg:
          (mapa['duracion_monotonica_seg'] as num?)?.toInt() ?? 0,
      intervalo_minutos: (mapa['intervalo_minutos'] as num?)?.toInt() ?? 5,
      hash_integridad_cliente: mapa['hash_integridad_cliente'] as String?,
      puntos: List.unmodifiable(puntos_parseados),
    );
  }

  Map<String, dynamic> aMapa() {
    return {
      'uuid_sesion': uuid_sesion,
      'estado': estado.name,
      'etiqueta_prueba': etiqueta_prueba,
      'dispositivo_info': dispositivo_info,
      'hora_inicio_dispositivo': hora_inicio_dispositivo,
      'hora_fin_dispositivo': hora_fin_dispositivo,
      'hora_inicio_gps': hora_inicio_gps,
      'hora_fin_gps': hora_fin_gps,
      'zona_horaria_offset_min': zona_horaria_offset_min,
      'duracion_monotonica_seg': duracion_monotonica_seg,
      'intervalo_minutos': intervalo_minutos,
      'hash_integridad_cliente': hash_integridad_cliente,
      'puntos': puntos.map((p) => p.aMapa()).toList(),
    };
  }

  Map<String, dynamic> aPayloadApi() {
    final etiqueta_limpia = etiqueta_prueba?.trim();
    return {
      'uuid_sesion': uuid_sesion,
      'etiqueta_prueba':
          (etiqueta_limpia != null && etiqueta_limpia.isNotEmpty)
              ? etiqueta_limpia
              : null,
      'dispositivo_info': dispositivo_info,
      'hora_inicio_dispositivo': hora_inicio_dispositivo,
      'hora_fin_dispositivo': hora_fin_dispositivo,
      'hora_inicio_gps': hora_inicio_gps,
      'hora_fin_gps': hora_fin_gps,
      'zona_horaria_offset_min': zona_horaria_offset_min,
      'duracion_monotonica_seg': duracion_monotonica_seg,
      'intervalo_minutos': intervalo_minutos,
      'hash_integridad_cliente': hash_integridad_cliente,
      'puntos': puntos.map((p) => p.aMapa()).toList(),
    };
  }
}
