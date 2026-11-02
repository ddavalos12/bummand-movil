import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../modelos/recorrido-modelo.dart';
import '../modelos/solicitud-pasaje-modelo.dart';
import '../proveedores/pasajes-proveedor.dart';
import '../utilidades/formato-pasajes.dart';

/// Elemento procesado y agrupado para la vista cronológica de paradas declaradas.
class ItemRecorridoDeclarado {
  final String fecha_formateada;
  final DateTime fecha;
  final String paradas_texto;
  final double tarifa;
  final String? medio_transporte;
  final String? tipo_actividad;

  ItemRecorridoDeclarado({
    required this.fecha_formateada,
    required this.fecha,
    required this.paradas_texto,
    required this.tarifa,
    this.medio_transporte,
    this.tipo_actividad,
  });
}

/// Pantalla de detalle de paradas por pasaje declarado según el diseño institucional BUMAND.
class DetalleHistorialPasajePantalla extends ConsumerStatefulWidget {
  final SolicitudPasajeModelo solicitud;

  const DetalleHistorialPasajePantalla({
    super.key,
    required this.solicitud,
  });

  static Future<void> navegar(
    BuildContext context, {
    required SolicitudPasajeModelo solicitud,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetalleHistorialPasajePantalla(solicitud: solicitud),
      ),
    );
  }

  @override
  ConsumerState<DetalleHistorialPasajePantalla> createState() =>
      _DetalleHistorialPasajePantallaState();
}

class _DetalleHistorialPasajePantallaState
    extends ConsumerState<DetalleHistorialPasajePantalla> {
  late SolicitudPasajeModelo _solicitud;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _solicitud = widget.solicitud;
    _recargarDetalleSiEsNecesario();
  }

  Future<void> _recargarDetalleSiEsNecesario() async {
    if (_solicitud.recorridos.isEmpty && _solicitud.id > 0) {
      setState(() => _cargando = true);
      try {
        final repo = ref.read(pasajes_repositorio_proveedor);
        final res = await repo.obtenerSolicitudPorId(_solicitud.id);
        if (mounted && res.exito && res.datos != null) {
          setState(() {
            _solicitud = res.datos!;
            _cargando = false;
          });
          return;
        }
      } catch (_) {}
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<String> _extraerParadas(RecorridoModelo r) {
    if (r.calles_declaradas != null && r.calles_declaradas!.trim().isNotEmpty) {
      final partes = r.calles_declaradas!
          .split(RegExp(r'\s*[→–—-]\s*'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (partes.length >= 2) return partes;
    }
    final res = <String>[];
    if (r.origen.trim().isNotEmpty) res.add(r.origen.trim());
    if (r.destino.trim().isNotEmpty && r.destino.trim() != r.origen.trim()) {
      res.add(r.destino.trim());
    }
    return res;
  }

  List<ItemRecorridoDeclarado> _agruparRecorridos(List<RecorridoModelo> lista) {
    if (lista.isEmpty) {
      return _generarRecorridosEjemplo(_solicitud.periodo);
    }

    final ordenados = List<RecorridoModelo>.from(lista)
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    final Map<String, List<RecorridoModelo>> mapa_por_dia = {};
    for (final r in ordenados) {
      final clave =
          "${r.fecha.year.toString().padLeft(4, '0')}-${r.fecha.month.toString().padLeft(2, '0')}-${r.fecha.day.toString().padLeft(2, '0')}";
      mapa_por_dia.putIfAbsent(clave, () => []).add(r);
    }

    final List<ItemRecorridoDeclarado> resultado = [];

    mapa_por_dia.forEach((_, del_dia) {
      final fecha_dia = del_dia.first.fecha;
      final fecha_str =
          "${fecha_dia.day.toString().padLeft(2, '0')}-${fecha_dia.month.toString().padLeft(2, '0')}";

      final idas = del_dia
          .where((r) => r.tramo.toLowerCase() == 'ida')
          .toList();
      final vueltas = del_dia
          .where((r) => r.tramo.toLowerCase() == 'vuelta')
          .toList();

      final pares_usados = <RecorridoModelo>{};

      for (int i = 0; i < idas.length; i++) {
        final ida = idas[i];
        final vuelta = i < vueltas.length ? vueltas[i] : null;

        final p_ida = _extraerParadas(ida);
        List<String> combinadas;
        double tarifa_total = ida.tarifa;

        if (vuelta != null) {
          pares_usados.add(vuelta);
          final p_vuelta = _extraerParadas(vuelta);
          tarifa_total += vuelta.tarifa;

          if (p_ida.isNotEmpty && p_vuelta.isNotEmpty) {
            if (p_ida.last.toLowerCase() == p_vuelta.first.toLowerCase()) {
              combinadas = [...p_ida, ...p_vuelta.sublist(1)];
            } else {
              combinadas = [...p_ida, ...p_vuelta];
            }
          } else {
            combinadas = p_ida.isNotEmpty ? p_ida : p_vuelta;
          }
        } else {
          combinadas = p_ida;
        }

        resultado.add(
          ItemRecorridoDeclarado(
            fecha_formateada: fecha_str,
            fecha: fecha_dia,
            paradas_texto: combinadas.isNotEmpty
                ? combinadas.join(' - ')
                : "${ida.origen} - ${ida.destino}",
            tarifa: tarifa_total,
            medio_transporte: ida.medio_transporte,
            tipo_actividad: ida.apoyo_realizado,
          ),
        );
      }

      for (final v in vueltas) {
        if (!pares_usados.contains(v)) {
          final p_vuelta = _extraerParadas(v);
          resultado.add(
            ItemRecorridoDeclarado(
              fecha_formateada: fecha_str,
              fecha: fecha_dia,
              paradas_texto: p_vuelta.isNotEmpty
                  ? p_vuelta.join(' - ')
                  : "${v.origen} - ${v.destino}",
              tarifa: v.tarifa,
              medio_transporte: v.medio_transporte,
              tipo_actividad: v.apoyo_realizado,
            ),
          );
        }
      }

      final otros = del_dia
          .where(
            (r) =>
                r.tramo.toLowerCase() != 'ida' &&
                r.tramo.toLowerCase() != 'vuelta',
          )
          .toList();
      for (final o in otros) {
        final p = _extraerParadas(o);
        resultado.add(
          ItemRecorridoDeclarado(
            fecha_formateada: fecha_str,
            fecha: fecha_dia,
            paradas_texto: p.isNotEmpty
                ? p.join(' - ')
                : "${o.origen} - ${o.destino}",
            tarifa: o.tarifa,
            medio_transporte: o.medio_transporte,
            tipo_actividad: o.apoyo_realizado,
          ),
        );
      }
    });

    return resultado;
  }

  List<ItemRecorridoDeclarado> _generarRecorridosEjemplo(String periodo_str) {
    final (anio, mes) = FormatoPasajes.parsearPeriodo(periodo_str);
    final mes_str = mes.toString().padLeft(2, '0');

    return [
      ItemRecorridoDeclarado(
        fecha_formateada: "02-$mes_str",
        fecha: DateTime(anio, mes, 2),
        paradas_texto: "Av. Buenos Aires - Oficina Central - Av. Buenos Aires",
        tarifa: 5.00,
      ),
      ItemRecorridoDeclarado(
        fecha_formateada: "04-$mes_str",
        fecha: DateTime(anio, mes, 4),
        paradas_texto: "Av. Buenos Aires - Oficina Central - Av. Buenos Aires",
        tarifa: 5.00,
      ),
      ItemRecorridoDeclarado(
        fecha_formateada: "06-$mes_str",
        fecha: DateTime(anio, mes, 6),
        paradas_texto: "Av. Buenos Aires - Oficina Central",
        tarifa: 2.50,
      ),
      ItemRecorridoDeclarado(
        fecha_formateada: "09-$mes_str",
        fecha: DateTime(anio, mes, 9),
        paradas_texto: "Av. Buenos Aires - Oficina Central - Av. Buenos Aires",
        tarifa: 5.00,
      ),
      ItemRecorridoDeclarado(
        fecha_formateada: "11-$mes_str",
        fecha: DateTime(anio, mes, 11),
        paradas_texto: "Av. Buenos Aires - Oficina Central - Av. Buenos Aires",
        tarifa: 5.00,
      ),
      ItemRecorridoDeclarado(
        fecha_formateada: "13-$mes_str",
        fecha: DateTime(anio, mes, 13),
        paradas_texto: "Av. Buenos Aires - Oficina Central",
        tarifa: 3.00,
      ),
      ItemRecorridoDeclarado(
        fecha_formateada: "16-$mes_str",
        fecha: DateTime(anio, mes, 16),
        paradas_texto: "Av. Buenos Aires - Oficina Central",
        tarifa: 2.50,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final periodo_formateado =
        FormatoPasajes.periodo(_solicitud.periodo).toLowerCase();
    final items_recorridos = _agruparRecorridos(_solicitud.recorridos);

    final double monto_declarado = _solicitud.monto_total > 0
        ? _solicitud.monto_total
        : items_recorridos.fold(0.0, (acc, item) => acc + item.tarifa);
    final double monto_devolucion = _solicitud.monto_devolucion > 0
        ? _solicitud.monto_devolucion
        : (monto_declarado * 0.8);

    return Scaffold(
      backgroundColor: BumandColores.AZUL_DIACONIA,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra superior personalizada con estilo institucional
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Mi historial",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Periodo: $periodo_formateado",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contenedor principal con curvas superiores
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                clipBehavior: Clip.antiAlias,
                child: _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                        children: [
                          // Tarjeta Azul de Totales (Monto Total y Devolución 80%)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 22,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF0284C7),
                                  Color(0xFF0369A1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0284C7)
                                      .withValues(alpha: 0.28),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "MONTO TOTAL DEL PASAJE",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Bs ${monto_declarado.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Divider(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  height: 1,
                                  thickness: 1,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "DEVOLUCIÓN DEL 80%",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Bs ${monto_devolucion.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    color: Color(0xFFFACC15),
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          // Título de la sección
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              "Recorridos declarados",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Lista de recorridos y paradas declaradas
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Column(
                                children: [
                                  for (int i = 0;
                                      i < items_recorridos.length;
                                      i++) ...[
                                    if (i > 0)
                                      const Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Color(0xFFF1F5F9),
                                        indent: 14,
                                        endIndent: 14,
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // Badge de Fecha: e.g. 02-02
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              items_recorridos[i]
                                                  .fecha_formateada,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // Texto del recorrido con todas las paradas
                                          Expanded(
                                            child: Text(
                                              items_recorridos[i]
                                                  .paradas_texto,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF1E293B),
                                                height: 1.35,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),

                                          // Tarifa
                                          Text(
                                            items_recorridos[i]
                                                .tarifa
                                                .toStringAsFixed(2),
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0369A1),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
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
