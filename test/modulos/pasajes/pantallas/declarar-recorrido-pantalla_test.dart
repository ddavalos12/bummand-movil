import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bumand_movil/modulos/pasajes/pantallas/declarar-recorrido-pantalla.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DeclararRecorridoPantalla Pruebas de Widget', () {
    testWidgets('Renderiza campos de formulario y botones de PIN GPS para tramos', (
      WidgetTester probador,
    ) async {
      probador.view.physicalSize = const Size(1080, 2400);
      probador.view.devicePixelRatio = 1.0;
      addTearDown(() {
        probador.view.resetPhysicalSize();
        probador.view.resetDevicePixelRatio();
      });

      await probador.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DeclararRecorridoPantalla(),
          ),
        ),
      );

      await probador.pumpAndSettle();

      expect(find.text('Declarar recorrido'), findsOneWidget);
      expect(find.textContaining('1 · Ida'), findsOneWidget);
      expect(find.textContaining('2 · Vuelta'), findsOneWidget);
      expect(find.text('📍'), findsWidgets);
      expect(find.text('Guardar recorrido del día'), findsOneWidget);
    });
  });
}
