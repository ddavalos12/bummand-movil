import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bumand_movil/modulos/inicio/pantallas/acerca-de-pantalla.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'token_prueba'});
  });

  group('AcercaDePantalla Pruebas de Widget', () {
    testWidgets(
      'Renderiza únicamente la información institucional para el becario y oculta métricas y controles administrativos',
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
              home: AcercaDePantalla(),
            ),
          ),
        );
        await probador.pumpAndSettle();

        // 1. Verificar contenido institucional legítimo para el becario
        expect(find.text("Misión Institucional"), findsOneWidget);
        expect(find.text("Visión Institucional"), findsOneWidget);
        expect(find.text("Los Tres Principios Diaconales"), findsOneWidget);
        expect(find.text("1. Compartir la Fe"), findsOneWidget);
        expect(find.text("2. Combatir la Pobreza"), findsOneWidget);
        expect(find.text("3. Promover la Justicia"), findsOneWidget);
        expect(find.text("🕊️"), findsOneWidget);
        expect(find.text("🌱"), findsOneWidget);
        expect(find.text("⚖️"), findsOneWidget);
        expect(find.text("Trayectoria Histórica (2015 – 2026)"), findsOneWidget);

        // 2. Verificar que las secciones administrativas y de auditoría NO se muestren al becario
        expect(find.text("Cifras Institucionales (Al 24 de Octubre de 2026)"), findsNothing);
        expect(find.text("Perspectiva por Rol Institucional"), findsNothing);
        expect(find.text("Supervisor"), findsNothing);
        expect(find.text("Directiva"), findsNothing);
        expect(find.text("Matriz de Evaluación 360° (100 Pts)"), findsNothing);
        expect(find.text("≥70: Óptimo"), findsNothing);
        expect(find.text("51-69: Condicionado"), findsNothing);
        expect(find.text("≤50: Pérdida"), findsNothing);
      },
    );
  });
}
