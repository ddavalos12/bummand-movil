import 'package:flutter/material.dart';

import '../nucleo/tema/colores.dart';

class EstadoVacioWidget extends StatelessWidget {
  final String titulo;
  final String? mensaje;
  final IconData icono;
  final Widget? ilustracion_personalizada;
  final String? texto_boton_accion;
  final VoidCallback? alPresionarAccion;
  final EdgeInsetsGeometry padding;

  const EstadoVacioWidget({
    super.key,
    required this.titulo,
    this.mensaje,
    this.icono = Icons.inbox_rounded,
    this.ilustracion_personalizada,
    this.texto_boton_accion,
    this.alPresionarAccion,
    this.padding = const EdgeInsets.all(32.0),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ilustracion_personalizada ??
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          BumandColores.AZUL_DIACONIA.withValues(alpha: 0.18),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icono,
                    size: 42,
                    color: BumandColores.AZUL_DIACONIA,
                  ),
                ),
            const SizedBox(height: 18),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: BumandColores.NEGRO,
                letterSpacing: -0.2,
              ),
            ),
            if (mensaje != null) ...[
              const SizedBox(height: 8),
              Text(
                mensaje!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ],
            if (texto_boton_accion != null && alPresionarAccion != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: alPresionarAccion,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(texto_boton_accion!),
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
