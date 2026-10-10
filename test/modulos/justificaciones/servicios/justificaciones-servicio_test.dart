import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bumand_movil/modulos/justificaciones/servicios/justificaciones-servicio.dart';
import 'package:bumand_movil/nucleo/servicios/cola-offline-servicio.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'jwt_prueba_valido'});
  });

  group('JustificacionesServicio Pruebas Unitarias', () {
    test('enviarJustificacion envía correctamente los datos al backend', () async {
      final mock_cliente = MockClient((request) async {
        if (request.url.path.contains('justificaciones')) {
          final payload = jsonDecode(request.body) as Map<String, dynamic>;
          expect(payload['motivo'], 'Corte de ruta/Paro');
          expect(payload['descripcion'], contains('bloqueo en autopista'));
          return http.Response(jsonEncode({'id': 1, 'mensaje': 'Registrado'}), 201);
        }
        return http.Response('Error', 400);
      });

      final servicio = JustificacionesServicio(cliente: mock_cliente);
      final res = await servicio.enviarJustificacion(
        tipo_incidencia: 'asistencia_evento',
        referencia_id: 1,
        fecha_incidencia: '2026-10-25',
        motivo: 'Corte de ruta/Paro',
        descripcion: 'Retraso por bloqueo en autopista La Paz - El Alto',
      );

      expect(res.exito, isTrue);
      expect(res.datos!['mensaje'], 'Registrado');
    });

    test('enviarJustificacion recurre a ColaOffline ante error de conexión', () async {
      final cola = ColaOfflineServicio();
      final mock_cliente = MockClient((request) async {
        throw Exception('Sin internet');
      });

      final servicio = JustificacionesServicio(
        cliente: mock_cliente,
        cola_offline: cola,
      );

      final res = await servicio.enviarJustificacion(
        tipo_incidencia: 'asistencia_evento',
        referencia_id: 2,
        fecha_incidencia: '2026-10-25',
        motivo: 'Emergencia médica',
        descripcion: 'Consulta médica de urgencia en hospital',
      );

      expect(res.exito, isTrue);
      expect(res.datos!['offline'], isTrue);

      final pendientes = await cola.obtenerPendientes();
      expect(pendientes.length, 1);
      expect(pendientes.first.tipo, 'justificacion');
    });
  });
}
