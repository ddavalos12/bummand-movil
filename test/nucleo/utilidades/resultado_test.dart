import 'package:flutter_test/flutter_test.dart';
import 'package:bumand_movil/nucleo/utilidades/resultado.dart';

void main() {
  group('Resultado Pruebas', () {
    test('Resultado exitoso contiene datos y exito en true', () {
      final resultado = Resultado<String>.exitoso('operacion completada');

      expect(resultado.exito, isTrue);
      expect(resultado.datos, equals('operacion completada'));
      expect(resultado.error, isNull);
    });

    test('Resultado fallido contiene error y exito en false', () {
      final resultado = Resultado<int>.fallido('error de conexion');

      expect(resultado.exito, isFalse);
      expect(resultado.datos, isNull);
      expect(resultado.error, equals('error de conexion'));
    });
  });
}
