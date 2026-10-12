import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/tarjeta-spotlight.dart';
import '../../../widgets-comunes/boton-juicy.dart';
import '../proveedores/autenticacion-proveedor.dart';
import '../verificacion_post_login_vista.dart';
import 'registro-pantalla.dart';

class InicioSesionPantalla extends ConsumerStatefulWidget {
  const InicioSesionPantalla({super.key});

  @override
  ConsumerState<InicioSesionPantalla> createState() =>
      _InicioSesionPantallaState();
}

class _InicioSesionPantallaState extends ConsumerState<InicioSesionPantalla> {
  final _correo_controlador = TextEditingController();
  final _contrasena_controlador = TextEditingController();
  bool _ocultar_contrasena = true;
  String? _error_local;

  @override
  void dispose() {
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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const VerificacionPostLoginVista(),
        ),
        (_) => false,
      );
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controlador,
        obscureText: es_contrasena && _ocultar_contrasena,
        keyboardType: es_contrasena
            ? TextInputType.text
            : TextInputType.emailAddress,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: texto_marcador,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: BumandColores.AZUL_DIACONIA, size: 18),
          ),
          suffixIcon: es_contrasena
              ? IconButton(
                  icon: Icon(
                    _ocultar_contrasena
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade500,
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
      backgroundColor: const Color(0xFF091E3A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF091E3A),
              BumandColores.AZUL_DIACONIA,
              Color(0xFF0F172A),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Tarjeta Dinámica con Reflector de Luz (Cult UI Spotlight)
                  TarjetaSpotlight(
                    radio_borde: 28,
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Contenedor de Logos Institucionales lado a lado (Image 3)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/logos/logo-bumand.svg',
                                  height: 32,
                                  fit: BoxFit.contain,
                                ),
                                Container(
                                  height: 26,
                                  width: 1.5,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  color: const Color(0xFFCBD5E1),
                                ),
                                SvgPicture.asset(
                                  'assets/logos/logo-diaconia.svg',
                                  height: 22,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          "Iniciar Sesión",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: BumandColores.AZUL_DIACONIA,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Ingresa tus credenciales corporativas para continuar",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Sistema de gestión de becarios",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                            color: BumandColores.AZUL_DIACONIA,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        _construirCampoTexto(
                          controlador: _correo_controlador,
                          texto_marcador: "Correo electrónico",
                          icono: Icons.email_outlined,
                        ),
                        const SizedBox(height: 16),
                        _construirCampoTexto(
                          controlador: _contrasena_controlador,
                          texto_marcador: "Contraseña",
                          icono: Icons.lock_outline,
                          es_contrasena: true,
                        ),
                        const SizedBox(height: 16),

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

                        // Botón Juicy animado (Watermelon UI)
                        BotonJuicy(
                          al_presionar:
                              estado_auth.cargando ? null : _iniciarSesion,
                          cargando: estado_auth.cargando,
                          color_fondo: BumandColores.NARANJA,
                          color_texto: BumandColores.NEGRO,
                          radio_borde: 26,
                          alto: 52,
                          icono: Icons.arrow_forward_rounded,
                          texto_o_hijo: const Text(
                            "Ingresar",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: BumandColores.NEGRO,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "¿No tienes una cuenta? ",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            GestureDetector(
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
                                "Regístrate",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: BumandColores.AZUL_DIACONIA,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Lema Institucional BUMAND (Image 3 footer)
                  const SizedBox(height: 24),
                  Column(
                    children: [
                      Text(
                        "AMOR, LEALTAD Y SACRIFICIO",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "BUMAND AL SERVICIO",
                        style: TextStyle(
                          color: BumandColores.NARANJA,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
