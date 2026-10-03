import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../modelos/notificacion-modelo.dart';
import '../proveedores/notificaciones-proveedor.dart';

class NotificacionesPantalla extends ConsumerStatefulWidget {
  const NotificacionesPantalla({super.key});

  @override
  ConsumerState<NotificacionesPantalla> createState() =>
      _NotificacionesPantallaState();
}

class _NotificacionesPantallaState
    extends ConsumerState<NotificacionesPantalla> {
  static const _FONDO = Color(0xFFEFF3F8);
  static const _BORDE = Color(0xFFE3E9F2);

  String _filtro_actual = "todas";

  @override
  Widget build(BuildContext context) {
    final estado_notificaciones =
        ref.watch(notificaciones_notificador_proveedor);

    return Scaffold(
      backgroundColor: _FONDO,
      appBar: BarraSuperiorBumand(
        titulo: "Notificaciones y alertas",
        subtitulo: "Avisos de salida, pasajes y evaluaciones",
        acciones_adicionales: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: "Actualizar",
            onPressed: () =>
                ref.read(notificaciones_notificador_proveedor.notifier).recargar(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(notificaciones_notificador_proveedor.notifier).recargar(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _construirChipFiltro("todas", "Todas"),
                    const SizedBox(width: 8),
                    _construirChipFiltro("salida", "Recordatorios"),
                    const SizedBox(width: 8),
                    _construirChipFiltro("pasajes", "Pasajes"),
                    const SizedBox(width: 8),
                    _construirChipFiltro("evaluacion", "Evaluaciones"),
                  ],
                ),
              ),
            ),
            Expanded(
              child: estado_notificaciones.when(
                data: (notificaciones) {
                  final filtradas = _aplicarFiltro(notificaciones);
                  if (filtradas.isEmpty) {
                    return _VistaVacia(filtro: _filtro_actual);
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtradas.length,
                    itemBuilder: (context, index) {
                      final item = filtradas[index];
                      return _TarjetaNotificacion(
                        notificacion: item,
                        onTap: () {
                          if (!item.leido) {
                            ref
                                .read(
                                  notificaciones_notificador_proveedor.notifier,
                                )
                                .marcarComoLeida(item.id);
                          }
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Error al cargar notificaciones:\n$error",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => ref
                              .read(
                                notificaciones_notificador_proveedor.notifier,
                              )
                              .recargar(),
                          child: const Text("Reintentar"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirChipFiltro(String clave, String etiqueta) {
    final seleccionado = _filtro_actual == clave;
    return ChoiceChip(
      label: Text(etiqueta),
      selected: seleccionado,
      onSelected: (_) => setState(() => _filtro_actual = clave),
      selectedColor: BumandColores.AZUL_DIACONIA,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: seleccionado ? Colors.white : BumandColores.NEGRO,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      side: BorderSide(
        color: seleccionado ? BumandColores.AZUL_DIACONIA : _BORDE,
      ),
    );
  }

  List<NotificacionModelo> _aplicarFiltro(List<NotificacionModelo> lista) {
    if (_filtro_actual == "salida") {
      return lista.where((n) => n.esRecordatorioSalida).toList();
    }
    if (_filtro_actual == "pasajes") {
      return lista.where((n) => n.esPasajeObservado).toList();
    }
    if (_filtro_actual == "evaluacion") {
      return lista.where((n) => n.esEvaluacion).toList();
    }
    return lista;
  }
}

class _TarjetaNotificacion extends StatelessWidget {
  final NotificacionModelo notificacion;
  final VoidCallback onTap;

  const _TarjetaNotificacion({
    required this.notificacion,
    required this.onTap,
  });

  _ConfiguracionTipoAlerta _obtenerConfiguracion() {
    if (notificacion.esRecordatorioSalida) {
      return const _ConfiguracionTipoAlerta(
        icono: Icons.alarm_on_rounded,
        color_icono: BumandColores.AZUL_DIACONIA,
        color_fondo_icono: Color(0xFFE0F2FE),
        etiqueta: "Recordatorio de salida",
      );
    }
    if (notificacion.esPasajeObservado) {
      return const _ConfiguracionTipoAlerta(
        icono: Icons.warning_amber_rounded,
        color_icono: BumandColores.NARANJA_OSCURO,
        color_fondo_icono: Color(0xFFFEF3C7),
        etiqueta: "Pasajes observados",
      );
    }
    if (notificacion.esEvaluacion) {
      return const _ConfiguracionTipoAlerta(
        icono: Icons.rate_review_outlined,
        color_icono: Color(0xFF7C3AED),
        color_fondo_icono: Color(0xFFF3E8FF),
        etiqueta: "Evaluación",
      );
    }
    return const _ConfiguracionTipoAlerta(
      icono: Icons.notifications_outlined,
      color_icono: Colors.blueGrey,
      color_fondo_icono: Color(0xFFF1F5F9),
      etiqueta: "Aviso",
    );
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return "$dia/$mes/$anio $hora:$minuto";
  }

  @override
  Widget build(BuildContext context) {
    final configuracion = _obtenerConfiguracion();
    final fecha_texto = _formatearFecha(notificacion.fecha_envio);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notificacion.leido ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notificacion.leido
                ? const Color(0xFFE2E8F0)
                : configuracion.color_icono.withValues(alpha: 0.35),
            width: notificacion.leido ? 1.0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: configuracion.color_fondo_icono,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                configuracion.icono,
                color: configuracion.color_icono,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: configuracion.color_fondo_icono,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          configuracion.etiqueta,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: configuracion.color_icono,
                          ),
                        ),
                      ),
                      if (!notificacion.leido)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: configuracion.color_icono,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notificacion.mensaje,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: notificacion.leido
                          ? FontWeight.normal
                          : FontWeight.w600,
                      color: notificacion.leido
                          ? const Color(0xFF475569)
                          : BumandColores.NEGRO,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fecha_texto,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
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

class _ConfiguracionTipoAlerta {
  final IconData icono;
  final Color color_icono;
  final Color color_fondo_icono;
  final String etiqueta;

  const _ConfiguracionTipoAlerta({
    required this.icono,
    required this.color_icono,
    required this.color_fondo_icono,
    required this.etiqueta,
  });
}

class _VistaVacia extends StatelessWidget {
  final String filtro;

  const _VistaVacia({required this.filtro});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE2E8F0),
              ),
              child: const Icon(
                Icons.notifications_none_outlined,
                size: 48,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "No hay notificaciones pendientes",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BumandColores.NEGRO,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              filtro == "todas"
                  ? "Tus alertas sobre salida, pasajes observados y evaluaciones se mostrarán aquí."
                  : "No se encontraron alertas en esta categoría.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
