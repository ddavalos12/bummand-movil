import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../modelos/recorrido-modelo.dart';
import '../modelos/solicitud-pasaje-modelo.dart';
import '../proveedores/pasajes-proveedor.dart';
import '../utilidades/formato-pasajes.dart';
import 'declarar-recorrido-pantalla.dart';
import 'historial-paradas-pantalla.dart';

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
          "por ${FormatoPasajes.bs(solicitud.monto_devolucion)} a tu supervisor para su revisión.\n\n"
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
      appBar: const BarraSuperiorBumand(
        titulo: "Mis pasajes",
        subtitulo: "Declaración mensual de recorridos",
      ),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HistorialParadasPantalla(),
                      ),
                    ),
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text('Ver historial de todas las paradas'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BumandColores.AZUL_DIACONIA,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
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
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "Se habilita el 24 de cada mes para el envío del formulario.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.amber.shade900,
                ),
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
                    "${r.apoyo_realizado != null && r.apoyo_realizado!.isNotEmpty ? " · ${r.apoyo_realizado}" : ""}"
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
          if (s.estado != "borrador")
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: _LineaProgresoPasajes(estado: s.estado),
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
      "borrador" => ("Borrador", Colors.grey.shade700),
      "pendiente" => ("1. Pendiente", BumandColores.NARANJA_OSCURO),
      "revisado_supervisor" => ("2. Revisado por Supervisor", BumandColores.AZUL_DIACONIA),
      "aprobado_administracion" || "aprobado" => ("✓ Aprobado por Administración", Colors.green.shade700),
      "rechazado" => ("Con observaciones", Colors.red.shade700),
      _ => (estado, Colors.grey.shade700),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

class _LineaProgresoPasajes extends StatelessWidget {
  final String estado;
  const _LineaProgresoPasajes({required this.estado});

  @override
  Widget build(BuildContext context) {
    final paso1_completado = estado == 'revisado_supervisor' ||
        estado == 'aprobado_administracion' ||
        estado == 'aprobado';
    final paso2_completado =
        estado == 'aprobado_administracion' || estado == 'aprobado';
    final es_rechazado = estado == 'rechazado';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Paso 1: Supervisor
              Icon(
                paso1_completado
                    ? Icons.check_circle_rounded
                    : (es_rechazado
                        ? Icons.cancel_rounded
                        : Icons.hourglass_top_rounded),
                size: 18,
                color: paso1_completado
                    ? const Color(0xFF10B981)
                    : (es_rechazado
                        ? Colors.red
                        : BumandColores.amarilloRadiante),
              ),
              const SizedBox(width: 6),
              const Text(
                "Paso 1: Supervisor",
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_rounded,
                  size: 14, color: Color(0xFF94A3B8)),
              const Spacer(),
              // Paso 2: Administración
              Icon(
                paso2_completado
                    ? Icons.check_circle_rounded
                    : (es_rechazado
                        ? Icons.cancel_rounded
                        : (paso1_completado
                            ? Icons.hourglass_top_rounded
                            : Icons.radio_button_unchecked)),
                size: 18,
                color: paso2_completado
                    ? const Color(0xFF10B981)
                    : (es_rechazado
                        ? Colors.red
                        : (paso1_completado
                            ? BumandColores.AZUL_DIACONIA
                            : const Color(0xFFCBD5E1))),
              ),
              const SizedBox(width: 6),
              const Text(
                "Paso 2: Administración",
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _etiquetaEstado(estado),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _colorEstado(estado),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _etiquetaEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return '● Paso 1 en curso: Pendiente de revisión del Supervisor';
      case 'revisado_supervisor':
        return '✓ Paso 1 completado: Revisado por Supervisor → Esperando aprobación final de Administración';
      case 'aprobado_administracion':
      case 'aprobado':
        return '✓ Paso 2 completado: Aprobado por Administración — Planilla autorizada para desembolso';
      case 'rechazado':
        return '✕ Con observaciones — Corrige los tramos indicados y vuelve a enviar';
      default:
        return estado;
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFFD97706);
      case 'revisado_supervisor':
        return BumandColores.AZUL_DIACONIA;
      case 'aprobado_administracion':
      case 'aprobado':
        return const Color(0xFF047857);
      case 'rechazado':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
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
