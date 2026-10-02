import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bumand_movil/nucleo/utilidades/resultado.dart';
import 'package:bumand_movil/modulos/autenticacion/modelos/usuario-modelo.dart';
import 'package:bumand_movil/modulos/autenticacion/repositorios/autenticacion-repositorio.dart';
import 'package:bumand_movil/modulos/autenticacion/proveedores/autenticacion-proveedor.dart';
import 'package:bumand_movil/modulos/autenticacion/pantallas/inicio-sesion-pantalla.dart';
import 'package:bumand_movil/modulos/inicio/pantallas/pantalla-inicio.dart';

class RepositorioSimulado extends AutenticacionRepositorio {
  Resultado<UsuarioModelo>? resultado_configurado;

  @override
  Future<Resultado<UsuarioModelo>> iniciarSesion(
    String correo,
    String contrasena,
  ) async {
    return resultado_configurado ??
        Resultado.fallido('Credenciales incorrectas');
  }
}

void main() {
  group('InicioSesionPantalla Pruebas de Widget', () {
    testWidgets('Renderiza formulario de inicio de sesion correctamente', (WidgetTester probador) async {
      await probador.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: InicioSesionPantalla(),
          ),
        ),
      );

      expect(find.text('Sistema de gestión de becarios'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Ingresar'), findsOneWidget);
      expect(find.text('Regístrate'), findsOneWidget);
    });

    testWidgets('Valida campos vacios mostrando mensaje de error local', (WidgetTester probador) async {
      await probador.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: InicioSesionPantalla(),
          ),
        ),
      );

      // Pulsar Ingresar sin llenar datos
      await probador.tap(find.text('Ingresar'));
      await probador.pump();

      expect(find.text('Por favor ingresa tu correo y contraseña'), findsOneWidget);
    });

    testWidgets('Muestra error cuando la autenticacion falla', (WidgetTester probador) async {
      final repo_simulado = RepositorioSimulado();
      repo_simulado.resultado_configurado =
          Resultado.fallido('Correo o contraseña incorrectos');

      await probador.pumpWidget(
        ProviderScope(
          overrides: [
            autenticacion_repositorio_proveedor.overrideWithValue(repo_simulado),
          ],
          child: const MaterialApp(
            home: InicioSesionPantalla(),
          ),
        ),
      );

      final campos_texto = find.byType(TextField);
      await probador.enterText(campos_texto.first, 'usuario@bumand.bo');
      await probador.enterText(campos_texto.last, 'contrasena123');

      await probador.tap(find.text('Ingresar'));
      await probador.pumpAndSettle();

      expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
    });

    testWidgets('Muestra indicador de progreso y deshabilita boton durante carga', (WidgetTester probador) async {
      final contenedor = ProviderContainer();
      contenedor.read(autenticacion_proveedor.notifier).state =
          const AutenticacionEstado(cargando: true);

      await probador.pumpWidget(
        UncontrolledProviderScope(
          container: contenedor,
          child: const MaterialApp(
            home: InicioSesionPantalla(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final boton = probador.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(boton.onPressed, isNull);
    });

    testWidgets('Redireccion limpia a PantallaInicio tras inicio de sesion exitoso', (WidgetTester probador) async {
      final repo_simulado = RepositorioSimulado();
      const usuario_valido = UsuarioModelo(
        id: 1,
        nombre: 'Valeria Ramos',
        correo: 'valeria@bumand.bo',
        rol: 'becario',
        token: 'token-jwt-ok',
      );
      repo_simulado.resultado_configurado = Resultado.exitoso(usuario_valido);

      await probador.pumpWidget(
        ProviderScope(
          overrides: [
            autenticacion_repositorio_proveedor.overrideWithValue(repo_simulado),
          ],
          child: const MaterialApp(
            home: InicioSesionPantalla(),
          ),
        ),
      );

      final campos_texto = find.byType(TextField);
      await probador.enterText(campos_texto.first, 'valeria@bumand.bo');
      await probador.enterText(campos_texto.last, 'secretoSeguro');

      await probador.tap(find.text('Ingresar'));
      await probador.pump();
      await probador.pump(const Duration(milliseconds: 500));
      await probador.pump(const Duration(milliseconds: 500));

      // Verifica que navego limpiamente a PantallaInicio
      expect(find.byType(PantallaInicio), findsOneWidget);
      expect(find.byType(InicioSesionPantalla), findsNothing);
    });
  });
}
