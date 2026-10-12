import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../nucleo/tema/colores.dart';
import 'proveedores/autenticacion-proveedor.dart';
import '../inicio/pantallas/inicio-pantalla.dart';

/// Vista de Verificación Post-Login para confirmar correo institucional y datos precargados.
class VerificacionPostLoginVista extends ConsumerStatefulWidget {
  const VerificacionPostLoginVista({super.key});

  @override
  ConsumerState<VerificacionPostLoginVista> createState() =>
      _VerificacionPostLoginVistaState();
}

class _VerificacionPostLoginVistaState
    extends ConsumerState<VerificacionPostLoginVista> {
  int _paso_actual = 1;

  final TextEditingController _correo_controlador = TextEditingController();
  final TextEditingController _confirmar_correo_controlador =
      TextEditingController();

  String? _mensaje_error_correo;

  @override
  void initState() {
    super.initState();
    final usuario = ref.read(autenticacion_proveedor).usuario;
    if (usuario != null && usuario.correo.isNotEmpty) {
      _correo_controlador.text = usuario.correo;
    }
  }

  @override
  void dispose() {
    _correo_controlador.dispose();
    _confirmar_correo_controlador.dispose();
    super.dispose();
  }

  bool _validarFormatoCorreo(String correo) {
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');
    return regex.hasMatch(correo);
  }

  void _guardarCorreo() {
    final correo1 = _correo_controlador.text.trim();
    final correo2 = _confirmar_correo_controlador.text.trim();

    if (correo1.isEmpty || correo2.isEmpty) {
      setState(() {
        _mensaje_error_correo = 'Debes completar ambos campos de correo.';
      });
      return;
    }

    if (!_validarFormatoCorreo(correo1)) {
      setState(() {
        _mensaje_error_correo =
            'Ingresa un formato de correo válido (ej. usuario@bumand.bo).';
      });
      return;
    }

    if (correo1.toLowerCase() != correo2.toLowerCase()) {
      setState(() {
        _mensaje_error_correo =
            'Los correos no coinciden. Verifica e intenta de nuevo.';
      });
      return;
    }

    setState(() {
      _mensaje_error_correo = null;
      _paso_actual = 2;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Correo institucional verificado correctamente'),
        backgroundColor: BumandColores.TURQUESA_DIACONIA,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmarDatosFinales() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Datos institucionales confirmados'),
        backgroundColor: BumandColores.AZUL_DIACONIA,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const InicioPantalla(mostrar_versiculo_inicio: true),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(autenticacion_proveedor).usuario;
    final nombre_estudiante =
        (usuario != null && usuario.nombre.isNotEmpty)
            ? usuario.nombre
            : 'María Catunta Laime';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Banner superior Diaconía IFD
            _construirBannerDiaconia(),

            // Cuerpo interactivo con los pasos
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, animacion) {
                    return FadeTransition(
                      opacity: animacion,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0.0),
                          end: Offset.zero,
                        ).animate(animacion),
                        child: child,
                      ),
                    );
                  },
                  child: _paso_actual == 1
                      ? _construirPasoUnoCorreo()
                      : _construirPasoDosDatos(nombre_estudiante),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirBannerDiaconia() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BumandColores.AZUL_DIACONIA,
            Color(0xFF0F4C81),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Volver',
            onPressed: () {
              if (_paso_actual == 2) {
                setState(() => _paso_actual = 1);
              } else {
                Navigator.of(context).maybePop();
              }
            },
          ),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(
                Icons.account_balance,
                color: BumandColores.NARANJA,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diaconía IFD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'DEVOLUCIÓN DEL 80% DE PASAJES',
                  style: TextStyle(
                    color: Color(0xFFBEE3F8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirPasoUnoCorreo() {
    return KeyedSubtree(
      key: const ValueKey('paso_1_correo'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador de pasos
          Row(
            children: [
              _construirPuntoPaso(1, activo: true),
              _construirLineaPaso(activa: false),
              _construirPuntoPaso(2, activo: false),
            ],
          ),
          const SizedBox(height: 20),

          const Text(
            'CONFIRMA TU CORREO',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: BumandColores.NEGRO,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Por seguridad, verifica tu correo institucional antes de continuar.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 24),

          // Campo 1: Correo electrónico
          const Text(
            'Correo electrónico',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          _construirInputCorreo(
            controlador: _correo_controlador,
            texto_marcador: 'nombre.apellido@bumand.bo',
            icono: Icons.email_outlined,
          ),
          const SizedBox(height: 16),

          // Campo 2: Confirmar correo electrónico
          const Text(
            'Confirmar correo electrónico',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          _construirInputCorreo(
            controlador: _confirmar_correo_controlador,
            texto_marcador: 'Vuelve a escribir tu correo',
            icono: Icons.mark_email_read_outlined,
          ),
          const SizedBox(height: 12),

          // Mensaje de error
          if (_mensaje_error_correo != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFDC2626),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _mensaje_error_correo!,
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Botón Guardar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _guardarCorreo,
              style: ElevatedButton.styleFrom(
                backgroundColor: BumandColores.TURQUESA_DIACONIA,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirPasoDosDatos(String nombre_estudiante) {
    final hoy = DateTime.now();
    final meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    final mes_actual = meses[hoy.month - 1];
    final fecha_presentacion = '24/${hoy.month.toString().padLeft(2, '0')}/${hoy.year}';

    return KeyedSubtree(
      key: const ValueKey('paso_2_datos'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador de pasos
          Row(
            children: [
              _construirPuntoPaso(1, activo: false, completado: true),
              _construirLineaPaso(activa: true),
              _construirPuntoPaso(2, activo: true),
            ],
          ),
          const SizedBox(height: 20),

          const Text(
            'CONFIRMA ESTOS DATOS',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: BumandColores.NEGRO,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Verificado con tu correo institucional. Revisa que todo esté correcto.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),

          // Chip de correo confirmado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _correo_controlador.text.trim().isNotEmpty
                      ? _correo_controlador.text.trim()
                      : 'Correo confirmado',
                  style: const TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tarjeta informativa de solo lectura
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _construirFilaDato('Estudiante', nombre_estudiante),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _construirFilaDato('Carrera', 'Economía'),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _construirFilaDato(
                  'Universidad',
                  'Universidad Pública de El Alto',
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _construirFilaDato('Mes de prácticas', mes_actual),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _construirFilaDato(
                  'Fecha de presentación',
                  '$fecha_presentacion (Día 24)',
                  destacado: true,
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _construirFilaDato('Lugar de prácticas', 'Oficina Central'),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _construirFilaDato('Unidad', 'Créditos'),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _construirFilaDato('Responsable / mentor', 'Carlos Alanoca'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Botón Confirmar datos
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _confirmarDatosFinales,
              style: ElevatedButton.styleFrom(
                backgroundColor: BumandColores.NARANJA,
                foregroundColor: BumandColores.NEGRO,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Confirmar datos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _paso_actual = 1),
              icon: const Icon(Icons.edit, size: 14),
              label: const Text('Corregir correo institucional'),
              style: TextButton.styleFrom(
                foregroundColor: BumandColores.AZUL_DIACONIA,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFilaDato(
    String etiqueta,
    String valor, {
    bool destacado = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            valor,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: destacado
                  ? BumandColores.AZUL_DIACONIA
                  : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirInputCorreo({
    required TextEditingController controlador,
    required String texto_marcador,
    required IconData icono,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: TextField(
        controller: controlador,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: texto_marcador,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(
            icono,
            color: BumandColores.AZUL_DIACONIA,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _construirPuntoPaso(
    int numero, {
    required bool activo,
    bool completado = false,
  }) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completado
            ? BumandColores.TURQUESA_DIACONIA
            : activo
                ? BumandColores.AZUL_DIACONIA
                : const Color(0xFFE2E8F0),
      ),
      child: Center(
        child: completado
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : Text(
                '$numero',
                style: TextStyle(
                  color: activo ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }

  Widget _construirLineaPaso({required bool activa}) {
    return Expanded(
      child: Container(
        height: 2.5,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: activa
            ? BumandColores.TURQUESA_DIACONIA
            : const Color(0xFFE2E8F0),
      ),
    );
  }
}
