import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bumand_movil/modulos/devocionales/repositorios/devocionales-repositorio.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('DevocionalesRepositorio Citas de Seguimiento Pruebas', () {
    test('obtenerCitasSeguimiento retorna semillas en fallback o error', () async {
      final mock_cliente = MockClient((request) async {
        return http.Response('Error interno', 500);
      });

      final repo = DevocionalesRepositorio(cliente: mock_cliente);

      final res_becario = await repo.obtenerCitasSeguimiento(es_supervisor: false);
      expect(res_becario.exito, isTrue);
      expect(res_becario.datos, isNotNull);
      expect(res_becario.datos!.isNotEmpty, isTrue);

      final res_supervisor = await repo.obtenerCitasSeguimiento(es_supervisor: true);
      expect(res_supervisor.exito, isTrue);
      expect(res_supervisor.datos, isNotNull);
      expect(res_supervisor.datos!.length, greaterThanOrEqualTo(3));
    });

    test('obtenerCitasSeguimiento parsea respuesta exitosa de API', () async {
      final respuesta_json = jsonEncode([
        {
          'id': 301,
          'supervisor_id': 1,
          'supervisor_nombre': 'Pastor Marcos Quispe',
          'becario_id': 10,
          'becario_nombre': 'María Catunta Laime',
          'fecha_cita': '2026-11-05',
          'hora_cita': '14:00',
          'modalidad': 'virtual',
          'lugar_o_enlace': 'https://meet.google.com/test-meet',
          'motivo_retroalimentacion': 'Sesión de orientación vocacional',
          'estado': 'programada',
        }
      ]);

      final mock_cliente = MockClient((request) async {
        return http.Response(respuesta_json, 200, headers: {'content-type': 'application/json'});
      });

      final repo = DevocionalesRepositorio(cliente: mock_cliente);
      final res = await repo.obtenerCitasSeguimiento(es_supervisor: true);

      expect(res.exito, isTrue);
      expect(res.datos!.first.id, 301);
      expect(res.datos!.first.becario_nombre, 'María Catunta Laime');
    });

    test('crearCitaSeguimiento genera modelo local en fallback offline', () async {
      final mock_cliente = MockClient((request) async {
        throw Exception('Sin conexión');
      });

      final repo = DevocionalesRepositorio(cliente: mock_cliente);

      final res = await repo.crearCitaSeguimiento(
        becario_id: 11,
        becario_nombre: 'Carlos Mamani Choque',
        fecha_cita: '2026-11-10',
        hora_cita: '09:00',
        modalidad: 'presencial',
        lugar_o_enlace: 'Oficina Central Diaconía',
        motivo_retroalimentacion: 'Revisión trimestral',
        cita_biblica: 'Proverbios 3:5-6',
      );

      expect(res.exito, isTrue);
      expect(res.datos, isNotNull);
      expect(res.datos!.becario_nombre, 'Carlos Mamani Choque');
      expect(res.datos!.esta_programada, isTrue);
    });

    test('actualizarCitaSeguimiento genera modelo actualizado con acuerdos', () async {
      final mock_cliente = MockClient((request) async {
        return http.Response(jsonEncode({
          'id': 101,
          'supervisor_id': 1,
          'supervisor_nombre': 'Pastor Marcos Quispe',
          'becario_id': 10,
          'becario_nombre': 'María Catunta Laime',
          'fecha_cita': '2026-10-30',
          'hora_cita': '15:30',
          'modalidad': 'presencial',
          'lugar_o_enlace': 'Oficina Central Diaconía',
          'motivo_retroalimentacion': 'Revisión y acuerdos',
          'acuerdos_retroalimentacion': 'Mejorar horas de lectura bíblica',
          'estado': 'realizada',
        }), 200);
      });

      final repo = DevocionalesRepositorio(cliente: mock_cliente);

      final res = await repo.actualizarCitaSeguimiento(
        cita_id: 101,
        estado: 'realizada',
        acuerdos_retroalimentacion: 'Mejorar horas de lectura bíblica',
      );

      expect(res.exito, isTrue);
      expect(res.datos!.esta_realizada, isTrue);
      expect(res.datos!.acuerdos_retroalimentacion, 'Mejorar horas de lectura bíblica');
    });
  });
}
