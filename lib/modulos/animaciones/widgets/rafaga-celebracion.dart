import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../nucleo/tema/colores.dart';
import 'package:flutter/services.dart';

/// Watermelon UI — Ráfaga de Confeti y Celebración (Juicy UI)
/// Despliega una fiesta de confeti físico al confirmar asistencias,
/// pasajes liquidados o reflexiones devocionales guardadas.
class RafagaCelebracion extends StatefulWidget {
  final bool activo;
  final VoidCallback? alTerminar;
  final int cantidad_particulas;
  final Duration duracion;

  const RafagaCelebracion({
    super.key,
    required this.activo,
    this.alTerminar,
    this.cantidad_particulas = 50,
    this.duracion = const Duration(milliseconds: 2200),
  });

  @override
  State<RafagaCelebracion> createState() => _RafagaCelebracionState();
}

class _ParticulaConfeti {
  double x;
  double y;
  double vx;
  double vy;
  double ancho;
  double alto;
  Color color;
  double rotacion;
  double velocidad_rotacion;
  double opacidad = 1.0;

  _ParticulaConfeti({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.ancho,
    required this.alto,
    required this.color,
    required this.rotacion,
    required this.velocidad_rotacion,
  });
}

class _RafagaCelebracionState extends State<RafagaCelebracion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  final List<_ParticulaConfeti> _particulas = [];
  final math.Random _random = math.Random();

  static const List<Color> _COLORES_BUMAND = [
    BumandColores.amarilloRadiante,     // #FFB600 - Acento cálido y radiante
    BumandColores.azulCieloSuave,       // #00ABBD - Frescura y claridad
    BumandColores.azulMarinoProfundo,   // #007BBE - Primario institucional
    BumandColores.azulMarinoSecundario, // #035683 - Secundario institucional
    BumandColores.azulPetroleo,         // #00808E - Secundario verdoso
    BumandColores.blanco,               // #FFFFFF
  ];

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(
      vsync: this,
      duration: widget.duracion,
    );

    _controlador.addListener(() {
      final progreso = _controlador.value;
      for (final p in _particulas) {
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.25; // Gravedad
        p.vx *= 0.985; // Fricción
        p.rotacion += p.velocidad_rotacion;
        p.opacidad = math.max(0.0, 1.0 - progreso * 1.3);
      }
      setState(() {});
    });

    _controlador.addStatusListener((estado) {
      if (estado == AnimationStatus.completed) {
        _particulas.clear();
        widget.alTerminar?.call();
      }
    });

    if (widget.activo) {
      _iniciarRafaga();
    }
  }

  @override
  void didUpdateWidget(covariant RafagaCelebracion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activo && !oldWidget.activo) {
      _iniciarRafaga();
    }
  }

  void _iniciarRafaga() {
    HapticFeedback.mediumImpact();
    _particulas.clear();
    // Se generarán en el primer layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tamanio = MediaQuery.of(context).size;
      final centro_x = tamanio.width / 2;
      final centro_y = tamanio.height * 0.45;

      for (int i = 0; i < widget.cantidad_particulas; i++) {
        final angulo = _random.nextDouble() * math.pi * 2;
        final velocidad = 4.0 + _random.nextDouble() * 9.0;
        _particulas.add(
          _ParticulaConfeti(
            x: centro_x,
            y: centro_y,
            vx: math.cos(angulo) * velocidad + (_random.nextDouble() - 0.5) * 2,
            vy: math.sin(angulo) * velocidad - 3,
            ancho: 6.0 + _random.nextDouble() * 6.0,
            alto: 8.0 + _random.nextDouble() * 8.0,
            color: _COLORES_BUMAND[_random.nextInt(_COLORES_BUMAND.length)],
            rotacion: _random.nextDouble() * math.pi * 2,
            velocidad_rotacion: (_random.nextDouble() - 0.5) * 0.25,
          ),
        );
      }
      _controlador.forward(from: 0.0);
    });
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.activo && _particulas.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _PintorConfeti(particulas: _particulas),
      ),
    );
  }
}

class _PintorConfeti extends CustomPainter {
  final List<_ParticulaConfeti> particulas;

  const _PintorConfeti({required this.particulas});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particulas) {
      if (p.opacidad <= 0.0) continue;

      final pincel = Paint()
        ..color = p.color.withValues(alpha: p.opacidad)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(p.x, p.y);
      canvas.rotate(p.rotacion);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.ancho,
          height: p.alto,
        ),
        pincel,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PintorConfeti oldDelegate) {
    return true;
  }
}
