import 'package:flutter_test/flutter_test.dart';
import 'package:bumand_movil/modulos/eventos/modelos/evento.dart';

void main() {
  group('Evento y AsistenciaEvento Pruebas Unitarias', () {
    test('Serialización e instanciación de Evento desde mapa', () {
      final mapa = {
        'id': 1,
        'creador_id': 2,
        'titulo': 'Taller de Liderazgo Diaconal',
        'descripcion': 'Jornada formativa para becarios en El Alto',
        'tipo_evento': 'taller',
        'fecha': '2026-10-25',
        'hora_inicio': '08:30',
        'hora_fin': '13:00',
        'latitud': -16.500054,
        'longitud': -68.173455,
        'radio_tolerancia_m': 120,
        'direccion_referencia': 'Av. Juan Pablo II, El Alto',
        'estado': 'programado',
      };

      final evento = Evento.desdeMapa(mapa);

      expect(evento.id, 1);
      expect(evento.titulo, 'Taller de Liderazgo Diaconal');
      expect(evento.latitud, -16.500054);
      expect(evento.longitud, -68.173455);
      expect(evento.radio_tolerancia_m, 120.0);
      expect(evento.estado, 'programado');

      final mapa_generado = evento.aMapa();
      expect(mapa_generado['id'], 1);
      expect(mapa_generado['tipo_evento'], 'taller');
    });

    test('Cálculo de distancia geodésica Haversine en metros', () {
      // Coordenadas epicentro (Oficina Central Diaconía El Alto)
      const lat_evento = -16.500054;
      const lng_evento = -68.173455;

      const evento = Evento(
        id: 1,
        titulo: 'Reunión Central',
        descripcion: 'Reunión de coordinación',
        tipo_evento: 'reunion',
        fecha: '2026-10-25',
        hora_inicio: '09:00',
        hora_fin: '11:00',
        latitud: lat_evento,
        longitud: lng_evento,
        radio_tolerancia_m: 80.0,
        direccion_referencia: 'El Alto',
        estado: 'programado',
      );

      // Mismas coordenadas: distancia debe ser cercana a 0
      final dist_cero = evento.calcularDistanciaMetros(lat_evento, lng_evento);
      expect(dist_cero, lessThan(1.0));
      expect(evento.estaDentroDeRadio(lat_evento, lng_evento), isTrue);

      // Punto a ~35 metros (ligeramente desplazado)
      const lat_cerca = -16.500300;
      const lng_cerca = -68.173455;
      final dist_cerca = evento.calcularDistanciaMetros(lat_cerca, lng_cerca);
      expect(dist_cerca, greaterThan(10.0));
      expect(dist_cerca, lessThan(50.0));
      expect(evento.estaDentroDeRadio(lat_cerca, lng_cerca), isTrue);

      // Punto en San Pedro, La Paz (~4 km de distancia)
      const lat_lejos = -16.501500;
      const lng_lejos = -68.138200;
      final dist_lejos = evento.calcularDistanciaMetros(lat_lejos, lng_lejos);
      expect(dist_lejos, greaterThan(3000.0));
      expect(evento.estaDentroDeRadio(lat_lejos, lng_lejos), isFalse);
    });

    test('Evaluación de horario de convocatoria', () {
      const evento = Evento(
        id: 2,
        titulo: 'Retiro Espiritual',
        descripcion: 'Retiro anual',
        tipo_evento: 'retiro',
        fecha: '2026-10-25',
        hora_inicio: '09:00',
        hora_fin: '12:00',
        latitud: -16.5,
        longitud: -68.15,
        radio_tolerancia_m: 100,
        direccion_referencia: 'Achocalla',
        estado: 'programado',
      );

      // 09:30 en el mismo día debe estar en horario
      final en_horario = DateTime(2026, 10, 25, 9, 30);
      expect(evento.estaEnHorario(en_horario), isTrue);

      // 08:30 (30 minutos antes, con tolerancia de 45 min) debe estar en horario
      final antes_tolerancia = DateTime(2026, 10, 25, 8, 30);
      expect(evento.estaEnHorario(antes_tolerancia), isTrue);

      // 07:00 (muy temprano) debe estar fuera de horario
      final muy_temprano = DateTime(2026, 10, 25, 7, 0);
      expect(evento.estaEnHorario(muy_temprano), isFalse);

      // 14:00 (después de la conclusión + 30 min tolerancia) debe estar fuera
      final muy_tarde = DateTime(2026, 10, 25, 14, 0);
      expect(evento.estaEnHorario(muy_tarde), isFalse);
    });

    test('Serialización de AsistenciaEvento', () {
      final mapa = {
        'id': 10,
        'evento_id': 1,
        'becario_id': 5,
        'hora_marcacion': '08:45:10',
        'latitud': -16.500054,
        'longitud': -68.173455,
        'distancia_m': 15.2,
        'dentro_de_radio': true,
        'estado': 'presente',
        'observaciones': 'Marcación presencial puntual',
      };

      final asistencia = AsistenciaEvento.desdeMapa(mapa);
      expect(asistencia.id, 10);
      expect(asistencia.dentro_de_radio, isTrue);
      expect(asistencia.distancia_m, 15.2);
      expect(asistencia.estado, 'presente');

      final mapa_respaldo = asistencia.aMapa();
      expect(mapa_respaldo['hora_marcacion'], '08:45:10');
      expect(mapa_respaldo['dentro_de_radio'], isTrue);
    });
  });
}
