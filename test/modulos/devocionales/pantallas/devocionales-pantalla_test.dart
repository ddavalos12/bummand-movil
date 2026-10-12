import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bumand_movil/nucleo/utilidades/resultado.dart';
import 'package:bumand_movil/modulos/devocionales/modelos/versiculo-diario-modelo.dart';
import 'package:bumand_movil/modulos/devocionales/proveedores/devocionales-proveedor.dart';
import 'package:bumand_movil/modulos/devocionales/repositorios/devocionales-repositorio.dart';
import 'package:bumand_movil/modulos/devocionales/pantallas/devocionales-pantalla.dart';

void main() {
  const versiculo_prueba = VersiculoDiarioModelo(
    cita: 'Filipenses 4:13',
    libro: 'Filipenses',
    capitulo: 4,
    versiculo: 13,
    texto: 'Todo lo puedo en Cristo que me fortalece.',
    version: 'Reina-Valera 1960 (RVR60)',
    tema: 'Fortaleza y Servicio',
    reflexion_diaconal:
        'En cada labor y apoyo formativo dentro de Diaconía, Cristo renueva nuestras capacidades.',
  );

  final devocionales_prueba = [
    const DevocionalModelo(
      id: 1,
      fecha: '2026-10-10',
      cita_biblica: 'Josué 1:9',
      titulo: 'Valentía en el Servicio',
      reflexion: 'Esforzarse y ser valiente en cada tarea diaconal.',
      oracion_peticion: 'Por sabiduría en los estudios y la práctica.',
    ),
  ];

  group('DevocionalesPantalla Pruebas de Widget', () {
    testWidgets(
      'Renderiza versículo del día destacado con botón Meditar y Registrar y lista de devocionales',
      (WidgetTester probador) async {
        await probador.pumpWidget(
          ProviderScope(
            overrides: [
              versiculo_diario_proveedor.overrideWith(
                (ref) async => versiculo_prueba,
              ),
              devocionales_lista_proveedor.overrideWith(
                (ref) async => Resultado.exitoso(devocionales_prueba),
              ),
            ],
            child: const MaterialApp(
              home: DevocionalesPantalla(),
            ),
          ),
        );

        await probador.pumpAndSettle();

        expect(find.text('VERSÍCULO DEL DÍA'), findsOneWidget);
        expect(find.text('«Todo lo puedo en Cristo que me fortalece.»'), findsOneWidget);
        expect(find.text('Filipenses 4:13'), findsOneWidget);
        expect(find.text('Fortaleza y Servicio'), findsOneWidget);
        expect(find.text('Meditar y Registrar'), findsOneWidget);

        expect(find.text('Historial de Devocionales'), findsOneWidget);
        expect(find.text('Valentía en el Servicio'), findsOneWidget);
        expect(find.text('Josué 1:9'), findsOneWidget);
      },
    );

    testWidgets(
      'Al presionar Meditar y Registrar abre formulario pre-rellenado con la cita y tema',
      (WidgetTester probador) async {
        await probador.pumpWidget(
          ProviderScope(
            overrides: [
              versiculo_diario_proveedor.overrideWith(
                (ref) async => versiculo_prueba,
              ),
              devocionales_lista_proveedor.overrideWith(
                (ref) async => Resultado.exitoso(devocionales_prueba),
              ),
            ],
            child: const MaterialApp(
              home: DevocionalesPantalla(),
            ),
          ),
        );

        await probador.pumpAndSettle();

        final boton_meditar = find.text('Meditar y Registrar');
        expect(boton_meditar, findsOneWidget);
        await probador.tap(boton_meditar);
        await probador.pumpAndSettle();

        expect(find.text('Nuevo Devocional'), findsOneWidget);
        expect(find.text('Filipenses 4:13'), findsWidgets);
        expect(find.text('Fortaleza y Servicio - Meditación'), findsOneWidget);
      },
    );

    testWidgets(
      'Muestra estado vacio cuando no hay devocionales pero mantiene visible el versiculo del dia',
      (WidgetTester probador) async {
        await probador.pumpWidget(
          ProviderScope(
            overrides: [
              versiculo_diario_proveedor.overrideWith(
                (ref) async => versiculo_prueba,
              ),
              devocionales_lista_proveedor.overrideWith(
                (ref) async => Resultado.exitoso(<DevocionalModelo>[]),
              ),
            ],
            child: const MaterialApp(
              home: DevocionalesPantalla(),
            ),
          ),
        );

        await probador.pumpAndSettle();

        expect(find.text('VERSÍCULO DEL DÍA'), findsOneWidget);
        expect(find.text('No tienes devocionales registrados'), findsOneWidget);
      },
    );
  });
}
