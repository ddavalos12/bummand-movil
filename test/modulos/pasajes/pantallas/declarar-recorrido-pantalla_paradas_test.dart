import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bumand_movil/modulos/pasajes/pantallas/declarar-recorrido-pantalla.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DeclararRecorridoPantalla Paradas Emblemáticas Pruebas de Widget', () {
    testWidgets('Muestra chips de paradas frecuentes y autocompleta al tocarlas', (
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

      expect(find.text('Paradas frecuentes (Origen):'), findsOneWidget);
      expect(find.text('Paradas frecuentes (Destino):'), findsOneWidget);

      // Verificamos que las paradas emblemáticas estén en los chips (aparecen tanto en Origen como en Destino)
      expect(find.text('Ceja'), findsNWidgets(2));
      expect(find.text('Pérez Velasco'), findsNWidgets(2));
      expect(find.text('Plaza San Francisco'), findsNWidgets(2));
      expect(find.text('San Pedro'), findsNWidgets(2));
      expect(find.text('Cruce Viacha'), findsNWidgets(2));
      expect(find.text('Miraflores'), findsNWidgets(2));
      expect(find.text('Sopocachi'), findsNWidgets(2));
      expect(find.text('Teleférico'), findsNWidgets(2));

      // Tocar el primer chip 'Ceja' (en Origen)
      await probador.tap(find.text('Ceja').first);
      await probador.pumpAndSettle();

      // Verificar que el campo Origen tenga 'Ceja'
      expect(find.widgetWithText(TextFormField, 'Ceja'), findsOneWidget);

      // Tocar el segundo chip 'San Pedro' (en Destino)
      await probador.tap(find.text('San Pedro').last);
      await probador.pumpAndSettle();

      // Verificar que el campo Destino tenga 'San Pedro'
      expect(find.widgetWithText(TextFormField, 'San Pedro'), findsOneWidget);
    });
  });
}
