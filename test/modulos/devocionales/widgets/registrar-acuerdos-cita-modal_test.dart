import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bumand_movil/modulos/devocionales/modelos/cita-seguimiento-modelo.dart';
import 'package:bumand_movil/modulos/devocionales/widgets/registrar-acuerdos-cita-modal.dart';

void main() {
  testWidgets('RegistrarAcuerdosCitaModal renderiza información de la cita y campos', (
    WidgetTester probador,
  ) async {
    const cita = CitaSeguimientoModelo(
      id: 101,
      supervisor_id: 1,
      supervisor_nombre: 'Pastor Marcos Quispe',
      becario_id: 10,
      becario_nombre: 'María Catunta Laime',
      fecha_cita: '2026-10-30',
      hora_cita: '15:30',
      modalidad: 'presencial',
      lugar_o_enlace: 'Oficina Central Diaconía',
      motivo_retroalimentacion: 'Revisión y acuerdos diaconales',
      cita_biblica: 'Josué 1:9',
      estado: 'programada',
    );

    await probador.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: RegistrarAcuerdosCitaModal(cita: cita),
          ),
        ),
      ),
    );

    await probador.pumpAndSettle();

    expect(find.text('Registrar Acuerdos'), findsOneWidget);
    expect(find.text('María Catunta Laime'), findsOneWidget);
    expect(find.text('Presencial'), findsOneWidget);
    expect(find.text('2026-10-30 a las 15:30'), findsOneWidget);
    expect(find.text('Motivo: Revisión y acuerdos diaconales'), findsOneWidget);
    expect(find.text('Josué 1:9'), findsOneWidget);

    expect(find.text('Realizada'), findsOneWidget);
    expect(find.text('Reprogramar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Guardar Acuerdos'), findsOneWidget);
  });
}
