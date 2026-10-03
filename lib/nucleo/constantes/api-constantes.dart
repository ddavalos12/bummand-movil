import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstantes {
  // Detección automática: 10.0.2.2 en emulador Android, localhost en Windows/Desktop/Web
  static String get RUTA_BASE {
    if (kIsWeb) return 'http://localhost:3002';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3002';
    } catch (_) {}
    return 'http://localhost:3002';
  }

  static const String PUNTO_INICIO_SESION = '/autenticacion/inicio-sesion';
  static const String PUNTO_REGISTRO = '/autenticacion/registro';
  static const String PUNTO_ASISTENCIA_INGRESO = '/asistencia/ingreso';
  static const String PUNTO_ASISTENCIA_SALIDA = '/asistencia/salida';
  static const String PUNTO_ASISTENCIA_HISTORIAL = '/asistencia';
  static const String PUNTO_PASAJES_CONFIRMAR = '/pasajes/confirmar-datos';
  static const String PUNTO_PASAJES = '/pasajes';
  static const String PUNTO_NOTIFICACIONES = '/notificaciones/mis-notificaciones';
  static const String PUNTO_NOTIFICACIONES_CONTEO = '/notificaciones/no-leidas/conteo';

  // Alias para retrocompatibilidad
  static String get baseUrl => RUTA_BASE;
  static const String loginEndpoint = PUNTO_INICIO_SESION;
  static const String registroEndpoint = PUNTO_REGISTRO;
  static const String asistenciaIngresoEndpoint = PUNTO_ASISTENCIA_INGRESO;
  static const String asistenciaSalidaEndpoint = PUNTO_ASISTENCIA_SALIDA;
  static const String asistenciaHistorialEndpoint = PUNTO_ASISTENCIA_HISTORIAL;
  static const String pasajesConfirmarEndpoint = PUNTO_PASAJES_CONFIRMAR;
}
