import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../nucleo/tema/colores.dart';

class BotonJuicy extends StatefulWidget {
  final Widget? hijo;
  final String? texto;
  final IconData? icono;
  final VoidCallback? alPresionar;
  final Color? color_fondo;
  final Color? color_texto;
  final double? ancho;
  final double? alto;
  final BorderRadius? radio_borde;
  final bool esta_cargando;
  final bool deshabilitado;
  final EdgeInsetsGeometry padding;

  const BotonJuicy({
    super.key,
    this.hijo,
    this.texto,
    this.icono,
    this.alPresionar,
    this.color_fondo,
    this.color_texto,
    this.ancho,
    this.alto = 52,
    this.radio_borde,
    this.esta_cargando = false,
    this.deshabilitado = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
      duration: const Duration(milliseconds: 140),
      reverseDuration: const Duration(milliseconds: 280),
    );
    _animacion_escala = Tween<double>(begin: 1.0, end: 0.92).animate(
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

  void _manejarToqueAbajo(TapDownDetails _) {
    if (widget.deshabilitado || widget.esta_cargando || widget.alPresionar == null) {
      return;
    }
    HapticFeedback.lightImpact();
    _controlador_escala.forward();
  }

  void _manejarToqueArriba(TapUpDetails _) {
    if (widget.deshabilitado || widget.esta_cargando || widget.alPresionar == null) {
      return;
    }
    HapticFeedback.mediumImpact();
    _controlador_escala.reverse();
    widget.alPresionar?.call();
  }

  void _manejarToqueCancelado() {
    _controlador_escala.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final fondo = widget.deshabilitado
        ? Colors.grey.shade300
        : (widget.color_fondo ?? BumandColores.AZUL_DIACONIA);
    final texto_color = widget.deshabilitado
        ? Colors.grey.shade500
        : (widget.color_texto ?? Colors.white);
    final radio = widget.radio_borde ?? BorderRadius.circular(14);

    return ScaleTransition(
      scale: _animacion_escala,
      child: GestureDetector(
        onTapDown: _manejarToqueAbajo,
        onTapUp: _manejarToqueArriba,
        onTapCancel: _manejarToqueCancelado,
        child: Container(
          width: widget.ancho,
          height: widget.alto,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: radio,
            boxShadow: widget.deshabilitado
                ? null
                : [
                    BoxShadow(
                      color: fondo.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: widget.esta_cargando
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: texto_color,
                    ),
                  )
                : widget.hijo ??
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icono != null) ...[
                          Icon(widget.icono, color: texto_color, size: 20),
                          const SizedBox(width: 8),
                        ],
                        if (widget.texto != null)
                          Text(
                            widget.texto!,
                            style: TextStyle(
                              color: texto_color,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}
