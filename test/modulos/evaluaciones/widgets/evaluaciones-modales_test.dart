import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bumand_movil/modulos/evaluaciones/widgets/detalle_evaluacion_modal.dart';

void main() {
  group('Evaluaciones Modales Pruebas de Widget', () {
    testWidgets('mostrarReceptorSocioeconomico abre modal con barra de progreso y sin mostrar notas al becario', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DetalleEvaluacionModal.mostrarReceptorSocioeconomico(context),
                child: const Text('Abrir Socioeconomica'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Socioeconomica'));
      await tester.pumpAndSettle();

      // Verificar cabecera oficial
      expect(find.text('Cuestionario de Bienestar Universitario'), findsOneWidget);
      expect(find.textContaining('Respondidas: 0 de 26'), findsOneWidget);

      // Regla estricta requerimientos.md: NO mostrar puntajes ni porcentajes de ponderación al becario
      expect(find.textContaining('pts'), findsNothing);
      expect(find.textContaining('ponderado'), findsNothing);

      // Verificar que se listan preguntas del catálogo canónico
      expect(find.text('Ingresos del hogar'), findsOneWidget);
      expect(find.text('A'), findsWidgets);
      expect(find.text('B'), findsWidgets);
      expect(find.text('C'), findsWidgets);
    });

    testWidgets('mostrarReceptorMentor abre modal con QR y verificación', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DetalleEvaluacionModal.mostrarReceptorMentor(context),
                child: const Text('Abrir Mentor'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Mentor'));
      await tester.pumpAndSettle();

      // Verificar vista QR del mentor
      expect(find.text('Evaluación del Mentor / Supervisor'), findsOneWidget);
      expect(find.textContaining('¿Eres el Supervisor/Tutor? Evaluar aquí'), findsOneWidget);

      // Abrir diálogo de confirmación
      await tester.tap(find.textContaining('¿Eres el Supervisor/Tutor? Evaluar aquí'));
      await tester.pumpAndSettle();

      expect(find.text('Verificación de Identidad del Tutor'), findsOneWidget);
      expect(find.text('Código en pantalla'), findsOneWidget);
    });

    testWidgets('mostrarFormularioMentor abre formulario estructurado tipo F-03 con 3 secciones', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DetalleEvaluacionModal.mostrarFormularioMentor(context),
                child: const Text('Abrir Formulario Mentor F-03'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Formulario Mentor F-03'));
      await tester.pumpAndSettle();

      // Verificar título oficial y 3 secciones tipo iglesia
      expect(find.text('Evaluación del Becario por el Mentor'), findsOneWidget);
      expect(find.text('Sección I — Datos Generales'), findsOneWidget);
      expect(find.text('Sección II — Preguntas 1 al 18 (Escala 1 al 10)'), findsOneWidget);
      expect(find.textContaining('Sección III — Preguntas Abiertas'), findsOneWidget);

      // Verificar que se listan criterios de evaluación y chips 1 a 10
      // Hacer scroll para ver el botón de envío al final del formulario
      await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
      await tester.pumpAndSettle();
      expect(find.text('Enviar Evaluación del Mentor'), findsOneWidget);
    });
  });
}
