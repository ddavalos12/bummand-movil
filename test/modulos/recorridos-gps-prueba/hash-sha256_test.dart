import 'package:flutter_test/flutter_test.dart';
import 'package:bumand_movil/modulos/recorridos-gps-prueba/modelos/recorrido-gps-prueba-modelo.dart';
import 'package:bumand_movil/modulos/recorridos-gps-prueba/utilidades/hash-sha256.dart';

void main() {
  group('SHA-256 puro en Dart', () {
    test('calcula hash correcto para cadena vacía', () {
      expect(
        calcularSha256Hex(''),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('calcula hash correcto para vector estándar "abc"', () {
      expect(
        calcularSha256Hex('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('calcula hash correcto para límite exacto de 56 bytes (2 bloques)', () {
      expect(
        calcularSha256Hex(
          'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq',
        ),
        '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
      );
    });

    test('calcula hash de punto y sesión de recorrido GPS prueba', () {
      final hash_punto_1 = calcularHashPunto(
        uuid_sesion: '11111111-1111-4111-8111-111111111111',
        secuencia: 1,
        latitud: -16.500000,
        longitud: -68.150000,
        precision_m: 4.5,
        hora_gps_iso: '2026-11-25T20:00:00.000Z',
        hora_dispositivo_iso: '2026-11-25T20:00:01.000Z',
        reloj_monotonico_ms: 0,
        es_ubicacion_simulada: false,
        hash_anterior: null,
      );
      expect(hash_punto_1.length, 64);
      expect(
        hash_punto_1,
        calcularSha256Hex(
          '11111111-1111-4111-8111-111111111111|1|-16.500000|-68.150000|4.5|2026-11-25T20:00:00.000Z|2026-11-25T20:00:01.000Z|0|0|GENESIS',
        ),
      );

      final hash_sesion = calcularHashSesion(
        uuid_sesion: '11111111-1111-4111-8111-111111111111',
        total_puntos: 1,
        ultimo_hash_punto: hash_punto_1,
        duracion_monotonica_seg: 300,
      );
      expect(hash_sesion.length, 64);
      expect(
        hash_sesion,
        calcularSha256Hex(
          '11111111-1111-4111-8111-111111111111|1|$hash_punto_1|300',
        ),
      );
    });

    test('serializa y deserializa SesionRecorridoGpsPrueba correctamente', () {
      final punto = const PuntoGpsPruebaModelo(
        secuencia: 1,
        latitud: -16.5,
        longitud: -68.15,
        precision_m: 5.0,
        hora_dispositivo_iso: '2026-11-25T20:00:00.000Z',
        hora_gps_iso: '2026-11-25T20:00:00.000Z',
        desfase_reloj_seg: 0,
        reloj_monotonico_ms: 0,
        es_ubicacion_simulada: false,
        modo_captura: 'offline',
        hash_punto: 'abc',
      );
      final sesion = SesionRecorridoGpsPrueba(
        uuid_sesion: generarUuidV4(),
        estado: EstadoRecorridoGpsPrueba.en_curso,
        etiqueta_prueba: 'Prueba campo',
        zona_horaria_offset_min: -240,
        duracion_monotonica_seg: 0,
        puntos: [punto],
      );

      final restaurada = SesionRecorridoGpsPrueba.desdeMapa(sesion.aMapa());
      expect(restaurada.uuid_sesion, sesion.uuid_sesion);
      expect(restaurada.estado, EstadoRecorridoGpsPrueba.en_curso);
      expect(restaurada.etiqueta_prueba, 'Prueba campo');
      expect(restaurada.puntos.length, 1);
      expect(restaurada.puntos.first.modo_captura, 'offline');
    });
  });
}
