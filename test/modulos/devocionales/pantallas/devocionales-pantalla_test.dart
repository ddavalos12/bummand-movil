import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bumand_movil/modulos/autenticacion/modelos/usuario-modelo.dart';
import 'package:bumand_movil/modulos/autenticacion/proveedores/autenticacion-proveedor.dart';
import 'package:bumand_movil/modulos/devocionales/modelos/cita-seguimiento-modelo.dart';
import 'package:bumand_movil/modulos/devocionales/modelos/versiculo-diario-modelo.dart';
import 'package:bumand_movil/modulos/devocionales/pantallas/devocionales-pantalla.dart';
import 'package:bumand_movil/modulos/devocionales/proveedores/devocionales-proveedor.dart';
import 'package:bumand_movil/modulos/devocionales/repositorios/devocionales-repositorio.dart';
import 'package:bumand_movil/nucleo/utilidades/resultado.dart';

class _AutenticacionNotificadorMock extends AutenticacionNotificador {
  final UsuarioModelo _usuario;

  _AutenticacionNotificadorMock(this._usuario);

  @override
  AutenticacionEstado build() {
    return AutenticacionEstado(usuario: _usuario);
  }
}

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

  final citas_prueba = [
    const CitaSeguimientoModelo(
      id: 101,
      supervisor_id: 1,
      supervisor_nombre: 'Pastor Marcos Quispe',
      becario_id: 10,
      becario_nombre: 'María Catunta Laime',
      fecha_cita: '2026-10-30',
      hora_cita: '15:30',
      modalidad: 'presencial',
      lugar_o_enlace: 'Oficina Central Diaconía',
      motivo_retroalimentacion: 'Revisión de avance formativo diaconal',
      cita_biblica: 'Jeremías 29:11',
      acuerdos_retroalimentacion: 'Mantener tiempo de devocional matutino',
      estado: 'programada',
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

    testWidgets(
      'Muestra sección Mis Citas de Seguimiento con mi Supervisor para becario con citas agendadas',
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
              citas_seguimiento_proveedor.overrideWith(
                (ref) async => Resultado.exitoso(citas_prueba),
              ),
            ],
            child: const MaterialApp(
              home: DevocionalesPantalla(),
            ),
          ),
        );

        await probador.pumpAndSettle();

        expect(
          find.text('Mis Citas de Seguimiento con mi Supervisor'),
          findsOneWidget,
        );
        expect(find.text('Pastor Marcos Quispe'), findsOneWidget);
        expect(find.text('2026-10-30 a las 15:30'), findsOneWidget);
        expect(
          find.text('Motivo: Revisión de avance formativo diaconal'),
          findsOneWidget,
        );
        expect(find.text('Jeremías 29:11'), findsOneWidget);
        expect(
          find.text('Mantener tiempo de devocional matutino'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Muestra vista exclusiva de supervisor con botón destacado, Mis Becarios Supervisados y abre DarCitaSeguimientoModal',
      (WidgetTester probador) async {
        const usuario_supervisor = UsuarioModelo(
          id: 1,
          nombre: 'Pastor Marcos Quispe',
          correo: 'marcos.quispe@diaconia.bo',
          rol: 'supervisor',
          token: 'token_supervisor',
        );

        await probador.pumpWidget(
          ProviderScope(
            overrides: [
              autenticacion_proveedor.overrideWith(
                () => _AutenticacionNotificadorMock(usuario_supervisor),
              ),
              citas_seguimiento_proveedor.overrideWith(
                (ref) async => Resultado.exitoso(citas_prueba),
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

        expect(find.text('Panel de Supervisión Diaconal'), findsOneWidget);
        expect(find.text('Mis Becarios Supervisados'), findsOneWidget);
        expect(find.text('Citas de Seguimiento Agendadas'), findsOneWidget);
        expect(find.text('Dar Cita a Supervisado'), findsWidgets);

        // Abre el modal para dar cita al supervisado
        final boton_dar_cita = find.widgetWithText(ElevatedButton, 'Dar Cita a Supervisado');
        expect(boton_dar_cita, findsOneWidget);
        await probador.tap(boton_dar_cita);
        await probador.pumpAndSettle();

        expect(find.text('Becario a supervisar'), findsOneWidget);
        expect(find.text('Agendar Cita de Seguimiento'), findsOneWidget);
        expect(find.text('Presencial'), findsOneWidget);
        expect(find.text('Virtual (Meet)'), findsOneWidget);
      },
    );

    testWidgets(
      'Muestra vista de acceso restringido cuando el usuario es administrador general',
      (WidgetTester probador) async {
        const usuario_admin = UsuarioModelo(
          id: 99,
          nombre: 'Administrador General',
          correo: 'admin@diaconia.bo',
          rol: 'administrador',
          token: 'token_admin',
        );

        await probador.pumpWidget(
          ProviderScope(
            overrides: [
              autenticacion_proveedor.overrideWith(
                () => _AutenticacionNotificadorMock(usuario_admin),
              ),
            ],
            child: const MaterialApp(
              home: DevocionalesPantalla(),
            ),
          ),
        );

        await probador.pumpAndSettle();

        expect(
          find.text('Módulo Exclusivo para Supervisor y Becarios'),
          findsOneWidget,
        );
        expect(find.text('Volver al Menú Principal'), findsOneWidget);
      },
    );
  });
}
