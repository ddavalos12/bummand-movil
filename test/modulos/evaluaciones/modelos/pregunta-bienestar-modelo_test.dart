import 'package:flutter_test/flutter_test.dart';
import 'package:bumand_movil/modulos/evaluaciones/modelos/pregunta-bienestar-modelo.dart';

void main() {
  group('PreguntaBienestarModelo Pruebas Unitarias', () {
    test('desdeJson y aJson serializan correctamente', () {
      final json = {
        'numero_orden': 1,
        'titulo': 'Ingresos del hogar',
        'enunciado': '¿Los ingresos cubren necesidades?',
        'categoria': 'Economía Familiar',
        'opciones': [
          {'inciso': 'A', 'texto': 'Alcanzan y permiten ahorrar'},
          {'inciso': 'B', 'texto': 'Alcanzan con dificultad'},
        ],
      };

      final modelo = PreguntaBienestarModelo.desdeJson(json);
      expect(modelo.numero_orden, equals(1));
      expect(modelo.titulo, equals('Ingresos del hogar'));
      expect(modelo.categoria, equals('Economía Familiar'));
      expect(modelo.opciones.length, equals(2));
      expect(modelo.opciones[0].inciso, equals('A'));

      final json_generado = modelo.aJson();
      expect(json_generado['numero_orden'], equals(1));
      expect((json_generado['opciones'] as List).length, equals(2));
    });
  });
}
