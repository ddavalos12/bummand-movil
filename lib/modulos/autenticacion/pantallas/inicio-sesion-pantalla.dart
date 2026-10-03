import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_svg/flutter_svg.dart';
import '../../../nucleo/tema/colores.dart';
import '../proveedores/autenticacion-proveedor.dart';
import '../../inicio/pantallas/pantalla-inicio.dart';
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: BumandColores.BLANCO,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE3E9F2)),
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
      backgroundColor: BumandColores.FONDO,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cabecera institucional con Degradado Diaconía
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 36,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    BumandColores.AZUL_DIACONIA,
                    BumandColores.TURQUESA_DIACONIA,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Column(
                children: [
                  // Logo BUMAND Oficial en versión Blanca para fondo oscuro
                  SvgPicture.asset(
                    'assets/logos/logo-bumand-blanco.svg',
                    height: 58,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  // Logo Diaconía IFD Oficial en cápsula blanca de alta visibilidad
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SvgPicture.asset(
                      'assets/logos/logo-diaconia.svg',
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "PROGRAMA CORPORATIVO DE BECARIOS",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Color(0xFFE0F4FA),
                    ),
                  ),
                ],
              ),
            ),

            // Tarjeta de Formulario de Ingreso
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: BumandColores.BLANCO,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: estado_auth.cargando ? null : _iniciarSesion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BumandColores.AZUL_DIACONIA,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: estado_auth.cargando
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: BumandColores.BLANCO,
                                ),
                              )
                            : const Text(
                                "Ingresar al Sistema",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: BumandColores.BLANCO,
                                ),
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
                                      builder: (_) => const RegistroPantalla(),
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
            ),
          ],
        ),
      ),
    );
  }
}
