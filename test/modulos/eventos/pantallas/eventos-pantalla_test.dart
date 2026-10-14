import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bumand_movil/nucleo/utilidades/resultado.dart';
import 'package:bumand_movil/modulos/eventos/modelos/evento.dart';
import 'package:bumand_movil/modulos/eventos/servicios/eventos-servicio.dart';
import 'package:bumand_movil/modulos/eventos/pantallas/eventos-pantalla.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'token_prueba'});
  });

  group('EventosPantalla Pruebas de Widget', () {
    testWidgets('Renderiza radar, agenda y opciones de evento', (
      WidgetTester probador,
    ) async {
      probador.view.physicalSize = const Size(1080, 2400);
      probador.view.devicePixelRatio = 1.0;
      addTearDown(() {
        probador.view.resetPhysicalSize();
        probador.view.resetDevicePixelRatio();
      });

      const evento_ejemplo = Evento(
        id: 1,
        titulo: 'Taller de Liderazgo Diaconal',
        descripcion: 'Formación para becarios de El Alto',
        tipo_evento: 'taller',
        fecha: '2026-10-25',
        hora_inicio: '08:30',
        hora_fin: '13:00',
        latitud: -16.500054,
        longitud: -68.173455,
        radio_tolerancia_m: 100,
        direccion_referencia: 'Av. Juan Pablo II, El Alto',
        estado: 'programado',
      );

      await probador.pumpWidget(
        ProviderScope(
          overrides: [
            eventos_lista_proveedor.overrideWith(
              (ref) async => Resultado.exitoso([evento_ejemplo]),
            ),
          ],
          child: const MaterialApp(
            home: EventosPantalla(),
          ),
        ),
      );

      await probador.pump();
      await probador.pump(const Duration(milliseconds: 100));

      expect(find.text('Eventos y Convocatorias'), findsOneWidget);
      expect(find.text('Encuentros y talleres diaconales'), findsOneWidget);
      expect(find.text('Agenda de Convocatorias'), findsOneWidget);
      expect(find.text('Taller de Liderazgo Diaconal'), findsAtLeastNWidgets(1));
      expect(find.text('Tolerancia: 100 m'), findsOneWidget);
      expect(find.text('Av. Juan Pablo II, El Alto'), findsOneWidget);
      expect(find.text('Reescanear'), findsOneWidget);
      expect(find.text('Justificar'), findsOneWidget);
    });

    testWidgets('Muestra badge e icono de marcado correctamente cuando la asistencia fue registrada', (
      WidgetTester probador,
    ) async {
      probador.view.physicalSize = const Size(1080, 2400);
      probador.view.devicePixelRatio = 1.0;
      addTearDown(() {
        probador.view.resetPhysicalSize();
        probador.view.resetDevicePixelRatio();
      });

      const asistencia_ejemplo = AsistenciaEvento(
        id: 10,
        evento_id: 2,
        becario_id: 1,
        hora_marcacion: '09:05',
        latitud: -16.500054,
        longitud: -68.173455,
        distancia_m: 12.0,
        dentro_de_radio: true,
        estado: 'presente',
      );

      const evento_marcado = Evento(
        id: 2,
        titulo: 'Escuela de Líderes Diaconales',
        descripcion: 'Formación institucional de viernes',
        tipo_evento: 'escuela_lideres',
        fecha: '2026-10-23',
        hora_inicio: '14:00',
        hora_fin: '17:00',
        latitud: -16.500054,
        longitud: -68.173455,
        radio_tolerancia_m: 100,
        direccion_referencia: 'Oficina Central Diaconía IFD',
        estado: 'programado',
        mi_asistencia: asistencia_ejemplo,
      );

      await probador.pumpWidget(
        ProviderScope(
          overrides: [
            eventos_lista_proveedor.overrideWith(
              (ref) async => Resultado.exitoso([evento_marcado]),
            ),
          ],
          child: const MaterialApp(
            home: EventosPantalla(),
          ),
        ),
      );

      await probador.pump();
      await probador.pump(const Duration(milliseconds: 100));

      expect(find.text('Marcado correctamente'), findsOneWidget);
      expect(find.text('Marcado correctamente ✓'), findsOneWidget);
      expect(find.text('Marcado correctamente por el supervisor'), findsOneWidget);
    });
  });
}
