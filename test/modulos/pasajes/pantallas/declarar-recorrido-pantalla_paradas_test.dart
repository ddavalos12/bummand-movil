import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bumand_movil/modulos/pasajes/pantallas/declarar-recorrido-pantalla.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DeclararRecorridoPantalla Paradas Libres y Validación Pruebas de Widget', () {
    testWidgets(
      'Muestra campos de texto libre sin catálogo predefinido, permite agregar parada intermedia y valida duplicados no adyacentes',
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

        // 1. Verificación del selector de Tipo de Actividad (solo Prácticas y Acciones de Servicio)
        expect(find.text('Tipo de actividad'), findsOneWidget);
        expect(find.text('Prácticas'), findsOneWidget);
        expect(find.text('Acciones de Servicio'), findsOneWidget);

        // 2. No debe existir menú desplegable de paradas frecuentes predefinidas
        expect(find.byTooltip('Paradas frecuentes'), findsNothing);

        // 3. Escribir origen y destino manualmente en texto libre
        final campos_iniciales = find.byType(TextField);
        // Índice 0 es "Apoyo realizado"; índices 1 y 2 son Parada 1 y Parada 2 de Ida
        await probador.enterText(campos_iniciales.at(1), 'Terminal de Buses');
        await probador.enterText(campos_iniciales.at(2), 'Oficina Central Diaconía');
        await probador.pumpAndSettle();

        expect(find.widgetWithText(TextField, 'Terminal de Buses'), findsOneWidget);
        expect(find.widgetWithText(TextField, 'Oficina Central Diaconía'), findsOneWidget);

        // 4. Agregar parada intermedia y verificar que se inserta entre Origen y Destino
        await probador.ensureVisible(find.text('Agregar parada intermedia'));
        await probador.tap(find.text('Agregar parada intermedia'));
        await probador.pumpAndSettle();

        final campos_parada = probador
            .widgetList<TextField>(find.byType(TextField))
            .toList();
        expect(campos_parada[1].controller?.text, 'Terminal de Buses');
        expect(campos_parada[2].controller?.text, '');
        expect(campos_parada[3].controller?.text, 'Oficina Central Diaconía');

        // 5. Verificar confirmación de parada válida y rechazo de duplicado no adyacente (Parada 1 == Parada 3)
        await probador.enterText(find.byType(TextField).at(2), 'Avenida Perú');
        await probador.enterText(find.byType(TextField).at(3), 'Terminal de Buses');
        await probador.pumpAndSettle();

        // Parada 1 y Parada 3 coinciden entre sí -> ambas muestran "📍 Fijar aquí" y solo Parada 2 muestra "Confirmar"
        expect(find.text('📍 Fijar aquí'), findsNWidgets(2));
        expect(find.text('Confirmar'), findsOneWidget);

        await probador.ensureVisible(find.text('Confirmar'));
        await probador.tap(find.text('Confirmar'));
        await probador.pumpAndSettle();
        expect(find.text('✓ Ubicación fijada'), findsOneWidget);

        await probador.ensureVisible(find.text('Siguiente: Vuelta →'));
        await probador.tap(find.text('Siguiente: Vuelta →'));
        await probador.pumpAndSettle();

        expect(
          find.text('El punto de partida y llegada no pueden ser la misma ubicación'),
          findsOneWidget,
        );

        // Esperar a que desaparezca el SnackBar anterior antes de la siguiente validación
        await probador.pump(const Duration(seconds: 5));
        await probador.pumpAndSettle();

        // 6. Agregar otra parada intermedia para validar duplicado no adyacente (Parada 1 == Parada 3, origen != destino)
        await probador.enterText(find.byType(TextField).at(3), 'Plaza Murillo');
        await probador.ensureVisible(find.text('Agregar parada intermedia'));
        await probador.tap(find.text('Agregar parada intermedia'));
        await probador.pumpAndSettle();

        await probador.enterText(find.byType(TextField).at(3), 'Terminal de Buses');
        await probador.pumpAndSettle();

        await probador.ensureVisible(find.text('Siguiente: Vuelta →'));
        await probador.tap(find.text('Siguiente: Vuelta →'));
        await probador.pumpAndSettle();

        expect(
          find.text('No puedes elegir dos veces el mismo lugar en el tramo de ida'),
          findsOneWidget,
        );
      },
    );
  });
}
