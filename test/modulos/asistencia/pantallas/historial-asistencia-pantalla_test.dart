import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bumand_movil/nucleo/utilidades/resultado.dart';
import 'package:bumand_movil/modulos/asistencia/proveedores/asistencia-proveedor.dart';
import 'package:bumand_movil/modulos/asistencia/pantallas/historial-asistencia-pantalla.dart';
import 'package:bumand_movil/modulos/evaluaciones/modelos/evaluacion-modelo.dart';
import 'package:bumand_movil/modulos/evaluaciones/proveedores/evaluaciones-proveedor.dart';
import 'package:bumand_movil/modulos/pasajes/modelos/solicitud-pasaje-modelo.dart';
import 'package:bumand_movil/modulos/pasajes/proveedores/pasajes-proveedor.dart';

class _FalsoSolicitudesNotificador extends SolicitudesPasajesNotificador {
  final List<SolicitudPasajeModelo> _datos;
  _FalsoSolicitudesNotificador(this._datos);

  @override
  Future<List<SolicitudPasajeModelo>> build() async {
    return _datos;
  }
}

void main() {
  group('HistorialAsistenciaPantalla Pruebas de Widget', () {
    testWidgets(
      'Renderiza lista de asistencias, bloque detectado y badge de viernes',
      (WidgetTester probador) async {
        final registros_prueba = [
          {
            "id": 1,
            "fecha": "2026-10-09",
            "tipo": "liderazgo",
            "bloque": "Bloque Norte (Auditorio)",
            "es_viernes": true,
            "confirmado_organizador": true,
            "horaIngreso": "14:32",
            "horaSalida": "17:00",
          },
          {
            "id": 2,
            "fecha": "2026-10-10",
            "tipo": "practicas",
            "bloque": "Bloque Central",
            "horaIngreso": "08:30",
            "horaSalida": "12:30",
          },
        ];

        await probador.pumpWidget(
          ProviderScope(
            overrides: [
              historial_asistencia_proveedor.overrideWith(
                (ref) async => Resultado.exitoso(registros_prueba),
              ),
            ],
            child: const MaterialApp(
              home: HistorialAsistenciaPantalla(),
            ),
          ),
        );

        await probador.pumpAndSettle();

        expect(find.text('Historial de Asistencias'), findsOneWidget);
        expect(find.text('2026-10-09'), findsOneWidget);
        expect(
          find.text('Bloque detectado: Bloque Norte (Auditorio)'),
          findsOneWidget,
        );
        expect(
          find.text('Viernes • Confirmada por organizador'),
          findsOneWidget,
        );
        expect(find.text('GPS Verificado'), findsNWidgets(2));
      },
    );

    testWidgets('Muestra estado vacio cuando no hay registros', (
      WidgetTester probador,
    ) async {
      await probador.pumpWidget(
        ProviderScope(
          overrides: [
            historial_asistencia_proveedor.overrideWith(
              (ref) async => Resultado.exitoso(<Map<String, dynamic>>[]),
            ),
          ],
          child: const MaterialApp(
            home: HistorialAsistenciaPantalla(),
          ),
        ),
      );

      await probador.pumpAndSettle();

      expect(find.text('No hay registros de asistencia'), findsOneWidget);
    });

    testWidgets(
      'Cambia a pestana Pasajes y muestra resumen de viaticos al 80%',
      (WidgetTester probador) async {
        final solicitudes_prueba = [
          SolicitudPasajeModelo(
            id: 201,
            periodo: 'Noviembre 2026',
            estado: 'APROBADO',
            monto_total: 200.0,
            monto_devolucion: 160.0,
            observaciones: 'Aprobación de pasajes diaconales',
            recorridos: [],
          ),
        ];

        await probador.pumpWidget(
          ProviderScope(
            overrides: [
              historial_asistencia_proveedor.overrideWith(
                (ref) async => Resultado.exitoso(<Map<String, dynamic>>[]),
              ),
              solicitudes_pasajes_proveedor.overrideWith(
                () => _FalsoSolicitudesNotificador(solicitudes_prueba),
              ),
            ],
            child: const MaterialApp(
              home: HistorialAsistenciaPantalla(),
            ),
          ),
        );

        await probador.pumpAndSettle();

        final pestana_pasajes = find.text('Pasajes');
        expect(pestana_pasajes, findsOneWidget);
        await probador.tap(pestana_pasajes);
        await probador.pumpAndSettle();

        expect(find.text('Total declarado'), findsOneWidget);
        expect(find.text('Devolución (80%)'), findsWidgets);
        expect(find.text('Noviembre 2026'), findsOneWidget);
        expect(find.text('Bs. 200.00'), findsWidgets);
        expect(find.text('Bs. 160.00'), findsWidgets);
        expect(find.text('APROBADO'), findsOneWidget);
      },
    );

    testWidgets(
      'Cambia a pestana Multas e Incidencias y muestra desglose transparente',
      (WidgetTester probador) async {
        await probador.pumpWidget(
          ProviderScope(
            overrides: [
              historial_asistencia_proveedor.overrideWith(
                (ref) async => Resultado.exitoso(<Map<String, dynamic>>[]),
              ),
            ],
            child: const MaterialApp(
              home: HistorialAsistenciaPantalla(),
            ),
          ),
        );

        await probador.pumpAndSettle();

        final pestana_multas = find.text('Multas e Incidencias');
        expect(pestana_multas, findsOneWidget);
        await probador.tap(pestana_multas);
        await probador.pumpAndSettle();

        expect(
          find.text('Aviso Institucional de Retención por Retraso'),
          findsOneWidget,
        );
        expect(find.text('Total Retención'), findsOneWidget);
        expect(find.text('Minutos Retraso'), findsOneWidget);
        expect(find.text('Viernes 09/10/2026'), findsOneWidget);
        expect(
          find.text('Retraso a Escuela de Líderes pasadas las 14:35'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'Cambia a pestana Evaluaciones (360°) y muestra sus subsecciones formativas',
      (WidgetTester probador) async {
        probador.view.physicalSize = const Size(1080, 2400);
        probador.view.devicePixelRatio = 1.0;
        addTearDown(() {
          probador.view.resetPhysicalSize();
          probador.view.resetDevicePixelRatio();
        });

        final evaluacion_ejemplo = EvaluacionConsolidadaModelo.modeloEjemplo();

        await probador.pumpWidget(
          ProviderScope(
            overrides: [
              historial_asistencia_proveedor.overrideWith(
                (ref) async => Resultado.exitoso(<Map<String, dynamic>>[]),
              ),
              evaluacion_consolidada_proveedor.overrideWith(
                (ref) async => Resultado.exitoso(evaluacion_ejemplo),
              ),
            ],
            child: const MaterialApp(
              home: HistorialAsistenciaPantalla(),
            ),
          ),
        );

        await probador.pumpAndSettle();

        final pestana_evaluaciones = find.text('Evaluaciones (360°)');
        expect(pestana_evaluaciones, findsOneWidget);
        await probador.tap(pestana_evaluaciones);
        await probador.pumpAndSettle();

        // Verifica chips de subsecciones
        expect(find.text('Todas las subsecciones'), findsOneWidget);
        expect(find.text('Nota Global 360°'), findsOneWidget);
        expect(find.text('Formulario F-03'), findsOneWidget);
        expect(find.text('Módulos Canónicos'), findsOneWidget);
        expect(find.text('Criterios Formativos'), findsOneWidget);

        // Verifica contenido de las 4 subsecciones
        expect(find.text('Nota Global Ponderada (360°)'), findsOneWidget);
        expect(find.text('17.7 / 20 pts'), findsOneWidget);
        expect(find.text('88.5%'), findsOneWidget);

        expect(find.text('Formulario F-03 del Pastor'), findsOneWidget);
        expect(find.text('Abrir F-03'), findsOneWidget);

        expect(find.text('Desglose por Módulos Canónicos'), findsOneWidget);
        expect(
          find.text('Liderazgo en la Iglesia (Formulario F-03)'),
          findsOneWidget,
        );

        expect(find.text('Criterios y Competencias Formativas'), findsOneWidget);
        expect(find.text('Criterios de Excelencia Diaconal'), findsOneWidget);

        // Prueba filtro de subsección específico (Formulario F-03)
        await probador.tap(find.text('Formulario F-03'));
        await probador.pumpAndSettle();

        expect(find.text('Formulario F-03 del Pastor'), findsOneWidget);
        expect(find.text('Nota Global Ponderada (360°)'), findsNothing);
      },
    );
  });
}
