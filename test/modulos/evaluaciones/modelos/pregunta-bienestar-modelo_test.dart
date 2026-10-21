import 'package:flutter_test/flutter_test.dart';
import 'package:bumand_movil/modulos/evaluaciones/modelos/pregunta-bienestar-modelo.dart';

void main() {
  group('PreguntaBienestarModelo Pruebas Unitarias', () {
    test('catalogoCanonico contiene exactamente 26 preguntas oficiales', () {
      final catalogo = PreguntaBienestarModelo.catalogoCanonico();
      expect(catalogo.length, equals(26));

      // Verificar orden consecutivo del 1 al 26
      for (int i = 0; i < 26; i++) {
        expect(catalogo[i].numero_orden, equals(i + 1));
        expect(catalogo[i].titulo.isNotEmpty, isTrue);
        expect(catalogo[i].enunciado.isNotEmpty, isTrue);
        expect(catalogo[i].opciones.isNotEmpty, isTrue);
      }
    });

    test('Preguntas 1 a 18 y 20 contienen 3 opciones (A, B, C)', () {
      final catalogo = PreguntaBienestarModelo.catalogoCanonico();
      for (int i = 1; i <= 18; i++) {
        final preg = catalogo.firstWhere((p) => p.numero_orden == i);
        expect(preg.opciones.length, equals(3), reason: 'Pregunta $i debe tener 3 opciones');
        expect(preg.opciones.map((o) => o.inciso).toList(), equals(['A', 'B', 'C']));
      }

      final preg_20 = catalogo.firstWhere((p) => p.numero_orden == 20);
      expect(preg_20.opciones.length, equals(3));
      expect(preg_20.opciones.map((o) => o.inciso).toList(), equals(['A', 'B', 'C']));
    });

    test('Pregunta 19 (violencia) y 21-26 contienen 4 opciones (A, B, C, D)', () {
      final catalogo = PreguntaBienestarModelo.catalogoCanonico();
      final indices_4_opciones = [19, 21, 22, 23, 24, 25, 26];

      for (final num in indices_4_opciones) {
        final preg = catalogo.firstWhere((p) => p.numero_orden == num);
        expect(preg.opciones.length, equals(4), reason: 'Pregunta $num debe tener 4 opciones');
        expect(preg.opciones.map((o) => o.inciso).toList(), equals(['A', 'B', 'C', 'D']));
      }
    });

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
