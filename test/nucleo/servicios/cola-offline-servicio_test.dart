import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bumand_movil/nucleo/servicios/cola-offline-servicio.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ColaOfflineServicio Pruebas Unitarias', () {
    test('Encola peticiones y las recupera correctamente', () async {
      final servicio = ColaOfflineServicio();

      expect(await servicio.obtenerPendientes(), isEmpty);

      await servicio.encolar(
        ruta: '/api/eventos/1/asistencia',
        metodo: 'POST',
        cuerpo: {'latitud': -16.500054, 'longitud': -68.173455},
        tipo: 'asistencia_evento',
      );

      final pendientes = await servicio.obtenerPendientes();
      expect(pendientes.length, 1);
      expect(pendientes.first.ruta, '/api/eventos/1/asistencia');
      expect(pendientes.first.tipo, 'asistencia_evento');
      expect(pendientes.first.cuerpo['latitud'], -16.500054);
    });

    test('Elimina una petición específica de la cola', () async {
      final servicio = ColaOfflineServicio();

      await servicio.encolar(
        ruta: '/api/justificaciones',
        metodo: 'POST',
        cuerpo: {'motivo': 'Corte de ruta/Paro'},
        tipo: 'justificacion',
      );

      final pendientes = await servicio.obtenerPendientes();
      expect(pendientes.length, 1);

      await servicio.eliminarPeticion(pendientes.first.id);
      expect(await servicio.obtenerPendientes(), isEmpty);
    });

    test('Sincroniza exitosamente las peticiones encoladas con mock HTTP', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', 'token_de_prueba');

      final servicio = ColaOfflineServicio();

      await servicio.encolar(
        ruta: '/api/eventos/2/asistencia',
        metodo: 'POST',
        cuerpo: {'latitud': -16.5, 'longitud': -68.15},
        tipo: 'asistencia_evento',
      );

      final mock_cliente = MockClient((request) async {
        return http.Response(jsonEncode({'mensaje': 'Asistencia guardada'}), 201);
      });

      final sincronizados = await servicio.sincronizarPendientes(
        cliente_personalizado: mock_cliente,
      );

      expect(sincronizados, 1);
      expect(await servicio.obtenerPendientes(), isEmpty);
    });
  });
}
