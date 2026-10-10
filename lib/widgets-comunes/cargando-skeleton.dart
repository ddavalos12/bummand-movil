import 'package:flutter/material.dart';

class CargandoSkeleton extends StatefulWidget {
  final double? ancho;
  final double alto;
  final BorderRadius? radio_borde;
  final EdgeInsetsGeometry? margen;

  const CargandoSkeleton({
    super.key,
    this.ancho,
    this.alto = 20,
    this.radio_borde,
    this.margen,
  });

  factory CargandoSkeleton.linea({
    Key? key,
    double ancho = double.infinity,
    double alto = 14,
    BorderRadius? radio_borde,
  }) {
    return CargandoSkeleton(
      key: key,
      ancho: ancho,
      alto: alto,
      radio_borde: radio_borde ?? BorderRadius.circular(6),
    );
  }

  factory CargandoSkeleton.tarjeta({
    Key? key,
    double alto = 100,
    BorderRadius? radio_borde,
    EdgeInsetsGeometry margen = const EdgeInsets.only(bottom: 12),
  }) {
    return CargandoSkeleton(
      key: key,
      ancho: double.infinity,
      alto: alto,
      radio_borde: radio_borde ?? BorderRadius.circular(16),
      margen: margen,
    );
  }

  static Widget lista({
    int cantidad = 4,
    double alto_item = 92,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return ListView.builder(
      padding: padding,
      itemCount: cantidad,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, _) => CargandoSkeleton.tarjeta(
        alto: alto_item,
      ),
    );
  }

  @override
  State<CargandoSkeleton> createState() => _CargandoSkeletonState();
}

class _CargandoSkeletonState extends State<CargandoSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador_pulso;
  late final Animation<double> _animacion_opacidad;

  @override
  void initState() {
    super.initState();
    _controlador_pulso = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _animacion_opacidad = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(
        parent: _controlador_pulso,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controlador_pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radio = widget.radio_borde ?? BorderRadius.circular(12);

    return AnimatedBuilder(
      animation: _animacion_opacidad,
      builder: (context, child) {
        return Container(
          width: widget.ancho,
          height: widget.alto,
          margin: widget.margen,
          decoration: BoxDecoration(
            color: const Color(0xFF94A3B8).withValues(
              alpha: _animacion_opacidad.value * 0.35,
            ),
            borderRadius: radio,
          ),
        );
      },
    );
  }
}
