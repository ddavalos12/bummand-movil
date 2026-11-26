import 'dart:convert';
import 'dart:typed_data';

const List<int> _CONSTANTES_SHA256 = [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];

const List<int> _VALORES_INICIALES_SHA256 = [
  0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
  0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
];

int _rotarDerecha32(int valor, int bits) {
  final normalizado = valor & 0xFFFFFFFF;
  return ((normalizado >> bits) | ((normalizado << (32 - bits)) & 0xFFFFFFFF)) &
      0xFFFFFFFF;
}

/// Implementación pura de SHA-256 (FIPS 180-4) sobre UTF-8 sin dependencias externas.
String calcularSha256Hex(String entrada) {
  final bytes_entrada = utf8.encode(entrada);
  final longitud_bytes = bytes_entrada.length;
  final longitud_bits = longitud_bytes * 8;

  // Padding: byte 0x80 + ceros hasta residuo 56 (mod 64) + longitud en 64 bits big-endian.
  final bytes_con_marcador = longitud_bytes + 1;
  final resto_bloque = bytes_con_marcador % 64;
  final ceros_padding = resto_bloque <= 56
      ? (56 - resto_bloque)
      : (64 - resto_bloque + 56);
  final longitud_total = bytes_con_marcador + ceros_padding + 8;

  final bloque_relleno = Uint8List(longitud_total);
  bloque_relleno.setRange(0, longitud_bytes, bytes_entrada);
  bloque_relleno[longitud_bytes] = 0x80;

  final bits_parte_alta = longitud_bits ~/ 0x100000000;
  final bits_parte_baja = longitud_bits & 0xFFFFFFFF;
  final indice_longitud = longitud_total - 8;

  bloque_relleno[indice_longitud] = (bits_parte_alta >> 24) & 0xFF;
  bloque_relleno[indice_longitud + 1] = (bits_parte_alta >> 16) & 0xFF;
  bloque_relleno[indice_longitud + 2] = (bits_parte_alta >> 8) & 0xFF;
  bloque_relleno[indice_longitud + 3] = bits_parte_alta & 0xFF;
  bloque_relleno[indice_longitud + 4] = (bits_parte_baja >> 24) & 0xFF;
  bloque_relleno[indice_longitud + 5] = (bits_parte_baja >> 16) & 0xFF;
  bloque_relleno[indice_longitud + 6] = (bits_parte_baja >> 8) & 0xFF;
  bloque_relleno[indice_longitud + 7] = bits_parte_baja & 0xFF;

  final hash_estado = Uint32List.fromList(_VALORES_INICIALES_SHA256);
  final palabras = Uint32List(64);

  for (int offset = 0; offset < longitud_total; offset += 64) {
    for (int i = 0; i < 16; i++) {
      final idx = offset + (i * 4);
      palabras[i] = ((bloque_relleno[idx] << 24) |
              (bloque_relleno[idx + 1] << 16) |
              (bloque_relleno[idx + 2] << 8) |
              bloque_relleno[idx + 3]) &
          0xFFFFFFFF;
    }

    for (int i = 16; i < 64; i++) {
      final w15 = palabras[i - 15];
      final w2 = palabras[i - 2];
      final s0 = _rotarDerecha32(w15, 7) ^ _rotarDerecha32(w15, 18) ^ (w15 >> 3);
      final s1 = _rotarDerecha32(w2, 17) ^ _rotarDerecha32(w2, 19) ^ (w2 >> 10);
      palabras[i] = (palabras[i - 16] + s0 + palabras[i - 7] + s1) & 0xFFFFFFFF;
    }

    int a = hash_estado[0];
    int b = hash_estado[1];
    int c = hash_estado[2];
    int d = hash_estado[3];
    int e = hash_estado[4];
    int f = hash_estado[5];
    int g = hash_estado[6];
    int h = hash_estado[7];

    for (int i = 0; i < 64; i++) {
      final s1 = _rotarDerecha32(e, 6) ^ _rotarDerecha32(e, 11) ^ _rotarDerecha32(e, 25);
      final ch = (e & f) ^ ((~e & 0xFFFFFFFF) & g);
      final temp1 = (h + s1 + ch + _CONSTANTES_SHA256[i] + palabras[i]) & 0xFFFFFFFF;
      final s0 = _rotarDerecha32(a, 2) ^ _rotarDerecha32(a, 13) ^ _rotarDerecha32(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final temp2 = (s0 + maj) & 0xFFFFFFFF;

      h = g;
      g = f;
      f = e;
      e = (d + temp1) & 0xFFFFFFFF;
      d = c;
      c = b;
      b = a;
      a = (temp1 + temp2) & 0xFFFFFFFF;
    }

    hash_estado[0] = (hash_estado[0] + a) & 0xFFFFFFFF;
    hash_estado[1] = (hash_estado[1] + b) & 0xFFFFFFFF;
    hash_estado[2] = (hash_estado[2] + c) & 0xFFFFFFFF;
    hash_estado[3] = (hash_estado[3] + d) & 0xFFFFFFFF;
    hash_estado[4] = (hash_estado[4] + e) & 0xFFFFFFFF;
    hash_estado[5] = (hash_estado[5] + f) & 0xFFFFFFFF;
    hash_estado[6] = (hash_estado[6] + g) & 0xFFFFFFFF;
    hash_estado[7] = (hash_estado[7] + h) & 0xFFFFFFFF;
  }

  final buffer = StringBuffer();
  for (final palabra in hash_estado) {
    buffer.write(palabra.toRadixString(16).padLeft(8, '0'));
  }
  return buffer.toString();
}

String calcularHashPunto({
  required String uuid_sesion,
  required int secuencia,
  required double latitud,
  required double longitud,
  required double precision_m,
  String? hora_gps_iso,
  required String hora_dispositivo_iso,
  required int reloj_monotonico_ms,
  required bool es_ubicacion_simulada,
  String? hash_anterior,
}) {
  final lat_6 = latitud.toStringAsFixed(6);
  final lng_6 = longitud.toStringAsFixed(6);
  final prec_1 = precision_m.toStringAsFixed(1);
  final hora_gps_norm = hora_gps_iso ?? hora_dispositivo_iso;
  final simulada_bit = es_ubicacion_simulada ? '1' : '0';
  final hash_prev = hash_anterior ?? 'GENESIS';

  final cadena =
      '$uuid_sesion|$secuencia|$lat_6|$lng_6|$prec_1|$hora_gps_norm|$hora_dispositivo_iso|$reloj_monotonico_ms|$simulada_bit|$hash_prev';
  return calcularSha256Hex(cadena);
}

String calcularHashSesion({
  required String uuid_sesion,
  required int total_puntos,
  required String ultimo_hash_punto,
  required int duracion_monotonica_seg,
}) {
  final cadena =
      '$uuid_sesion|$total_puntos|$ultimo_hash_punto|$duracion_monotonica_seg';
  return calcularSha256Hex(cadena);
}
