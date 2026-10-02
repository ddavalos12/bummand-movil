import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bumand_movil/modulos/asistencia/repositorios/asistencia-repositorio.dart';

void main() {
  group('AsistenciaRepositorio Pruebas de Geocerca', () {
    final repo = AsistenciaRepositorio();

    Position crearPosicion({
      required double latitud,
      required double longitud,
      double precision = 5.0,
      bool simulada = false,
    }) {
      return Position(
        latitude: latitud,
        longitude: longitud,
        timestamp: DateTime.now(),
        accuracy: precision,
        altitude: 3600.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        isMocked: simulada,
      );
    }

    test('validarGeocerca retorna true cuando esta dentro del radio de tolerancia', () {
      // Coordenadas idénticas
      final pos = crearPosicion(latitud: -16.5000, longitud: -68.1500);
      final resultado = repo.validarGeocerca(
        posicion: pos,
        latitud_destino: -16.5000,
        longitud_destino: -68.1500,
        radio_tolerancia_m: 100,
      );

      expect(resultado, isTrue);
    });

    test('validarGeocerca retorna false cuando la ubicacion esta fuera de rango', () {
      // Ubicación muy lejana (e.g. 50 km de diferencia)
      final pos = crearPosicion(latitud: -16.2000, longitud: -68.1500);
      final resultado = repo.validarGeocerca(
        posicion: pos,
        latitud_destino: -16.5000,
        longitud_destino: -68.1500,
        radio_tolerancia_m: 100,
      );

      expect(resultado, isFalse);
    });

    test('validarGeocerca rechaza ubicaciones simuladas', () {
      final pos_simulada = crearPosicion(
        latitud: -16.5000,
        longitud: -68.1500,
        simulada: true,
      );
      final resultado = repo.validarGeocerca(
        posicion: pos_simulada,
        latitud_destino: -16.5000,
        longitud_destino: -68.1500,
        radio_tolerancia_m: 100,
      );

      expect(resultado, isFalse);
    });

    test('calcularDistancia retorna distancia mayor a cero para puntos distintos', () {
      final pos = crearPosicion(latitud: -16.5000, longitud: -68.1500);
      final distancia = repo.calcularDistancia(
        posicion: pos,
        latitud_destino: -16.5050,
        longitud_destino: -68.1550,
      );

      expect(distancia, greaterThan(0));
    });
  });
}
