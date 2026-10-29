import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bumand_movil/nucleo/utilidades/resultado.dart';
import 'package:bumand_movil/modulos/autenticacion/modelos/usuario-modelo.dart';
import 'package:bumand_movil/modulos/autenticacion/repositorios/autenticacion-repositorio.dart';
import 'package:bumand_movil/modulos/autenticacion/proveedores/autenticacion-proveedor.dart';
import 'package:bumand_movil/modulos/autenticacion/pantallas/mi-perfil-pantalla.dart';

class RepositorioSimulado extends AutenticacionRepositorio {
  UsuarioModelo usuario_actual;

  RepositorioSimulado({required this.usuario_actual});

  @override
  Future<UsuarioModelo?> obtenerSesionActual() async {
    return usuario_actual;
  }

  @override
  Future<Resultado<UsuarioModelo>> actualizarMiPerfil({
    required String nombre,
    String? telefono,
    String? direccion,
    String? carrera,
    String? semestre,
  }) async {
    usuario_actual = usuario_actual.copiarCon(
      nombre: nombre,
      telefono: telefono,
      direccion: direccion,
      carrera: carrera,
      semestre: semestre,
    );
    return Resultado.exitoso(usuario_actual);
  }

  @override
  Future<Resultado<Map<String, dynamic>>> listarMisCorreos() async {
    return Resultado.exitoso({
      'correo_principal': usuario_actual.correo,
      'correo_alternativo': usuario_actual.correo_alternativo,
      'correos_adicionales': [
        {
          'id': 1,
          'correo': 'correo.alt@gmail.com',
          'etiqueta': 'Personal',
        },
      ],
    });
  }

  @override
  Future<Resultado<Map<String, dynamic>>> vincularCorreoAlternativo({
    required String correo,
    String etiqueta = 'Personal',
  }) async {
    final lista = List<String>.from(usuario_actual.correos_adicionales);
    if (!lista.contains(correo)) lista.add(correo);
    usuario_actual = usuario_actual.copiarCon(
      correo_alternativo: correo,
      correos_adicionales: lista,
    );
    return Resultado.exitoso({
      'correo_principal': usuario_actual.correo,
      'correo_alternativo': correo,
      'correos_adicionales': [
        {'id': 1, 'correo': correo, 'etiqueta': etiqueta},
      ],
    });
  }

  @override
  Future<Resultado<String>> cambiarMiContrasena({
    required String contrasena_actual,
    required String nueva_contrasena,
  }) async {
    return Resultado.exitoso('Contraseña actualizada exitosamente');
  }

  @override
  Future<Resultado<List<Map<String, dynamic>>>> listarUsuariosInstitucionales({
    String? rol,
  }) async {
    return Resultado.exitoso([
      {
        'id': 1,
        'nombre': 'Adai Belen Huayta',
        'correo': 'adai.huayta@diaconia.bo',
        'rol': 'administrador',
        'estado': 'activo',
      },
      {
        'id': 2,
        'nombre': 'Angel Javier Ali Paz',
        'correo': 'angel.ali@diaconia.bo',
        'rol': 'supervisor',
        'estado': 'activo',
      },
      {
        'id': 3,
        'nombre': 'María Catunta Laime',
        'correo': 'maria.catunta@diaconia.bo',
        'rol': 'becario',
        'estado': 'activo',
      },
    ]);
  }
}

void main() {
  group('MiPerfilPantalla Pruebas de Widget', () {
    testWidgets(
      'Muestra secciones de Datos Personales, Correos de Inicio de Sesión y Cambio de Contraseña con el botón de mostrar/ocultar contraseña',
      (WidgetTester probador) async {
        probador.view.physicalSize = const Size(800, 2400);
        probador.view.devicePixelRatio = 1.0;
        addTearDown(() {
          probador.view.resetPhysicalSize();
          probador.view.resetDevicePixelRatio();
        });

        const usuario_prueba = UsuarioModelo(
          id: 1,
          nombre: 'María Catunta Laime',
          correo: 'maria.catunta@diaconia.bo',
          rol: 'becario',
          token: 'token-jwt-prueba',
          correo_alternativo: 'maria.personal@gmail.com',
          telefono: '78945612',
          direccion: 'Zona 16 de Julio, Calle Eulert #120, El Alto',
          carrera: 'Contaduría Pública',
          semestre: '6to Semestre',
        );

        final repo_simulado = RepositorioSimulado(usuario_actual: usuario_prueba);
        final contenedor = ProviderContainer(
          overrides: [
            autenticacion_repositorio_proveedor.overrideWithValue(repo_simulado),
          ],
        );
        contenedor.read(autenticacion_proveedor.notifier).state =
            const AutenticacionEstado(usuario: usuario_prueba);

        await probador.pumpWidget(
          UncontrolledProviderScope(
            container: contenedor,
            child: const MaterialApp(
              home: MiPerfilPantalla(),
            ),
          ),
        );
        await probador.pumpAndSettle();

        // 1. Verificar Tarjeta Superior de Identidad Institucional
        expect(find.text('María Catunta Laime'), findsWidgets);
        expect(find.text('BECARIO'), findsOneWidget);
        expect(find.text('Cuenta Activa'), findsOneWidget);
        expect(find.text('maria.catunta@diaconia.bo'), findsWidgets);

        // 2. Verificar Sección 1: Datos Personales
        expect(
          find.text('Datos Personales e Institucionales'),
          findsOneWidget,
        );
        expect(find.text('Guardar Datos Personales'), findsOneWidget);

        // 3. Verificar Sección 2: Correos de Inicio de Sesión
        expect(
          find.text('Correos de Inicio de Sesión'),
          findsOneWidget,
        );
        expect(find.text('Vincular Nuevo Correo Alternativo'), findsOneWidget);

        // 4. Verificar Sección 3: Cambio de Contraseña y botón de mostrar/ocultar contraseña
        expect(
          find.text('Cambiar Contraseña y Seguridad'),
          findsOneWidget,
        );
        expect(find.text('Actualizar Contraseña'), findsOneWidget);

        // Verificar botón de visibilidad de contraseña (icono de ojo)
        final iconos_ojo = find.byIcon(Icons.visibility_outlined);
        expect(iconos_ojo, findsWidgets);

        // Tocar el primer icono de ojo para conmutar visibilidad
        await probador.tap(iconos_ojo.first);
        await probador.pump();

        // Debe haber al menos un icono de ojo tachado tras alternar visibilidad
        expect(find.byIcon(Icons.visibility_off_outlined), findsWidgets);
      },
    );

    testWidgets(
      'Permite al usuario editar su nombre y guardar los datos personales con confirmación',
      (WidgetTester probador) async {
        probador.view.physicalSize = const Size(800, 2400);
        probador.view.devicePixelRatio = 1.0;
        addTearDown(() {
          probador.view.resetPhysicalSize();
          probador.view.resetDevicePixelRatio();
        });

        const usuario_prueba = UsuarioModelo(
          id: 1,
          nombre: 'María Catunta',
          correo: 'maria@diaconia.bo',
          rol: 'becario',
          token: 'token-jwt-prueba',
        );

        final repo_simulado = RepositorioSimulado(usuario_actual: usuario_prueba);
        final contenedor = ProviderContainer(
          overrides: [
            autenticacion_repositorio_proveedor.overrideWithValue(repo_simulado),
          ],
        );
        contenedor.read(autenticacion_proveedor.notifier).state =
            const AutenticacionEstado(usuario: usuario_prueba);

        await probador.pumpWidget(
          UncontrolledProviderScope(
            container: contenedor,
            child: const MaterialApp(
              home: MiPerfilPantalla(),
            ),
          ),
        );
        await probador.pumpAndSettle();

        // Buscar campo de nombre completo (el primer TextFormField de la pantalla)
        final campos_texto = find.byType(TextFormField);
        expect(campos_texto, findsWidgets);

        await probador.enterText(campos_texto.first, 'María Catunta Actualizada');
        await probador.pump();

        // Tocar botón de Guardar Datos Personales
        final boton_guardar = find.text('Guardar Datos Personales');
        await probador.tap(boton_guardar);
        await probador.pump();
        await probador.pump(const Duration(milliseconds: 300));

        // Debe mostrar SnackBar de confirmación
        expect(
          find.text('Datos personales actualizados exitosamente'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Permite al usuario ingresar y vincular un nuevo correo alternativo',
      (WidgetTester probador) async {
        probador.view.physicalSize = const Size(800, 2400);
        probador.view.devicePixelRatio = 1.0;
        addTearDown(() {
          probador.view.resetPhysicalSize();
          probador.view.resetDevicePixelRatio();
        });

        const usuario_prueba = UsuarioModelo(
          id: 1,
          nombre: 'María Catunta',
          correo: 'maria@diaconia.bo',
          rol: 'becario',
          token: 'token-jwt-prueba',
        );

        final repo_simulado = RepositorioSimulado(usuario_actual: usuario_prueba);
        final contenedor = ProviderContainer(
          overrides: [
            autenticacion_repositorio_proveedor.overrideWithValue(repo_simulado),
          ],
        );
        contenedor.read(autenticacion_proveedor.notifier).state =
            const AutenticacionEstado(usuario: usuario_prueba);

        await probador.pumpWidget(
          UncontrolledProviderScope(
            container: contenedor,
            child: const MaterialApp(
              home: MiPerfilPantalla(),
            ),
          ),
        );
        await probador.pumpAndSettle();

        // Buscar campo de correo alternativo por icono
        final campo_correo_icono = find.byIcon(Icons.add_circle_outline_rounded);
        expect(campo_correo_icono, findsOneWidget);

        final campo_correo = find.ancestor(
          of: campo_correo_icono,
          matching: find.byType(TextFormField),
        );
        expect(campo_correo, findsOneWidget);

        await probador.enterText(campo_correo, 'nuevo.alternativo@gmail.com');
        await probador.pump();

        // Tocar botón de vincular
        final boton_vincular = find.text('Vincular Correo Alternativo');
        await probador.tap(boton_vincular);
        await probador.pump();
        await probador.pump(const Duration(milliseconds: 300));

        // Debe mostrar SnackBar de confirmación
        expect(
          find.text('Correo alternativo vinculado exitosamente'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Muestra pestañas de Mi Perfil y Gestión de Usuarios cuando el usuario es Administrador',
      (WidgetTester probador) async {
        probador.view.physicalSize = const Size(800, 2400);
        probador.view.devicePixelRatio = 1.0;
        addTearDown(() {
          probador.view.resetPhysicalSize();
          probador.view.resetDevicePixelRatio();
        });

        const usuario_admin = UsuarioModelo(
          id: 99,
          nombre: 'Adai Belen Huayta',
          correo: 'admin@diaconia.bo',
          rol: 'administrador',
          token: 'token-jwt-admin',
        );

        final repo_simulado = RepositorioSimulado(usuario_actual: usuario_admin);
        final contenedor = ProviderContainer(
          overrides: [
            autenticacion_repositorio_proveedor.overrideWithValue(repo_simulado),
          ],
        );
        contenedor.read(autenticacion_proveedor.notifier).state =
            const AutenticacionEstado(usuario: usuario_admin);

        await probador.pumpWidget(
          UncontrolledProviderScope(
            container: contenedor,
            child: const MaterialApp(
              home: MiPerfilPantalla(),
            ),
          ),
        );
        await probador.pumpAndSettle();

        // Debe mostrar las pestañas exclusivas
        expect(find.text('Mi Perfil y Cuenta'), findsWidgets);
        expect(find.text('Gestión de Usuarios'), findsOneWidget);

        // Tocar pestaña de Gestión de Usuarios
        await probador.tap(find.text('Gestión de Usuarios'));
        await probador.pumpAndSettle();

        // Debe mostrar panel de administración de cuentas
        expect(find.text('Gestión de Cuentas BUMAND'), findsOneWidget);
        expect(find.text('Nuevo Usuario'), findsOneWidget);
        expect(find.text('Todos'), findsOneWidget);
        expect(find.text('Supervisores'), findsOneWidget);
        expect(find.text('Becarios'), findsOneWidget);
      },
    );
  });
}
