import 'package:flutter/material.dart';

import '../../../nucleo/tema/colores.dart';
import '../../asistencia/pantallas/asistencia-pantalla.dart';
import '../../pasajes/pantallas/pasajes-pantalla.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  int _indice = 0;

  static const _pantallas = [AsistenciaPantalla(), PasajesPantalla()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BumandColores.FONDO,
      body: IndexedStack(index: _indice, children: _pantallas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        backgroundColor: BumandColores.BLANCO,
        indicatorColor: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fingerprint_outlined),
            selectedIcon: Icon(
              Icons.fingerprint,
              color: BumandColores.AZUL_DIACONIA,
            ),
            label: "Asistencia",
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined),
            selectedIcon: Icon(
              Icons.directions_bus,
              color: BumandColores.AZUL_DIACONIA,
            ),
            label: "Pasajes",
          ),
        ],
      ),
    );
  }
}
