import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bumand_movil/nucleo/utilidades/resultado.dart';
import 'package:bumand_movil/modulos/evaluaciones/modelos/evaluacion-modelo.dart';
import 'package:bumand_movil/modulos/evaluaciones/proveedores/evaluaciones-proveedor.dart';
import 'package:bumand_movil/modulos/evaluaciones/pantallas/evaluaciones-pantalla.dart';

void main() {
  group('EvaluacionesPantalla Pruebas de Widget', () {
    testWidgets('Renderiza nota global 360 y modulos formativos', (
      WidgetTester probador,
    ) async {
      probador.view.physicalSize = const Size(1080, 2400);
      probador.view.devicePixelRatio = 1.0;
      addTearDown(probador.view.resetPhysicalSize);
      addTearDown(probador.view.resetDevicePixelRatio);

      final modelo_prueba = EvaluacionConsolidadaModelo.modeloEjemplo();

      await probador.pumpWidget(
        ProviderScope(
          overrides: [
            evaluacion_consolidada_proveedor.overrideWith(
              (ref) async => Resultado.exitoso(modelo_prueba),
            ),
          ],
          child: const MaterialApp(
            home: EvaluacionesPantalla(),
          ),
        ),
      );

      await probador.pumpAndSettle();

      expect(find.text('Mis Evaluaciones'), findsOneWidget);
      expect(find.text('Calificación Global'), findsOneWidget);
      expect(find.text('17.7 / 20 pts'), findsOneWidget);
      expect(find.text('88.5%'), findsNothing);
      expect(find.text('Liderazgo en la Iglesia (Formulario F-03)'), findsOneWidget);
      expect(find.text('Autoevaluación Académica'), findsOneWidget);
      expect(find.text('Evaluación del Mentor / Prácticas'), findsOneWidget);
      expect(find.text('Evaluación Escuela de Líderes'), findsOneWidget);
      expect(find.text('Evaluación Socioeconómica'), findsOneWidget);
    });
  });
}
