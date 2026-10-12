import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bumand_movil/nucleo/utilidades/resultado.dart';
import 'package:bumand_movil/modulos/asistencia/proveedores/asistencia-proveedor.dart';
import 'package:bumand_movil/modulos/asistencia/pantallas/historial-asistencia-pantalla.dart';
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
  });
}
