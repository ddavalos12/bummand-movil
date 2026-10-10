import 'dart:ui';
import 'package:flutter/material.dart';

class ElementoComando {
  final IconData icono;
  final String etiqueta;

  const ElementoComando({
    required this.icono,
    required this.etiqueta,
  });
}

/// Skipper UI — Barra de Comandos Flotante Táctil (Floating Action Dock)
/// Barra flotante inferior de acceso rápido con cristal esmerilado, pastilla indicadora
/// y micro-animación al toque.
class BarraComandosFlotante extends StatelessWidget {
  final int indice_seleccionado;
  final ValueChanged<int> alSeleccionar;
  final List<ElementoComando> elementos;

  const BarraComandosFlotante({
    super.key,
    required this.indice_seleccionado,
    required this.alSeleccionar,
    required this.elementos,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: const Color(0xFFE3DCCB),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16.0,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(elementos.length, (i) {
              final elem = elementos[i];
              final esta_activo = indice_seleccionado == i;

              return GestureDetector(
                onTap: () => alSeleccionar(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: esta_activo
                        ? const Color(0x2817B4C4)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16.0),
                    border: esta_activo
                        ? Border.all(
                            color: const Color(0x6617B4C4),
                            width: 1.0,
                          )
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        elem.icono,
                        size: 20.0,
                        color: esta_activo
                            ? const Color(0xFF063A6B)
                            : const Color(0xFF8A9BA4),
                      ),
                      if (esta_activo) ...[
                        const SizedBox(width: 6.0),
                        Text(
                          elem.etiqueta,
                          style: const TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF063A6B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
