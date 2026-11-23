import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bumand_movil/nucleo/utilidades/resultado.dart';
import 'package:bumand_movil/modulos/evaluaciones/modelos/evaluacion-modelo.dart';
import 'package:bumand_movil/modulos/evaluaciones/proveedores/evaluaciones-proveedor.dart';
import 'package:bumand_movil/modulos/evaluaciones/pantallas/evaluaciones-pantalla.dart';

void main() {
  group('EvaluacionesPantalla Pruebas de Widget', () {
    testWidgets('Renderiza evaluación de desempeño y módulos formativos sin notas ponderadas', (
      WidgetTester probador,
    ) async {
      probador.view.physicalSize = const Size(1080, 2400);
      probador.view.devicePixelRatio = 1.0;
      addTearDown(probador.view.resetPhysicalSize);
      addTearDown(probador.view.resetDevicePixelRatio);

      const modelo_prueba = EvaluacionConsolidadaModelo(
        becario_id: 1,
        periodo_id: 1,
        periodo_nombre: 'Semestre II - 2026',
        total_porcentual: 0.0,
        total_vigesimal: 0.0,
        modulos_evaluados: 0,
        total_modulos: 5,
        desglose_modulos: [
          DetalleModuloEvaluacion(
            modulo_id: 1,
            nombre: 'Liderazgo en la Iglesia',
            evaluador_rol: 'Iglesia',
            peso_porcentaje: 20,
            puntaje: 0,
            contribucion_ponderada: 0,
            estado: 'pendiente',
          ),
          DetalleModuloEvaluacion(
            modulo_id: 2,
            nombre: 'Autoevaluación Académica',
            evaluador_rol: 'Becario',
            peso_porcentaje: 20,
            puntaje: 0,
            contribucion_ponderada: 0,
            estado: 'pendiente',
          ),
          DetalleModuloEvaluacion(
            modulo_id: 3,
            nombre: 'Evaluación del Mentor',
            evaluador_rol: 'Mentor',
            peso_porcentaje: 20,
            puntaje: 0,
            contribucion_ponderada: 0,
            estado: 'pendiente',
          ),
          DetalleModuloEvaluacion(
            modulo_id: 4,
            nombre: 'Evaluación Escuela de Líderes',
            evaluador_rol: 'Tutor',
            peso_porcentaje: 20,
            puntaje: 0,
            contribucion_ponderada: 0,
            estado: 'pendiente',
          ),
          DetalleModuloEvaluacion(
            modulo_id: 5,
            nombre: 'Evaluación Socioeconómica',
            evaluador_rol: 'Trabajador Social',
            peso_porcentaje: 20,
            puntaje: 0,
            contribucion_ponderada: 0,
            estado: 'pendiente',
          ),
        ],
      );

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

      expect(find.text('Evaluación de Desempeño'), findsOneWidget);
      expect(find.text('5 módulos · 1 vez por semestre'), findsOneWidget);
      expect(find.text('Semestre II - 2026'), findsOneWidget);
      expect(find.text('Módulos Formativos Semestrales'), findsOneWidget);

      expect(find.text('Liderazgo en la Iglesia'), findsOneWidget);
      expect(find.text('Autoevaluación Académica'), findsOneWidget);
      expect(find.text('Evaluación del Mentor'), findsOneWidget);
      expect(find.text('Evaluación Escuela de Líderes'), findsOneWidget);
      expect(find.text('Evaluación Socioeconómica'), findsOneWidget);

      // Sin nota global ponderada, porcentajes ni puntos
      expect(find.text('Nota Global Ponderada'), findsNothing);
      expect(find.text('Calificación Global'), findsNothing);
      expect(find.textContaining('pts'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    });
  });
}
