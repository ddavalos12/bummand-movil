import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bumand_movil/modulos/devocionales/modelos/versiculo-diario-modelo.dart';
import 'package:bumand_movil/modulos/devocionales/widgets/dialogo-versiculo-diario.dart';

void main() {
  group('DialogoVersiculoDiario Pruebas de Widget', () {
    testWidgets('Renderiza cita bíblica, texto y reflexión diaconal', (WidgetTester tester) async {
      const versiculo = VersiculoDiarioModelo(
        cita: 'Filipenses 4:13',
        libro: 'Filipenses',
        capitulo: 4,
        versiculo: 13,
        texto: 'Todo lo puedo en Cristo que me fortalece.',
        version: 'Reina-Valera 1960 (RVR60)',
        tema: 'Fortaleza y Servicio',
        reflexion_diaconal: 'En cada labor y apoyo formativo, Cristo renueva nuestras fuerzas.',
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DialogoVersiculoDiario(versiculo: versiculo),
            ),
          ),
        ),
      );

      expect(find.text('Versículo del Día'), findsOneWidget);
      expect(find.text('Filipenses 4:13'), findsOneWidget);
      expect(find.text('«Todo lo puedo en Cristo que me fortalece.»'), findsOneWidget);
      expect(find.text('Fortaleza y Servicio'), findsOneWidget);
      expect(find.text('Reina-Valera 1960 (RVR60)'), findsOneWidget);
      expect(find.text('Comenzar'), findsOneWidget);
      expect(find.text('Devocional'), findsOneWidget);
    });
  });
}
