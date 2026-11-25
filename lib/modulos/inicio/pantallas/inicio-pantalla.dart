import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../nucleo/utilidades/filtro-mentor.dart';
import '../../../widgets-comunes/banner-conexion.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../../asistencia/pantallas/asistencia-pantalla.dart';
import '../../asistencia/pantallas/historial-asistencia-pantalla.dart';
import '../../asistencia/proveedores/asistencia-proveedor.dart';
import '../../asistencia/repositorios/asistencia-repositorio.dart';
import '../../evaluaciones/pantallas/evaluaciones-pantalla.dart';
import '../../justificaciones/pantallas/permisos-pantalla.dart';
import '../../pasajes/pantallas/declarar-recorrido-pantalla.dart';
import '../proveedores/inicio-proveedor.dart';
import '../../refrigerios/pantallas/refrigerios-pantalla.dart';
import '../../refrigerios/proveedores/refrigerios-proveedor.dart';
import '../../autenticacion/proveedores/autenticacion-proveedor.dart';
import '../../devocionales/pantallas/devocionales-pantalla.dart';


class InicioPantalla extends ConsumerStatefulWidget {
  final bool mostrar_versiculo_inicio;
  const InicioPantalla({super.key, this.mostrar_versiculo_inicio = false});

  @override
  ConsumerState<InicioPantalla> createState() => _InicioPantallaState();
}

class _InicioPantallaState extends ConsumerState<InicioPantalla> {
  static const _pantallas = [
    AsistenciaPantalla(),
    DeclararRecorridoPantalla(es_pestana: true, solo_hoy: true),
    EvaluacionesPantalla(),
    HistorialAsistenciaPantalla(),
  ];

  @override
  Widget build(BuildContext context) {
    final indice_actual = ref.watch(pestana_inicio_proveedor);
    final menu_abierto = ref.watch(menu_principal_proveedor);

    return Scaffold(
      backgroundColor: BumandColores.FONDO,
      body: Column(
        children: [
          const BannerConexion(),
          Expanded(
            child: menu_abierto
                ? _construirVistaMenuPrincipal(context)
                : IndexedStack(index: indice_actual, children: _pantallas),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: indice_actual,
        onDestinationSelected: (i) {
          ref.read(menu_principal_proveedor.notifier).ocultar();
          ref.read(pestana_inicio_proveedor.notifier).cambiarPestana(i);
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
            icon: Icon(Icons.directions_bus_outlined),
            selectedIcon: Icon(
              Icons.directions_bus,
              color: BumandColores.AZUL_DIACONIA,
            ),
            label: "Pasajes",
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
    final turno_dupla = ref.watch(turno_dupla_activo_proveedor);
    final estado_auth = ref.watch(autenticacion_proveedor);
    final datos_perfil = perfil_async.asData?.value.datos;
    final rol_crudo = (estado_auth.usuario?.rol ?? datos_perfil?['rol'] ?? 'becario')
        .toString()
        .toLowerCase()
        .trim();
    final es_admin = esRolAdmin(rol_crudo);
    final es_supervisor = esRolMentor(rol_crudo) && !es_admin;
    final es_becario = !es_admin && !es_supervisor;
    final nombre_completo = datos_perfil?["nombre"] ??
        estado_auth.usuario?.nombre ??
        "Becario";
    final partes_nombre = nombre_completo.split(' ');
    final primer_nombre = partes_nombre.isNotEmpty ? partes_nombre.first : "Becario";
    final extractos_async = ref.watch(extractos_mensuales_proveedor);
    final extracto_actual = extractos_async.asData?.value.isNotEmpty == true
        ? extractos_async.asData!.value.first
        : null;

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
                    color: BumandColores.azulMarinoProfundo,
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
          const SizedBox(height: 12),

          if (es_becario && extracto_actual != null) ...[
            _construirTarjetaResumenAsistencia(extracto_actual),
            const SizedBox(height: 14),
          ] else
            const SizedBox(height: 2),

          // Tarjetas de Acceso Directo a los Módulos Clave (Fiel a 16.jpeg y 17.jpeg)
          _construirItemMenu(
            icono: Icons.location_on_rounded,
            color_icono: BumandColores.azulMarinoProfundo,
            fondo_icono: const Color(0xFFE0F2FE),
            titulo: "Asistencia y Ruta del Día",
            subtitulo: "Registra tu ingreso, salida y recorrido con mapa",
            alTocar: () {
              ref.read(menu_principal_proveedor.notifier).ocultar();
              ref.read(pestana_inicio_proveedor.notifier).cambiarPestana(0);
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
              ref.read(pestana_inicio_proveedor.notifier).cambiarPestana(1);
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
              ref.read(pestana_inicio_proveedor.notifier).cambiarPestana(2);
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
              ref.read(pestana_inicio_proveedor.notifier).cambiarPestana(3);
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
              ref.read(menu_principal_proveedor.notifier).ocultar();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PermisosPantalla(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _construirItemMenu(
            icono: Icons.restaurant_menu_rounded,
            color_icono: BumandColores.azulMarinoProfundo,
            fondo_icono: const Color(0xFFE0F2FE),
            titulo: 'Mis Refrigerios',
            subtitulo: turno_dupla.es_encargado
                ? '¡De turno con ${turno_dupla.companero_nombre}! Devolución 100%'
                : 'Duplas asignadas, recojo y devolución 100%',
            alTocar: () {
              ref.read(menu_principal_proveedor.notifier).ocultar();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RefrigeriosPantalla(),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          if ((es_becario || es_supervisor) && !es_admin) ...[
            _construirItemMenu(
              icono: Icons.calendar_month_rounded,
              color_icono: const Color(0xFF0284C7),
              fondo_icono: const Color(0xFFE0F2FE),
              titulo: "Seguimiento y Retroalimentación",
              subtitulo: es_supervisor
                  ? "Citas y acuerdos con tus becarios asignados"
                  : "Citas y acuerdos con tu Mentor",
              alTocar: () {
                ref.read(menu_principal_proveedor.notifier).ocultar();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DevocionalesPantalla(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _construirTarjetaResumenAsistencia(ExtractoMensualAsistencia extracto) {
    final pct_cumplimiento = extracto.porcentaje_cumplido.clamp(0, 100);
    final pct_puntualidad = extracto.tasa_puntualidad.clamp(0, 100);
    final tiene_permiso_compensado =
        extracto.dias_permiso_aprobado > 0 ||
        extracto.horas_compensadas_permiso > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            BumandColores.azulMarinoProfundo,
            BumandColores.azulMarinoSecundario,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: BumandColores.azulMarinoProfundo.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                color: BumandColores.amarilloRadiante,
                size: 18,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  "Mi Asistencia y Puntualidad",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  extracto.mes_nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Cumplimiento",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$pct_cumplimiento% (${extracto.horas_totales_hms} / ${extracto.meta_mensual_hms})",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Puntualidad",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$pct_puntualidad%",
                        style: const TextStyle(
                          color: Color(0xFF4ADE80),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (tiene_permiso_compensado) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF4ADE80).withValues(alpha: 0.5),
                ),
              ),
              child: const Text(
                "✓ Permisos aprobados compensados al 100%",
                style: TextStyle(
                  color: Color(0xFFDCFCE7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
