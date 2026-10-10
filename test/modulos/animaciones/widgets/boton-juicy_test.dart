import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bumand_movil/modulos/animaciones/widgets/boton-juicy.dart';

void main() {
  group('BotonJuicy Pruebas de Widget', () {
    testWidgets('Renderiza texto, icono y responde a toque con rebote', (
      WidgetTester probador,
    ) async {
      bool presionado = false;

      await probador.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BotonJuicy(
              texto: 'Confirmar Marcación',
              icono: Icons.fingerprint,
              alPresionar: () {
                presionado = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Confirmar Marcación'), findsOneWidget);
      expect(find.byIcon(Icons.fingerprint), findsOneWidget);

      await probador.tap(find.text('Confirmar Marcación'));
      await probador.pumpAndSettle();

      expect(presionado, isTrue);
    });

    testWidgets('Muestra indicador de progreso cuando esta_cargando es true', (
      WidgetTester probador,
    ) async {
      await probador.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BotonJuicy(
              texto: 'Guardando...',
              esta_cargando: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Guardando...'), findsNothing);
    });
  });
}
