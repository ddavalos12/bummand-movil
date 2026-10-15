import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/banner-conexion.dart';
import '../../asistencia/modelos/orden-confirmacion-modelo.dart';
import '../../asistencia/pantallas/asistencia-pantalla.dart';
import '../../asistencia/pantallas/confirmar-datos-pantalla.dart';
import '../../asistencia/proveedores/asistencia-proveedor.dart';
import '../../pasajes/pantallas/pasajes-pantalla.dart';
import '../../notificaciones/pantallas/notificaciones-pantalla.dart';
import '../../notificaciones/proveedores/notificaciones-proveedor.dart';

class InicioPantalla extends ConsumerStatefulWidget {
  final bool mostrar_versiculo_inicio;
  const InicioPantalla({super.key, this.mostrar_versiculo_inicio = false});

  @override
  ConsumerState<InicioPantalla> createState() => _InicioPantallaState();
}

class _InicioPantallaState extends ConsumerState<InicioPantalla> {
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
    final orden = ref.watch(orden_confirmacion_proveedor);

    return Scaffold(
      backgroundColor: BumandColores.FONDO,
      body: Column(
        children: [
          const BannerConexion(),
          if (orden.activa && !orden.confirmada_este_mes)
            _construirBannerOrdenConfirmacion(context, orden),
          Expanded(
            child: IndexedStack(index: _indice, children: _pantallas),
          ),
        ],
      ),
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

  Widget _construirBannerOrdenConfirmacion(
    BuildContext context,
    OrdenConfirmacionModelo orden,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFEF3C7),
        border: Border(
          bottom: BorderSide(color: Color(0xFFF59E0B)),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notification_important,
            color: Color(0xFFB45309),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Confirmación Mensual de Datos Requerida por Administración",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: Color(0xFF92400E),
                  ),
                ),
                Text(
                  "Período: ${orden.periodo} • Actualización de contacto requerida.",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ConfirmarDatosPantalla(periodo: orden.periodo),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text(
              "Confirmar",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// Alias para mantener compatibilidad total
typedef PantallaInicio = InicioPantalla;
