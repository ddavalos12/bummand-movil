import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../modelos/recorrido-modelo.dart';
import '../modelos/solicitud-pasaje-modelo.dart';
import '../proveedores/pasajes-proveedor.dart';
import '../utilidades/formato-pasajes.dart';
import 'declarar-recorrido-pantalla.dart';

class PasajesPantalla extends ConsumerStatefulWidget {
  const PasajesPantalla({super.key});

  @override
  ConsumerState<PasajesPantalla> createState() => _PasajesPantallaState();
}

class _PasajesPantallaState extends ConsumerState<PasajesPantalla> {
  bool _procesando = false;
  static const _ESTADOS_EDITABLES = ["borrador", "rechazado"];

  void _mensaje(String texto, {bool es_error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: es_error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _abrirDeclaracion(
    List<SolicitudPasajeModelo> solicitudes,
  ) async {
    final periodo = FormatoPasajes.periodoActual;
    final del_mes = solicitudes.where((s) => s.periodo == periodo).firstOrNull;

    if (del_mes != null && !_ESTADOS_EDITABLES.contains(del_mes.estado)) {
      _mensaje(
        "Tu formulario de ${FormatoPasajes.periodo(periodo)} ya fue enviado.",
        es_error: true,
      );
      return;
    }

    final guardado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DeclararRecorridoPantalla()),
    );

    if (guardado == true && mounted) {
      ref.read(solicitudes_pasajes_proveedor.notifier).cargarSolicitudes();
    }
  }

  Future<void> _eliminarRecorrido(RecorridoModelo recorrido) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Eliminar recorrido"),
        content: Text(
          "¿Eliminar el tramo de ${recorrido.tramo} del ${FormatoPasajes.diaMes(recorrido.fecha)} "
          "(${recorrido.origen} → ${recorrido.destino})?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _procesando = true);
    final r = await ref
        .read(solicitudes_pasajes_proveedor.notifier)
        .eliminarRecorrido(recorrido.id);
    if (mounted) setState(() => _procesando = false);
    _mensaje(r.error ?? "Recorrido eliminado exitosamente", es_error: !r.exito);
  }

  Future<void> _enviar(SolicitudPasajeModelo solicitud) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Enviar formulario mensual"),
        content: Text(
          "Se enviará tu formulario de ${FormatoPasajes.periodo(solicitud.periodo)} "
          "por ${FormatoPasajes.bs(solicitud.monto_devolucion)} a tu mentor para su firma.\n\n"
          "Después ya no podrás agregar recorridos de ese mes, "
          "salvo que te lo devuelvan con observaciones.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Enviar"),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    setState(() => _procesando = true);
    final r = await ref
        .read(solicitudes_pasajes_proveedor.notifier)
        .enviarSolicitud(solicitud.id);
    if (mounted) setState(() => _procesando = false);
    _mensaje(r.error ?? "Formulario enviado exitosamente", es_error: !r.exito);
  }

  @override
  Widget build(BuildContext context) {
    final solicitudes_async = ref.watch(solicitudes_pasajes_proveedor);

    return Scaffold(
      backgroundColor: BumandColores.FONDO,
      appBar: AppBar(title: const Text("Mis pasajes")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _procesando
            ? null
            : () => _abrirDeclaracion(solicitudes_async.asData?.value ?? []),
        icon: const Icon(Icons.directions_bus),
        label: const Text("Declarar recorrido"),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(solicitudes_pasajes_proveedor.notifier).cargarSolicitudes(),
        child: solicitudes_async.when(
          data: (solicitudes) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                if (_procesando) const LinearProgressIndicator(),
                if (solicitudes.isEmpty)
                  const _MensajeVacio(
                    icono: Icons.directions_bus_outlined,
                    texto: "Aún no declaraste recorridos.\nToca \"Declarar recorrido\" para registrar tu ida y vuelta.",
                  )
                else
                  for (final s in solicitudes) _tarjetaSolicitud(s),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            children: [
              _MensajeVacio(
                icono: Icons.cloud_off,
                texto: err.toString(),
                accion: () => ref
                    .read(solicitudes_pasajes_proveedor.notifier)
                    .cargarSolicitudes(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botonEnviar(SolicitudPasajeModelo s) {
    final habilitado = FormatoPasajes.puedeEnviar(s.periodo);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: _procesando || !habilitado ? null : () => _enviar(s),
            icon: const Icon(Icons.send),
            label: Text(
              s.estado == "rechazado"
                  ? "Corregido: volver a enviar"
                  : "Enviar formulario mensual",
            ),
          ),
          if (!habilitado)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                "Se habilita el ${FormatoPasajes.ddmmyyyy(FormatoPasajes.fechaHabilitada(s.periodo))} "
                "para el envío del formulario.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tarjetaSolicitud(SolicitudPasajeModelo s) {
    final editable = _ESTADOS_EDITABLES.contains(s.estado);
    final tema = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    FormatoPasajes.periodo(s.periodo),
                    style: tema.textTheme.titleMedium,
                  ),
                ),
                _ChipEstado(estado: s.estado),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _Monto(
                    etiqueta: "Total declarado",
                    valor: FormatoPasajes.bs(s.monto_total),
                  ),
                ),
                Expanded(
                  child: _Monto(
                    etiqueta: "Devolución (80%)",
                    valor: FormatoPasajes.bs(s.monto_devolucion),
                    destacado: true,
                  ),
                ),
              ],
            ),
          ),
          if (s.observaciones != null && s.observaciones!.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: s.estado == "rechazado"
                    ? Colors.red.shade50
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    s.estado == "rechazado"
                        ? Icons.report_outlined
                        : Icons.comment_outlined,
                    size: 20,
                    color: s.estado == "rechazado"
                        ? Colors.red.shade700
                        : BumandColores.AZUL_DIACONIA,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Observación del supervisor: ${s.observaciones}",
                    ),
                  ),
                ],
              ),
            ),
          ExpansionTile(
            title: Text("${s.recorridos.length} tramo(s) declarado(s)"),
            initiallyExpanded: editable,
            children: [
              for (final r in s.recorridos)
                ListTile(
                  dense: true,
                  leading: Icon(
                    r.tramo == "ida" ? Icons.arrow_forward : Icons.arrow_back,
                    color: r.tramo == "ida"
                        ? BumandColores.NARANJA_OSCURO
                        : BumandColores.AZUL_DIACONIA,
                  ),
                  title: Text("${r.origen} → ${r.destino}"),
                  subtitle: Text(
                    "${FormatoPasajes.diaMes(r.fecha)} · ${r.tramo == "ida" ? "Ida" : "Vuelta"}"
                    "${r.lat_origen != null || r.lat_destino != null ? " · 📍 con ubicación" : ""}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(FormatoPasajes.bs(r.tarifa)),
                      if (editable)
                        IconButton(
                          tooltip: "Eliminar tramo",
                          icon: const Icon(Icons.delete_outline),
                          onPressed: _procesando
                              ? null
                              : () => _eliminarRecorrido(r),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          if (editable && s.recorridos.isNotEmpty) _botonEnviar(s),
          if (s.estado == "pendiente")
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                "● Pendiente de firma del mentor",
                style: TextStyle(color: BumandColores.NARANJA_OSCURO),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChipEstado extends StatelessWidget {
  final String estado;
  const _ChipEstado({required this.estado});

  @override
  Widget build(BuildContext context) {
    final (texto, color) = switch (estado) {
      "borrador" => ("En preparación", Colors.grey.shade700),
      "pendiente" => ("En revisión", BumandColores.NARANJA_OSCURO),
      "aprobado" => ("Aprobado", Colors.green.shade700),
      "rechazado" => ("Con observaciones", Colors.red.shade700),
      _ => (estado, Colors.grey.shade700),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Monto extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool destacado;
  const _Monto({
    required this.etiqueta,
    required this.valor,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: tema.bodySmall),
        Text(
          valor,
          style: (destacado ? tema.titleLarge : tema.titleMedium)?.copyWith(
            fontWeight: destacado ? FontWeight.bold : null,
            color: destacado ? Colors.green.shade800 : null,
          ),
        ),
      ],
    );
  }
}

class _MensajeVacio extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback? accion;
  const _MensajeVacio({required this.icono, required this.texto, this.accion});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(icono, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(texto, textAlign: TextAlign.center),
          if (accion != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: accion, child: const Text("Reintentar")),
          ],
        ],
      ),
    );
  }
}
