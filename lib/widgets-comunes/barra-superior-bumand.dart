import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../nucleo/tema/colores.dart';
import '../modulos/autenticacion/proveedores/autenticacion-proveedor.dart';
import '../modulos/autenticacion/pantallas/inicio-sesion-pantalla.dart';
import '../modulos/evaluaciones/pantallas/evaluaciones-pantalla.dart';
import '../modulos/asistencia/pantallas/historial-asistencia-pantalla.dart';
import '../modulos/justificaciones/pantallas/solicitar-justificacion-dialogo.dart';
import '../modulos/notificaciones/pantallas/notificaciones-pantalla.dart';
import '../modulos/inicio/pantallas/acerca-de-pantalla.dart';
import '../modulos/refrigerios/pantallas/refrigerios-pantalla.dart';


class BarraSuperiorBumand extends ConsumerWidget implements PreferredSizeWidget {
  final String titulo;
  final String? subtitulo;
  final List<Widget>? acciones_adicionales;
  final bool mostrar_logos;
  final bool mostrar_perfil;
  final VoidCallback? alTocarLogo;

  const BarraSuperiorBumand({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acciones_adicionales,
    this.mostrar_logos = true,
    this.mostrar_perfil = true,
    this.alTocarLogo,
  });

  static const _DEGRADADO_DIACONIA = LinearGradient(
    colors: [BumandColores.AZUL_DIACONIA, BumandColores.TURQUESA_DIACONIA],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Size get preferredSize => const Size.fromHeight(74);

  void _mostrarDialogoCorreosAlternativos(BuildContext context, WidgetRef ref) {
    final usuario = ref.read(autenticacion_proveedor).usuario;
    final controlador_correo = TextEditingController(
      text: usuario?.correo_alternativo ?? '',
    );
    String? error_dialogo;
    bool guardando = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, actualizarEstadoDialogo) {
          final correos_adicionales = <String>{
            if (usuario?.correo_alternativo != null &&
                usuario!.correo_alternativo!.trim().isNotEmpty)
              usuario.correo_alternativo!.trim(),
            ...(usuario?.correos_adicionales ?? const <String>[]),
          }.where((c) => c != (usuario?.correo ?? "")).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.alternate_email_rounded,
                  color: BumandColores.AZUL_DIACONIA,
                  size: 22,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Correos de Inicio de Sesión",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: BumandColores.AZUL_DIACONIA,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Puedes iniciar sesión con tu correo principal o vincular un correo alternativo (personal o institucional).",
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: BumandColores.AZUL_DIACONIA,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Principal: ${usuario?.correo ?? 'becario@bumand.bo'}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (correos_adicionales.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (final c in correos_adicionales)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.mark_email_read_outlined,
                              size: 15,
                              color: Color(0xFF0D9488),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Alternativo: $c",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF0F766E),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: controlador_correo,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Correo alternativo de acceso",
                      hintText: "ejemplo@diaconia.bo",
                      errorText: error_dialogo,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: guardando ? null : () => Navigator.of(ctx).pop(),
                child: const Text("Cancelar"),
              ),
              FilledButton(
                onPressed: guardando
                    ? null
                    : () async {
                        actualizarEstadoDialogo(() {
                          guardando = true;
                          error_dialogo = null;
                        });
                        final res = await ref
                            .read(autenticacion_proveedor.notifier)
                            .actualizarCorreoAlternativo(
                              controlador_correo.text,
                            );
                        if (!ctx.mounted) return;
                        if (res.exito) {
                          Navigator.of(ctx).pop();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  res.datos ??
                                      "Correo alternativo actualizado",
                                ),
                                backgroundColor: const Color(0xFF059669),
                              ),
                            );
                          }
                        } else {
                          actualizarEstadoDialogo(() {
                            guardando = false;
                            error_dialogo = res.error;
                          });
                        }
                      },
                child: const Text("Guardar correo"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarDialogoPerfil(BuildContext context, WidgetRef ref) {
    final estado_auth = ref.read(autenticacion_proveedor);
    final usuario = estado_auth.usuario;
    final correos_alternativos = <String>{
      if (usuario?.correo_alternativo != null &&
          usuario!.correo_alternativo!.trim().isNotEmpty)
        usuario.correo_alternativo!.trim(),
      ...(usuario?.correos_adicionales ?? const <String>[]),
    }.where((c) => c != (usuario?.correo ?? "")).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.88,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: BumandColores.AZUL_DIACONIA,
                        child: Text(
                          (usuario?.nombre.isNotEmpty ?? false)
                              ? usuario!.nombre.substring(0, 1).toUpperCase()
                              : "B",
                          style: const TextStyle(
                            color: BumandColores.NARANJA,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              usuario?.nombre ?? "Usuario Becario",
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: BumandColores.AZUL_DIACONIA,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              usuario?.correo ?? "becario@bumand.bo",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (correos_alternativos.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                "Alternativo(s): ${correos_alternativos.join(' · ')}",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: BumandColores.AZUL_DIACONIA.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (usuario?.rol ?? "becario").toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: BumandColores.AZUL_DIACONIA,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: BumandColores.azulCieloSuave.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.alternate_email_rounded,
                        color: BumandColores.AZUL_DIACONIA,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      "Correos de Inicio de Sesión",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: BumandColores.NEGRO,
                      ),
                    ),
                    subtitle: Text(
                      correos_alternativos.isNotEmpty
                          ? "Alternativo activo: ${correos_alternativos.first}"
                          : "Vincular correo alternativo o institucional de acceso",
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _mostrarDialogoCorreosAlternativos(context, ref);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assignment_turned_in_outlined,
                        color: BumandColores.AZUL_DIACONIA,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      "Mis Evaluaciones (360°)",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: BumandColores.NEGRO,
                      ),
                    ),
                    subtitle: const Text(
                      "Calificación ponderada y desglose modular",
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EvaluacionesPantalla()),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: BumandColores.TURQUESA_DIACONIA.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: BumandColores.AZUL_DIACONIA,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      "Historial de Asistencias",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: BumandColores.NEGRO,
                      ),
                    ),
                    subtitle: const Text(
                      "Marcaciones de ingreso y salida con GPS",
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HistorialAsistenciaPantalla(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assignment_late_outlined,
                        color: Color(0xFFD97706),
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      "Permisos y Justificaciones",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: BumandColores.NEGRO,
                      ),
                    ),
                    subtitle: const Text(
                      "Reportes médicos y de incidencias con prueba",
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      SolicitarJustificacionDialogo.mostrar(context);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: BumandColores.azulMarinoSecundario.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: BumandColores.azulMarinoSecundario,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      "Acerca de Nosotros",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: BumandColores.NEGRO,
                      ),
                    ),
                    subtitle: const Text(
                      "Diaconía FRIF-IFD · Principios e historia",
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AcercaDePantalla(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: BumandColores.azulCieloSuave.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: BumandColores.azulMarinoProfundo,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Mis Refrigerios',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: BumandColores.NEGRO,
                      ),
                    ),
                    subtitle: const Text(
                      'Registro de recojo y constancias de ración',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RefrigeriosPantalla(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 4),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      "Cerrar sesión corporativa",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: const Text(
                      "Finalizar sesión en este dispositivo",
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await ref.read(autenticacion_proveedor.notifier).cerrarSesion();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const InicioSesionPantalla(),
                          ),
                          (_) => false,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 74,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: _DEGRADADO_DIACONIA),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          if (subtitulo != null)
            Text(
              subtitulo!,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFD6F1F7),
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      actions: [
        ...?acciones_adicionales,
        if (mostrar_logos) ...[
          // Logo BUMAND Blanco oficial interactivo
          GestureDetector(
            onTap: () {
              if (alTocarLogo != null) {
                alTocarLogo!();
              } else {
                ref.read(menu_principal_proveedor.notifier).alternar();
              }
            },
            child: Tooltip(
              message: "Menú principal",
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: SvgPicture.asset(
                  'assets/logos/logo-bumand-dorado-blanco.svg',
                  height: 26,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Logo Diaconía IFD oficial en cápsula blanca de alta visibilidad
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: SvgPicture.asset(
              'assets/logos/logo-diaconia-color.svg',
              height: 18,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 6),
        ],
        if (mostrar_perfil) ...[
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 22),
            tooltip: "Notificaciones y códigos",
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificacionesPantalla(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 24),
            tooltip: "Mi perfil y sesión",
            visualDensity: VisualDensity.compact,
            onPressed: () => _mostrarDialogoPerfil(context, ref),
          ),
        ],
        const SizedBox(width: 4),
      ],
    );
  }
}

class MenuPrincipalNotificador extends Notifier<bool> {
  @override
  bool build() => false;

  void alternar() => state = !state;
  void mostrar() => state = true;
  void ocultar() => state = false;
}

final menu_principal_proveedor =
    NotifierProvider<MenuPrincipalNotificador, bool>(
  MenuPrincipalNotificador.new,
);

