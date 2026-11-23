import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../nucleo/tema/colores.dart';
import '../modulos/autenticacion/proveedores/autenticacion-proveedor.dart';
import '../modulos/autenticacion/pantallas/inicio-sesion-pantalla.dart';
import '../modulos/autenticacion/pantallas/mi-perfil-pantalla.dart';
import '../modulos/notificaciones/pantallas/notificaciones-pantalla.dart';
import '../modulos/devocionales/modelos/versiculo-diario-modelo.dart';
import '../modulos/devocionales/servicios/cola-descarga-biblia-servicio.dart';
import '../modulos/notificaciones/proveedores/notificaciones-proveedor.dart';
import '../modulos/inicio/pantallas/acerca-de-pantalla.dart';


class BarraSuperiorBumand extends ConsumerWidget implements PreferredSizeWidget {
  final String titulo;
  final String? subtitulo;
  final List<Widget>? acciones_adicionales;
  final bool mostrar_logos;
  final bool mostrar_perfil;
  final bool mostrar_versiculo_diario;
  final VoidCallback? alTocarLogo;

  const BarraSuperiorBumand({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acciones_adicionales,
    this.mostrar_logos = true,
    this.mostrar_perfil = true,
    this.mostrar_versiculo_diario = true,
    this.alTocarLogo,
  });

  static void mostrarDialogoVersiculoDiario(BuildContext context) {
    final servicio = ColaDescargaBibliaServicio();
    List<VersiculoDiarioModelo> catalogo = [];
    int indiceActual = 0;
    bool cargando = true;
    String? error;
    bool iniciado = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, actualizarEstadoDialogo) {
          Future<void> cargarVersiculos() async {
            actualizarEstadoDialogo(() {
              cargando = true;
              error = null;
            });
            try {
              final lista = await servicio.obtenerCatalogoVersiculos();
              if (!ctx.mounted) return;
              actualizarEstadoDialogo(() {
                catalogo = lista;
                indiceActual = lista.length > 1
                    ? math.Random().nextInt(lista.length)
                    : 0;
                cargando = false;
              });
            } catch (_) {
              if (!ctx.mounted) return;
              actualizarEstadoDialogo(() {
                cargando = false;
                error = 'No se pudo obtener el versículo diario desde el servidor.';
              });
            }
          }

          if (!iniciado) {
            iniciado = true;
            Future.microtask(cargarVersiculos);
          }

          final versiculo = catalogo.isNotEmpty ? catalogo[indiceActual] : null;

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabecera institucional Diaconía FRIF-IFD
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                    decoration: const BoxDecoration(
                      gradient: _DEGRADADO_DIACONIA,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Versículo Bíblico Diario",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Reina-Valera 1960 · Diaconía FRIF-IFD",
                                style: TextStyle(
                                  color: Color(0xFFD6F1F7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                          tooltip: "Cerrar",
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),

                  // Cuerpo con Versículo, Referencia y Reflexión Diaconal
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: cargando
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : (error != null || versiculo == null)
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.cloud_off_rounded,
                                        size: 36,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        error ?? 'Sin versículo disponible.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF475569),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      OutlinedButton.icon(
                                        onPressed: cargarVersiculos,
                                        icon: const Icon(Icons.refresh_rounded, size: 16),
                                        label: const Text('Reintentar'),
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Chip de Tema
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 13,
                                  color: BumandColores.AZUL_DIACONIA,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  versiculo.tema,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: BumandColores.AZUL_DIACONIA,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Referencia bíblica destacada
                          Row(
                            children: [
                              const Icon(
                                Icons.bookmark_added_rounded,
                                size: 18,
                                color: BumandColores.AZUL_DIACONIA,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                versiculo.cita,
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w900,
                                  color: BumandColores.AZUL_DIACONIA,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Texto Bíblico RVR1960
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.format_quote_rounded,
                                  color: BumandColores.AZUL_DIACONIA,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    versiculo.texto,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.45,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF1E293B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Reflexión Diaconal formativa
                          if (versiculo.reflexion_diaconal.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.lightbulb_outline_rounded,
                                    size: 18,
                                    color: Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Reflexión Diaconal",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFB45309),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          versiculo.reflexion_diaconal,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            height: 1.35,
                                            color: Color(0xFF78350F),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Botones de Acción
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: catalogo.length <= 1
                                ? cargarVersiculos
                                : () {
                                    actualizarEstadoDialogo(() {
                                      int nuevo;
                                      do {
                                        nuevo = math.Random().nextInt(catalogo.length);
                                      } while (catalogo.length > 1 && nuevo == indiceActual);
                                      indiceActual = nuevo;
                                    });
                                  },
                            icon: const Text("🎲", style: TextStyle(fontSize: 13)),
                            label: const Text(
                              "Otro versículo al azar",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: BumandColores.AZUL_DIACONIA,
                              side: const BorderSide(color: BumandColores.AZUL_DIACONIA),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: BumandColores.AZUL_DIACONIA,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          ),
                          child: const Text(
                            "Cerrar",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostrarDialogoVersiculoDiarioAzar(BuildContext context) {
    mostrarDialogoVersiculoDiario(context);
  }

  Widget _construirBotonVersiculoDiario(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _mostrarDialogoVersiculoDiarioAzar(context),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 13,
                color: BumandColores.AZUL_DIACONIA,
              ),
              SizedBox(width: 3.5),
              Text(
                "Versículo Diario",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: BumandColores.AZUL_DIACONIA,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                            "Principal: ${usuario?.correo ?? ''}",
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
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: const BoxConstraints(
        maxWidth: 580,
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.88,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
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
                              usuario?.nombre ?? "Sin sesión",
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: BumandColores.AZUL_DIACONIA,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              usuario?.correo ?? "",
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
                                (usuario?.rol ?? "").toUpperCase(),
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
                        color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.manage_accounts_rounded,
                        color: BumandColores.AZUL_DIACONIA,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      "Mi Perfil y Seguridad de Cuenta",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: BumandColores.NEGRO,
                      ),
                    ),
                    subtitle: const Text(
                      "Nombre, correo(s), contraseña y datos personales",
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MiPerfilPantalla()),
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
                      final navegador = Navigator.of(context, rootNavigator: true);
                      final notificador = ref.read(autenticacion_proveedor.notifier);
                      Navigator.of(ctx).pop();
                      try {
                        await notificador.cerrarSesion();
                      } finally {
                        navegador.pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const InicioSesionPantalla(),
                          ),
                          (route) => false,
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
    final bool puede_retroceder = Navigator.of(context).canPop();
    final bool mostrar_boton_versiculo = mostrar_versiculo_diario && !puede_retroceder;

    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 74,
      titleSpacing: mostrar_boton_versiculo ? 6 : NavigationToolbar.kMiddleSpacing,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: _DEGRADADO_DIACONIA),
      ),
      title: mostrar_boton_versiculo
          ? Row(
              children: [
                _construirBotonVersiculoDiario(context),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitulo != null)
                        Text(
                          subtitulo!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFFD6F1F7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitulo != null)
                  Text(
                    subtitulo!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
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
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SvgPicture.asset(
                  'assets/logos/logo-bumand-dorado-blanco.svg',
                  height: 20,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Logo Diaconía IFD oficial en cápsula blanca de alta visibilidad
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: SvgPicture.asset(
              'assets/logos/logo-diaconia-color.svg',
              height: 14,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 2),
        ],
        if (mostrar_perfil) ...[
          Consumer(
            builder: (context, ref_campana, _) {
              final conteo_async = ref_campana.watch(notificaciones_conteo_proveedor);
              final conteo_no_leidas = conteo_async.asData?.value ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 20),
                    tooltip: "Notificaciones y códigos",
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificacionesPantalla(),
                        ),
                      );
                    },
                  ),
                  if (conteo_no_leidas > 0)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            conteo_no_leidas > 99 ? '99+' : '$conteo_no_leidas',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 22),
            tooltip: "Mi perfil y sesión",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
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

