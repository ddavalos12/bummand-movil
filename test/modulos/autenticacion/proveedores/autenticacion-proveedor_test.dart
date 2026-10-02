import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bumand_movil/nucleo/utilidades/resultado.dart';
import 'package:bumand_movil/modulos/autenticacion/modelos/usuario-modelo.dart';
import 'package:bumand_movil/modulos/autenticacion/repositorios/autenticacion-repositorio.dart';
import 'package:bumand_movil/modulos/autenticacion/proveedores/autenticacion-proveedor.dart';

class RepositorioSimulado extends AutenticacionRepositorio {
  Resultado<UsuarioModelo>? resultado_preparado;
  bool sesion_cerrada = false;

  @override
  Future<Resultado<UsuarioModelo>> iniciarSesion(
    String correo,
    String contrasena,
  ) async {
    return resultado_preparado ??
        Resultado.fallido('Sin resultado configurado');
  }

  @override
  Future<Resultado<UsuarioModelo>> registrar(
    String ci,
    String correo,
    String contrasena,
  ) async {
    return resultado_preparado ??
        Resultado.fallido('Sin resultado configurado');
  }

  @override
  Future<void> cerrarSesion() async {
    sesion_cerrada = true;
  }
}

void main() {
  group('AutenticacionProveedor Pruebas', () {
    test('Estado inicial es inactivo, sin usuario y sin error', () {
      final contenedor = ProviderContainer();
      addTearDown(contenedor.dispose);

      final estado_inicial = contenedor.read(autenticacion_proveedor);

      expect(estado_inicial.cargando, isFalse);
      expect(estado_inicial.usuario, isNull);
      expect(estado_inicial.error, isNull);
    });

    test('iniciarSesion exitoso actualiza el usuario y quita cargando', () async {
      final repo_falso = RepositorioSimulado();
      const usuario_esperado = UsuarioModelo(
        id: 5,
        nombre: 'Mario Becario',
        correo: 'mario@bumand.bo',
        rol: 'becario',
        token: 'token-mario',
      );
      repo_falso.resultado_preparado = Resultado.exitoso(usuario_esperado);

      final contenedor = ProviderContainer(
        overrides: [
          autenticacion_repositorio_proveedor.overrideWithValue(repo_falso),
        ],
      );
      addTearDown(contenedor.dispose);

      final exito = await contenedor
          .read(autenticacion_proveedor.notifier)
          .iniciarSesion('mario@bumand.bo', 'password');

      expect(exito, isTrue);

      final estado_final = contenedor.read(autenticacion_proveedor);
      expect(estado_final.cargando, isFalse);
      expect(estado_final.usuario, equals(usuario_esperado));
      expect(estado_final.error, isNull);
    });

    test('iniciarSesion fallido asigna el mensaje de error', () async {
      final repo_falso = RepositorioSimulado();
      repo_falso.resultado_preparado =
          Resultado.fallido('Credenciales incorrectas');

      final contenedor = ProviderContainer(
        overrides: [
          autenticacion_repositorio_proveedor.overrideWithValue(repo_falso),
        ],
      );
      addTearDown(contenedor.dispose);

      final exito = await contenedor
          .read(autenticacion_proveedor.notifier)
          .iniciarSesion('erroneo@bumand.bo', 'clave');

      expect(exito, isFalse);

      final estado_final = contenedor.read(autenticacion_proveedor);
      expect(estado_final.cargando, isFalse);
      expect(estado_final.usuario, isNull);
      expect(estado_final.error, equals('Credenciales incorrectas'));
    });

    test('limpiarError limpia el mensaje de error del estado', () {
      final contenedor = ProviderContainer();
      addTearDown(contenedor.dispose);

      final notificador = contenedor.read(autenticacion_proveedor.notifier);
      notificador.state = notificador.state.copiarCon(error: 'Fallo temporal');
      expect(contenedor.read(autenticacion_proveedor).error, equals('Fallo temporal'));

      notificador.limpiarError();
      expect(contenedor.read(autenticacion_proveedor).error, isNull);
    });

    test('cerrarSesion reinicia el estado y llama al repositorio', () async {
      final repo_falso = RepositorioSimulado();
      final contenedor = ProviderContainer(
        overrides: [
          autenticacion_repositorio_proveedor.overrideWithValue(repo_falso),
        ],
      );
      addTearDown(contenedor.dispose);

      final notificador = contenedor.read(autenticacion_proveedor.notifier);
      notificador.state = const AutenticacionEstado(
        usuario: UsuarioModelo(
          id: 1,
          nombre: 'Activo',
          correo: 'a@b.com',
          rol: 'becario',
          token: 'token',
        ),
      );

      await notificador.cerrarSesion();

      final estado_post = contenedor.read(autenticacion_proveedor);
      expect(estado_post.usuario, isNull);
      expect(estado_post.cargando, isFalse);
      expect(repo_falso.sesion_cerrada, isTrue);
    });
  });
}
