import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bumand_movil/nucleo/utilidades/resultado.dart';
import 'package:bumand_movil/modulos/inicio/pantallas/inicio-pantalla.dart';
import 'package:bumand_movil/modulos/asistencia/proveedores/asistencia-proveedor.dart';
import 'package:bumand_movil/modulos/autenticacion/modelos/usuario-modelo.dart';
import 'package:bumand_movil/modulos/autenticacion/proveedores/autenticacion-proveedor.dart';
import 'package:bumand_movil/modulos/evaluaciones/proveedores/evaluaciones-proveedor.dart';
import 'package:bumand_movil/modulos/evaluaciones/modelos/evaluacion-modelo.dart';
import 'package:bumand_movil/widgets-comunes/barra-superior-bumand.dart';

class _MenuAbiertoNotificador extends MenuPrincipalNotificador {
  @override
  bool build() => true;
}

class _AutenticacionNotificadorMock extends AutenticacionNotificador {
  final UsuarioModelo _usuario;
  _AutenticacionNotificadorMock(this._usuario);

  @override
  AutenticacionEstado build() {
    return AutenticacionEstado(usuario: _usuario);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'token_prueba'});
  });

  group('InicioPantalla Navegación Pruebas de Widget', () {
    testWidgets(
      'Renderiza los 4 destinos en la barra inferior (Asistencia, Pasajes, Evaluación, Historial)',
      (WidgetTester probador) async {
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
              evaluacion_consolidada_proveedor.overrideWith(
                (ref) async =>
                    Resultado.exitoso(EvaluacionConsolidadaModelo.modeloEjemplo()),
              ),
            ],
            child: const MaterialApp(
              home: InicioPantalla(),
            ),
          ),
        );

        await probador.pump();
        await probador.pump(const Duration(milliseconds: 100));

        // Valida los destinos de la barra inferior
        expect(find.text('Asistencia'), findsWidgets);
        expect(find.text('Pasajes'), findsWidgets);
        expect(find.text('Evaluación'), findsWidgets);
        expect(find.text('Historial'), findsWidgets);

        // No incluye pestañas obsoletas
        expect(find.text('Eventos'), findsNothing);
        expect(find.text('Devocional'), findsNothing);
        expect(find.text('Notificaciones'), findsNothing);

        // Conmutar a la pestaña Pasajes (Declarar pasajes de hoy)
        await probador.tap(find.text('Pasajes'));
        await probador.pump();
        await probador.pump(const Duration(milliseconds: 100));

        expect(find.text('Declarar pasajes'), findsOneWidget);
        expect(find.textContaining('1 · Ida'), findsOneWidget);
        expect(find.textContaining('2 · Vuelta'), findsOneWidget);
        expect(find.text('Disponible para editar sólo hoy'), findsOneWidget);

        // Conmutar a la pestaña Evaluación
        await probador.tap(find.text('Evaluación'));
        await probador.pump();
        await probador.pump(const Duration(milliseconds: 100));

        expect(find.text('Evaluación'), findsWidgets);

        // Conmutar a la pestaña Historial
        await probador.tap(find.text('Historial'));
        await probador.pump();
        await probador.pump(const Duration(milliseconds: 100));

        expect(find.text('Historial'), findsWidgets);
      },
    );

    testWidgets('Renderiza la vista de Menú principal cuando está activo', (
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
            menu_principal_proveedor.overrideWith(_MenuAbiertoNotificador.new),
          ],
          child: const MaterialApp(
            home: InicioPantalla(),
          ),
        ),
      );

      await probador.pumpAndSettle();

      expect(find.text('Menú principal'), findsOneWidget);
      expect(find.text('Espacio integral BUMAND'), findsOneWidget);
      expect(find.textContaining('Hola, Valeria'), findsOneWidget);
      expect(find.textContaining('Bienvenida a tu espacio BUMAND'), findsOneWidget);
      expect(find.text('Permisos y Justificaciones'), findsOneWidget);
      expect(find.text('Reportes médicos y de inasistencia'), findsOneWidget);
      expect(find.text('Seguimiento y Retroalimentación'), findsOneWidget);
    });

    testWidgets(
      'Oculta ítem Seguimiento y Retroalimentación en Menú principal para rol administrador',
      (WidgetTester probador) async {
        probador.view.physicalSize = const Size(1080, 2400);
        probador.view.devicePixelRatio = 1.0;
        addTearDown(() {
          probador.view.resetPhysicalSize();
          probador.view.resetDevicePixelRatio();
        });

        const usuario_admin = UsuarioModelo(
          id: 99,
          nombre: 'Administrador General',
          correo: 'admin@diaconia.bo',
          rol: 'administrador',
          token: 'token_admin',
        );

        await probador.pumpWidget(
          ProviderScope(
            overrides: [
              autenticacion_proveedor.overrideWith(
                () => _AutenticacionNotificadorMock(usuario_admin),
              ),
              perfil_proveedor.overrideWith((ref) async => Resultado.exitoso({
                    'nombre': 'Administrador General',
                    'rol': 'administrador',
                  })),
              menu_principal_proveedor.overrideWith(_MenuAbiertoNotificador.new),
            ],
            child: const MaterialApp(
              home: InicioPantalla(),
            ),
          ),
        );

        await probador.pumpAndSettle();

        expect(find.text('Menú principal'), findsOneWidget);
        expect(find.text('Seguimiento y Retroalimentación'), findsNothing);
      },
    );
  });
}
