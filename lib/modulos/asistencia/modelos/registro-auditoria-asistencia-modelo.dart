/// Registro institucional de auditoría de asistencia (paridad con
/// `RegistroAuditoriaAsistencia` de `auditoria-asistencia.tsx` en Web).
class RegistroAuditoriaAsistencia {
  static const String ESTADO_APROBADO_ADMINISTRACION = 'aprobado_administracion';
  static const String ESTADO_REVISADO_SUPERVISOR = 'revisado_supervisor';
  static const String ESTADO_CONVALIDADO = 'convalidado';

  final int id;
  final int becario_id;
  final String becario_nombre;
  final String carrera;
  final String sede_nombre;
  final String fecha; // yyyy-MM-dd
  final String tipo; // practicas | escuela_lideres | acciones_servicio
  final String hora_ingreso;
  final String? hora_salida;
  final double? horas_trabajadas;
  final double? distancia_ingreso_m;
  final bool dentro_de_radio;
  final bool dentro_de_horario;

  /// Estado de lectura: conforme | en_curso | tardanza | fuera_geocerca |
  /// revisado_supervisor | convalidado.
  final String estado;

  /// Estado de aprobación del backend: pendiente | revisado_supervisor |
  /// aprobado_administracion | observado.
  final String estado_aprobacion;
  final double? lat_ingreso;
  final double? lng_ingreso;
  final int minutos_retraso;
  final double monto_multa_bs;
  final bool confirmacion_presencial;
  final bool es_viernes;
  final String? convalidado_por;
  final String? observacion_admin;

  /// `true` cuando el registro proviene del catálogo institucional semilla y
  /// no de una respuesta real del backend.
  final bool es_semilla;

  const RegistroAuditoriaAsistencia({
    required this.id,
    required this.becario_id,
    required this.becario_nombre,
    required this.carrera,
    required this.sede_nombre,
    required this.fecha,
    this.tipo = 'practicas',
    required this.hora_ingreso,
    this.hora_salida,
    this.horas_trabajadas,
    this.distancia_ingreso_m,
    this.dentro_de_radio = true,
    this.dentro_de_horario = true,
    required this.estado,
    this.estado_aprobacion = 'pendiente',
    this.lat_ingreso,
    this.lng_ingreso,
    this.minutos_retraso = 0,
    this.monto_multa_bs = 0,
    this.confirmacion_presencial = false,
    this.es_viernes = false,
    this.convalidado_por,
    this.observacion_admin,
    this.es_semilla = false,
  });

  // ---------------------------------------------------------------------------
  // Derivados
  // ---------------------------------------------------------------------------

  bool get esta_aprobado_administracion =>
      estado_aprobacion == ESTADO_APROBADO_ADMINISTRACION ||
      estado == ESTADO_CONVALIDADO;

  bool get esta_revisado_supervisor =>
      estado == ESTADO_REVISADO_SUPERVISOR ||
      estado_aprobacion == ESTADO_REVISADO_SUPERVISOR;

  bool get es_tardanza => estado == 'tardanza' || minutos_retraso > 0;

  /// Monto de multa vigente (0 si fue convalidada por Administración).
  double get multa_vigente_bs {
    if (esta_aprobado_administracion) return 0;
    return monto_multa_bs;
  }

  bool get tiene_multa_vigente => multa_vigente_bs > 0;

  /// Anomalía pendiente de convalidar (tardanza, fuera de geocerca o multa).
  bool get requiere_convalidacion {
    if (esta_aprobado_administracion) return false;
    return estado == 'tardanza' ||
        estado == 'fuera_geocerca' ||
        estado == ESTADO_REVISADO_SUPERVISOR ||
        tiene_multa_vigente;
  }

  String get iniciales {
    final partes = becario_nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes.first[0] + partes[1][0]).toUpperCase();
  }

  String get horario_texto => '$hora_ingreso -> ${hora_salida ?? '--:--'}';

  String get horas_texto => horas_trabajadas == null
      ? 'Jornada en curso'
      : '${horas_trabajadas!.toStringAsFixed(2)} hrs computadas';

  String get distancia_texto => distancia_ingreso_m == null
      ? 'Distancia: --'
      : 'Distancia: ${distancia_ingreso_m!.round()}m';

  String get multa_texto =>
      'Multa Escuela de Líderes: Bs ${multa_vigente_bs.toStringAsFixed(2)} (${minutos_retraso}m)';

  // ---------------------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------------------

  static double calcularMultaEscuelaLideres(int minutos) {
    if (minutos <= 0) return 0;
    if (minutos <= 10) return 10;
    if (minutos <= 30) return 20;
    if (minutos <= 60) return 30;
    return 50;
  }

  RegistroAuditoriaAsistencia copiarCon({
    String? estado,
    String? estado_aprobacion,
    double? monto_multa_bs,
    String? convalidado_por,
    String? observacion_admin,
  }) {
    return RegistroAuditoriaAsistencia(
      id: id,
      becario_id: becario_id,
      becario_nombre: becario_nombre,
      carrera: carrera,
      sede_nombre: sede_nombre,
      fecha: fecha,
      tipo: tipo,
      hora_ingreso: hora_ingreso,
      hora_salida: hora_salida,
      horas_trabajadas: horas_trabajadas,
      distancia_ingreso_m: distancia_ingreso_m,
      dentro_de_radio: dentro_de_radio,
      dentro_de_horario: dentro_de_horario,
      estado: estado ?? this.estado,
      estado_aprobacion: estado_aprobacion ?? this.estado_aprobacion,
      lat_ingreso: lat_ingreso,
      lng_ingreso: lng_ingreso,
      minutos_retraso: minutos_retraso,
      monto_multa_bs: monto_multa_bs ?? this.monto_multa_bs,
      confirmacion_presencial: confirmacion_presencial,
      es_viernes: es_viernes,
      convalidado_por: convalidado_por ?? this.convalidado_por,
      observacion_admin: observacion_admin ?? this.observacion_admin,
      es_semilla: es_semilla,
    );
  }

  /// Convierte una entidad `RegistroAsistencia` del backend (con relaciones
  /// `becario`, `usuario` y `lugar_practica`) al modelo de auditoría.
  factory RegistroAuditoriaAsistencia.desdeMapa(Map<String, dynamic> mapa) {
    double? aDouble(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());
    int aInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;
    bool aBool(dynamic v, bool defecto) {
      if (v is bool) return v;
      if (v == null) return defecto;
      return v.toString().toLowerCase() == 'true';
    }

    final becario = mapa['becario'] is Map
        ? Map<String, dynamic>.from(mapa['becario'] as Map)
        : <String, dynamic>{};
    final usuario = becario['usuario'] is Map
        ? Map<String, dynamic>.from(becario['usuario'] as Map)
        : <String, dynamic>{};
    final lugar = becario['lugar_practica'] is Map
        ? Map<String, dynamic>.from(becario['lugar_practica'] as Map)
        : (mapa['lugar_practica'] is Map
            ? Map<String, dynamic>.from(mapa['lugar_practica'] as Map)
            : <String, dynamic>{});

    final tipo = (mapa['tipo'] ?? mapa['tipo_actividad'] ?? 'practicas')
        .toString();
    final aprobacion =
        (mapa['estado_aprobacion'] ?? 'pendiente').toString();
    final hora_salida = mapa['hora_salida']?.toString();
    final dentro_radio = aBool(mapa['dentro_de_radio'], true);
    final dentro_horario = aBool(mapa['dentro_de_horario'], true);
    final minutos = aInt(mapa['minutos_retraso']);

    String estado;
    if (aprobacion == ESTADO_APROBADO_ADMINISTRACION ||
        mapa['estado'] == ESTADO_CONVALIDADO) {
      estado = ESTADO_CONVALIDADO;
    } else if (aprobacion == ESTADO_REVISADO_SUPERVISOR) {
      estado = ESTADO_REVISADO_SUPERVISOR;
    } else if (hora_salida == null || hora_salida.isEmpty) {
      estado = 'en_curso';
    } else if (!dentro_radio) {
      estado = 'fuera_geocerca';
    } else if (!dentro_horario || minutos > 0) {
      estado = 'tardanza';
    } else {
      estado = 'conforme';
    }

    double monto = aDouble(mapa['monto_multa_bs']) ?? 0;
    if (monto == 0 && tipo == 'escuela_lideres' && minutos > 0) {
      monto = calcularMultaEscuelaLideres(minutos);
    }

    final fecha_cruda = mapa['fecha']?.toString() ?? '';
    final fecha = fecha_cruda.isEmpty ? '' : fecha_cruda.split('T').first;

    String texto_hora(dynamic v, String defecto) {
      final s = v?.toString() ?? '';
      if (s.isEmpty) return defecto;
      return s.length >= 5 ? s.substring(0, 5) : s;
    }

    return RegistroAuditoriaAsistencia(
      id: aInt(mapa['id']),
      becario_id: aInt(mapa['becario_id'] ?? becario['id']),
      becario_nombre: (becario['nombre'] ??
              usuario['nombre'] ??
              mapa['becario_nombre'] ??
              'Becario Institucional')
          .toString(),
      carrera: (becario['carrera'] ?? mapa['carrera'] ?? 'Carrera BUMAND')
          .toString(),
      sede_nombre: (lugar['nombre'] ??
              mapa['sede_nombre'] ??
              mapa['bloque'] ??
              'Oficina Central')
          .toString(),
      fecha: fecha,
      tipo: tipo,
      hora_ingreso: texto_hora(mapa['hora_ingreso'], '--:--'),
      hora_salida: (hora_salida == null || hora_salida.isEmpty)
          ? null
          : texto_hora(hora_salida, '--:--'),
      horas_trabajadas: aDouble(mapa['horas_trabajadas']),
      distancia_ingreso_m: aDouble(mapa['distancia_ingreso_m']),
      dentro_de_radio: dentro_radio,
      dentro_de_horario: dentro_horario,
      estado: estado,
      estado_aprobacion: aprobacion,
      lat_ingreso: aDouble(mapa['lat_ingreso']),
      lng_ingreso: aDouble(mapa['lng_ingreso']),
      minutos_retraso: minutos,
      monto_multa_bs: monto,
      confirmacion_presencial: aBool(
        mapa['confirmacion_presencial'] ?? mapa['confirmado_organizador'],
        false,
      ),
      es_viernes: aBool(mapa['es_viernes'], false),
      convalidado_por: mapa['convalidado_por']?.toString(),
      observacion_admin: mapa['observacion_admin']?.toString(),
    );
  }

  // ---------------------------------------------------------------------------
  // Catálogo institucional semilla (idéntico a `REGISTROS_AUDITORIA_INICIALES`
  // de `auditoria-asistencia.tsx`)
  // ---------------------------------------------------------------------------

  static List<RegistroAuditoriaAsistencia> semillas() => const [
        RegistroAuditoriaAsistencia(
          id: 1,
          becario_id: 101,
          becario_nombre: 'Nilda Amalia Churata Paye',
          carrera: 'Educación Parvularia',
          sede_nombre: 'Centro Infantil Sagrada Familia',
          fecha: '2026-10-09',
          hora_ingreso: '08:12',
          horas_trabajadas: 4.2,
          distancia_ingreso_m: 35,
          estado: 'en_curso',
          lat_ingreso: -16.5023,
          lng_ingreso: -68.1511,
          es_viernes: true,
          confirmacion_presencial: true,
          es_semilla: true,
        ),
        RegistroAuditoriaAsistencia(
          id: 2,
          becario_id: 102,
          becario_nombre: 'Edgar Elias Alarcon Huanca',
          carrera: 'Ingeniería de Sistemas',
          sede_nombre: 'Oficina Central Bloque A',
          fecha: '2026-10-09',
          hora_ingreso: '08:45',
          horas_trabajadas: 3.5,
          distancia_ingreso_m: 48,
          dentro_de_horario: false,
          estado: 'tardanza',
          lat_ingreso: -16.4998,
          lng_ingreso: -68.1502,
          es_viernes: true,
          minutos_retraso: 45,
          confirmacion_presencial: true,
          es_semilla: true,
        ),
        RegistroAuditoriaAsistencia(
          id: 3,
          becario_id: 103,
          becario_nombre: 'Adai Belen Huayta Cardozo',
          carrera: 'Contaduría Pública',
          sede_nombre: 'Agencia Villa Dolores',
          fecha: '2026-10-09',
          hora_ingreso: '07:58',
          hora_salida: '16:30',
          horas_trabajadas: 8.53,
          distancia_ingreso_m: 185,
          dentro_de_radio: false,
          estado: 'fuera_geocerca',
          lat_ingreso: -16.518,
          lng_ingreso: -68.163,
          es_viernes: true,
          es_semilla: true,
        ),
        RegistroAuditoriaAsistencia(
          id: 4,
          becario_id: 104,
          becario_nombre: 'Ronald Franz Mamani Quispe',
          carrera: 'Bioquímica y Farmacia',
          sede_nombre: 'Consultorio Médico San Lucas',
          fecha: '2026-10-09',
          hora_ingreso: '08:00',
          hora_salida: '17:00',
          horas_trabajadas: 9.0,
          distancia_ingreso_m: 22,
          estado: 'conforme',
          lat_ingreso: -16.505,
          lng_ingreso: -68.148,
          es_viernes: true,
          confirmacion_presencial: true,
          es_semilla: true,
        ),
        RegistroAuditoriaAsistencia(
          id: 5,
          becario_id: 105,
          becario_nombre: 'Abigail Ruth Condori Flores',
          carrera: 'Trabajo Social',
          sede_nombre: 'Hogar de Niños Amor y Esperanza',
          fecha: '2026-10-09',
          hora_ingreso: '08:35',
          hora_salida: '17:10',
          horas_trabajadas: 8.58,
          distancia_ingreso_m: 140,
          dentro_de_radio: false,
          dentro_de_horario: false,
          estado: 'convalidado',
          estado_aprobacion: 'aprobado_administracion',
          convalidado_por: 'Lic. Marcos Quispe',
          lat_ingreso: -16.521,
          lng_ingreso: -68.169,
          es_viernes: true,
          minutos_retraso: 35,
          confirmacion_presencial: true,
          es_semilla: true,
        ),
        RegistroAuditoriaAsistencia(
          id: 6,
          becario_id: 106,
          becario_nombre: 'Jhoselin Pamela Mamani Choque',
          carrera: 'Medicina',
          sede_nombre: 'Escuela de Líderes (Auditorio Central)',
          fecha: '2026-10-09',
          tipo: 'escuela_lideres',
          hora_ingreso: '14:50',
          hora_salida: '17:30',
          horas_trabajadas: 2.67,
          distancia_ingreso_m: 18,
          dentro_de_horario: false,
          estado: 'tardanza',
          lat_ingreso: -16.5020,
          lng_ingreso: -68.1510,
          es_viernes: true,
          minutos_retraso: 20,
          monto_multa_bs: 20,
          confirmacion_presencial: true,
          es_semilla: true,
        ),
      ];
}
