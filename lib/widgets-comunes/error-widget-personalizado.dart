import 'package:flutter/material.dart';

import '../nucleo/errores/codigos-error.dart';
import '../nucleo/errores/error-bumand.dart';
import '../nucleo/tema/colores.dart';

class ErrorWidgetPersonalizado extends StatelessWidget {
  final ErrorBumand? error_bumand;
  final String? codigo_error;
  final String? mensaje;
  final String? sugerencia;
  final List<String>? detalles;
  final VoidCallback? alReintentar;
  final String texto_boton_reintentar;
  final bool mostrar_icono;
  final EdgeInsetsGeometry padding;

  const ErrorWidgetPersonalizado({
    super.key,
    this.error_bumand,
    this.codigo_error,
    this.mensaje,
    this.sugerencia,
    this.detalles,
    this.alReintentar,
    this.texto_boton_reintentar = 'Reintentar operación',
    this.mostrar_icono = true,
    this.padding = const EdgeInsets.all(24.0),
  });

  @override
  Widget build(BuildContext context) {
    final codigo = error_bumand?.codigo_error ?? codigo_error ?? CodigosError.ERR_9001;
    final mensaje_mostrar = mensaje ??
        error_bumand?.mensaje ??
        CodigosError.obtenerDescripcion(codigo);
    final sugerencia_mostrar = sugerencia ??
        error_bumand?.sugerencia ??
        CodigosError.obtenerSugerencia(codigo);
    final lista_detalles = detalles ?? error_bumand?.detalles ?? const [];

    final es_error_red = codigo == CodigosError.ERR_5001;
    final icono_principal = es_error_red
        ? Icons.wifi_off_rounded
        : Icons.warning_amber_rounded;

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (mostrar_icono) ...[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Icon(
                  icono_principal,
                  size: 38,
                  color: const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF87171)),
              ),
              child: Text(
                codigo,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB91C1C),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              mensaje_mostrar,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BumandColores.NEGRO,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              sugerencia_mostrar,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.35,
              ),
            ),
            if (lista_detalles.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final d in lista_detalles)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '• ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Expanded(
                              child: Text(
                                d,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (alReintentar != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: alReintentar,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(texto_boton_reintentar),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BumandColores.AZUL_DIACONIA,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
