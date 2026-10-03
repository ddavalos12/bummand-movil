import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../nucleo/tema/colores.dart';
import '../modulos/autenticacion/proveedores/autenticacion-proveedor.dart';
import '../modulos/autenticacion/pantallas/inicio-sesion-pantalla.dart';

class BarraSuperiorBumand extends ConsumerWidget implements PreferredSizeWidget {
  final String titulo;
  final String? subtitulo;
  final List<Widget>? acciones_adicionales;
  final bool mostrar_logos;
  final bool mostrar_perfil;

  const BarraSuperiorBumand({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acciones_adicionales,
    this.mostrar_logos = true,
    this.mostrar_perfil = true,
  });

  static const _DEGRADADO_DIACONIA = LinearGradient(
    colors: [BumandColores.AZUL_DIACONIA, BumandColores.TURQUESA_DIACONIA],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Size get preferredSize => const Size.fromHeight(74);

  void _mostrarDialogoPerfil(BuildContext context, WidgetRef ref) {
    final estado_auth = ref.read(autenticacion_proveedor);
    final usuario = estado_auth.usuario;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
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
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
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
          // Logo BUMAND Blanco oficial
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 22),
            child: SvgPicture.asset(
              'assets/logos/logo-bumand-blanco.svg',
              height: 26,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 8),
          // Logo Diaconía IFD oficial en cápsula blanca de alta visibilidad
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: SvgPicture.asset(
              'assets/logos/logo-diaconia.svg',
              height: 16,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
        ],
        if (mostrar_perfil)
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 24),
            tooltip: "Mi perfil y sesión",
            onPressed: () => _mostrarDialogoPerfil(context, ref),
          ),
        const SizedBox(width: 4),
      ],
    );
  }
}
