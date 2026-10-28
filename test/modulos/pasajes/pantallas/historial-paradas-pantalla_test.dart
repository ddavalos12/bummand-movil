import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bumand_movil/modulos/pasajes/pantallas/historial-paradas-pantalla.dart';
import 'package:bumand_movil/modulos/pasajes/proveedores/pasajes-proveedor.dart';
import 'package:bumand_movil/modulos/pasajes/repositorios/pasajes-repositorio.dart';
import 'package:bumand_movil/nucleo/utilidades/resultado.dart';

class _PasajesRepositorioFalso extends PasajesRepositorio {
  @override
  Future<ResultadoPasaje<Map<String, dynamic>>> obtenerHistorialConsolidadoParadas({
    String? tramo,
    String? fecha_inicio,
    String? fecha_fin,
  }) async {
    return ResultadoPasaje.exitoso({
      'total_recorridos': 5,
      'total_gastado_bs': 20.0,
      'total_devolucion_bs': 16.0,
      'paradas_mas_frecuentes': [
        {'nombre': 'Ceja El Alto', 'frecuencia': 4},
        {'nombre': 'Pérez Velasco', 'frecuencia': 3},
      ],
      'recorridos': [
        {
          'id': 'rec-1',
          'fecha': '2026-10-28',
          'dia_semana': 'Miércoles',
          'tramo': 'ida',
          'origen': 'Ceja El Alto',
          'destino': 'Pérez Velasco',
          'tarifa': 4.0,
          'medio_transporte': 'Minibús',
          'paradas_secuencia': ['Ceja El Alto', 'Pérez Velasco'],
        },
      ],
    });
  }
}

void main() {
  group('HistorialParadasPantalla Pruebas de Widget', () {
    testWidgets('Renderiza métricas consolidadas, chips de filtro y tarjetas de recorrido', (
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
            pasajes_repositorio_proveedor.overrideWithValue(
              _PasajesRepositorioFalso(),
            ),
          ],
          child: const MaterialApp(
            home: HistorialParadasPantalla(),
          ),
        ),
      );

      await probador.pumpAndSettle();

      // Cabecera y título
      expect(find.text('Historial de Paradas'), findsOneWidget);
      expect(find.text('Trazabilidad y paradas frecuentes'), findsOneWidget);

      // Métricas consolidadas
      expect(find.text('Consolidado de Transporte'), findsOneWidget);
      expect(find.text('Recorridos'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Bs 20.00'), findsOneWidget);
      expect(find.text('Bs 16.00'), findsOneWidget);

      // Paradas frecuentes
      expect(find.text('Paradas más utilizadas'), findsOneWidget);
      expect(find.textContaining('Ceja El Alto (4)'), findsOneWidget);
      expect(find.textContaining('Pérez Velasco (3)'), findsOneWidget);

      // Tarjeta de recorrido
      expect(find.text('TRAMO IDA'), findsOneWidget);
      expect(find.text('Bs 4.00'), findsOneWidget);
    });
  });
}
