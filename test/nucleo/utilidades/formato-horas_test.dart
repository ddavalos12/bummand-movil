import 'package:flutter_test/flutter_test.dart';
import 'package:bumand_movil/modulos/asistencia/repositorios/asistencia-repositorio.dart';
import 'package:bumand_movil/modulos/pasajes/modelos/recorrido-modelo.dart';
import 'package:bumand_movil/modulos/pasajes/utilidades/formato-pasajes.dart';
import 'package:bumand_movil/nucleo/utilidades/formato-horas.dart';

void main() {
  group('FormatoHoras y ExtractoMensualAsistencia', () {
    test('calcula duración exacta en hh:mm:ss sin perder segundos', () {
      expect(
        calcularSegundosEntreHoras('08:00:43', '13:50:04'),
        equals(20961),
      );
      expect(
        formatearDuracionAsistencia(
          hora_ingreso: '08:00:43',
          hora_salida: '13:50:04',
        ),
        equals('05:49:21'),
      );
      expect(formatearHorasDecimalAHhmmss(36.0), equals('36:00:00'));
    });

    test('respeta jornada en curso y distancia_metros real en MovimientoExtractoAsistencia', () {
      final mov_cerrado = MovimientoExtractoAsistencia.desdeMapa({
        'id': 1,
        'fecha': '2026-11-25',
        'tipo': 'practicas',
        'hora_entrada': '08:00:43',
        'hora_salida': '13:50:04',
        'distancia_metros': 35,
      });

      expect(mov_cerrado.hora_entrada, equals('08:00:43'));
      expect(mov_cerrado.hora_salida, equals('13:50:04'));
      expect(mov_cerrado.horas_dia_hms, equals('05:49:21'));
      expect(mov_cerrado.distancia_gps, equals(35.0));

      final mov_abierto = MovimientoExtractoAsistencia.desdeMapa({
        'id': 2,
        'fecha': '2026-11-25',
        'tipo': 'practicas',
        'hora_entrada': '08:00:43',
        'hora_salida': null,
        'distancia_metros': 35,
      });

      expect(mov_abierto.hora_salida, equals('En curso'));
      expect(mov_abierto.horas_dia_hms, equals('En curso'));
      expect(mov_abierto.segundos_dia, equals(0));
    });

    test('aplica corte bancario desde el día 24 en FormatoPasajes.periodoDe', () {
      expect(
        FormatoPasajes.periodoDe(DateTime(2026, 11, 23)),
        equals('2026-11'),
      );
      expect(
        FormatoPasajes.periodoDe(DateTime(2026, 11, 24)),
        equals('2026-12'),
      );
      expect(
        FormatoPasajes.periodoDe(DateTime(2026, 12, 24)),
        equals('2027-01'),
      );
    });

    test('RecorridoModelo soporta apoyo_realizado nulo y tipo_actividad', () {
      final recorrido = RecorridoModelo.desdeJson({
        'id': 10,
        'fecha': '2026-11-25T00:00:00.000Z',
        'tramo': 'ida',
        'origen': 'Ceja',
        'destino': 'Oficina Central',
        'tarifa': 2.5,
        'tipo_actividad': 'acciones_servicio',
        'apoyo_realizado': null,
      });

      expect(recorrido.tipo_actividad, equals('acciones_servicio'));
      expect(recorrido.apoyo_realizado, isNull);
    });
  });
}
