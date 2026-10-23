import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bumand_movil/modulos/pasajes/modelos/recorrido-modelo.dart';
import 'package:bumand_movil/modulos/pasajes/modelos/solicitud-pasaje-modelo.dart';
import 'package:bumand_movil/modulos/pasajes/pantallas/declarar-recorrido-pantalla.dart';
import 'package:bumand_movil/modulos/pasajes/proveedores/pasajes-proveedor.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pestaña Declarar Pasajes (Recorrido de Hoy)', () {
    testWidgets(
      'Renderiza formulario de hoy con pestañas de ida y vuelta y badge de sólo hoy',
      (WidgetTester probador) async {
        probador.view.physicalSize = const Size(1080, 2400);
        probador.view.devicePixelRatio = 1.0;
        addTearDown(() {
          probador.view.resetPhysicalSize();
          probador.view.resetDevicePixelRatio();
        });

        await probador.pumpWidget(
          ProviderScope(
            overrides: [
              solicitudes_pasajes_proveedor.overrideWith(
                () => _SolicitudesVaciasNotificador(),
              ),
            ],
            child: const MaterialApp(
              home: DeclararRecorridoPantalla(
                es_pestana: true,
                solo_hoy: true,
              ),
            ),
          ),
        );

        await probador.pumpAndSettle();

        // 1. Cabecera de la pestaña
        expect(find.text('Declarar pasajes'), findsOneWidget);
        expect(find.text('Recorrido de hoy'), findsOneWidget);

        // 2. Indicadores de fecha fija y restricción sólo hoy
        expect(find.text('Declaración activa para hoy'), findsOneWidget);
        expect(find.text('Disponible para editar sólo hoy'), findsOneWidget);
        expect(find.text('HOY'), findsOneWidget);

        // 3. Pasos de Ida y Vuelta presentes
        expect(find.textContaining('1 · Ida'), findsOneWidget);
        expect(find.textContaining('2 · Vuelta'), findsOneWidget);

        // 4. Selector de tipo de actividad
        expect(find.text('Tipo de actividad'), findsOneWidget);
        expect(find.text('Prácticas'), findsOneWidget);

        // 5. Botón de guardar de hoy (cuando no hay registro previo)
        expect(find.text('Guardar recorrido de hoy'), findsOneWidget);
      },
    );

    testWidgets(
      'Muestra tarjeta de recorrido de hoy declarado con opción de actualizar',
      (WidgetTester probador) async {
        probador.view.physicalSize = const Size(1080, 2400);
        probador.view.devicePixelRatio = 1.0;
        addTearDown(() {
          probador.view.resetPhysicalSize();
          probador.view.resetDevicePixelRatio();
        });

        final ahora = DateTime.now();
        final recorrido_ida = RecorridoModelo(
          id: 501,
          fecha: ahora,
          tramo: 'ida',
          origen: 'Villa Adela, El Alto',
          destino: 'Oficina Central Diaconía',
          tarifa: 4.5,
          apoyo_realizado: '[Prácticas] Soporte técnico matutino | Calles: Villa Adela → Ceja → Diaconía | Transporte: Minibús + Teleférico',
          calles_declaradas: 'Villa Adela → Ceja → Diaconía',
          medio_transporte: 'Minibús + Teleférico',
        );

        final recorrido_vuelta = RecorridoModelo(
          id: 502,
          fecha: ahora,
          tramo: 'vuelta',
          origen: 'Oficina Central Diaconía',
          destino: 'Villa Adela, El Alto',
          tarifa: 4.5,
          apoyo_realizado: '[Prácticas] Retorno a domicilio | Calles: Diaconía → Ceja → Villa Adela | Transporte: Teleférico + Minibús',
          calles_declaradas: 'Diaconía → Ceja → Villa Adela',
          medio_transporte: 'Teleférico + Minibús',
        );

        final solicitud_hoy = SolicitudPasajeModelo(
          id: 10,
          periodo: '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}',
          estado: 'borrador',
          monto_total: 9.0,
          monto_devolucion: 7.2,
          recorridos: [recorrido_ida, recorrido_vuelta],
        );

        await probador.pumpWidget(
          ProviderScope(
            overrides: [
              solicitudes_pasajes_proveedor.overrideWith(
                () => _SolicitudesConDatosNotificador([solicitud_hoy]),
              ),
            ],
            child: const MaterialApp(
              home: DeclararRecorridoPantalla(
                es_pestana: true,
                solo_hoy: true,
              ),
            ),
          ),
        );

        await probador.pump();
        await probador.pump(const Duration(milliseconds: 100));
        await probador.pumpAndSettle();

        // 1. Tarjeta informativa de hoy ya declarado
        expect(find.text('Recorrido de hoy declarado'), findsOneWidget);
        expect(
          find.text('Disponible para editar sólo hoy · Puedes ajustar cualquier parada o tarifa'),
          findsOneWidget,
        );

        // 2. Detalle de tramos de ida y vuelta guardados
        expect(find.textContaining('Ida: Villa Adela, El Alto → Oficina Central Diaconía'), findsOneWidget);
        expect(find.textContaining('Vuelta: Oficina Central Diaconía → Villa Adela, El Alto'), findsOneWidget);

        // 3. Botón para actualizar el recorrido de hoy
        expect(find.text('Actualizar recorrido de hoy'), findsOneWidget);
      },
    );
  });
}

class _SolicitudesVaciasNotificador extends SolicitudesPasajesNotificador {
  @override
  Future<List<SolicitudPasajeModelo>> build() async => [];
}

class _SolicitudesConDatosNotificador extends SolicitudesPasajesNotificador {
  final List<SolicitudPasajeModelo> lista_solicitudes;
  _SolicitudesConDatosNotificador(this.lista_solicitudes);

  @override
  Future<List<SolicitudPasajeModelo>> build() async => lista_solicitudes;
}
