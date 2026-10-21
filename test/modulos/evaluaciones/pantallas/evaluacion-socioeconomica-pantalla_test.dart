import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bumand_movil/modulos/evaluaciones/pantallas/evaluacion-socioeconomica-pantalla.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'token_prueba'});
  });

  group('EvaluacionSocioeconomicaPantalla Pruebas de Widget', () {
    testWidgets(
      'Renderiza encabezado institucional, barra de progreso 0/26, chips de filtro y las preguntas sin puntajes numéricos',
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
              home: EvaluacionSocioeconomicaPantalla(),
            ),
          ),
        );

        await probador.pumpAndSettle();

        // Verifica AppBar limpia sin el banner redundante superior
        expect(find.text('Evaluación Socioeconómica'), findsOneWidget);
        expect(find.text('Cuestionario de Bienestar · 26 preguntas'), findsOneWidget);
        expect(
          find.text('Cuestionario Oficial de Bienestar Universitario'),
          findsNothing,
        );

        // Verifica barra de progreso interactiva y chips de filtro
        expect(find.text('Respondidas: 0 de 26 preguntas'), findsOneWidget);
        expect(find.text('Todas (26)'), findsOneWidget);
        expect(find.text('Hogar y Economía'), findsOneWidget);
        expect(find.text('Salud y Servicios'), findsOneWidget);
        expect(find.text('Convivencia'), findsOneWidget);
        expect(find.text('Universidad y Futuro'), findsOneWidget);

        // Regla estricta requerimientos.md: NO mostrar puntajes ni porcentajes al becario
        expect(find.textContaining('pts'), findsNothing);
        expect(find.textContaining('%'), findsNothing);
        expect(find.textContaining('ponderado'), findsNothing);

        // Verifica botón rápido de autocompletado y barra inferior
        expect(find.text('Autocompletar demostración (26/26)'), findsOneWidget);
        expect(
          find.text('Enviar Evaluación Socioeconómica (0/26)'),
          findsOneWidget,
        );

        // Probar autocompletado de demostración (26/26)
        await probador.tap(find.text('Autocompletar demostración (26/26)'));
        await probador.pumpAndSettle();

        expect(find.text('Respondidas: 26 de 26 preguntas'), findsOneWidget);
        expect(
          find.text('Enviar Evaluación Socioeconómica (26/26)'),
          findsOneWidget,
        );
      },
    );
  });
}
