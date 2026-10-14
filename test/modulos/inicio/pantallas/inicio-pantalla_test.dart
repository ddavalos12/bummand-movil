import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bumand_movil/nucleo/utilidades/resultado.dart';
import 'package:bumand_movil/modulos/inicio/pantallas/inicio-pantalla.dart';
import 'package:bumand_movil/modulos/asistencia/proveedores/asistencia-proveedor.dart';
import 'package:bumand_movil/modulos/eventos/servicios/eventos-servicio.dart';
import 'package:bumand_movil/modulos/eventos/modelos/evento.dart';
import 'package:bumand_movil/modulos/notificaciones/proveedores/notificaciones-proveedor.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'token_prueba'});
  });

  group('InicioPantalla Navegación Pruebas de Widget', () {
    testWidgets('Renderiza los 4 destinos de navegación y no incluye Devocional', (
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
            eventos_lista_proveedor.overrideWith(
              (ref) async => Resultado.exitoso(<Evento>[]),
            ),
            notificaciones_conteo_proveedor.overrideWith((ref) async => 0),
          ],
          child: const MaterialApp(
            home: InicioPantalla(),
          ),
        ),
      );

      await probador.pump();
      await probador.pump(const Duration(milliseconds: 100));

      expect(find.text('Asistencia'), findsOneWidget);
      expect(find.text('Eventos'), findsOneWidget);
      expect(find.text('Pasajes'), findsOneWidget);
      expect(find.text('Notificaciones'), findsOneWidget);
      expect(find.text('Devocional'), findsNothing);

      // Conmutar a la pestaña Eventos
      await probador.tap(find.text('Eventos'));
      await probador.pump();
      await probador.pump(const Duration(milliseconds: 100));

      expect(find.text('Eventos y Convocatorias'), findsOneWidget);
    });
  });
}
