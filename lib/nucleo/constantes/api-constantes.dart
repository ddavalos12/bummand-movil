class ApiConstantes {
  // Ajustar la IP al entorno local, 10.0.2.2 para emulador Android, localhost para Windows Desktop
  static const String RUTA_BASE = 'http://10.0.2.2:3002';
  static const String PUNTO_INICIO_SESION = '/autenticacion/inicio-sesion';
  static const String PUNTO_REGISTRO = '/autenticacion/registro';
  static const String PUNTO_ASISTENCIA_INGRESO = '/asistencia/ingreso';
  static const String PUNTO_ASISTENCIA_SALIDA = '/asistencia/salida';
  static const String PUNTO_ASISTENCIA_HISTORIAL = '/asistencia';
  static const String PUNTO_PASAJES_CONFIRMAR = '/pasajes/confirmar-datos';
  static const String PUNTO_PASAJES = '/pasajes';

  // Alias para retrocompatibilidad
  static const String baseUrl = RUTA_BASE;
  static const String loginEndpoint = PUNTO_INICIO_SESION;
  static const String registroEndpoint = PUNTO_REGISTRO;
  static const String asistenciaIngresoEndpoint = PUNTO_ASISTENCIA_INGRESO;
  static const String asistenciaSalidaEndpoint = PUNTO_ASISTENCIA_SALIDA;
  static const String asistenciaHistorialEndpoint = PUNTO_ASISTENCIA_HISTORIAL;
  static const String pasajesConfirmarEndpoint = PUNTO_PASAJES_CONFIRMAR;
}
