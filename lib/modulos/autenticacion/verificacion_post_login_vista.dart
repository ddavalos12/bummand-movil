import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../nucleo/tema/colores.dart';
import '../asistencia/proveedores/asistencia-proveedor.dart';
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
  bool _guardando_confirmacion = false;
  bool _contacto_inicializado = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(perfil_proveedor));
  }

  String _formatearHorarios(Map<String, dynamic>? perfil) {
    if (perfil == null) return 'Cargando...';
    final lista = perfil['horarios_apoyo'];
    const nombres_dias = {
      1: 'Lun',
      2: 'Mar',
      3: 'Mié',
      4: 'Jue',
      5: 'Vie',
      6: 'Sáb',
    };
    if (lista is List && lista.isNotEmpty) {
      final partes = <String>[];
      for (final h in lista) {
        if (h is Map) {
          final dia = int.tryParse(h['dia_semana']?.toString() ?? '') ?? 0;
          final ini = (h['hora_inicio'] ?? '').toString();
          final fin = (h['hora_fin'] ?? '').toString();
          final ini_corta = ini.length >= 5 ? ini.substring(0, 5) : ini;
          final fin_corta = fin.length >= 5 ? fin.substring(0, 5) : fin;
          if (dia > 0 && ini_corta.isNotEmpty && fin_corta.isNotEmpty) {
            partes.add('${nombres_dias[dia] ?? 'Día $dia'} $ini_corta-$fin_corta');
          }
        }
      }
      if (partes.isNotEmpty) return partes.join(' · ');
    }
    final semanal = perfil['horario_semanal'];
    if (semanal is Map && semanal.isNotEmpty) {
      const orden_dias = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado'];
      const etiquetas = {
        'lunes': 'Lun',
        'martes': 'Mar',
        'miercoles': 'Mié',
        'jueves': 'Jue',
        'viernes': 'Vie',
        'sabado': 'Sáb',
      };
      final partes = <String>[];
      for (final clave in orden_dias) {
        final v = semanal[clave]?.toString().trim();
        if (v != null && v.isNotEmpty && v != '-' && v != '—') {
          partes.add('${etiquetas[clave]} $v');
        }
      }
      if (partes.isNotEmpty) return partes.join(' · ');
    }
    return 'Horario pendiente de asignación';
  }

  @override
  void dispose() {
    _telefono_controlador.dispose();
    _direccion_controlador.dispose();
    _emergencia_controlador.dispose();
    super.dispose();
  }

  Future<void> _confirmarDatosFinales() async {
    if (_guardando_confirmacion) return;
    final tel = _telefono_controlador.text.trim();
    final dir = _direccion_controlador.text.trim();
    if (tel.isEmpty || dir.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Debes ingresar tu número de celular y dirección actual.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _guardando_confirmacion = true);

    final repo = ref.read(autenticacion_repositorio_proveedor);
    final resultado = await repo.confirmarDatosPropios(
      celular: tel,
      direccion: dir,
    );

    if (!mounted) return;

    if (resultado.exito) {
      await ref.read(autenticacion_proveedor.notifier).refrescarMiPerfil();
      if (!mounted) return;
      setState(() => _guardando_confirmacion = false);
      ref.invalidate(perfil_proveedor);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Datos confirmados formalmente ante Diaconía FRIF-IFD'),
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
    } else {
      setState(() => _guardando_confirmacion = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado.error ?? 'No se pudo registrar la confirmación'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
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
    final perfil_async = ref.watch(perfil_proveedor);
    final datos_perfil = perfil_async.asData?.value.datos;

    if (datos_perfil != null && !_contacto_inicializado) {
      _contacto_inicializado = true;
      _telefono_controlador.text =
          (datos_perfil['celular'] ?? datos_perfil['telefono'] ?? '').toString();
      _direccion_controlador.text =
          (datos_perfil['direccion'] ?? '').toString();
      _emergencia_controlador.text =
          (datos_perfil['contacto_emergencia'] ?? '').toString();
    }

    final nombre_estudiante =
        (datos_perfil?['nombre']?.toString().trim().isNotEmpty == true)
            ? datos_perfil!['nombre'].toString()
            : ((usuario != null && usuario.nombre.isNotEmpty)
                ? usuario.nombre
                : 'Becario');
    final correo_estudiante =
        (usuario != null && usuario.correo.isNotEmpty)
            ? usuario.correo
            : '';
    final universidad =
        (datos_perfil?['universidad']?.toString().trim().isNotEmpty == true)
            ? datos_perfil!['universidad'].toString()
            : 'Registrado en expediente';
    final carrera =
        (datos_perfil?['carrera']?.toString().trim().isNotEmpty == true)
            ? datos_perfil!['carrera'].toString()
            : 'Registrado en expediente';
    final lugar_practica_mapa = datos_perfil?['lugar_practica'] is Map
        ? Map<String, dynamic>.from(datos_perfil!['lugar_practica'] as Map)
        : (datos_perfil?['lugarPractica'] is Map
            ? Map<String, dynamic>.from(datos_perfil!['lugarPractica'] as Map)
            : null);
    final lugar_practica =
        (lugar_practica_mapa?['nombre']?.toString().trim().isNotEmpty == true)
            ? lugar_practica_mapa!['nombre'].toString()
            : (perfil_async.isLoading ? 'Cargando...' : 'Sin sede asignada');
    final ubicacion =
        (datos_perfil?['ubicacion']?.toString().trim().isNotEmpty == true)
            ? datos_perfil!['ubicacion'].toString()
            : (perfil_async.isLoading ? 'Cargando...' : 'Por asignar');
    final unidad =
        (datos_perfil?['unidad']?.toString().trim().isNotEmpty == true)
            ? datos_perfil!['unidad'].toString()
            : (perfil_async.isLoading ? 'Cargando...' : 'Registrado en expediente');
    final supervisor_mapa = datos_perfil?['supervisor'] is Map
        ? Map<String, dynamic>.from(datos_perfil!['supervisor'] as Map)
        : null;
    final responsable =
        (supervisor_mapa?['nombre']?.toString().trim().isNotEmpty == true)
            ? supervisor_mapa!['nombre'].toString()
            : (perfil_async.isLoading ? 'Cargando...' : 'Por asignar');
    final horario_asignado = _formatearHorarios(datos_perfil);

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
                            universidad,
                          ),
                          _construirFilaDatoSoloLectura(
                            'Carrera',
                            carrera,
                          ),
                          _construirFilaDatoSoloLectura(
                            'Lugar de prácticas',
                            lugar_practica,
                          ),
                          _construirFilaDatoSoloLectura(
                            'Ubicación',
                            ubicacion,
                          ),
                          _construirFilaDatoSoloLectura(
                            'Unidad',
                            unidad,
                          ),
                          _construirFilaDatoSoloLectura(
                            'Responsable',
                            responsable,
                          ),
                          _construirFilaDatoSoloLectura(
                            'Horario asignado',
                            horario_asignado,
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
                        onPressed: _guardando_confirmacion ? null : _confirmarDatosFinales,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BumandColores.NARANJA,
                          foregroundColor: BumandColores.NEGRO,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _guardando_confirmacion
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
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
