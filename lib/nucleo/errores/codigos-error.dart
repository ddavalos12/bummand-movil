class CodigosError {
  static const String ERR_1001 = 'ERR-1001';
  static const String ERR_1002 = 'ERR-1002';
  static const String ERR_1003 = 'ERR-1003';
  static const String ERR_1004 = 'ERR-1004';

  static const String ERR_2001 = 'ERR-2001';
  static const String ERR_2002 = 'ERR-2002';
  static const String ERR_2003 = 'ERR-2003';
  static const String ERR_2004 = 'ERR-2004';

  static const String ERR_3001 = 'ERR-3001';
  static const String ERR_3002 = 'ERR-3002';
  static const String ERR_3003 = 'ERR-3003';
  static const String ERR_3004 = 'ERR-3004';

  static const String ERR_4001 = 'ERR-4001';
  static const String ERR_4002 = 'ERR-4002';
  static const String ERR_4003 = 'ERR-4003';
  static const String ERR_4004 = 'ERR-4004';

  static const String ERR_5001 = 'ERR-5001';
  static const String ERR_5002 = 'ERR-5002';
  static const String ERR_5003 = 'ERR-5003';

  static const String ERR_9001 = 'ERR-9001';
  static const String ERR_9002 = 'ERR-9002';

  static const Map<String, String> DESCRIPCIONES = {
    ERR_1001: 'Credenciales de acceso incorrectas',
    ERR_1002: 'Token JWT expirado o inválido',
    ERR_1003: 'Permiso denegado por rol RBAC',
    ERR_1004: 'Usuario deshabilitado o inactivo',

    ERR_2001: 'Ubicación GPS fuera del radio de tolerancia de la geocerca',
    ERR_2002: 'Marcación de asistencia fuera de la ventana horaria permitida',
    ERR_2003: 'Asistencia de ingreso ya registrada para la fecha',
    ERR_2004: 'No existe marcación de ingreso previa para registrar salida',

    ERR_3001: 'Solicitud rechazada: declaración permitida únicamente a partir del día 24',
    ERR_3002: 'Cálculo de centavos de viáticos inválido o tarifa no homologada',
    ERR_3003: 'Ya existe una solicitud de viáticos enviada o aprobada para este periodo',
    ERR_3004: 'Observación obligatoria no provista para rechazar solicitud',

    ERR_4001: 'Evento institucional no encontrado o finalizado',
    ERR_4002: 'Asistencia al evento fuera del radio geodésico',
    ERR_4003: 'Contenido de reflexión devocional vacío o inferior al mínimo',
    ERR_4004: 'Motivo y justificación detallada obligatoria',

    ERR_5001: 'Conexión de red no disponible / Fallo de comunicación',
    ERR_5002: 'Validación fallida: campos obligatorios vacíos o con formato inválido',
    ERR_5003: 'Servidor no responde: solicitud encolada en modo offline',

    ERR_9001: 'Error interno del servidor no controlado',
    ERR_9002: 'Entidad o recurso no encontrado en base de datos',
  };

  static const Map<String, String> DOMINIOS = {
    ERR_1001: 'AUTENTICACION_SEGURIDAD',
    ERR_1002: 'AUTENTICACION_SEGURIDAD',
    ERR_1003: 'AUTENTICACION_SEGURIDAD',
    ERR_1004: 'AUTENTICACION_SEGURIDAD',

    ERR_2001: 'ASISTENCIA_GEOCERCA',
    ERR_2002: 'ASISTENCIA_GEOCERCA',
    ERR_2003: 'ASISTENCIA_GEOCERCA',
    ERR_2004: 'ASISTENCIA_GEOCERCA',

    ERR_3001: 'PASAJES_VIATICOS',
    ERR_3002: 'PASAJES_VIATICOS',
    ERR_3003: 'PASAJES_VIATICOS',
    ERR_3004: 'PASAJES_VIATICOS',

    ERR_4001: 'DEVOCIONALES_EVENTOS',
    ERR_4002: 'DEVOCIONALES_EVENTOS',
    ERR_4003: 'DEVOCIONALES_EVENTOS',
    ERR_4004: 'DEVOCIONALES_EVENTOS',

    ERR_5001: 'CLIENTE_RED_VALIDACION',
    ERR_5002: 'CLIENTE_RED_VALIDACION',
    ERR_5003: 'CLIENTE_RED_VALIDACION',

    ERR_9001: 'SISTEMA',
    ERR_9002: 'SISTEMA',
  };

  static const Map<String, String> SUGERENCIAS = {
    ERR_1001: 'Verifique sus credenciales e intente nuevamente. Si olvidó su contraseña, contacte a administración.',
    ERR_1002: 'Su sesión ha expirado por inactividad. Vuelva a iniciar sesión en la plataforma.',
    ERR_1003: 'No cuenta con permisos para realizar esta acción. Solicite elevación de privilegios si corresponde.',
    ERR_1004: 'Cuenta desactivada. Comuníquese con la administración institucional de Diaconía.',

    ERR_2001: 'Acérquese al punto geográfico autorizado del lugar de práctica o iglesia y active alta precisión GPS.',
    ERR_2002: 'Registre su asistencia únicamente dentro del rango horario asignado a su turno o actividad.',
    ERR_2003: 'La marcación de ingreso ya fue registrada previamente hoy. Registre su salida al finalizar.',
    ERR_2004: 'No se detectó un ingreso previo registrado hoy. Notifique a su supervisor pastoral o tutor.',

    ERR_3001: 'Conserve los recorridos en estado borrador. Podrá remitir la declaración oficial a partir del día 24.',
    ERR_3002: 'Verifique que los montos declarados coincidan exactamente con las rutas y tarifas autorizadas.',
    ERR_3003: 'Ya cuenta con una solicitud registrada para este mes. Revise el estado en el módulo de pasajes.',
    ERR_3004: 'Debe fundamentar por escrito el motivo de la observación o rechazo para orientar al becario.',

    ERR_4001: 'Verifique la agenda institucional. El evento seleccionado ya concluyó o no está disponible.',
    ERR_4002: 'Sitúese dentro del recinto oficial del evento antes de confirmar su asistencia.',
    ERR_4003: 'Ingrese una reflexión personal meditada cumpliendo la extensión mínima requerida.',
    ERR_4004: 'Detalle los motivos de fuerza mayor y adjunte la evidencia o respaldo correspondiente.',

    ERR_5001: 'Compruebe su conexión a internet (Wi-Fi o datos móviles) y vuelva a intentarlo.',
    ERR_5002: 'Revise los campos marcados en el formulario y proporcione información válida.',
    ERR_5003: 'No se preocupe: su acción se guardó y se sincronizará automáticamente al recuperar conexión.',

    ERR_9001: 'Ocurrió un error inesperado. Intente nuevamente en unos minutos o reporte el incidente a soporte.',
    ERR_9002: 'El recurso solicitado no fue encontrado. Verifique la dirección o actualice el catálogo.',
  };

  static String obtenerDescripcion(String? codigo) {
    if (codigo == null) return 'Error general no especificado';
    return DESCRIPCIONES[codigo] ?? 'Error reportado por el sistema ($codigo)';
  }

  static String obtenerDominio(String? codigo) {
    if (codigo == null) return 'SISTEMA';
    return DOMINIOS[codigo] ?? 'SISTEMA';
  }

  static String obtenerSugerencia(String? codigo) {
    if (codigo == null) return 'Intente nuevamente más tarde.';
    return SUGERENCIAS[codigo] ?? 'Consulte con el área de soporte técnico de BUMAND.';
  }
}
