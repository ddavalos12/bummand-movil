import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bumand_movil/nucleo/utilidades/resultado.dart';
import 'package:bumand_movil/modulos/justificaciones/pantallas/permisos-pantalla.dart';
import 'package:bumand_movil/modulos/justificaciones/servicios/justificaciones-servicio.dart';

void main() {
  group('PermisosPantalla Pruebas de Widget', () {
    testWidgets('Renderiza cabecera, flujo de 2 niveles, listado de solicitudes y badge sin multa', (
      WidgetTester probador,
    ) async {
      probador.view.physicalSize = const Size(1080, 2400);
      probador.view.devicePixelRatio = 1.0;
      addTearDown(() {
        probador.view.resetPhysicalSize();
        probador.view.resetDevicePixelRatio();
      });

      final lista_permisos = [
        {
          "id": 1,
          "tipo_incidencia": "escuela_lideres",
          "fecha_incidencia": "2026-10-23",
          "motivo": "Emergencia médica / Receta",
          "descripcion": "Atención de urgencia odontológica en centro de salud.",
          "nombre_archivo_prueba": "Certificado_Odontologico.pdf",
          "estado": "aprobado_administracion",
          "observacion_supervisor": "Verificado con respaldo.",
          "observacion_admin": "Aprobado sin multa de viernes.",
        },
        {
          "id": 2,
          "tipo_incidencia": "asistencia_practicas",
          "fecha_incidencia": "2026-10-26",
          "motivo": "Trámite académico / Examen",
          "descripcion": "Defensa de perfil de grado universitario.",
          "nombre_archivo_prueba": "Boleta_Tramite.pdf",
          "estado": "revisado_supervisor",
          "observacion_supervisor": "Pasa a administración.",
        },
        {
          "id": 3,
          "tipo_incidencia": "asistencia_evento",
          "fecha_incidencia": "2026-10-30",
          "motivo": "Asunto pastoral / Institucional",
          "descripcion": "Permiso anticipado para jornada de viernes.",
          "estado": "pendiente",
        },
      ];

      await probador.pumpWidget(
        ProviderScope(
          overrides: [
            mis_justificaciones_proveedor.overrideWith(
              (ref) async => Resultado.exitoso(lista_permisos),
            ),
          ],
          child: const MaterialApp(
            home: PermisosPantalla(),
          ),
        ),
      );

      await probador.pumpAndSettle();

      // Cabecera y tarjeta explicativa de 2 niveles
      expect(find.text('Permisos y Justificaciones'), findsOneWidget);
      expect(find.text('Flujo de Aprobación en 2 Niveles'), findsOneWidget);
      expect(find.text('Solicitar Permiso'), findsOneWidget);

      // Filtros rápidos
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('1. Pendientes'), findsOneWidget);
      expect(find.text('2. Revisados'), findsOneWidget);
      expect(find.text('Aprobados'), findsOneWidget);
      expect(find.text('Viernes (Sin Multa)'), findsOneWidget);

      // Solicitud 1: Escuela de Líderes Aprobada con Exención de Multa
      expect(find.text('Escuela de Líderes (Viernes)'), findsOneWidget);
      expect(find.text('Sin Multa (Permiso Aprobado) — Bs 0.00'), findsOneWidget);
      expect(find.text('Certificado_Odontologico.pdf'), findsOneWidget);
      expect(find.text('Administración: Aprobado sin multa de viernes.'), findsOneWidget);

      // Solicitud 2: Prácticas revisada por supervisor
      expect(find.text('Prácticas Institucionales'), findsOneWidget);
      expect(find.text('Supervisor: Pasa a administración.'), findsOneWidget);

      // Solicitud 3: Pendiente
      expect(find.text('Acción de Servicio (Viernes)'), findsOneWidget);
    });

    testWidgets('Muestra estado vacío amigable cuando no existen solicitudes', (
      WidgetTester probador,
    ) async {
      await probador.pumpWidget(
        ProviderScope(
          overrides: [
            mis_justificaciones_proveedor.overrideWith(
              (ref) async => Resultado.exitoso(<Map<String, dynamic>>[]),
            ),
          ],
          child: const MaterialApp(
            home: PermisosPantalla(),
          ),
        ),
      );

      await probador.pumpAndSettle();

      expect(find.text('No hay solicitudes en esta sección'), findsOneWidget);
    });
  });
}
