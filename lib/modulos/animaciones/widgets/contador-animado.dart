import 'package:flutter/material.dart';

/// Watermelon UI — Contador Numérico Animado (Bouncy Counter)
/// Realiza un conteo elástico ascendente suave para métricas, horas y viáticos.
class ContadorAnimado extends StatefulWidget {
  final double valor;
  final String prefijo;
  final String sufijo;
  final int decimales;
  final Duration duracion;
  final TextStyle? estilo;

  const ContadorAnimado({
    super.key,
    required this.valor,
    this.prefijo = '',
    this.sufijo = '',
    this.decimales = 0,
    this.duracion = const Duration(milliseconds: 1200),
    this.estilo,
  });

  @override
  State<ContadorAnimado> createState() => _ContadorAnimadoState();
}

class _ContadorAnimadoState extends State<ContadorAnimado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  late Animation<double> _animacion;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(
      vsync: this,
      duration: widget.duracion,
    );
    _animacion = Tween<double>(begin: 0.0, end: widget.valor).animate(
      CurvedAnimation(parent: _controlador, curve: Curves.easeOutExpo),
    );
    _controlador.forward();
  }

  @override
  void didUpdateWidget(covariant ContadorAnimado oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valor != widget.valor) {
      _animacion = Tween<double>(
        begin: oldWidget.valor,
        end: widget.valor,
      ).animate(
        CurvedAnimation(parent: _controlador, curve: Curves.easeOutExpo),
      );
      _controlador.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animacion,
      builder: (context, child) {
        final texto = widget.decimales > 0
            ? _animacion.value.toStringAsFixed(widget.decimales)
            : _animacion.value.round().toString();

        return Text(
          '${widget.prefijo}$texto${widget.sufijo}',
          style: widget.estilo,
        );
      },
    );
  }
}
