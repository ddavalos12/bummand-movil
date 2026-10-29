import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/tarjeta-spotlight.dart';
import '../../../widgets-comunes/boton-juicy.dart';
import '../proveedores/autenticacion-proveedor.dart';
import '../../inicio/pantallas/pantalla-inicio.dart';
import 'inicio-sesion-pantalla.dart';

class RegistroPantalla extends ConsumerStatefulWidget {
  const RegistroPantalla({super.key});

  @override
  ConsumerState<RegistroPantalla> createState() => _RegistroPantallaState();
}

class _RegistroPantallaState extends ConsumerState<RegistroPantalla>
    with SingleTickerProviderStateMixin {
  final _ci_controlador = TextEditingController();
  final _correo_controlador = TextEditingController();
  final _confirmar_correo_controlador = TextEditingController();
  final _contrasena_controlador = TextEditingController();
  final _confirmar_controlador = TextEditingController();

  bool _ocultar_contrasena = true;
  bool _ocultar_confirmar_contrasena = true;
  String? _error_validacion;
  late final AnimationController _animacion_controlador;

  bool _verificando_ci = false;
  String? _nombre_becario_verificado;
  bool _ci_verificado_exitoso = false;
  String _ultimo_ci_verificado = "";

  @override
  void initState() {
    super.initState();
    _animacion_controlador = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _ci_controlador.addListener(() {
      final ci = _ci_controlador.text.trim();
      if (ci.length >= 6 && !_verificando_ci && ci != _ultimo_ci_verificado) {
        _ultimo_ci_verificado = ci;
        _verificarCiEnVivo(ci);
      }
    });
  }

  Future<void> _verificarCiEnVivo(String ci) async {
    if (!RegExp(r'^\d{5,10}$').hasMatch(ci)) return;

    setState(() => _verificando_ci = true);
    final resultado =
        await ref.read(autenticacion_proveedor.notifier).verificarCi(ci);
    if (!mounted) return;

    setState(() {
      _verificando_ci = false;
      if (resultado.exito && resultado.datos != null) {
        final datos = resultado.datos!;
        final existe = datos['existe'] == true;
        final ya_registrado = datos['ya_registrado'] == true;
        final nombre = datos['nombre']?.toString();

        if (existe && !ya_registrado) {
          _nombre_becario_verificado = nombre;
          _ci_verificado_exitoso = true;
          _error_validacion = null;
        } else if (ya_registrado) {
          _nombre_becario_verificado = null;
          _ci_verificado_exitoso = false;
          _error_validacion =
              "El C.I. $ci ya tiene una cuenta activa. Inicia sesión directamente.";
        } else {
          _nombre_becario_verificado = null;
          _ci_verificado_exitoso = false;
          _error_validacion =
              "El C.I. $ci no figura en la nómina oficial. Consulta con Administración.";
        }
      }
    });
  }

  @override
  void dispose() {
    _animacion_controlador.dispose();
    _ci_controlador.dispose();
    _correo_controlador.dispose();
    _confirmar_correo_controlador.dispose();
    _contrasena_controlador.dispose();
    _confirmar_controlador.dispose();
    super.dispose();
  }

  String? _validar() {
    final ci = _ci_controlador.text.trim();
    final correo = _correo_controlador.text.trim();
    if (!RegExp(r'^\d{5,10}$').hasMatch(ci)) {
      return "Escribe tu CI solo con números, sin la extensión (ej. 9107373)";
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(correo)) {
      return "Revisa tu correo, no tiene un formato válido";
    }
    if (correo.toLowerCase() !=
        _confirmar_correo_controlador.text.trim().toLowerCase()) {
      return "Los correos no coinciden. Revisa que esté bien escrito.";
    }
    if (_contrasena_controlador.text.length < 6) {
      return "La contraseña debe tener al menos 6 caracteres";
    }
    if (_contrasena_controlador.text != _confirmar_controlador.text) {
      return "Las contraseñas no coinciden";
    }
    return null;
  }

  void _registrar() async {
    final error_local = _validar();
    if (error_local != null) {
      setState(() => _error_validacion = error_local);
      return;
    }
    setState(() => _error_validacion = null);

    final ci = _ci_controlador.text.trim();
    final correo = _correo_controlador.text.trim();
    final contrasena = _contrasena_controlador.text;

    final exito = await ref
        .read(autenticacion_proveedor.notifier)
        .registrar(ci, correo, contrasena);

    if (exito && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PantallaInicio()),
        (_) => false,
      );
    }
  }

  Widget _construirCampoTexto({
    required TextEditingController controlador,
    required String texto_marcador,
    required IconData icono,
    bool es_contrasena = false,
    bool? ocultar_texto,
    VoidCallback? al_alternar_visibilidad,
    bool deshabilitar_pegar = false,
    TextInputType tipo_teclado = TextInputType.text,
  }) {
    final bool esta_oculto = ocultar_texto ?? _ocultar_contrasena;
    return Container(
      decoration: BoxDecoration(
        color: BumandColores.fondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BumandColores.grisClaro,
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: controlador,
        obscureText: es_contrasena && esta_oculto,
        keyboardType: tipo_teclado,
        enableInteractiveSelection: !deshabilitar_pegar,
        autocorrect: false,
        style: const TextStyle(
          fontSize: 14.5,
          color: BumandColores.negro,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: texto_marcador,
          hintStyle: const TextStyle(
            color: BumandColores.grisMedio,
            fontSize: 14.5,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 8, top: 7, bottom: 7, right: 12),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: BumandColores.azulCieloSuave.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icono,
              color: BumandColores.azulMarinoProfundo,
              size: 19,
            ),
          ),
          suffixIcon: es_contrasena
              ? IconButton(
                  icon: Icon(
                    esta_oculto
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: BumandColores.grisMedio,
                    size: 20,
                  ),
                  onPressed: al_alternar_visibilidad ??
                      () => setState(
                            () => _ocultar_contrasena = !_ocultar_contrasena,
                          ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estado_auth = ref.watch(autenticacion_proveedor);
    final error_visible = _error_validacion ?? estado_auth.error;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Capas decorativas celestes en movimiento continuo (idénticas a Login)
          AnimatedBuilder(
            animation: _animacion_controlador,
            builder: (context, _) {
              final progreso = _animacion_controlador.value;
              final fase = progreso * 2 * math.pi;

              return Stack(
                children: [
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

          // Tarjeta flotante central unificada con InicioSesionPantalla
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: TarjetaSpotlight(
                  radio_borde: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                  color_fondo: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Fila superior con botón atrás y logos institucionales
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Color(0xFF0F172A),
                              ),
                              tooltip: "Volver",
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: BumandColores.azulMarinoSecundario
                                          .withValues(alpha: 0.05),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Hero(
                                        tag: 'hero-logo-bumand',
                                        child: SvgPicture.asset(
                                          'assets/logos/logo-bumand-oficial.svg',
                                          height: 38,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      Container(
                                        height: 32,
                                        width: 1.5,
                                        margin:
                                            const EdgeInsets.symmetric(horizontal: 10),
                                        color: BumandColores.grisClaro,
                                      ),
                                      Hero(
                                        tag: 'hero-logo-diaconia',
                                        child: SvgPicture.asset(
                                          'assets/logos/logo-diaconia-color.svg',
                                          height: 34,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Título bicolor idéntico en estilo a "Bienvenido"
                      Center(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                            children: [
                              TextSpan(
                                text: 'Crear mi ',
                                style: TextStyle(color: BumandColores.negro),
                              ),
                              TextSpan(
                                text: 'cuenta',
                                style: TextStyle(color: BumandColores.azulMarinoProfundo),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Activación de cuenta para becarios en nómina oficial",
                        style: TextStyle(
                          fontSize: 13,
                          color: BumandColores.textoSecundario,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Container(
                          width: 44,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: BumandColores.amarilloRadiante,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      _construirCampoTexto(
                        controlador: _ci_controlador,
                        texto_marcador: "Tu C.I. (sin extensión)",
                        icono: Icons.badge_outlined,
                        tipo_teclado: TextInputType.number,
                      ),
                      if (_verificando_ci) ...[
                        const SizedBox(height: 6),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Verificando carnet en la nómina...",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0284C7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_ci_verificado_exitoso && _nombre_becario_verificado != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF16A34A),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "¡Hola $_nombre_becario_verificado! Tu C.I. está registrado en nómina. Crea tus credenciales:",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF166534),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 11),
                      _construirCampoTexto(
                        controlador: _correo_controlador,
                        texto_marcador: "Tu correo electrónico real",
                        icono: Icons.email_outlined,
                        tipo_teclado: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 11),
                      _construirCampoTexto(
                        controlador: _confirmar_correo_controlador,
                        texto_marcador: "Confirma tu correo electrónico",
                        icono: Icons.mark_email_read_outlined,
                        tipo_teclado: TextInputType.emailAddress,
                        deshabilitar_pegar: true,
                      ),
                      const SizedBox(height: 11),
                      _construirCampoTexto(
                        controlador: _contrasena_controlador,
                        texto_marcador: "Elige una contraseña",
                        icono: Icons.lock_outline,
                        es_contrasena: true,
                        ocultar_texto: _ocultar_contrasena,
                        al_alternar_visibilidad: () => setState(
                          () => _ocultar_contrasena = !_ocultar_contrasena,
                        ),
                      ),
                      const SizedBox(height: 11),
                      _construirCampoTexto(
                        controlador: _confirmar_controlador,
                        texto_marcador: "Confirma tu contraseña",
                        icono: Icons.lock_outline,
                        es_contrasena: true,
                        ocultar_texto: _ocultar_confirmar_contrasena,
                        al_alternar_visibilidad: () => setState(
                          () => _ocultar_confirmar_contrasena =
                              !_ocultar_confirmar_contrasena,
                        ),
                      ),
                      const SizedBox(height: 14),

                      if (error_visible != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      BotonJuicy(
                        al_presionar: estado_auth.cargando ? null : _registrar,
                        cargando: estado_auth.cargando,
                        color_fondo: BumandColores.azulMarinoProfundo,
                        color_texto: BumandColores.blanco,
                        radio_borde: 16,
                        alto: 48,
                        icono: Icons.check_circle_outline_rounded,
                        texto_o_hijo: const Text(
                          "Crear cuenta",
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).maybePop(),
                          child: const Text(
                            "¿Ya tienes cuenta activa? Inicia sesión",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: BumandColores.azulMarinoProfundo,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          const Expanded(
                            child: Divider(
                              color: BumandColores.grisClaro,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: CustomPaint(
                              size: const Size(26, 13),
                              painter: const PintorPezCristiano(
                                color: BumandColores.amarilloRadiante,
                                grosor: 1.8,
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(
                              color: BumandColores.grisClaro,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "AMOR, LEALTAD Y SACRIFICIO · BUMAND AL SERVICIO",
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
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
