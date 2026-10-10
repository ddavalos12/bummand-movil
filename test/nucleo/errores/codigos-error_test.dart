import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:bumand_movil/nucleo/errores/codigos-error.dart';
import 'package:bumand_movil/nucleo/errores/error-bumand.dart';

void main() {
  group('CodigosError y ErrorBumand Pruebas Unitarias', () {
    test('Taxonomia de codigos contiene las claves obligatorias ERR-NNNN', () {
      expect(CodigosError.ERR_1001, equals('ERR-1001'));
      expect(CodigosError.ERR_2001, equals('ERR-2001'));
      expect(CodigosError.ERR_3001, equals('ERR-3001'));
      expect(CodigosError.ERR_4001, equals('ERR-4001'));
      expect(CodigosError.ERR_5001, equals('ERR-5001'));
      expect(CodigosError.ERR_5002, equals('ERR-5002'));
      expect(CodigosError.ERR_5003, equals('ERR-5003'));
      expect(CodigosError.ERR_9001, equals('ERR-9001'));

      expect(CodigosError.obtenerDominio(CodigosError.ERR_2001), equals('ASISTENCIA_GEOCERCA'));
      expect(CodigosError.obtenerDominio(CodigosError.ERR_3001), equals('PASAJES_VIATICOS'));
      expect(CodigosError.obtenerDominio(CodigosError.ERR_5001), equals('CLIENTE_RED_VALIDACION'));
    });

    test('ErrorBumand.desdeJson extrae propiedades completas del payload canonico', () {
      final mapa_json = {
        'codigo_error': 'ERR-2001',
        'tipo': 'ASISTENCIA_GEOCERCA',
        'mensaje': 'Ubicación GPS fuera del radio de tolerancia de la geocerca',
        'detalles': ['Distancia: 120m, tolerancia: 50m'],
        'marca_tiempo': '2026-10-10T12:00:00.000Z',
        'ruta': '/api/v1/asistencia/marcar',
        'metodo': 'POST',
      };

      final error = ErrorBumand.desdeJson(mapa_json, estado_http: 400);

      expect(error.codigo_error, equals('ERR-2001'));
      expect(error.tipo, equals('ASISTENCIA_GEOCERCA'));
      expect(error.mensaje, equals('Ubicación GPS fuera del radio de tolerancia de la geocerca'));
      expect(error.detalles.first, contains('Distancia: 120m'));
      expect(error.ruta, equals('/api/v1/asistencia/marcar'));
      expect(error.metodo, equals('POST'));
      expect(error.estado_http, equals(400));
      expect(error.esErrorConexion, isFalse);
    });

    test('ErrorBumand.desdeRespuesta maneja respuestas HTTP no estructuradas', () {
      final respuesta = http.Response('Error de pasarela 502', 502);
      final error = ErrorBumand.desdeRespuesta(respuesta);

      expect(error.codigo_error, equals(CodigosError.ERR_9001));
      expect(error.estado_http, equals(502));
      expect(error.detalles, contains('Error de pasarela 502'));
    });

    test('ErrorBumand.conexionOffline y encoladoOffline configuran codigos correspondientes', () {
      final error_offline = ErrorBumand.conexionOffline(ruta: '/api/asistencia');
      expect(error_offline.codigo_error, equals(CodigosError.ERR_5001));
      expect(error_offline.esErrorConexion, isTrue);
      expect(error_offline.fueEncolado, isFalse);

      final error_encolado = ErrorBumand.encoladoOffline(ruta: '/api/asistencia');
      expect(error_encolado.codigo_error, equals(CodigosError.ERR_5003));
      expect(error_encolado.esErrorConexion, isFalse);
      expect(error_encolado.fueEncolado, isTrue);
    });
  });
}
