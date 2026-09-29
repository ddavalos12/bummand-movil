import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../datos/universidades.dart';
import '../proveedores/asistencia-proveedor.dart';

class ConfirmarDatosPantalla extends ConsumerStatefulWidget {
  final String periodo;
  const ConfirmarDatosPantalla({super.key, required this.periodo});

  @override
  ConsumerState<ConfirmarDatosPantalla> createState() =>
      _ConfirmarDatosPantallaState();
}

class _ConfirmarDatosPantallaState
    extends ConsumerState<ConfirmarDatosPantalla> {
  static const _FONDO = Color(0xFFEFF3F8);

  void _mensaje(String texto, {bool es_error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: es_error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _editarUniversidad(String? actual) async {
    const otra = "__otra__";
    if (!mounted) return;
    final elegida = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SelectorUniversidad(actual: actual, valor_otra: otra),
    );

    if (elegida == null) return;
    String valor_final = elegida;

    if (elegida == otra) {
      if (!mounted) return;
      final ctrl = TextEditingController(text: actual ?? "");
      final nuevo = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Escribir Universidad",
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: "Universidad",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                child: const Text("Guardar"),
              ),
            ],
          ),
        ),
      );
      if (nuevo == null || nuevo.isEmpty) return;
      valor_final = nuevo;
    }

    if (valor_final != actual) {
      final error = await ref
          .read(asistencia_notificador_proveedor.notifier)
          .actualizarPerfil({"universidad": valor_final});
      if (error == null) {
        _mensaje("Universidad actualizada");
      } else {
        _mensaje(error, es_error: true);
      }
    }
  }

  Future<void> _confirmar() async {
    final error = await ref
        .read(asistencia_notificador_proveedor.notifier)
        .confirmarDatosPasajes(widget.periodo);
    if (error == null) {
      _mensaje("Datos confirmados");
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
        title: const Text("Confirma tus datos"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: BumandColores.NEGRO,
      ),
      body: perfil_async.when(
        data: (resultado) {
          if (!resultado.exito || resultado.datos == null) {
            return Center(
              child: Text(resultado.error ?? "Error al cargar perfil"),
            );
          }
          final p = resultado.datos!;
          final faltantes = ((p["faltantes"] as List?) ?? []).cast<String>();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                "Formulario de devolución de pasajes",
                style: TextStyle(
                  color: BumandColores.AZUL_DIACONIA,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Column(
                  children: [
                    _Fila("Estudiante", p["nombre"]?.toString()),
                    const Divider(),
                    _Fila("C.I.", p["ci"]?.toString()),
                    const Divider(),
                    _Fila("Carrera", p["carrera"]?.toString()),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Universidad",
                          style: TextStyle(color: Colors.grey),
                        ),
                        Row(
                          children: [
                            Text(
                              p["universidad"]?.toString() ?? "No registrada",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: BumandColores.AZUL_DIACONIA,
                              ),
                              onPressed: () => _editarUniversidad(
                                p["universidad"]?.toString(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    _Fila(
                      "Lugar de prácticas",
                      p["lugarPractica"]?["nombre"]?.toString(),
                    ),
                  ],
                ),
              ),
              if (faltantes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  "Para confirmar, completa: ${faltantes.join(", ")}",
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (faltantes.isEmpty && !estado_accion.isLoading)
                    ? _confirmar
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BumandColores.NARANJA,
                  foregroundColor: BumandColores.NEGRO,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: estado_accion.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text(
                        "Confirmar datos",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String etiqueta;
  final String? valor;
  const _Fila(this.etiqueta, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: const TextStyle(color: Colors.grey)),
          Text(
            valor ?? "Por asignar",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _SelectorUniversidad extends StatefulWidget {
  final String? actual;
  final String valor_otra;
  const _SelectorUniversidad({required this.actual, required this.valor_otra});

  @override
  State<_SelectorUniversidad> createState() => _SelectorUniversidadState();
}

class _SelectorUniversidadState extends State<_SelectorUniversidad> {
  String _filtro = "";

  @override
  Widget build(BuildContext context) {
    final f = _filtro.toLowerCase();
    final lista = UNIVERSIDADES_LA_PAZ_EL_ALTO
        .where((u) => f.isEmpty || u.nombre.toLowerCase().contains(f))
        .toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: "Buscar universidad",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _filtro = v),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final u in lista)
                    ListTile(
                      title: Text(u.nombre),
                      subtitle: Text(u.sigla),
                      onTap: () => Navigator.pop(context, u.nombre),
                    ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text("Otra (escribir el nombre)"),
                    onTap: () => Navigator.pop(context, widget.valor_otra),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
