import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bumand_movil/modulos/autenticacion/modelos/usuario-modelo.dart';
import 'package:bumand_movil/modulos/autenticacion/proveedores/autenticacion-proveedor.dart';
import 'package:bumand_movil/modulos/evaluaciones/modelos/evaluacion-modelo.dart';
import 'package:bumand_movil/modulos/evaluaciones/pantallas/evaluaciones-pantalla.dart';
import 'package:bumand_movil/modulos/evaluaciones/proveedores/evaluaciones-proveedor.dart';
import 'package:bumand_movil/modulos/evaluaciones/repositorios/evaluaciones-repositorio.dart';
import 'package:bumand_movil/modulos/evaluaciones/widgets/detalle_evaluacion_modal.dart';
import 'package:bumand_movil/nucleo/utilidades/resultado.dart';

void main() {
  group('Bloque 2 Evaluaciones - TAREA-02, TAREA-13 y TAREA-12', () {
    test('TAREA-02 Repositorio: obtenerBecariosAsignadosModulo3 retorna lista válida', () async {
      final repo = EvaluacionesRepositorio();
      final res = await repo.obtenerBecariosAsignadosModulo3();

      expect(res.exito, isTrue);
      expect(res.datos, isNotNull);
      expect(res.datos!.isNotEmpty, isTrue);
      expect(res.datos!.first.nombre, contains('María Catunta'));
    });

    test('TAREA-12 Repositorio: obtenerTareasEscuelaLideres retorna 12 tareas teológicas CETI', () async {
      final repo = EvaluacionesRepositorio();
      final res = await repo.obtenerTareasEscuelaLideres();

      expect(res.exito, isTrue);
      expect(res.datos, isNotNull);
      expect(res.datos!.length, 12);
      expect(res.datos!.first.tema, 'Liderazgo Servidor y Mayordomía Cristiana');
      expect(res.datos!.first.ponderacion, 8.33);
    });

    testWidgets('TAREA-02 Widget: Vista de supervisor muestra lista de becarios y botón Evaluar / Editar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const usuario_supervisor = UsuarioModelo(
        id: 99,
        nombre: 'Lic. Carlos Mendoza',
        correo: 'carlos.mendoza@diaconia.bo',
        rol: 'supervisor',
        token: 'token_prueba',
      );

      final lista_becarios = BecarioAsignadoModulo3Modelo.listaEjemplo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            autenticacion_proveedor.overrideWith(
              () => _AutenticacionNotificadorMock(usuario_supervisor),
            ),
            becarios_asignados_modulo3_proveedor.overrideWith(
              (ref) async => Resultado.exitoso(lista_becarios),
            ),
          ],
          child: const MaterialApp(
            home: EvaluacionesPantalla(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Debe mostrar la cabecera y lista de becarios asignados para el supervisor
      expect(find.text('Mis Becarios Asignados (Módulo 3)'), findsWidgets);
      expect(find.text('María Catunta Laime'), findsOneWidget);
      expect(find.text('Juan Carlos Mamani Quispe'), findsOneWidget);
      expect(find.text('Evaluar / Editar Módulo 3'), findsWidgets);
      expect(find.text('Editar Módulo 3'), findsOneWidget);
    });

    testWidgets('TAREA-13 Widget: mostrarReceptorAcademico muestra selector de semestre, doble botón y badge de administración', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DetalleEvaluacionModal.mostrarReceptorAcademico(context),
                child: const Text('Abrir Receptor Académico'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Receptor Académico'));
      await tester.pumpAndSettle();

      // Verificar cabecera oficial
      expect(find.text('Subida de Documentos Académicos'), findsOneWidget);
      expect(find.text('Revisión Directa por Administración'), findsOneWidget);

      // Selector de semestre dinámico
      expect(find.text('Semestre II - 2026'), findsWidgets);
      expect(find.text('Semestre I - 2026'), findsOneWidget);
      expect(find.text('Semestre II - 2025'), findsOneWidget);

      // Dos botones independientes
      expect(find.text('1. Récord Académico'), findsOneWidget);
      expect(find.text('Subir Récord Académico'), findsOneWidget);
      expect(find.text('2. Historial Académico'), findsOneWidget);
      expect(find.text('Subir Historial Académico'), findsOneWidget);
    });

    testWidgets('TAREA-12 Widget: mostrarReceptorLideresClassroom muestra estilo Classroom, 12 tareas y sello REVISADO', (tester) async {
      tester.view.physicalSize = const Size(1080, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => DetalleEvaluacionModal.mostrarReceptorLideresClassroom(context),
                child: const Text('Abrir Aula Virtual Lideres'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Aula Virtual Lideres'));
      await tester.pumpAndSettle();

      // Cabecera Classroom y progreso
      expect(find.text('Aula Virtual · Escuela de Líderes'), findsOneWidget);
      expect(find.text('Progreso de Tareas Semestrales'), findsOneWidget);
      expect(find.textContaining('de 12 revisadas'), findsOneWidget);

      // Filtros
      expect(find.text('Todas (12)'), findsOneWidget);
      expect(find.textContaining('Pendientes'), findsWidgets);
      expect(find.textContaining('Entregadas'), findsWidgets);
      expect(find.textContaining('Revisadas'), findsWidgets);

      // Tarea 1 revisada con su sello
      expect(find.text('Liderazgo Servidor y Mayordomía Cristiana'), findsOneWidget);
      expect(find.textContaining('REVISADO · 95/100 pts'), findsOneWidget);
      expect(find.textContaining('Retroalimentación:'), findsWidgets);
    });
  });
}

class _AutenticacionNotificadorMock extends AutenticacionNotificador {
  final UsuarioModelo _usuario;

  _AutenticacionNotificadorMock(this._usuario);

  @override
  AutenticacionEstado build() {
    return AutenticacionEstado(usuario: _usuario);
  }
}
