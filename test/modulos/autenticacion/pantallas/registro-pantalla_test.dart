import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bumand_movil/nucleo/utilidades/resultado.dart';
import 'package:bumand_movil/modulos/autenticacion/repositorios/autenticacion-repositorio.dart';
import 'package:bumand_movil/modulos/autenticacion/proveedores/autenticacion-proveedor.dart';
import 'package:bumand_movil/modulos/autenticacion/pantallas/registro-pantalla.dart';

class RepositorioSimuladoRegistro extends AutenticacionRepositorio {
  @override
  Future<Resultado<Map<String, dynamic>>> verificarCi(String ci) async {
    if (ci == '13696496') {
      return Resultado.exitoso({
        'existe': true,
        'ya_registrado': false,
        'nombre': 'Adai Belen Huayta Cardozo',
      });
    }
    return Resultado.fallido('No figura en nómina');
  }
}

void main() {
  group('RegistroPantalla Pruebas de Widget', () {
    testWidgets('Renderiza campos de registro y botón crear cuenta', (WidgetTester probador) async {
      await probador.pumpWidget(
        ProviderScope(
          overrides: [
            autenticacion_repositorio_proveedor.overrideWithValue(RepositorioSimuladoRegistro()),
          ],
          child: const MaterialApp(
            home: RegistroPantalla(),
          ),
        ),
      );

      expect(find.text('Activación de cuenta para becarios en nómina oficial'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(5));
      expect(find.text('Crear cuenta'), findsOneWidget);
    });

    testWidgets('Valida formato de CI incorrecto', (WidgetTester probador) async {
      await probador.pumpWidget(
        ProviderScope(
          overrides: [
            autenticacion_repositorio_proveedor.overrideWithValue(RepositorioSimuladoRegistro()),
          ],
          child: const MaterialApp(
            home: RegistroPantalla(),
          ),
        ),
      );

      await probador.enterText(find.byType(TextField).at(0), 'abc');
      await probador.tap(find.text('Crear cuenta'));
      await probador.pump(const Duration(milliseconds: 100));

      expect(find.textContaining('Escribe tu CI solo con números'), findsOneWidget);
    });
  });
}
