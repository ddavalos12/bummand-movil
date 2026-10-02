import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:bumand_movil/modulos/autenticacion/modelos/usuario-modelo.dart';

void main() {
  group('UsuarioModelo Pruebas', () {
    test('Creacion de instancia y acceso a atributos en snake_case', () {
      const usuario = UsuarioModelo(
        id: 10,
        nombre: 'Carlos Perez',
        correo: 'carlos.perez@bumand.bo',
        rol: 'becario',
        token: 'token-jwt-prueba-123',
      );

      expect(usuario.id, equals(10));
      expect(usuario.nombre, equals('Carlos Perez'));
      expect(usuario.correo, equals('carlos.perez@bumand.bo'));
      expect(usuario.rol, equals('becario'));
      expect(usuario.token, equals('token-jwt-prueba-123'));
    });

    test('desdeJson con formato anidado de usuario y token', () {
      final mapa_json = {
        'token': 'jwt.token.valido',
        'usuario': {
          'id': 42,
          'nombre': 'Ana Gomez',
          'correo': 'ana.gomez@bumand.bo',
          'rol': 'supervisor',
        },
      };

      final usuario = UsuarioModelo.desdeJson(mapa_json);

      expect(usuario.id, equals(42));
      expect(usuario.nombre, equals('Ana Gomez'));
      expect(usuario.correo, equals('ana.gomez@bumand.bo'));
      expect(usuario.rol, equals('supervisor'));
      expect(usuario.token, equals('jwt.token.valido'));
    });

    test('desdeJson extrayendo informacion desde la carga util JWT', () {
      final encabezado = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
      final carga_util = base64Url.encode(
        utf8.encode('{"sub":7,"correo":"becario7@bumand.bo","rol":"becario"}'),
      );
      final firma = 'firma-falsa';
      final token_jwt = '$encabezado.$carga_util.$firma';

      final mapa_json = {
        'token': token_jwt,
      };

      final usuario = UsuarioModelo.desdeJson(mapa_json);

      expect(usuario.id, equals(7));
      expect(usuario.correo, equals('becario7@bumand.bo'));
      expect(usuario.rol, equals('becario'));
      expect(usuario.token, equals(token_jwt));
      expect(usuario.nombre, equals('becario7'));
    });

    test('aJson serializa correctamente todos los atributos', () {
      const usuario = UsuarioModelo(
        id: 15,
        nombre: 'Maria Lopez',
        correo: 'maria.lopez@bumand.bo',
        rol: 'becario',
        token: 'tok-abc-123',
      );

      final serializado = usuario.aJson();

      expect(serializado['id'], equals(15));
      expect(serializado['nombre'], equals('Maria Lopez'));
      expect(serializado['correo'], equals('maria.lopez@bumand.bo'));
      expect(serializado['rol'], equals('becario'));
      expect(serializado['token'], equals('tok-abc-123'));
    });

    test('copiarCon actualiza campos seleccionados', () {
      const original = UsuarioModelo(
        id: 1,
        nombre: 'Original',
        correo: 'orig@bumand.bo',
        rol: 'becario',
        token: 'tok-orig',
      );

      final modificado = original.copiarCon(
        nombre: 'Modificado',
        rol: 'administrador',
      );

      expect(modificado.id, equals(1));
      expect(modificado.nombre, equals('Modificado'));
      expect(modificado.correo, equals('orig@bumand.bo'));
      expect(modificado.rol, equals('administrador'));
      expect(modificado.token, equals('tok-orig'));
    });
  });
}
