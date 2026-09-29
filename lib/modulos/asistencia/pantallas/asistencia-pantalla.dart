import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../modelos/tipo-asistencia.dart';
import '../proveedores/asistencia-proveedor.dart';

class AsistenciaPantalla extends ConsumerStatefulWidget {
  const AsistenciaPantalla({super.key});

  @override
  ConsumerState<AsistenciaPantalla> createState() => _AsistenciaPantallaState();
}

class _AsistenciaPantallaState extends ConsumerState<AsistenciaPantalla> {
  static const _FONDO = Color(0xFFEFF3F8);
  static const _BORDE = Color(0xFFE3E9F2);
  static const _DEGRADADO_DIACONIA = LinearGradient(
    colors: [BumandColores.AZUL_DIACONIA, BumandColores.TURQUESA_DIACONIA],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  String _tipo = TipoAsistencia.practicas.valor;

  void _mensaje(String texto, {bool es_error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: es_error
            ? Colors.red.shade700
            : BumandColores.TURQUESA_DIACONIA,
      ),
    );
  }

  Future<void> _marcar({required bool ingreso}) async {
    final notificador = ref.read(asistencia_notificador_proveedor.notifier);
    final error = ingreso
        ? await notificador.registrarIngreso(_tipo)
        : await notificador.registrarSalida(_tipo);
    if (error == null) {
      _mensaje(ingreso ? "Ingreso registrado" : "Salida registrada");
    } else {
      _mensaje(error, es_error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfil_async = ref.watch(perfil_proveedor);
    final historial_async = ref.watch(historial_asistencia_proveedor);
    final estado_accion = ref.watch(asistencia_notificador_proveedor);

    return Scaffold(
      backgroundColor: _FONDO,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 76,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: _DEGRADADO_DIACONIA),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Registro de asistencia",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            Text(
              "Verificación por geolocalización",
              style: TextStyle(fontSize: 12, color: Color(0xFFD6F1F7)),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(perfil_proveedor);
          ref.invalidate(historial_asistencia_proveedor);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Selector de tipo
            for (final t in TipoAsistencia.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ChoiceChip(
                    label: Text(t.etiqueta),
                    selected: _tipo == t.valor,
                    onSelected: estado_accion.isLoading
                        ? null
                        : (_) => setState(() => _tipo = t.valor),
                    selectedColor: BumandColores.AZUL_DIACONIA,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _tipo == t.valor
                          ? Colors.white
                          : BumandColores.NEGRO,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Datos del lugar
            perfil_async.when(
              data: (res) {
                final lugar = res.datos?["lugarPractica"];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _BORDE),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.apartment,
                        color: BumandColores.AZUL_DIACONIA,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          lugar?["nombre"]?.toString() ?? "Lugar por asignar",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text("Error: $e"),
            ),

            const SizedBox(height: 20),

            // Botones
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 62,
                    child: ElevatedButton(
                      onPressed: estado_accion.isLoading
                          ? null
                          : () => _marcar(ingreso: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BumandColores.NARANJA,
                        foregroundColor: BumandColores.NEGRO,
                      ),
                      child: estado_accion.isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                              "Marcar\ningreso",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 62,
                    child: OutlinedButton(
                      onPressed: estado_accion.isLoading
                          ? null
                          : () => _marcar(ingreso: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BumandColores.AZUL_DIACONIA,
                      ),
                      child: const Text(
                        "Marcar salida",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text(
              "Historial",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),

            historial_async.when(
              data: (res) {
                if (!res.exito || res.datos == null || res.datos!.isEmpty) {
                  return const Text("No hay registros.");
                }
                return Column(
                  children: res.datos!
                      .map(
                        (r) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _BORDE),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${r["fecha"]} · ${TipoAsistencia.etiquetaDe(r["tipo"].toString())}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "Ingreso: ${r["horaIngreso"] ?? "--:--"} | Salida: ${r["horaSalida"] ?? "--:--"}",
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text("Error: $e"),
            ),
          ],
        ),
      ),
    );
  }
}
