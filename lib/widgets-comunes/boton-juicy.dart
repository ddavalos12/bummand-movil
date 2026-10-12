import 'package:flutter/material.dart';

import '../nucleo/tema/colores.dart';

/// Botón con rebote táctil y contracción amortiguada (Watermelon UI - Juicy Button)
/// Al presionar se contrae ligeramente a escala ~0.94 y regresa con física elástica amortiguada.
class BotonJuicy extends StatefulWidget {
  final VoidCallback? al_presionar;
  final Widget texto_o_hijo;
  final Color color_fondo;
  final Color color_texto;
  final double alto;
  final double radio_borde;
  final bool cargando;
  final IconData? icono;

  const BotonJuicy({
    super.key,
    required this.al_presionar,
    required this.texto_o_hijo,
    this.color_fondo = BumandColores.NARANJA,
    this.color_texto = BumandColores.NEGRO,
    this.alto = 52.0,
    this.radio_borde = 26.0,
    this.cargando = false,
    this.icono,
  });

  @override
  State<BotonJuicy> createState() => _BotonJuicyState();
}

class _BotonJuicyState extends State<BotonJuicy>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador_escala;
  late final Animation<double> _animacion_escala;

  @override
  void initState() {
    super.initState();
    _controlador_escala = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 300),
    );

    _animacion_escala = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(
        parent: _controlador_escala,
        curve: Curves.easeInOut,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controlador_escala.dispose();
    super.dispose();
  }

  void _manejarTapDown(TapDownDetails _) {
    if (widget.al_presionar == null || widget.cargando) return;
    _controlador_escala.forward();
  }

  void _manejarTapUp(TapUpDetails _) {
    if (widget.al_presionar == null || widget.cargando) return;
    _controlador_escala.reverse();
  }

  void _manejarTapCancel() {
    if (widget.al_presionar == null || widget.cargando) return;
    _controlador_escala.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final habilitado = widget.al_presionar != null && !widget.cargando;

    return AnimatedBuilder(
      animation: _animacion_escala,
      builder: (context, child) {
        return Transform.scale(
          scale: _animacion_escala.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _manejarTapDown,
        onTapUp: _manejarTapUp,
        onTapCancel: _manejarTapCancel,
        child: SizedBox(
          width: double.infinity,
          height: widget.alto,
          child: ElevatedButton(
            onPressed: habilitado ? widget.al_presionar : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color_fondo,
              foregroundColor: widget.color_texto,
              disabledBackgroundColor: widget.color_fondo.withValues(alpha: 0.5),
              elevation: habilitado ? 3 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(widget.radio_borde),
              ),
            ),
            child: widget.cargando
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(widget.color_texto),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      widget.texto_o_hijo,
                      if (widget.icono != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          widget.icono,
                          color: widget.color_texto,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
