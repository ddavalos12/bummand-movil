import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bumand_movil/nucleo/utilidades/resultado.dart';
import 'package:bumand_movil/modulos/asistencia/pantallas/confirmar-datos-pantalla.dart';
import 'package:bumand_movil/modulos/asistencia/proveedores/asistencia-proveedor.dart';

void main() {
  group('ConfirmarDatosPantalla Pruebas de Widget', () {
    testWidgets('Campos Universidad, Carrera e Iglesia aparecen bloqueados y de solo lectura', (
      WidgetTester probador,
    ) async {
      probador.view.physicalSize = const Size(1080, 2400);
      probador.view.devicePixelRatio = 1.0;
      addTearDown(() {
        probador.view.resetPhysicalSize();
        probador.view.resetDevicePixelRatio();
      });

      final datos_perfil = {
        'nombre': 'María Catunta Laime',
        'ci': '9876543 LP',
        'universidad': 'Universidad Pública de El Alto (UPEA)',
        'carrera': 'Contaduría Pública',
        'iglesia': 'Iglesia Bautista Central',
        'telefono': '78945612',
        'direccion': 'Zona 16 de Julio, Calle Eulert #120',
        'contacto_emergencia': 'Juana Laime (Madre) - Cel: 71234567',
      };

      await probador.pumpWidget(
        ProviderScope(
          overrides: [
            perfil_proveedor.overrideWith((ref) async => Resultado.exitoso(datos_perfil)),
          ],
          child: const MaterialApp(
            home: ConfirmarDatosPantalla(periodo: 'Octubre 2026'),
          ),
        ),
      );

      await probador.pumpAndSettle();

      expect(find.text('Confirmación Mensual de Datos'), findsOneWidget);
      expect(find.text('Orden Administrativa Activa'), findsOneWidget);

      // Verificar campos bloqueados
      expect(find.text('Universidad'), findsOneWidget);
      expect(find.text('Universidad Pública de El Alto (UPEA)'), findsOneWidget);
      expect(find.text('Carrera'), findsOneWidget);
      expect(find.text('Contaduría Pública'), findsOneWidget);
      expect(find.text('Iglesia'), findsOneWidget);
      expect(find.text('Iglesia Bautista Central'), findsOneWidget);
      expect(
        find.text('Solo lectura por orden de administración'),
        findsNWidgets(3),
      );

      // Verificar campos editables de contacto
      expect(find.text('DATOS DE CONTACTO (EDITABLES)'), findsOneWidget);
      expect(find.text('Teléfono / Celular personal'), findsOneWidget);
      expect(find.text('Dirección domiciliaria'), findsOneWidget);
      expect(find.text('Contacto de emergencia (Nombre y teléfono)'), findsOneWidget);
      expect(find.text('Confirmar datos mensuales'), findsOneWidget);
    });
  });
}
