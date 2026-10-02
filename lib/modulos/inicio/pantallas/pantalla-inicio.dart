import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../asistencia/pantallas/asistencia-pantalla.dart';
import '../../pasajes/pantallas/pasajes-pantalla.dart';
import '../../notificaciones/pantallas/notificaciones-pantalla.dart';
import '../../notificaciones/proveedores/notificaciones-proveedor.dart';

class PantallaInicio extends ConsumerStatefulWidget {
  const PantallaInicio({super.key});

  @override
  ConsumerState<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends ConsumerState<PantallaInicio> {
  int _indice = 0;

  static const _pantallas = [
    AsistenciaPantalla(),
    PasajesPantalla(),
    NotificacionesPantalla(),
  ];

  @override
  Widget build(BuildContext context) {
    final conteo_no_leidas =
        ref.watch(notificaciones_conteo_proveedor).value ?? 0;

    return Scaffold(
      backgroundColor: BumandColores.FONDO,
      body: IndexedStack(index: _indice, children: _pantallas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        backgroundColor: BumandColores.BLANCO,
        indicatorColor: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.2),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.fingerprint_outlined),
            selectedIcon: Icon(
              Icons.fingerprint,
              color: BumandColores.AZUL_DIACONIA,
            ),
            label: "Asistencia",
          ),
          const NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined),
            selectedIcon: Icon(
              Icons.directions_bus,
              color: BumandColores.AZUL_DIACONIA,
            ),
            label: "Pasajes",
          ),
          NavigationDestination(
            icon: conteo_no_leidas > 0
                ? Badge(
                    label: Text("$conteo_no_leidas"),
                    child: const Icon(Icons.notifications_outlined),
                  )
                : const Icon(Icons.notifications_outlined),
            selectedIcon: conteo_no_leidas > 0
                ? Badge(
                    label: Text("$conteo_no_leidas"),
                    child: const Icon(
                      Icons.notifications,
                      color: BumandColores.AZUL_DIACONIA,
                    ),
                  )
                : const Icon(
                    Icons.notifications,
                    color: BumandColores.AZUL_DIACONIA,
                  ),
            label: "Notificaciones",
          ),
        ],
      ),
    );
  }
}
