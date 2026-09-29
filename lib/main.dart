import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'nucleo/tema/colores.dart';
import 'modulos/autenticacion/pantallas/inicio-sesion-pantalla.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: BumandColores.NARANJA,
          primary: BumandColores.NARANJA_OSCURO,
          secondary: BumandColores.AZUL_DIACONIA,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: BumandColores.FONDO,
      ),
      home: const InicioSesionPantalla(),
    );
  }
}
