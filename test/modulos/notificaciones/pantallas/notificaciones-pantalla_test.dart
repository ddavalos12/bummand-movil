import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bumand_movil/nucleo/utilidades/resultado.dart';
import 'package:bumand_movil/modulos/notificaciones/modelos/notificacion-modelo.dart';
import 'package:bumand_movil/modulos/notificaciones/repositorios/notificaciones-repositorio.dart';
import 'package:bumand_movil/modulos/notificaciones/proveedores/notificaciones-proveedor.dart';
import 'package:bumand_movil/modulos/notificaciones/pantallas/notificaciones-pantalla.dart';

class NotificacionesRepositorioSimulado extends NotificacionesRepositorio {
  List<NotificacionModelo> lista_simulada;
  int id_marcado = 0;

  NotificacionesRepositorioSimulado(this.lista_simulada);

  @override
  Future<Resultado<List<NotificacionModelo>>> obtenerMisNotificaciones() async {
    return Resultado.exitoso(lista_simulada);
  }

  @override
  Future<Resultado<int>> contarNoLeidas() async {
    final conteo = lista_simulada.where((n) => !n.leido).length;
    return Resultado.exitoso(conteo);
  }

  @override
  Future<Resultado<void>> marcarLeida(int id) async {
    id_marcado = id;
    lista_simulada = lista_simulada
        .map((n) => n.id == id ? n.copiarCon(leido: true) : n)
        .toList();
    return Resultado.exitoso(null);
  }
}

void main() {
  group('NotificacionesPantalla Pruebas de Widget', () {
    testWidgets('Renderiza lista de notificaciones con categorias de alertas', (
      WidgetTester probador,
    ) async {
      final notificaciones = [
        NotificacionModelo(
          id: 1,
          usuario_id: 10,
          tipo: 'recordatorio_salida',
          mensaje: 'Hora de registrar tu salida de prácticas',
          leido: false,
          fecha_envio: DateTime(2026, 10, 2, 18, 0),
        ),
        NotificacionModelo(
          id: 2,
          usuario_id: 10,
          tipo: 'pasajes_observados',
          mensaje: 'El recibo del día martes requiere corrección',
          leido: true,
          fecha_envio: DateTime(2026, 10, 2, 12, 30),
        ),
        NotificacionModelo(
          id: 3,
          usuario_id: 10,
          tipo: 'evaluacion_desempeno',
          mensaje: 'Se ha habilitado la evaluación de tu tutor',
          leido: false,
          fecha_envio: DateTime(2026, 10, 2, 9, 15),
        ),
      ];

      final repo = NotificacionesRepositorioSimulado(notificaciones);

      await probador.pumpWidget(
        ProviderScope(
          overrides: [
            notificaciones_repositorio_proveedor.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: NotificacionesPantalla(),
          ),
        ),
      );

      await probador.pumpAndSettle();

      expect(find.text('Notificaciones y alertas'), findsOneWidget);
      expect(find.text('Hora de registrar tu salida de prácticas'), findsOneWidget);
      expect(find.text('El recibo del día martes requiere corrección'), findsOneWidget);
      expect(find.text('Se ha habilitado la evaluación de tu tutor'), findsOneWidget);
      expect(find.text('Recordatorio de salida'), findsOneWidget);
      expect(find.text('Pasajes observados'), findsOneWidget);
      expect(find.text('Evaluación'), findsOneWidget);
    });

    testWidgets('Muestra estado vacio cuando no hay notificaciones', (
      WidgetTester probador,
    ) async {
      final repo = NotificacionesRepositorioSimulado([]);

      await probador.pumpWidget(
        ProviderScope(
          overrides: [
            notificaciones_repositorio_proveedor.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: NotificacionesPantalla(),
          ),
        ),
      );

      await probador.pumpAndSettle();

      expect(find.text('No hay notificaciones pendientes'), findsOneWidget);
    });

    testWidgets('Filtra notificaciones segun el filtro seleccionado', (
      WidgetTester probador,
    ) async {
      final notificaciones = [
        NotificacionModelo(
          id: 1,
          usuario_id: 10,
          tipo: 'recordatorio_salida',
          mensaje: 'Salida de prácticas',
          leido: false,
          fecha_envio: DateTime(2026, 10, 2, 18, 0),
        ),
        NotificacionModelo(
          id: 2,
          usuario_id: 10,
          tipo: 'pasajes_observados',
          mensaje: 'Recibo observado',
          leido: false,
          fecha_envio: DateTime(2026, 10, 2, 12, 0),
        ),
      ];

      final repo = NotificacionesRepositorioSimulado(notificaciones);

      await probador.pumpWidget(
        ProviderScope(
          overrides: [
            notificaciones_repositorio_proveedor.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: NotificacionesPantalla(),
          ),
        ),
      );

      await probador.pumpAndSettle();

      expect(find.text('Salida de prácticas'), findsOneWidget);
      expect(find.text('Recibo observado'), findsOneWidget);

      await probador.tap(find.text('Recordatorios'));
      await probador.pumpAndSettle();

      expect(find.text('Salida de prácticas'), findsOneWidget);
      expect(find.text('Recibo observado'), findsNothing);
    });

    testWidgets('Marca notificacion no leida como leida al tocarla', (
      WidgetTester probador,
    ) async {
      final notificaciones = [
        NotificacionModelo(
          id: 42,
          usuario_id: 10,
          tipo: 'recordatorio_salida',
          mensaje: 'Notificacion sin leer',
          leido: false,
          fecha_envio: DateTime(2026, 10, 2, 10, 0),
        ),
      ];

      final repo = NotificacionesRepositorioSimulado(notificaciones);

      await probador.pumpWidget(
        ProviderScope(
          overrides: [
            notificaciones_repositorio_proveedor.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: NotificacionesPantalla(),
          ),
        ),
      );

      await probador.pumpAndSettle();

      await probador.tap(find.text('Notificacion sin leer'));
      await probador.pumpAndSettle();

      expect(repo.id_marcado, 42);
    });
  });
}
