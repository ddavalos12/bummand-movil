import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../proveedores/asistencia-proveedor.dart';

class ConfirmarDatosPantalla extends ConsumerStatefulWidget {
  final String periodo;
  const ConfirmarDatosPantalla({super.key, required this.periodo});

  @override
  ConsumerState<ConfirmarDatosPantalla> createState() =>
      _ConfirmarDatosPantallaState();
}

class _ConfirmarDatosPantallaState extends ConsumerState<ConfirmarDatosPantalla> {
  static const _FONDO = BumandColores.fondo;
  static const _BORDE = BumandColores.grisClaro;

  final TextEditingController _telefono_controlador = TextEditingController();
  final TextEditingController _direccion_controlador = TextEditingController();
  final TextEditingController _emergencia_controlador = TextEditingController();

  bool _datos_inicializados = false;

  @override
  void dispose() {
    _telefono_controlador.dispose();
    _direccion_controlador.dispose();
    _emergencia_controlador.dispose();
    super.dispose();
  }

  void _inicializarCamposContacto(Map<String, dynamic> perfil) {
    if (_datos_inicializados) return;
    _telefono_controlador.text =
        perfil['telefono']?.toString() ??
        perfil['celular']?.toString() ??
        '78945612';
    _direccion_controlador.text =
        perfil['direccion']?.toString() ??
        'Zona 16 de Julio, Calle Eulert #120, El Alto';
    _emergencia_controlador.text =
        perfil['contactoEmergencia']?.toString() ??
        perfil['contacto_emergencia']?.toString() ??
        'Juana Laime (Madre) - Cel: 71234567';
    _datos_inicializados = true;
  }

  void _mensaje(String texto, {bool es_error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: es_error ? Colors.red.shade700 : const Color(0xFF10B981),
      ),
    );
  }

  Future<void> _guardarDatosContacto() async {
    final tel = _telefono_controlador.text.trim();
    final dir = _direccion_controlador.text.trim();
    final emg = _emergencia_controlador.text.trim();

    if (tel.isEmpty || dir.isEmpty || emg.isEmpty) {
      _mensaje('Debes completar todos los datos de contacto requeridos.', es_error: true);
      return;
    }

    final error = await ref
        .read(asistencia_notificador_proveedor.notifier)
        .actualizarPerfil({
      'telefono': tel,
      'direccion': dir,
      'contacto_emergencia': emg,
    });

    if (error == null) {
      _mensaje('Datos de contacto actualizados correctamente');
    } else {
      _mensaje(error, es_error: true);
    }
  }

  Future<void> _confirmar() async {
    await _guardarDatosContacto();
    final error = await ref
        .read(asistencia_notificador_proveedor.notifier)
        .confirmarDatosPasajes(widget.periodo);

    if (error == null) {
      ref.read(orden_confirmacion_proveedor.notifier).marcarConfirmado();
      _mensaje('Confirmación mensual de datos registrada exitosamente');
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      _mensaje(error, es_error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil_async = ref.watch(perfil_proveedor);
    final estado_accion = ref.watch(asistencia_notificador_proveedor);

    return Scaffold(
      backgroundColor: _FONDO,
      appBar: AppBar(
        title: const Text(
          "Confirmación Mensual de Datos",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: BumandColores.AZUL_DIACONIA,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: perfil_async.when(
        data: (resultado) {
          final p = resultado.datos ?? {
            'nombre': 'María Catunta Laime',
            'ci': '9876543 LP',
            'universidad': 'Universidad Pública de El Alto (UPEA)',
            'carrera': 'Contaduría Pública',
            'iglesia': 'Iglesia Bautista Central',
            'lugarPractica': {'nombre': 'Oficina Central Diaconía IFD'},
            'tutor': {'nombre': 'Angel Javier Ali Paz'},
          };

          _inicializarCamposContacto(p);

          final universidad = p['universidad']?.toString() ?? 'Universidad Pública de El Alto (UPEA)';
          final carrera = p['carrera']?.toString() ?? 'Contaduría Pública';
          final iglesia = p['iglesia']?.toString() ??
              p['iglesia_nombre']?.toString() ??
              'Iglesia Bautista Central';

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              // Banner de orden administrativa
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: BumandColores.AZUL_DIACONIA,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Orden Administrativa Activa",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: BumandColores.AZUL_DIACONIA,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Por disposición institucional, los campos académicos y eclesiásticos están bloqueados para edición. Solo puedes modificar tus datos de contacto.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey.shade800,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sección 1: Campos Bloqueados por Administración
              const Text(
                "DATOS INSTITUCIONALES (BLOQUEADOS)",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _BORDE),
                ),
                child: Column(
                  children: [
                    _FilaBloqueada(
                      etiqueta: "Estudiante",
                      valor: p["nombre"]?.toString() ?? "María Catunta Laime",
                    ),
                    const Divider(height: 20),
                    _FilaBloqueada(
                      etiqueta: "C.I.",
                      valor: p["ci"]?.toString() ?? "9876543 LP",
                    ),
                    const Divider(height: 20),
                    _FilaBloqueada(
                      etiqueta: "Universidad",
                      valor: universidad,
                      es_bloqueado_orden: true,
                    ),
                    const Divider(height: 20),
                    _FilaBloqueada(
                      etiqueta: "Carrera",
                      valor: carrera,
                      es_bloqueado_orden: true,
                    ),
                    const Divider(height: 20),
                    _FilaBloqueada(
                      etiqueta: "Iglesia",
                      valor: iglesia,
                      es_bloqueado_orden: true,
                    ),
                    const Divider(height: 20),
                    _FilaBloqueada(
                      etiqueta: "Período actual",
                      valor: widget.periodo,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Sección 2: Campos de Contacto Editables
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "DATOS DE CONTACTO (EDITABLES)",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: BumandColores.AZUL_DIACONIA,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF10B981)),
                    ),
                    child: const Text(
                      "Edición habilitada",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _BORDE),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Teléfono / Celular personal",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _telefono_controlador,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.phone_outlined,
                          color: BumandColores.AZUL_DIACONIA,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      "Dirección domiciliaria",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _direccion_controlador,
                      maxLines: 2,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.home_outlined,
                          color: BumandColores.AZUL_DIACONIA,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      "Contacto de emergencia (Nombre y teléfono)",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emergencia_controlador,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.contact_phone_outlined,
                          color: BumandColores.NARANJA_OSCURO,
                          size: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: estado_accion.isLoading ? null : _guardarDatosContacto,
                        icon: const Icon(Icons.save_outlined, size: 16),
                        label: const Text("Guardar cambios de contacto"),
                        style: TextButton.styleFrom(
                          foregroundColor: BumandColores.AZUL_DIACONIA,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botón principal Confirmar datos
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: estado_accion.isLoading ? null : _confirmar,
                  icon: const Icon(Icons.check_circle_outline),
                  label: estado_accion.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Confirmar datos mensuales",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BumandColores.amarilloRadiante,
                    foregroundColor: BumandColores.azulMarinoSecundario,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }
}

class _FilaBloqueada extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool es_bloqueado_orden;

  const _FilaBloqueada({
    required this.etiqueta,
    required this.valor,
    this.es_bloqueado_orden = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Row(
            children: [
              if (es_bloqueado_orden) ...[
                const Icon(
                  Icons.lock_outline,
                  size: 14,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  etiqueta,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                valor,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: BumandColores.NEGRO,
                ),
              ),
              if (es_bloqueado_orden)
                const Text(
                  "Solo lectura por orden de administración",
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
