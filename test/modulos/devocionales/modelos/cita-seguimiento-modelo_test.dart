import 'package:flutter_test/flutter_test.dart';
import 'package:bumand_movil/modulos/devocionales/modelos/cita-seguimiento-modelo.dart';

void main() {
  group('CitaSeguimientoModelo Pruebas Unitarias', () {
    test('Serialización y deserialización desdeJson / aJson', () {
      final mapa = {
        'id': 105,
        'supervisor_id': 1,
        'supervisor_nombre': 'Pastor Marcos Quispe',
        'becario_id': 10,
        'becario_nombre': 'María Catunta Laime',
        'fecha_cita': '2026-10-30',
        'hora_cita': '15:30',
        'modalidad': 'presencial',
        'lugar_o_enlace': 'Oficina Central Diaconía',
        'motivo_retroalimentacion': 'Revisión y acompañamiento',
        'cita_biblica': 'Josué 1:9',
        'acuerdos_retroalimentacion': 'Cumplir metas de servicio',
        'estado': 'programada',
        'created_at': '2026-10-25T10:00:00Z',
      };

      final modelo = CitaSeguimientoModelo.desdeJson(mapa);

      expect(modelo.id, 105);
      expect(modelo.supervisor_id, 1);
      expect(modelo.supervisor_nombre, 'Pastor Marcos Quispe');
      expect(modelo.becario_id, 10);
      expect(modelo.becario_nombre, 'María Catunta Laime');
      expect(modelo.fecha_cita, '2026-10-30');
      expect(modelo.hora_cita, '15:30');
      expect(modelo.modalidad, 'presencial');
      expect(modelo.es_presencial, isTrue);
      expect(modelo.es_virtual, isFalse);
      expect(modelo.esta_programada, isTrue);
      expect(modelo.esta_realizada, isFalse);

      final json = modelo.aJson();
      expect(json['id'], 105);
      expect(json['modalidad'], 'presencial');
      expect(json['acuerdos_retroalimentacion'], 'Cumplir metas de servicio');
    });

    test('Getters de modalidad y estado funcionan correctamente', () {
      const cita_virtual = CitaSeguimientoModelo(
        id: 106,
        supervisor_id: 1,
        supervisor_nombre: 'Supervisor',
        becario_id: 11,
        becario_nombre: 'Carlos Mamani',
        fecha_cita: '2026-10-31',
        hora_cita: '10:00',
        modalidad: 'virtual',
        lugar_o_enlace: 'https://meet.google.com/test',
        motivo_retroalimentacion: 'Seguimiento',
        estado: 'realizada',
      );

      expect(cita_virtual.es_virtual, isTrue);
      expect(cita_virtual.es_presencial, isFalse);
      expect(cita_virtual.esta_realizada, isTrue);
      expect(cita_virtual.esta_programada, isFalse);

      final cita_reprogramada = cita_virtual.copiarCon(estado: 'reprogramada');
      expect(cita_reprogramada.esta_reprogramada, isTrue);

      final cita_cancelada = cita_virtual.copiarCon(estado: 'cancelada');
      expect(cita_cancelada.esta_cancelada, isTrue);
    });

    test('Semillas de becario y supervisor contienen datos iniciales válidos', () {
      final semillas_becario = CitaSeguimientoModelo.semillasBecario();
      final semillas_supervisor = CitaSeguimientoModelo.semillasSupervisor();

      expect(semillas_becario.isNotEmpty, isTrue);
      expect(semillas_supervisor.isNotEmpty, isTrue);

      expect(semillas_becario.any((c) => c.es_presencial), isTrue);
      expect(semillas_becario.any((c) => c.es_virtual), isTrue);

      expect(semillas_supervisor.length, greaterThanOrEqualTo(3));
      expect(semillas_supervisor.any((c) => c.esta_programada), isTrue);
      expect(semillas_supervisor.any((c) => c.esta_realizada), isTrue);
    });
  });
}
