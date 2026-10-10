import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bumand_movil/nucleo/errores/codigos-error.dart';
import 'package:bumand_movil/nucleo/errores/error-bumand.dart';
import 'package:bumand_movil/widgets-comunes/error-widget-personalizado.dart';

void main() {
  group('ErrorWidgetPersonalizado Pruebas de Widget', () {
    testWidgets('Muestra badge con codigo ERR, mensaje, sugerencia y boton de reintento', (
      WidgetTester probador,
    ) async {
      bool reintento_presionado = false;

      const error = ErrorBumand(
        codigo_error: CodigosError.ERR_2001,
        tipo: 'ASISTENCIA_GEOCERCA',
        mensaje: 'Fuera de rango de geocerca',
        detalles: ['Distancia actual: 180 metros'],
      );

      await probador.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorWidgetPersonalizado(
              error_bumand: error,
              alReintentar: () {
                reintento_presionado = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('ERR-2001'), findsOneWidget);
      expect(find.text('Fuera de rango de geocerca'), findsOneWidget);
      expect(find.textContaining('Acérquese al punto geográfico autorizado'), findsOneWidget);
      expect(find.text('Distancia actual: 180 metros'), findsOneWidget);

      final boton_reintentar = find.text('Reintentar operación');
      expect(boton_reintentar, findsOneWidget);

      await probador.tap(boton_reintentar);
      await probador.pump();

      expect(reintento_presionado, isTrue);
    });

    testWidgets('Muestra icono de wifi desconectado ante error ERR-5001', (
      WidgetTester probador,
    ) async {
      final error_red = ErrorBumand.conexionOffline();

      await probador.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorWidgetPersonalizado(
              error_bumand: error_red,
            ),
          ),
        ),
      );

      expect(find.text('ERR-5001'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    });
  });
}
