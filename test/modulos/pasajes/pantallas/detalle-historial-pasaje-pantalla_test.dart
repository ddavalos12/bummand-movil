import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bumand_movil/modulos/pasajes/modelos/recorrido-modelo.dart';
import 'package:bumand_movil/modulos/pasajes/modelos/solicitud-pasaje-modelo.dart';
import 'package:bumand_movil/modulos/pasajes/pantallas/detalle-historial-pasaje-pantalla.dart';

void main() {
  testWidgets('DetalleHistorialPasajePantalla renderiza totales y paradas declaradas',
      (WidgetTester tester) async {
    final solicitud = SolicitudPasajeModelo(
      id: 201,
      periodo: '2026-10',
      estado: 'borrador',
      monto_total: 28.00,
      monto_devolucion: 22.40,
      recorridos: [
        RecorridoModelo(
          id: 1,
          fecha: DateTime(2026, 10, 2),
          tramo: 'ida',
          origen: 'Av. Buenos Aires',
          destino: 'Oficina Central',
          tarifa: 2.50,
        ),
        RecorridoModelo(
          id: 2,
          fecha: DateTime(2026, 10, 2),
          tramo: 'vuelta',
          origen: 'Oficina Central',
          destino: 'Av. Buenos Aires',
          tarifa: 2.50,
        ),
        RecorridoModelo(
          id: 3,
          fecha: DateTime(2026, 10, 6),
          tramo: 'ida',
          origen: 'Av. Buenos Aires',
          destino: 'Oficina Central',
          tarifa: 2.50,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: DetalleHistorialPasajePantalla(solicitud: solicitud),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verificación de cabecera
    expect(find.text('Mi historial'), findsOneWidget);
    expect(find.textContaining('Periodo:'), findsOneWidget);

    // Verificación de tarjeta de montos
    expect(find.text('MONTO TOTAL DEL PASAJE'), findsOneWidget);
    expect(find.text('Bs 28.00'), findsOneWidget);
    expect(find.text('DEVOLUCIÓN DEL 80%'), findsOneWidget);
    expect(find.text('Bs 22.40'), findsOneWidget);

    // Verificación de lista de recorridos declarados
    expect(find.text('Recorridos declarados'), findsOneWidget);

    // Debe mostrar la secuencia consolidada de ida y vuelta con paradas separadas por '-'
    expect(
      find.text('Av. Buenos Aires - Oficina Central - Av. Buenos Aires'),
      findsOneWidget,
    );
    expect(find.text('5.00'), findsOneWidget);

    // Debe mostrar el tramo simple de solo ida
    expect(find.text('Av. Buenos Aires - Oficina Central'), findsOneWidget);
    expect(find.text('2.50'), findsOneWidget);

    // Debe mostrar las fechas en los badges
    expect(find.text('02-10'), findsOneWidget);
    expect(find.text('06-10'), findsOneWidget);
  });
}
