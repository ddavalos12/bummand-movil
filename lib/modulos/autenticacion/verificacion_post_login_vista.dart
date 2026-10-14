import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../nucleo/tema/colores.dart';
import 'proveedores/autenticacion-proveedor.dart';
import '../inicio/pantallas/inicio-pantalla.dart';

/// Vista de Verificación Post-Login para confirmar datos institucionales y de contacto del becario.
class VerificacionPostLoginVista extends ConsumerStatefulWidget {
  const VerificacionPostLoginVista({super.key});

  @override
  ConsumerState<VerificacionPostLoginVista> createState() =>
      _VerificacionPostLoginVistaState();
}

class _VerificacionPostLoginVistaState
    extends ConsumerState<VerificacionPostLoginVista> {
  final TextEditingController _telefono_controlador = TextEditingController();
  final TextEditingController _direccion_controlador = TextEditingController();
  final TextEditingController _emergencia_controlador = TextEditingController();

  @override
  void initState() {
    super.initState();
    _telefono_controlador.text = '78945612';
    _direccion_controlador.text = 'Zona 16 de Julio, Calle Eulert #120, El Alto';
    _emergencia_controlador.text = 'Juana Laime (Madre) - Cel: 71234567';
  }

  @override
  void dispose() {
    _telefono_controlador.dispose();
    _direccion_controlador.dispose();
    _emergencia_controlador.dispose();
    super.dispose();
  }

  void _confirmarDatosFinales() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Datos institucionales y de contacto confirmados'),
        backgroundColor: BumandColores.AZUL_DIACONIA,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const InicioPantalla(),
      ),
      (_) => false,
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
            onPressed: () => Navigator.of(context).maybePop(),
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

  Widget _construirFilaDatoSoloLectura(
    String etiqueta,
    String valor, {
    bool destacado = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 13,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    etiqueta,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
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
      ),
    );
  }

  Widget _construirCampoContactoEditable({
    required String etiqueta,
    required TextEditingController controlador,
    required IconData icono,
    TextInputType tipo_teclado = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 14, color: BumandColores.AZUL_DIACONIA),
              const SizedBox(width: 6),
              Text(
                etiqueta,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const Spacer(),
              const Text(
                'Editable',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: controlador,
              keyboardType: tipo_teclado,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(autenticacion_proveedor).usuario;
    final nombre_estudiante =
        (usuario != null && usuario.nombre.isNotEmpty)
            ? usuario.nombre
            : 'María Catunta Laime';
    final correo_estudiante =
        (usuario != null && usuario.correo.isNotEmpty)
            ? usuario.correo
            : 'nilda.churata@bumand.bo';

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
    final fecha_presentacion =
        '24/${hoy.month.toString().padLeft(2, '0')}/${hoy.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Banner superior Diaconía IFD
            _construirBannerDiaconia(),

            // Cuerpo desplazable
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título de la pantalla
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
                      'Verifica tus datos institucionales y mantén actualizado tu contacto.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey.shade700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Badge de Correo Institucional Confirmado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF10B981)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF10B981),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Correo institucional verificado: $correo_estudiante',
                              style: const TextStyle(
                                color: Color(0xFF065F46),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Tarjeta 1: Información Académica e Institucional (Solo lectura)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: BumandColores.AZUL_DIACONIA
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.school_outlined,
                                  color: BumandColores.AZUL_DIACONIA,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Ficha Institucional y Beca',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const Spacer(),
                              const Tooltip(
                                message:
                                    'Datos protegidos por convenio institucional',
                                child: Icon(
                                  Icons.lock,
                                  size: 15,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 6),
                          _construirFilaDatoSoloLectura(
                            'Estudiante',
                            nombre_estudiante,
                          ),
                          _construirFilaDatoSoloLectura(
                            'Universidad',
                            'Universidad Pública de El Alto',
                          ),
                          _construirFilaDatoSoloLectura(
                            'Carrera',
                            'Economía',
                          ),
                          _construirFilaDatoSoloLectura(
                            'Lugar de prácticas',
                            'Oficina Central Diaconía IFD',
                          ),
                          _construirFilaDatoSoloLectura(
                            'Unidad',
                            'Créditos',
                          ),
                          _construirFilaDatoSoloLectura(
                            'Responsable',
                            'Carlos Alanoca',
                          ),
                          _construirFilaDatoSoloLectura(
                            'Mes de prácticas',
                            mes_actual,
                          ),
                          _construirFilaDatoSoloLectura(
                            'Presentación',
                            '$fecha_presentacion (Día 24)',
                            destacado: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Tarjeta 2: Datos de Contacto (Editables por el becario)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: BumandColores.TURQUESA_DIACONIA
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.contact_phone_outlined,
                                  color: BumandColores.TURQUESA_DIACONIA,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Datos de Contacto Directo',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _construirCampoContactoEditable(
                            etiqueta: 'Celular / WhatsApp',
                            controlador: _telefono_controlador,
                            icono: Icons.phone_android_outlined,
                            tipo_teclado: TextInputType.phone,
                          ),
                          _construirCampoContactoEditable(
                            etiqueta: 'Dirección de residencia',
                            controlador: _direccion_controlador,
                            icono: Icons.home_outlined,
                          ),
                          _construirCampoContactoEditable(
                            etiqueta: 'Contacto de emergencia',
                            controlador: _emergencia_controlador,
                            icono: Icons.emergency_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón Principal Confirmar Datos
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _confirmarDatosFinales,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BumandColores.NARANJA,
                          foregroundColor: BumandColores.NEGRO,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Confirmar datos e ingresar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
