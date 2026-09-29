import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../proveedores/autenticacion-proveedor.dart';
import '../../inicio/pantallas/pantalla-inicio.dart';

class RegistroPantalla extends ConsumerStatefulWidget {
  const RegistroPantalla({super.key});

  @override
  ConsumerState<RegistroPantalla> createState() => _RegistroPantallaState();
}

class _RegistroPantallaState extends ConsumerState<RegistroPantalla> {
  final _ci_controlador = TextEditingController();
  final _correo_controlador = TextEditingController();
  final _confirmar_correo_controlador = TextEditingController();
  final _contrasena_controlador = TextEditingController();
  final _confirmar_controlador = TextEditingController();

  bool _ocultar_contrasena = true;
  String? _error_validacion;

  @override
  void dispose() {
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
    bool deshabilitar_pegar = false,
    TextInputType tipo_teclado = TextInputType.text,
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
        keyboardType: tipo_teclado,
        enableInteractiveSelection: !deshabilitar_pegar,
        autocorrect: false,
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

    return Scaffold(
      backgroundColor: BumandColores.FONDO,
      appBar: AppBar(
        title: const Text("Crear mi cuenta"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: BumandColores.NEGRO,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: BumandColores.BLANCO,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Si ya estás en la lista de becarios de BUMAND (tu CI ya fue cargado por el administrador), crea tu cuenta aquí con tu correo real.",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 20),
                _construirCampoTexto(
                  controlador: _ci_controlador,
                  texto_marcador: "Tu C.I. (sin extensión)",
                  icono: Icons.badge_outlined,
                  tipo_teclado: TextInputType.number,
                ),
                const SizedBox(height: 14),
                _construirCampoTexto(
                  controlador: _correo_controlador,
                  texto_marcador: "Tu correo real",
                  icono: Icons.email_outlined,
                  tipo_teclado: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                _construirCampoTexto(
                  controlador: _confirmar_correo_controlador,
                  texto_marcador: "Confirma tu correo",
                  icono: Icons.mark_email_read_outlined,
                  tipo_teclado: TextInputType.emailAddress,
                  deshabilitar_pegar: true,
                ),
                const SizedBox(height: 14),
                _construirCampoTexto(
                  controlador: _contrasena_controlador,
                  texto_marcador: "Elige una contraseña",
                  icono: Icons.lock_outline,
                  es_contrasena: true,
                ),
                const SizedBox(height: 14),
                _construirCampoTexto(
                  controlador: _confirmar_controlador,
                  texto_marcador: "Confirma tu contraseña",
                  icono: Icons.lock_outline,
                  es_contrasena: true,
                ),
                const SizedBox(height: 16),
                if (_error_validacion != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error_validacion!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (estado_auth.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      estado_auth.error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: estado_auth.cargando ? null : _registrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BumandColores.NARANJA_OSCURO,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: estado_auth.cargando
                        ? const CircularProgressIndicator(
                            color: BumandColores.BLANCO,
                          )
                        : const Text(
                            "Crear cuenta",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: BumandColores.BLANCO,
                            ),
                          ),
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
