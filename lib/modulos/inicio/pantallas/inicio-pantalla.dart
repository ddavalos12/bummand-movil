import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/banner-conexion.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../../asistencia/pantallas/asistencia-pantalla.dart';
import '../../asistencia/pantallas/historial-asistencia-pantalla.dart';
import '../../asistencia/proveedores/asistencia-proveedor.dart';
import '../../evaluaciones/pantallas/evaluacion-socioeconomica-pantalla.dart';
import '../../evaluaciones/pantallas/evaluaciones-pantalla.dart';
import '../../justificaciones/pantallas/solicitar-justificacion-dialogo.dart';
import '../../pasajes/pantallas/declarar-recorrido-pantalla.dart';

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
    EvaluacionesPantalla(),
    HistorialAsistenciaPantalla(),
  ];

  @override
  Widget build(BuildContext context) {
    final menu_abierto = ref.watch(menu_principal_proveedor);

    return Scaffold(
      backgroundColor: BumandColores.FONDO,
      body: Column(
        children: [
          const BannerConexion(),
          Expanded(
            child: menu_abierto
                ? _construirVistaMenuPrincipal(context)
                : IndexedStack(index: _indice, children: _pantallas),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) {
          ref.read(menu_principal_proveedor.notifier).ocultar();
          setState(() => _indice = i);
        },
        backgroundColor: BumandColores.BLANCO,
        indicatorColor: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(
              Icons.location_on,
              color: BumandColores.AZUL_DIACONIA,
            ),
            label: "Asistencia",
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(
              Icons.assignment,
              color: BumandColores.AZUL_DIACONIA,
            ),
            label: "Evaluación",
          ),
          NavigationDestination(
            icon: Icon(Icons.access_time_outlined),
            selectedIcon: Icon(
              Icons.access_time_filled,
              color: BumandColores.AZUL_DIACONIA,
            ),
            label: "Historial",
          ),
        ],
      ),
    );
  }

  Widget _construirVistaMenuPrincipal(BuildContext context) {
    final perfil_async = ref.watch(perfil_proveedor);
    final datos_perfil = perfil_async.asData?.value.datos;
    final nombre_completo = datos_perfil?["nombre"] ?? "María Catunta Laime";
    final partes_nombre = nombre_completo.split(' ');
    final primer_nombre = partes_nombre.isNotEmpty ? partes_nombre.first : "María";

    return Scaffold(
      backgroundColor: BumandColores.FONDO,
      appBar: BarraSuperiorBumand(
        titulo: "Menú principal",
        subtitulo: "Espacio integral BUMAND",
        alTocarLogo: () => ref.read(menu_principal_proveedor.notifier).ocultar(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // Tarjeta de Saludo Personalizado
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0284C7),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hola, $primer_nombre",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: BumandColores.NEGRO,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Bienvenida a tu espacio BUMAND",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Tarjetas de Acceso Directo a los Módulos Clave (Fiel a 16.jpeg y 17.jpeg)
          _construirItemMenu(
            icono: Icons.location_on_rounded,
            color_icono: const Color(0xFF0284C7),
            fondo_icono: const Color(0xFFE0F2FE),
            titulo: "Asistencia y Ruta del Día",
            subtitulo: "Registra tu ingreso, salida y recorrido con mapa",
            alTocar: () {
              ref.read(menu_principal_proveedor.notifier).ocultar();
              setState(() => _indice = 0);
            },
          ),
          const SizedBox(height: 10),

          _construirItemMenu(
            icono: Icons.directions_bus_rounded,
            color_icono: const Color(0xFFD97706),
            fondo_icono: const Color(0xFFFEF3C7),
            titulo: "Declarar Recorrido de Pasajes",
            subtitulo: "Declara tus paradas de ida y vuelta con mapa",
            alTocar: () {
              ref.read(menu_principal_proveedor.notifier).ocultar();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DeclararRecorridoPantalla(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          _construirItemMenu(
            icono: Icons.assignment_turned_in_rounded,
            color_icono: const Color(0xFF0D9488),
            fondo_icono: const Color(0xFFCCFBF1),
            titulo: "Evaluación",
            subtitulo: "Revisa tus módulos",
            alTocar: () {
              ref.read(menu_principal_proveedor.notifier).ocultar();
              setState(() => _indice = 1);
            },
          ),
          const SizedBox(height: 10),

          _construirItemMenu(
            icono: Icons.volunteer_activism_rounded,
            color_icono: const Color(0xFF059669),
            fondo_icono: const Color(0xFFD1FAE5),
            titulo: "Evaluación Socioeconómica",
            subtitulo: "Cuestionario de Bienestar · 26 preguntas",
            alTocar: () {
              ref.read(menu_principal_proveedor.notifier).ocultar();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EvaluacionSocioeconomicaPantalla(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          _construirItemMenu(
            icono: Icons.access_time_filled_rounded,
            color_icono: const Color(0xFF7C3AED),
            fondo_icono: const Color(0xFFEDE9FE),
            titulo: "Historial",
            subtitulo: "Consulta tus asistencias y pasajes",
            alTocar: () {
              ref.read(menu_principal_proveedor.notifier).ocultar();
              setState(() => _indice = 2);
            },
          ),
          const SizedBox(height: 10),

          _construirItemMenu(
            icono: Icons.assignment_late_rounded,
            color_icono: const Color(0xFFEA580C),
            fondo_icono: const Color(0xFFFFEDD5),
            titulo: "Permisos y Justificaciones",
            subtitulo: "Reportes médicos y de inasistencia",
            alTocar: () {
              SolicitarJustificacionDialogo.mostrar(context);
            },
          ),
          const SizedBox(height: 14),

          // Fila del Perfil del Becario
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_circle,
                  color: Color(0xFF0284C7),
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nombre_completo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 22,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirItemMenu({
    required IconData icono,
    required Color color_icono,
    required Color fondo_icono,
    required String titulo,
    required String subtitulo,
    required VoidCallback alTocar,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: alTocar,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: fondo_icono,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icono, color: color_icono, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

typedef PantallaInicio = InicioPantalla;
