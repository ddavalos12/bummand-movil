import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../nucleo/servicios/cola-offline-servicio.dart';
import '../nucleo/tema/colores.dart';

class BannerConexion extends ConsumerStatefulWidget {
  final bool? sin_conexion_forzado;
  final int? conteo_forzado;
  final Future<void> Function()? alForzarSincronizacion;

  const BannerConexion({
    super.key,
    this.sin_conexion_forzado,
    this.conteo_forzado,
    this.alForzarSincronizacion,
  });

  @override
  ConsumerState<BannerConexion> createState() => _BannerConexionState();
}

class _BannerConexionState extends ConsumerState<BannerConexion> {
  bool _sincronizando = false;

  Future<void> _ejecutarSincronizacion() async {
    if (_sincronizando) return;
    setState(() => _sincronizando = true);

    try {
      if (widget.alForzarSincronizacion != null) {
        await widget.alForzarSincronizacion!();
      } else {
        final servicio = ref.read(cola_offline_servicio_proveedor);
        final sincronizados = await servicio.sincronizarPendientes();
        ref.invalidate(cola_offline_conteo_proveedor);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                sincronizados > 0
                    ? 'Se sincronizaron $sincronizados registros pendientes.'
                    : 'Sin registros pendientes de sincronización.',
              ),
              backgroundColor: BumandColores.AZUL_DIACONIA,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _sincronizando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hay_red_sistema = ref.watch(hay_conexion_red_proveedor);
    final conteo_async = ref.watch(cola_offline_conteo_proveedor);

    final bool sin_conexion =
        widget.sin_conexion_forzado ?? (!hay_red_sistema);
    final int conteo_pendientes =
        widget.conteo_forzado ?? (conteo_async.value ?? 0);

    final bool debe_mostrarse = sin_conexion || conteo_pendientes > 0;

    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      child: debe_mostrarse
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFF59E0B), width: 1.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE68A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.cloud_off_rounded,
                            size: 20,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Modo sin conexión — Tus marcaciones se guardan localmente y se sincronizarán al recuperar señal',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF92400E),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD97706),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$conteo_pendientes en cola',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  TextButton.icon(
                                    onPressed: _sincronizando
                                        ? null
                                        : _ejecutarSincronizacion,
                                    icon: _sincronizando
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFFB45309),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.sync_rounded,
                                            size: 16,
                                            color: Color(0xFF92400E),
                                          ),
                                    label: Text(
                                      _sincronizando
                                          ? 'Sincronizando...'
                                          : 'Forzar sincronización',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF92400E),
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
