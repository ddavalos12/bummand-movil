import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bumand_movil/widgets-comunes/cargando-skeleton.dart';

void main() {
  group('CargandoSkeleton Pruebas de Widget', () {
    testWidgets('Renderiza contenedor individual con altura y ancho configurados', (
      WidgetTester probador,
    ) async {
      await probador.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CargandoSkeleton(
              ancho: 200,
              alto: 40,
            ),
          ),
        ),
      );

      expect(find.byType(CargandoSkeleton), findsOneWidget);

      await probador.pump(const Duration(milliseconds: 300));
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('Renderiza lista de esqueletos con cantidad configurada', (
      WidgetTester probador,
    ) async {
      await probador.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CargandoSkeleton.lista(cantidad: 3, alto_item: 80),
            ),
          ),
        ),
      );

      await probador.pump(const Duration(milliseconds: 100));

      expect(find.byType(CargandoSkeleton), findsNWidgets(3));
    });
  });
}
