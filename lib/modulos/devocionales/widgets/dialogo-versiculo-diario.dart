import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../nucleo/tema/colores.dart';
import '../modelos/versiculo-diario-modelo.dart';
import '../servicios/cola-descarga-biblia-servicio.dart';

class DialogoVersiculoDiario extends StatelessWidget {
  final VersiculoDiarioModelo versiculo;
  final VoidCallback? al_crear_devocional;

  const DialogoVersiculoDiario({
    super.key,
    required this.versiculo,
    this.al_crear_devocional,
  });

  static Future<void> mostrar(
    BuildContext context,
    WidgetRef ref, {
    bool forzar = false,
    VoidCallback? al_crear_devocional,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final hoy = DateTime.now().toIso8601String().substring(0, 10);
    final clave_mostrado_hoy = 'bumand_versiculo_mostrado_$hoy';

    if (!forzar && (prefs.getBool(clave_mostrado_hoy) ?? false)) {
      return;
    }

    final servicio = ref.read(cola_descarga_biblia_proveedor);
    final versiculo_actual = await servicio.obtenerVersiculoHoy();
    await prefs.setBool(clave_mostrado_hoy, true);

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DialogoVersiculoDiario(
        versiculo: versiculo_actual,
        al_crear_devocional: al_crear_devocional,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      backgroundColor: BumandColores.BLANCO,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 520, maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabecera institucional con Degradado Diaconía
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
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
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Versículo del Día',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        versiculo.version,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Cuerpo con versículo y reflexión
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  children: [
                    // Cita bíblica destacada
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        versiculo.cita,
                        style: const TextStyle(
                          color: BumandColores.AZUL_DIACONIA,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Texto bíblico
                    Text(
                      '«${versiculo.texto}»',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        fontStyle: FontStyle.italic,
                        color: BumandColores.NEGRO,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reflexión institucional
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE9ECEF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 16,
                                color: BumandColores.NARANJA_OSCURO,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                versiculo.tema,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: BumandColores.NARANJA_OSCURO,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            versiculo.reflexion_diaconal,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Comenzar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: BumandColores.AZUL_DIACONIA,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (al_crear_devocional != null) {
                                al_crear_devocional!();
                              }
                            },
                            child: const Text('Devocional'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
