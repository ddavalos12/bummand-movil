import 'package:flutter_test/flutter_test.dart';
import 'package:bumand_movil/modulos/notificaciones/modelos/notificacion-modelo.dart';

void main() {
  group('NotificacionModelo Pruebas Unitarias', () {
    test('Creacion de instancia y propiedades', () {
      final fecha = DateTime(2026, 10, 2, 10, 30);
      final notificacion = NotificacionModelo(
        id: 1,
        usuario_id: 42,
        tipo: 'recordatorio_salida',
        mensaje: 'Recuerda registrar tu salida antes de las 18:00',
        leido: false,
        fecha_envio: fecha,
      );

      expect(notificacion.id, 1);
      expect(notificacion.usuario_id, 42);
      expect(notificacion.tipo, 'recordatorio_salida');
      expect(notificacion.mensaje, contains('Recuerda registrar tu salida'));
      expect(notificacion.leido, isFalse);
      expect(notificacion.fecha_envio, fecha);
      expect(notificacion.esRecordatorioSalida, isTrue);
      expect(notificacion.esPasajeObservado, isFalse);
      expect(notificacion.esEvaluacion, isFalse);
      expect(notificacion.etiquetaTipo, 'Recordatorio de salida');
    });

    test('desdeJson procesa atributos correctamente', () {
      final mapa = {
        'id': 10,
        'usuario_id': 5,
        'tipo': 'pasajes_observados',
        'mensaje': 'Tu recibo de pasaje tiene una observación',
        'leido': true,
        'fecha_envio': '2026-10-02T14:00:00.000Z',
      };

      final notificacion = NotificacionModelo.desdeJson(mapa);

      expect(notificacion.id, 10);
      expect(notificacion.usuario_id, 5);
      expect(notificacion.tipo, 'pasajes_observados');
      expect(notificacion.leido, isTrue);
      expect(notificacion.esPasajeObservado, isTrue);
      expect(notificacion.etiquetaTipo, 'Pasaje observado');
    });

    test('Evaluacion se identifica correctamente', () {
      final mapa = {
        'id': 15,
        'usuarioId': 7,
        'tipo': 'evaluacion_desempeno',
        'mensaje': 'Tienes una evaluación trimestral pendiente',
        'leido': false,
        'fechaEnvio': '2026-10-02T09:00:00.000Z',
      };

      final notificacion = NotificacionModelo.desdeJson(mapa);

      expect(notificacion.id, 15);
      expect(notificacion.usuario_id, 7);
      expect(notificacion.esEvaluacion, isTrue);
      expect(notificacion.etiquetaTipo, 'Evaluación');
    });

    test('copiarCon actualiza campos específicos manteniendo inmutabilidad', () {
      final original = NotificacionModelo(
        id: 1,
        usuario_id: 3,
        tipo: 'general',
        mensaje: 'Aviso general',
        leido: false,
        fecha_envio: DateTime(2026, 1, 1),
      );

      final copia = original.copiarCon(leido: true);

      expect(copia.id, original.id);
      expect(copia.mensaje, original.mensaje);
      expect(copia.leido, isTrue);
      expect(original.leido, isFalse);
    });

    test('aJson serializa atributos adecuadamente', () {
      final fecha = DateTime.parse('2026-10-02T12:00:00.000Z');
      final notificacion = NotificacionModelo(
        id: 2,
        usuario_id: 9,
        tipo: 'aviso',
        mensaje: 'Prueba',
        leido: false,
        fecha_envio: fecha,
      );

      final json = notificacion.aJson();

      expect(json['id'], 2);
      expect(json['usuario_id'], 9);
      expect(json['tipo'], 'aviso');
      expect(json['mensaje'], 'Prueba');
      expect(json['leido'], isFalse);
      expect(json['fecha_envio'], fecha.toIso8601String());
    });
  });
}
