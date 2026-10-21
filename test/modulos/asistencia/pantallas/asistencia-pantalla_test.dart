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

      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);

      expect(find.text('Marcar ingreso'), findsOneWidget);
      expect(find.text('Marcar salida'), findsOneWidget);

      // Verificación de Cita Bíblica
      expect(find.textContaining('«Todo lo puedo en Cristo que me fortalece»'), findsOneWidget);
      expect(find.textContaining('Filipenses 4:13'), findsOneWidget);
    });

    testWidgets('Verifica que modo supervisor no aparece en móvil y renderiza los 3 pilares', (
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

      // No debe existir el modo supervisor ni llamada de lista rápida en móvil
      expect(find.byIcon(Icons.checklist_rtl_rounded), findsNothing);
      expect(find.text('Llamada de Lista Rápida'), findsNothing);
      expect(find.text('Confirmar sala'), findsNothing);

      // Debe mostrar los tres pilares institucionales como pestañas
      expect(find.text('Prácticas'), findsOneWidget);
      expect(find.text('Escuela de Líderes'), findsOneWidget);
      expect(find.text('Servicio'), findsOneWidget);
    });
  });
}
