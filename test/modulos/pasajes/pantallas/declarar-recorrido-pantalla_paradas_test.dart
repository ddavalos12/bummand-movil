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
    testWidgets(
      'Muestra selector de tipo de actividad y paradas frecuentes integradas en combobox dinámico con autocompletado y menú',
      (WidgetTester probador) async {
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

        // 1. Verificación del selector de Tipo de Actividad
        expect(find.text('Tipo de actividad'), findsOneWidget);
        expect(find.text('Prácticas'), findsOneWidget);
        expect(find.text('Escuela de Líderes'), findsOneWidget);
        expect(find.text('Acciones de Servicio'), findsOneWidget);

        // Seleccionar Tipo de Actividad 'Escuela de Líderes'
        await probador.tap(find.text('Escuela de Líderes'));
        await probador.pumpAndSettle();

        // 2. Verificación de Combobox dinámico en Origen y Destino
        final botones_desplegables = find.byTooltip('Paradas frecuentes');
        expect(botones_desplegables, findsAtLeastNWidgets(2));

        // Abrir menú desplegable en Origen (primer combobox)
        await probador.tap(botones_desplegables.first);
        await probador.pumpAndSettle();

        // Verificar que aparezcan las paradas frecuentes en el menú
        expect(find.text('Ceja'), findsWidgets);
        expect(find.text('Pérez Velasco'), findsWidgets);
        expect(find.text('Plaza San Francisco'), findsWidgets);
        expect(find.text('San Pedro'), findsWidgets);
        expect(find.text('Teleférico'), findsWidgets);

        // Seleccionar 'Ceja' en Origen
        await probador.tap(find.text('Ceja').last);
        await probador.pumpAndSettle();

        expect(find.widgetWithText(TextField, 'Ceja'), findsOneWidget);

        // Abrir menú desplegable en Destino (segundo combobox)
        await probador.tap(find.byTooltip('Paradas frecuentes').at(1));
        await probador.pumpAndSettle();

        // Verificar que no aparece 'Ceja' como opción duplicada en el menú desplegable de la parada 2,
        // pero sí están disponibles la institución y demás paradas
        expect(find.widgetWithText(PopupMenuItem<String>, 'Ceja'), findsNothing);
        expect(
          find.widgetWithText(PopupMenuItem<String>, 'Oficina Central Diaconía'),
          findsOneWidget,
        );

        // Seleccionar 'Oficina Central Diaconía' en Destino
        await probador.tap(find.text('Oficina Central Diaconía').last);
        await probador.pumpAndSettle();

        expect(
          find.widgetWithText(TextField, 'Oficina Central Diaconía'),
          findsOneWidget,
        );

        // Agregar una parada intermedia y verificar que el destino final sigue siendo la última parada
        await probador.tap(find.text('Agregar parada intermedia'));
        await probador.pumpAndSettle();

        final campos_parada = probador
            .widgetList<TextField>(find.byType(TextField))
            .toList();
        expect(campos_parada[1].controller?.text, 'Ceja');
        expect(campos_parada[2].controller?.text, '');
        expect(campos_parada[3].controller?.text, 'Oficina Central Diaconía');
      },
    );
  });
}
