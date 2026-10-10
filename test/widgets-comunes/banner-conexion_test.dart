import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bumand_movil/nucleo/servicios/cola-offline-servicio.dart';
import 'package:bumand_movil/widgets-comunes/banner-conexion.dart';

void main() {
  group('BannerConexion Pruebas de Widget', () {
    testWidgets('Muestra banner y texto de modo sin conexion cuando no hay red', (
      WidgetTester probador,
    ) async {
      await probador.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BannerConexion(
                sin_conexion_forzado: true,
                conteo_forzado: 3,
              ),
            ),
          ),
        ),
      );

      await probador.pumpAndSettle();

      expect(
        find.text(
          'Modo sin conexión — Tus marcaciones se guardan localmente y se sincronizarán al recuperar señal',
        ),
        findsOneWidget,
      );
      expect(find.text('3 en cola'), findsOneWidget);
      expect(find.text('Forzar sincronización'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    });

    testWidgets('Se oculta completamente cuando hay conexion y cola vacia', (
      WidgetTester probador,
    ) async {
      await probador.pumpWidget(
        ProviderScope(
          overrides: [
            hay_conexion_red_proveedor.overrideWith((ref) => true),
            cola_offline_conteo_proveedor.overrideWith((ref) => 0),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BannerConexion(),
            ),
          ),
        ),
      );

      await probador.pumpAndSettle();

      expect(
        find.text(
          'Modo sin conexión — Tus marcaciones se guardan localmente y se sincronizarán al recuperar señal',
        ),
        findsNothing,
      );
      expect(find.byIcon(Icons.cloud_off_rounded), findsNothing);
    });

    testWidgets('Dispara sincronizacion al presionar boton Forzar sincronizacion', (
      WidgetTester probador,
    ) async {
      bool sincronizacion_invocada = false;

      await probador.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BannerConexion(
                sin_conexion_forzado: true,
                conteo_forzado: 2,
                alForzarSincronizacion: () async {
                  sincronizacion_invocada = true;
                },
              ),
            ),
          ),
        ),
      );

      await probador.pumpAndSettle();

      final boton_sincronizar = find.text('Forzar sincronización');
      expect(boton_sincronizar, findsOneWidget);

      await probador.tap(boton_sincronizar);
      await probador.pump();

      expect(sincronizacion_invocada, isTrue);
    });
  });
}
