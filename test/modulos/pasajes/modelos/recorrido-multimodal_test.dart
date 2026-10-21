import 'package:flutter_test/flutter_test.dart';
import 'package:bumand_movil/modulos/pasajes/modelos/recorrido-modelo.dart';

void main() {
  group('RecorridoModelo Multimodal Pruebas Unitarias', () {
    test('Serializa y deserializa calles_declaradas, medio_transporte y detalle_tramos_json', () {
      final json = {
        'id': 101,
        'fecha': '2026-10-18T10:00:00.000',
        'tramo': 'ida',
        'origen': 'Villa Adela, El Alto',
        'destino': 'Oficina Central Diaconía',
        'tarifa': 5.5,
        'apoyo_realizado': '[practicas] Apoyo en caja | Calles: Villa Adela → Ceja → Prado | Transporte: Minibús + Mi Teleférico',
        'calles_declaradas': 'Villa Adela → Ceja → Prado',
        'medio_transporte': 'Minibús + Mi Teleférico',
        'detalle_tramos_json': '{"sentido":"ida","calles_paradas":["Villa Adela","Ceja","Prado"]}',
        'lat_origen': -16.505,
        'lng_origen': -68.163,
        'lat_destino': -16.501,
        'lng_destino': -68.158,
      };

      final modelo = RecorridoModelo.desdeJson(json);

      expect(modelo.id, equals(101));
      expect(modelo.calles_declaradas, equals('Villa Adela → Ceja → Prado'));
      expect(modelo.callesDeclaradas, equals('Villa Adela → Ceja → Prado'));
      expect(modelo.medio_transporte, equals('Minibús + Mi Teleférico'));
      expect(modelo.medioTransporte, equals('Minibús + Mi Teleférico'));
      expect(modelo.detalle_tramos_json, isNotNull);
      expect(modelo.detalleTramosJson, isNotNull);

      final generado = modelo.aJson();
      expect(generado['calles_declaradas'], equals('Villa Adela → Ceja → Prado'));
      expect(generado['medio_transporte'], equals('Minibús + Mi Teleférico'));
      expect(generado['detalle_tramos_json'], equals(modelo.detalle_tramos_json));
    });

    test('Soporta deserialización con campos camelCase de backend', () {
      final json_camel = {
        'id': 102,
        'fecha': '2026-10-18T14:00:00.000',
        'tramo': 'vuelta',
        'origen': 'Oficina Central Diaconía',
        'destino': 'Villa Adela, El Alto',
        'tarifa': 5.0,
        'callesDeclaradas': 'Prado → Ceja → Villa Adela',
        'medioTransporte': 'Teleférico Línea Plateada + Minibús',
        'detalleTramosJson': '{"sentido":"vuelta"}',
      };

      final modelo = RecorridoModelo.desdeJson(json_camel);
      expect(modelo.calles_declaradas, equals('Prado → Ceja → Villa Adela'));
      expect(modelo.medio_transporte, equals('Teleférico Línea Plateada + Minibús'));
      expect(modelo.detalle_tramos_json, equals('{"sentido":"vuelta"}'));
    });
  });
}
