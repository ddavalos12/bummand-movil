import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bumand_movil/nucleo/utilidades/resultado.dart';
import 'package:bumand_movil/modulos/asistencia/pantallas/asistencia-pantalla.dart';
import 'package:bumand_movil/modulos/asistencia/proveedores/asistencia-proveedor.dart';

void main() {
  group('AsistenciaPantalla Pruebas de Widget', () {
    testWidgets('Renderiza radar geocerca y componentes de asistencia', (
      WidgetTester probador,
    ) async {
      probador.view.physicalSize = const Size(1080, 2400);
      probador.view.devicePixelRatio = 1.0;
      addTearDown(() {
        probador.view.resetPhysicalSize();
        probador.view.resetDevicePixelRatio();
      });

      await probador.pumpWidget(
        ProviderScope(
          overrides: [
            perfil_proveedor.overrideWith((ref) async => Resultado.exitoso({
                  'nombre': 'Valeria Ramos',
                  'lugarPractica': {
                    'nombre': 'Oficina Central Diaconía',
                    'latitud': -16.5000,
                    'longitud': -68.1500,
                    'radio_tolerancia_m': 100,
                  },
                })),
            historial_asistencia_proveedor.overrideWith(
              (ref) async => Resultado.exitoso(<Map<String, dynamic>>[]),
            ),
          ],
          child: const MaterialApp(
            home: AsistenciaPantalla(),
          ),
        ),
      );

      await probador.pump();

      expect(find.text('Registro de asistencia'), findsOneWidget);
      expect(find.text('Verificación por geolocalización'), findsOneWidget);
      expect(find.text('Oficina Central Diaconía'), findsOneWidget);

      expect(find.text('Reescanear GPS'), findsOneWidget);

      expect(find.text('Marcar\ningreso'), findsOneWidget);
      expect(find.text('Marcar\nsalida'), findsOneWidget);

      // Verificación de Bloques y Cita Bíblica
      expect(find.text('Plano del Edificio Institucional'), findsOneWidget);
      expect(find.textContaining('Bloque detectado: Bloque Norte'), findsOneWidget);
      expect(find.textContaining('«Todo lo puedo en Cristo que me fortalece»'), findsOneWidget);
    });

    testWidgets('Abre dialogo de Llamada de Lista Rapida en modo organizador', (
      WidgetTester probador,
    ) async {
      probador.view.physicalSize = const Size(1080, 2400);
      probador.view.devicePixelRatio = 1.0;
      addTearDown(() {
        probador.view.resetPhysicalSize();
        probador.view.resetDevicePixelRatio();
      });

      await probador.pumpWidget(
        ProviderScope(
          overrides: [
            perfil_proveedor.overrideWith((ref) async => Resultado.exitoso({
                  'nombre': 'Valeria Ramos',
                  'lugarPractica': {
                    'nombre': 'Oficina Central Diaconía',
                    'latitud': -16.5000,
                    'longitud': -68.1500,
                    'radio_tolerancia_m': 100,
                  },
                })),
            historial_asistencia_proveedor.overrideWith(
              (ref) async => Resultado.exitoso(<Map<String, dynamic>>[]),
            ),
          ],
          child: const MaterialApp(
            home: AsistenciaPantalla(),
          ),
        ),
      );

      await probador.pump();

      // Tocar botón de llamada de lista rápida
      await probador.tap(find.byIcon(Icons.checklist_rtl_rounded).first);
      await probador.pump();
      await probador.pump(const Duration(milliseconds: 300));

      expect(find.text('Llamada de Lista Rápida'), findsOneWidget);
      expect(find.text('Confirmar sala'), findsOneWidget);
      expect(find.text('María Catunta Laime'), findsOneWidget);
    });
  });
}
