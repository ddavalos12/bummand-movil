import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bumand_movil/modulos/eventos/servicios/eventos-servicio.dart';
import 'package:bumand_movil/nucleo/servicios/cola-offline-servicio.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'jwt_prueba_valido'});
  });

  group('EventosServicio Pruebas Unitarias', () {
    test('obtenerEventos retorna lista de eventos parseados', () async {
      final mock_cliente = MockClient((request) async {
        if (request.url.path.contains('eventos')) {
          final body = jsonEncode([
            {
              'id': 1,
              'titulo': 'Taller de Liderazgo',
              'descripcion': 'Capacitación diaconal',
              'tipo_evento': 'taller',
              'fecha': '2026-10-25',
              'hora_inicio': '08:30',
              'hora_fin': '12:30',
              'latitud': -16.500054,
              'longitud': -68.173455,
              'radio_tolerancia_m': 100,
              'direccion_referencia': 'El Alto',
              'estado': 'programado',
            }
          ]);
          return http.Response(body, 200);
        }
        return http.Response('Not Found', 404);
      });

      final servicio = EventosServicio(cliente: mock_cliente);
      final resultado = await servicio.obtenerEventos();

      expect(resultado.exito, isTrue);
      expect(resultado.datos, isNotNull);
      expect(resultado.datos!.length, 1);
      expect(resultado.datos!.first.titulo, 'Taller de Liderazgo');
    });

    test('marcarAsistencia registra con éxito en el servidor', () async {
      final mock_cliente = MockClient((request) async {
        if (request.url.path.contains('/asistencia')) {
          final body = jsonEncode({
            'id': 50,
            'evento_id': 1,
            'becario_id': 2,
            'hora_marcacion': '08:35:00',
            'latitud': -16.500054,
            'longitud': -68.173455,
            'distancia_m': 12.0,
            'dentro_de_radio': true,
            'estado': 'presente',
          });
          return http.Response(body, 201);
        }
        return http.Response('Error', 400);
      });

      final servicio = EventosServicio(cliente: mock_cliente);
      final resultado = await servicio.marcarAsistencia(
        evento_id: 1,
        latitud: -16.500054,
        longitud: -68.173455,
      );

      expect(resultado.exito, isTrue);
      expect(resultado.datos!.dentro_de_radio, isTrue);
      expect(resultado.datos!.distancia_m, 12.0);
    });

    test('marcarAsistencia encola en ColaOffline cuando falla la red', () async {
      final cola = ColaOfflineServicio();

      // Cliente que simula caída de red (SocketException o error 500)
      final mock_cliente = MockClient((request) async {
        throw Exception('Sin conexión de red');
      });

      final servicio = EventosServicio(
        cliente: mock_cliente,
        cola_offline: cola,
      );

      final resultado = await servicio.marcarAsistencia(
        evento_id: 3,
        latitud: -16.500054,
        longitud: -68.173455,
      );

      expect(resultado.exito, isTrue);
      expect(resultado.datos!.observaciones, contains('offline'));

      final pendientes = await cola.obtenerPendientes();
      expect(pendientes.length, 1);
      expect(pendientes.first.tipo, 'asistencia_evento');
    });
  });
}
