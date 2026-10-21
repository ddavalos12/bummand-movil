import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../widgets-comunes/tarjeta-spotlight.dart';
import '../../../widgets-comunes/boton-juicy.dart';
import '../proveedores/autenticacion-proveedor.dart';
import '../verificacion_post_login_vista.dart';
import '../../inicio/pantallas/inicio-pantalla.dart';
import 'registro-pantalla.dart';

class InicioSesionPantalla extends ConsumerStatefulWidget {
  const InicioSesionPantalla({super.key});

  @override
  ConsumerState<InicioSesionPantalla> createState() =>
      _InicioSesionPantallaState();
}

class _InicioSesionPantallaState extends ConsumerState<InicioSesionPantalla>
    with SingleTickerProviderStateMixin {
  final _correo_controlador = TextEditingController();
  final _contrasena_controlador = TextEditingController();
  bool _ocultar_contrasena = true;
  String? _error_local;
  late final AnimationController _animacion_controlador;

  @override
  void initState() {
    super.initState();
    _animacion_controlador = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _animacion_controlador.dispose();
    _correo_controlador.dispose();
    _contrasena_controlador.dispose();
    super.dispose();
  }

  void _iniciarSesion() async {
    final correo = _correo_controlador.text.trim();
    final contrasena = _contrasena_controlador.text;

    if (correo.isEmpty || contrasena.isEmpty) {
      setState(() {
        _error_local = "Por favor ingresa tu correo y contraseña";
      });
      return;
    }

    setState(() {
      _error_local = null;
    });

    final exito = await ref
        .read(autenticacion_proveedor.notifier)
        .iniciarSesion(correo, contrasena);

    if (exito && mounted) {
      final repo = ref.read(autenticacion_repositorio_proveedor);
      final estado_confirmacion = await repo.consultarEstadoConfirmacion();

      if (!mounted) return;

      final bool debe_confirmar =
          estado_confirmacion.exito &&
          (estado_confirmacion.datos?['debe_confirmar'] == true);

      if (debe_confirmar) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const VerificacionPostLoginVista(),
          ),
          (_) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const InicioPantalla(),
          ),
          (_) => false,
        );
      }
    }
  }

  Widget _construirCampoTexto({
    required TextEditingController controlador,
    required String texto_marcador,
    required IconData icono,
    bool es_contrasena = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: controlador,
        obscureText: es_contrasena && _ocultar_contrasena,
        keyboardType: es_contrasena
            ? TextInputType.text
            : TextInputType.emailAddress,
        style: const TextStyle(
          fontSize: 14.5,
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: texto_marcador,
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14.5,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 8, top: 7, bottom: 7, right: 12),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icono,
              color: const Color(0xFF0284C7),
              size: 19,
            ),
          ),
          suffixIcon: es_contrasena
              ? IconButton(
                  icon: Icon(
                    _ocultar_contrasena
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _ocultar_contrasena = !_ocultar_contrasena),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado_auth = ref.watch(autenticacion_proveedor);
    final error_visible = _error_local ?? estado_auth.error;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Capas decorativas celestes en movimiento continuo
          AnimatedBuilder(
            animation: _animacion_controlador,
            builder: (context, _) {
              final progreso = _animacion_controlador.value;
              final fase = progreso * 2 * math.pi;

              return Stack(
                children: [
                  // 1. Mancha orgánica celeste superior izquierda
                  Positioned(
                    top: -50 + 12 * math.sin(fase),
                    left: -50 + 12 * math.cos(fase),
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF38BDF8).withValues(alpha: 0.65),
                            const Color(0xFF0284C7).withValues(alpha: 0.35),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // 2. Estructura geométrica isométrica 3D superior derecha
                  Positioned(
                    top: 25 + 8 * math.sin(fase),
                    right: 10 + 5 * math.cos(fase),
                    child: Transform.rotate(
                      angle: 0.04 * math.sin(fase),
                      child: CustomPaint(
                        size: const Size(120, 120),
                        painter: PintorCuboIsometrico(
                          color: const Color(0xFF7DD3FC).withValues(alpha: 0.85),
                          progreso: progreso,
                        ),
                      ),
                    ),
                  ),

                  // 3. Ondas y curvas celestes inferiores en flujo líquido
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 190,
                    child: CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, 190),
                      painter: PintorOndasCelestes(progreso: progreso),
                    ),
                  ),
                ],
              );
            },
          ),

          // Tarjeta flotante central
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: TarjetaSpotlight(
                  radio_borde: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                  color_fondo: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Encabezado con Logos Institucionales
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF063A6B).withValues(alpha: 0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Hero(
                                tag: 'hero-logo-bumand',
                                child: SvgPicture.asset(
                                  'assets/logos/logo-bumand.svg',
                                  height: 56,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Container(
                                height: 44,
                                width: 1.5,
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                color: const Color(0xFFE2E8F0),
                              ),
                              Hero(
                                tag: 'hero-logo-diaconia',
                                child: SvgPicture.asset(
                                  'assets/logos/logo-diaconia.svg',
                                  height: 50,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Título: Bienvenido ("Bienve" oscuro, "nido" celeste)
                      Center(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                            children: [
                              TextSpan(
                                text: 'Bienve',
                                style: TextStyle(color: Color(0xFF0F172A)),
                              ),
                              TextSpan(
                                text: 'nido',
                                style: TextStyle(color: Color(0xFF0284C7)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      const Text(
                        "Portal del Estudiante Becario",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),

                      Center(
                        child: Container(
                          width: 44,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "Acceso móvil exclusivo para estudiantes becarios",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 22),

                      // Campo Correo electrónico
                      _construirCampoTexto(
                        controlador: _correo_controlador,
                        texto_marcador: "Correo electrónico",
                        icono: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),

                      // Campo Contraseña
                      _construirCampoTexto(
                        controlador: _contrasena_controlador,
                        texto_marcador: "Contraseña",
                        icono: Icons.lock_outline,
                        es_contrasena: true,
                      ),
                      const SizedBox(height: 18),

                      // Alerta de error reactiva
                      if (error_visible != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  error_visible,
                                  style: TextStyle(
                                    color: Colors.red.shade800,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Botón Ingresar con rebote táctil (BotonJuicy)
                      BotonJuicy(
                        al_presionar:
                            estado_auth.cargando ? null : _iniciarSesion,
                        cargando: estado_auth.cargando,
                        color_fondo: const Color(0xFFF59E0B),
                        color_texto: Colors.white,
                        radio_borde: 26,
                        alto: 50,
                        icono: Icons.arrow_forward_rounded,
                        texto_o_hijo: const Text(
                          "Ingresar",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Enlace a Registro
                      Center(
                        child: GestureDetector(
                          onTap: estado_auth.cargando
                              ? null
                              : () {
                                  ref
                                      .read(autenticacion_proveedor.notifier)
                                      .limpiarError();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const RegistroPantalla(),
                                    ),
                                  );
                                },
                          child: const Text(
                            "¿Ya estás en la lista de becarios? Crea tu cuenta",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0284C7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Separador con pez cristiano institucional
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(
                              color: Color(0xFFE2E8F0),
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: CustomPaint(
                              size: const Size(26, 13),
                              painter: PintorPezCristiano(
                                color: const Color(0xFFFDBC58),
                                grosor: 1.8,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(
                              color: Color(0xFFE2E8F0),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Lemas institucionales
                      const Text(
                        "AMOR, LEALTAD Y SACRIFICIO",
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        "BUMAND AL SERVICIO",
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PintorPezCristiano extends CustomPainter {
  final Color color;
  final double grosor;

  const PintorPezCristiano({
    this.color = const Color(0xFFFDBC58),
    this.grosor = 1.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = grosor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(0, h * 0.5);
    path.cubicTo(w * 0.35, -h * 0.15, w * 0.8, h * 0.2, w, h * 0.85);

    path.moveTo(0, h * 0.5);
    path.cubicTo(w * 0.35, h * 1.15, w * 0.8, h * 0.8, w, h * 0.15);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PintorCuboIsometrico extends CustomPainter {
  final Color color;
  final double progreso;

  const PintorCuboIsometrico({
    required this.color,
    required this.progreso,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paint_interno = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final radio = size.width * 0.42;

    List<Offset> vertices = [];
    for (int i = 0; i < 6; i++) {
      final angulo = (30 + i * 60) * math.pi / 180;
      vertices.add(Offset(
        cx + radio * math.cos(angulo),
        cy + radio * math.sin(angulo),
      ));
    }

    final hex_path = Path()..moveTo(vertices[0].dx, vertices[0].dy);
    for (int i = 1; i < 6; i++) {
      hex_path.lineTo(vertices[i].dx, vertices[i].dy);
    }
    hex_path.close();
    canvas.drawPath(hex_path, paint);

    final centro = Offset(cx, cy);
    canvas.drawLine(centro, vertices[1], paint);
    canvas.drawLine(centro, vertices[3], paint);
    canvas.drawLine(centro, vertices[5], paint);

    final radio_pequeno = radio * 0.65;
    List<Offset> vertices_p = [];
    for (int i = 0; i < 6; i++) {
      final angulo = (30 + i * 60) * math.pi / 180;
      vertices_p.add(Offset(
        cx + radio_pequeno * math.cos(angulo),
        cy + radio_pequeno * math.sin(angulo),
      ));
    }
    final hex_path_p = Path()..moveTo(vertices_p[0].dx, vertices_p[0].dy);
    for (int i = 1; i < 6; i++) {
      hex_path_p.lineTo(vertices_p[i].dx, vertices_p[i].dy);
    }
    hex_path_p.close();
    canvas.drawPath(hex_path_p, paint_interno);

    canvas.drawLine(centro, vertices_p[1], paint_interno);
    canvas.drawLine(centro, vertices_p[3], paint_interno);
    canvas.drawLine(centro, vertices_p[5], paint_interno);
  }

  @override
  bool shouldRepaint(covariant PintorCuboIsometrico oldDelegate) =>
      oldDelegate.progreso != progreso;
}

class PintorOndasCelestes extends CustomPainter {
  final double progreso;

  const PintorOndasCelestes({required this.progreso});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final fase = progreso * 2 * math.pi;

    final paint_trasera = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF38BDF8).withValues(alpha: 0.30),
          const Color(0xFF0284C7).withValues(alpha: 0.18),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path_trasera = Path();
    path_trasera.moveTo(0, h * 0.45 + 12 * math.sin(fase));
    path_trasera.cubicTo(
      w * 0.3,
      h * 0.25 + 16 * math.cos(fase),
      w * 0.65,
      h * 0.70 + 14 * math.sin(fase + 1.0),
      w,
      h * 0.50 + 10 * math.cos(fase + 0.5),
    );
    path_trasera.lineTo(w, h);
    path_trasera.lineTo(0, h);
    path_trasera.close();
    canvas.drawPath(path_trasera, paint_trasera);

    final paint_delantera = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF0284C7),
          Color(0xFF06B6D4),
          Color(0xFF0EA5E9),
        ],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final path_delantera = Path();
    path_delantera.moveTo(0, h * 0.60 + 10 * math.cos(fase));
    path_delantera.cubicTo(
      w * 0.35,
      h * 0.40 + 14 * math.sin(fase),
      w * 0.70,
      h * 0.85 + 12 * math.cos(fase),
      w,
      h * 0.65 + 8 * math.sin(fase + 0.8),
    );
    path_delantera.lineTo(w, h);
    path_delantera.lineTo(0, h);
    path_delantera.close();
    canvas.drawPath(path_delantera, paint_delantera);
  }

  @override
  bool shouldRepaint(covariant PintorOndasCelestes oldDelegate) =>
      oldDelegate.progreso != progreso;
}
