import 'package:flutter/material.dart';

/// Motion Primitives — Elemento Escalonado (Stagger Item)
/// Anima la entrada de elementos con fade-in y slide-up suave con retardo progresivo.
class ElementoEscalonado extends StatefulWidget {
  final Widget hijo;
  final int indice;
  final Duration retardo_base;
  final Duration retardo_paso;
  final Duration duracion;

  const ElementoEscalonado({
    super.key,
    required this.hijo,
    this.indice = 0,
    this.retardo_base = const Duration(milliseconds: 60),
    this.retardo_paso = const Duration(milliseconds: 70),
    this.duracion = const Duration(milliseconds: 400),
  });

  @override
  State<ElementoEscalonado> createState() => _ElementoEscalonadoState();
}

class _ElementoEscalonadoState extends State<ElementoEscalonado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  late final Animation<double> _opacidad;
  late final Animation<Offset> _desplazamiento;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(
      vsync: this,
      duration: widget.duracion,
    );

    final curva = CurvedAnimation(
      parent: _controlador,
      curve: Curves.easeOutCubic,
    );

    _opacidad = Tween<double>(begin: 0.0, end: 1.0).animate(curva);
    _desplazamiento = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(curva);

    final retardo = widget.retardo_base + (widget.retardo_paso * widget.indice);
    Future.delayed(retardo, () {
      if (mounted) {
        _controlador.forward();
      }
    });
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacidad,
      child: SlideTransition(
        position: _desplazamiento,
        child: widget.hijo,
      ),
    );
  }
}
