import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bumand_movil/nucleo/constantes/api-constantes.dart';
import 'package:bumand_movil/modulos/autenticacion/repositorios/autenticacion-repositorio.dart';

class MockClienteHttp extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest peticion) manejador;

  MockClienteHttp(this.manejador);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final respuesta = await manejador(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(respuesta.body)),
      respuesta.statusCode,
      headers: respuesta.headers,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AutenticacionRepositorio Pruebas', () {
    test('Validacion de credenciales vacias en iniciarSesion sin peticion HTTP', () async {
      final repositorio = AutenticacionRepositorio();

      final resultado_correo_vacio = await repositorio.iniciarSesion('', 'secreto123');
      expect(resultado_correo_vacio.exito, isFalse);
      expect(resultado_correo_vacio.error, contains('correo electrónico es requerido'));

      final resultado_clave_vacia = await repositorio.iniciarSesion('becario@bumand.bo', '');
      expect(resultado_clave_vacia.exito, isFalse);
      expect(resultado_clave_vacia.error, contains('contraseña es requerida'));
    });

    test('Inicio de sesion exitoso con ApiConstantes y persistencia de token y rol', () async {
      String? url_solicitada;
      String? cuerpo_solicitado;

      final cliente_simulado = MockClienteHttp((peticion) async {
        url_solicitada = peticion.url.toString();
        if (peticion is http.Request) {
          cuerpo_solicitado = peticion.body;
        }

        final cuerpo_respuesta = jsonEncode({
          'mensaje': 'Inicio de sesión exitoso',
          'token': 'jwt.token.de.prueba',
          'usuario': {
            'id': 101,
            'nombre': 'Valeria Ramos',
            'correo': 'valeria.ramos@bumand.bo',
            'rol': 'becario',
          },
        });

        return http.Response(cuerpo_respuesta, 200, headers: {'content-type': 'application/json'});
      });

      final repositorio = AutenticacionRepositorio(cliente_http: cliente_simulado);

      final resultado = await repositorio.iniciarSesion('valeria.ramos@bumand.bo', 'clave123');

      expect(resultado.exito, isTrue);
      expect(resultado.datos, isNotNull);
      expect(resultado.datos!.id, equals(101));
      expect(resultado.datos!.nombre, equals('Valeria Ramos'));
      expect(resultado.datos!.correo, equals('valeria.ramos@bumand.bo'));
      expect(resultado.datos!.rol, equals('becario'));
      expect(resultado.datos!.token, equals('jwt.token.de.prueba'));

      // Verificacion de endpoint con ApiConstantes
      final url_esperada = '${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_INICIO_SESION}';
      expect(url_solicitada, equals(url_esperada));
      expect(cuerpo_solicitado, contains('valeria.ramos@bumand.bo'));

      // Verificacion de persistencia en SharedPreferences
      final preferencias = await SharedPreferences.getInstance();
      expect(preferencias.getString('token'), equals('jwt.token.de.prueba'));
      expect(preferencias.getString('usuario_rol'), equals('becario'));
      expect(preferencias.getInt('usuario_id'), equals(101));
      expect(preferencias.getString('usuario_nombre'), equals('Valeria Ramos'));
      expect(preferencias.getString('usuario_correo'), equals('valeria.ramos@bumand.bo'));

      // Verificacion de metodos auxiliares
      final token_obtenido = await repositorio.obtenerToken();
      final rol_obtenido = await repositorio.obtenerRol();
      final sesion_actual = await repositorio.obtenerSesionActual();
      final esta_activo = await repositorio.estaAutenticado();

      expect(token_obtenido, equals('jwt.token.de.prueba'));
      expect(rol_obtenido, equals('becario'));
      expect(sesion_actual, isNotNull);
      expect(sesion_actual!.rol, equals('becario'));
      expect(esta_activo, isTrue);
    });

    test('Cierre de sesion elimina token y rol de SharedPreferences', () async {
      final preferencias = await SharedPreferences.getInstance();
      await preferencias.setString('token', 'token-a-borrar');
      await preferencias.setString('usuario_rol', 'becario');
      await preferencias.setInt('usuario_id', 99);
      await preferencias.setString('usuario_nombre', 'Usuario Borrable');
      await preferencias.setString('usuario_correo', 'borrable@bumand.bo');

      final repositorio = AutenticacionRepositorio();
      await repositorio.cerrarSesion();

      expect(preferencias.getString('token'), isNull);
      expect(preferencias.getString('usuario_rol'), isNull);
      expect(preferencias.getInt('usuario_id'), isNull);
      expect(preferencias.getString('usuario_nombre'), isNull);
      expect(preferencias.getString('usuario_correo'), isNull);

      final esta_activo = await repositorio.estaAutenticado();
      expect(esta_activo, isFalse);
    });

    test('Inicio de sesion con credenciales invalidas (401) maneja error con Resultado.fallido', () async {
      final cliente_simulado = MockClienteHttp((peticion) async {
        return http.Response(
          jsonEncode({'mensaje': 'Credenciales inválidas'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final repositorio = AutenticacionRepositorio(cliente_http: cliente_simulado);
      final resultado = await repositorio.iniciarSesion('erroneo@bumand.bo', 'mala123');

      expect(resultado.exito, isFalse);
      expect(resultado.datos, isNull);
      expect(resultado.error, contains('Credenciales inválidas'));
    });

    test('Excepcion de conexion de red se captura limpiamente en Resultado.fallido', () async {
      final cliente_simulado = MockClienteHttp((peticion) async {
        throw Exception('Fallo de resolucion de host');
      });

      final repositorio = AutenticacionRepositorio(cliente_http: cliente_simulado);
      final resultado = await repositorio.iniciarSesion('becario@bumand.bo', '123456');

      expect(resultado.exito, isFalse);
      expect(resultado.datos, isNull);
      expect(resultado.error, contains('No se pudo conectar con el servidor'));
    });

    test('Registro exitoso utiliza ApiConstantes.PUNTO_REGISTRO y persiste sesion', () async {
      String? url_solicitada;

      final cliente_simulado = MockClienteHttp((peticion) async {
        url_solicitada = peticion.url.toString();
        final cuerpo = jsonEncode({
          'mensaje': 'Cuenta creada',
          'token': 'token-nuevo-registro',
          'usuario': {
            'id': 202,
            'nombre': 'Nuevo Becario',
            'correo': 'nuevo@bumand.bo',
            'rol': 'becario',
          },
        });
        return http.Response(cuerpo, 201, headers: {'content-type': 'application/json'});
      });

      final repositorio = AutenticacionRepositorio(cliente_http: cliente_simulado);
      final resultado = await repositorio.registrar('9107373', 'nuevo@bumand.bo', 'claveSegura123');

      expect(resultado.exito, isTrue);
      expect(resultado.datos!.id, equals(202));
      expect(url_solicitada, equals('${ApiConstantes.RUTA_BASE}${ApiConstantes.PUNTO_REGISTRO}'));

      final token_guardado = await repositorio.obtenerToken();
      final rol_guardado = await repositorio.obtenerRol();
      expect(token_guardado, equals('token-nuevo-registro'));
      expect(rol_guardado, equals('becario'));
    });
  });
}
