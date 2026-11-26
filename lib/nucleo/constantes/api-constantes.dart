class ApiConstantes {
  static const String URL_PRODUCCION = 'https://bummand-backend.vercel.app';
  static const String URL_FRONTEND = String.fromEnvironment(
    'FRONTEND_URL',
    defaultValue: 'https://bummand-frontend.vercel.app',
  );
  static const String _URL_ENTORNO = String.fromEnvironment(
    'API_URL',
    defaultValue: URL_PRODUCCION,
  );

  static String get RUTA_BASE =>
      _URL_ENTORNO.replaceFirst(RegExp(r'/+$'), '');

  // Rutas base requeridas por el ecosistema BUMAND
  static const String PUNTO_ASISTENCIA = '/api/asistencia';
  static const String PUNTO_PASAJES = '/api/pasajes';
  static const String PUNTO_DEVOCIONALES = '/api/devocionales';
  static const String PUNTO_EVENTOS = '/api/eventos';
  static const String PUNTO_JUSTIFICACIONES = '/api/justificaciones';
  static const String PUNTO_PASAJES_PARADAS = '/api/pasajes/paradas';
  static const String PUNTO_CITAS_SEGUIMIENTO = '/api/devocionales/citas';

  // Rutas específicas de módulos
  static const String PUNTO_INICIO_SESION = '/api/autenticacion/inicio-sesion';
  static const String PUNTO_REGISTRO = '/api/autenticacion/registro';
  static const String PUNTO_VERIFICAR_CI = '/api/autenticacion/verificar-ci';
  static const String PUNTO_ASISTENCIA_INGRESO = '/api/asistencia/ingreso';
  static const String PUNTO_ASISTENCIA_SALIDA = '/api/asistencia/salida';
  static const String PUNTO_ASISTENCIA_HISTORIAL = '/api/asistencia';
  static const String PUNTO_PASAJES_CONFIRMAR = '/api/pasajes/confirmar-datos';
  static const String PUNTO_NOTIFICACIONES = '/api/notificaciones/mis-notificaciones';
  static const String PUNTO_NOTIFICACIONES_CONTEO = '/api/notificaciones/no-leidas/conteo';
  static const String PUNTO_BIBLIA_VERSICULO = '/api/biblia/versiculo-diario';
  static const String PUNTO_BIBLIA_OFFLINE = '/api/biblia/paquete-offline';
  static const String PUNTO_BIBLIA_PASAJE = '/api/biblia/pasaje';
  static const String PUNTO_BECARIOS_ESTADO_CONFIRMACION = '/api/becarios/estado-confirmacion-datos';
  static const String PUNTO_BECARIOS_CONFIRMAR_DATOS = '/api/becarios/confirmar-datos';
  static const String PUNTO_USUARIOS = '/api/usuarios';
  static const String PUNTO_USUARIOS_MI_PERFIL = '/api/usuarios/mi-perfil';
  static const String PUNTO_USUARIOS_MI_PERFIL_CORREOS = '/api/usuarios/mi-perfil/correos';
  static const String PUNTO_USUARIOS_MI_PERFIL_CONTRASENA = '/api/usuarios/mi-perfil/contrasena';
  static const String PUNTO_RECORRIDOS_GPS_PRUEBA = '/api/recorridos-gps-prueba';

  // Alias para retrocompatibilidad
  static String get baseUrl => RUTA_BASE;
  static const String loginEndpoint = PUNTO_INICIO_SESION;
  static const String registroEndpoint = PUNTO_REGISTRO;
  static const String asistenciaIngresoEndpoint = PUNTO_ASISTENCIA_INGRESO;
  static const String asistenciaSalidaEndpoint = PUNTO_ASISTENCIA_SALIDA;
  static const String asistenciaHistorialEndpoint = PUNTO_ASISTENCIA_HISTORIAL;
  static const String pasajesConfirmarEndpoint = PUNTO_PASAJES_CONFIRMAR;
}
