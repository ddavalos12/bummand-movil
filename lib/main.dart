import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nucleo/tema/tema.dart';
import 'modulos/autenticacion/pantallas/inicio-sesion-pantalla.dart';
import 'modulos/justificaciones/pantallas/permisos-pantalla.dart';
import 'modulos/devocionales/pantallas/devocionales-pantalla.dart';

void main() {
  runApp(const ProviderScope(child: BumandApp()));
}

class BumandApp extends StatelessWidget {
  const BumandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BUMAND',
      debugShowCheckedModeBanner: false,
      theme: BumandTema.temaClaro,
      home: const InicioSesionPantalla(),
      routes: {
        '/permisos': (context) => const PermisosPantalla(),
        '/citas': (context) => const DevocionalesPantalla(),
      },
    );
  }
}
