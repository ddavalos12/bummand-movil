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
    testWidgets('Renderiza motivos, campo de descripción y botón de envío', (
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

      expect(find.text('Solicitud de Justificación'), findsOneWidget);
      expect(find.text('Taller de Liderazgo'), findsOneWidget);
      expect(find.text('Motivo de la incidencia:'), findsOneWidget);

      expect(find.text('Corte de ruta/Paro'), findsOneWidget);
      expect(find.text('Emergencia médica'), findsOneWidget);
      expect(find.text('Trámite académico'), findsOneWidget);
      expect(find.text('Otro'), findsOneWidget);

      expect(find.text('Enviar Justificación'), findsOneWidget);
    });
  });
}
