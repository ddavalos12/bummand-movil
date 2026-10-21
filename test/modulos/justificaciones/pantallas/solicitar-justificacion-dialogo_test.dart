import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bumand_movil/modulos/justificaciones/pantallas/solicitar-justificacion-dialogo.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'token': 'token_prueba'});
  });

  group('SolicitarJustificacionDialogo Pruebas de Widget', () {
    testWidgets('Renderiza motivos, prueba justificable, campo de descripción y botón de envío', (
      WidgetTester probador,
    ) async {
      probador.view.physicalSize = const Size(1080, 2400);
      probador.view.devicePixelRatio = 1.0;
      addTearDown(() {
        probador.view.resetPhysicalSize();
        probador.view.resetDevicePixelRatio();
      });

      await probador.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SolicitarJustificacionDialogo(
                evento_id: 1,
                titulo_evento: 'Taller de Liderazgo',
              ),
            ),
          ),
        ),
      );

      await probador.pumpAndSettle();

      expect(find.text('Permisos y Justificaciones'), findsOneWidget);
      expect(find.text('Reporte con prueba médica o comprobante justificable'), findsOneWidget);
      expect(find.text('Taller de Liderazgo'), findsOneWidget);
      expect(find.text('Motivo del permiso o incidencia:'), findsOneWidget);

      expect(find.text('Emergencia médica / Receta'), findsOneWidget);
      expect(find.text('Corte de ruta / Transporte'), findsOneWidget);
      expect(find.text('Trámite académico / Examen'), findsOneWidget);
      expect(find.text('Otro'), findsOneWidget);

      // Verificación de prueba justificable obligatoria (no carta)
      expect(find.text('Prueba Justificable (Obligatoria)'), findsOneWidget);
      expect(find.text('Receta médica prescrita'), findsOneWidget);
      expect(find.text('Certificado médico SSU'), findsOneWidget);

      // Seleccionar prueba justificable
      await probador.tap(find.text('Receta médica prescrita'));
      await probador.pumpAndSettle();
      expect(find.text('Receta_Medica_Prescrita.pdf'), findsOneWidget);

      expect(find.text('Enviar Permiso / Justificación'), findsOneWidget);
    });
  });
}
