import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../proveedores/pasajes-proveedor.dart';

class HistorialParadasPantalla extends ConsumerStatefulWidget {
  const HistorialParadasPantalla({super.key});

  @override
  ConsumerState<HistorialParadasPantalla> createState() =>
      _HistorialParadasPantallaState();
}

class _HistorialParadasPantallaState
    extends ConsumerState<HistorialParadasPantalla> {
  String _filtro_tramo = 'todos';
  bool _cargando = true;
  Map<String, dynamic>? _datos_historial;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    setState(() => _cargando = true);
    final repo = ref.read(pasajes_repositorio_proveedor);
    final res = await repo.obtenerHistorialConsolidadoParadas(
      tramo: _filtro_tramo,
    );
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _datos_historial = res.datos;
    });
  }

  @override
  Widget build(BuildContext context) {
    final recorridos = (_datos_historial?['recorridos'] as List<dynamic>?) ?? [];
    final paradas_frecuentes =
        (_datos_historial?['paradas_mas_frecuentes'] as List<dynamic>?) ?? [];
    final total_recorridos = _datos_historial?['total_recorridos'] ?? 0;
    final total_gastado_bs =
        (_datos_historial?['total_gastado_bs'] as num?)?.toDouble() ?? 0.0;
    final total_devolucion_bs =
        (_datos_historial?['total_devolucion_bs'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: BumandColores.FONDO,
      appBar: const BarraSuperiorBumand(
        titulo: 'Historial de Paradas',
        subtitulo: 'Trazabilidad y paradas frecuentes',
      ),
      body: RefreshIndicator(
        onRefresh: _cargarHistorial,
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Tarjeta de Resumen Consolidado
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.route_rounded,
                                color: BumandColores.AZUL_DIACONIA,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Consolidado de Transporte',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: BumandColores.AZUL_MARINO_SECUNDARIO,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _itemMetrica(
                                'Recorridos',
                                '$total_recorridos',
                                Icons.directions_bus_outlined,
                                BumandColores.AZUL_DIACONIA,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _itemMetrica(
                                'Gasto Total',
                                'Bs ${total_gastado_bs.toStringAsFixed(2)}',
                                Icons.account_balance_wallet_outlined,
                                const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _itemMetrica(
                                'Devolución 80%',
                                'Bs ${total_devolucion_bs.toStringAsFixed(2)}',
                                Icons.check_circle_outline,
                                BumandColores.AMARILLO_RADIANTE,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Paradas Frecuentes Destacadas
                  if (paradas_frecuentes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Paradas más utilizadas',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: BumandColores.AZUL_MARINO_SECUNDARIO,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: paradas_frecuentes.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final p = paradas_frecuentes[i] as Map<String, dynamic>;
                          final nombre = p['nombre'] ?? '';
                          final frec = p['frecuencia'] ?? 0;
                          return Chip(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            avatar: const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Color(0xFFDC2626),
                            ),
                            label: Text(
                              '$nombre ($frec)',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          );
                        },
                      ),
                    ),
                  ],

                  // Filtro por Sentido (Ida / Vuelta / Todos)
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _filtroChip('Todos', 'todos'),
                      const SizedBox(width: 8),
                      _filtroChip('Solo Ida', 'ida'),
                      const SizedBox(width: 8),
                      _filtroChip('Solo Vuelta', 'vuelta'),
                    ],
                  ),

                  // Lista Cronológica de Paradas
                  const SizedBox(height: 14),
                  if (recorridos.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'No se encontraron paradas registradas',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  else
                    ...recorridos.map((r) => _tarjetaRecorrido(r as Map<String, dynamic>)),
                ],
              ),
      ),
    );
  }

  Widget _filtroChip(String label, String valor) {
    final activo = _filtro_tramo == valor;
    return ChoiceChip(
      label: Text(label),
      selected: activo,
      selectedColor: BumandColores.AZUL_DIACONIA,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: activo ? Colors.white : const Color(0xFF64748B),
      ),
      side: BorderSide(color: activo ? BumandColores.AZUL_DIACONIA : const Color(0xFFCBD5E1)),
      onSelected: (_) {
        setState(() => _filtro_tramo = valor);
        _cargarHistorial();
      },
    );
  }

  Widget _itemMetrica(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          Text(
            titulo,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaRecorrido(Map<String, dynamic> r) {
    final tramo = (r['tramo'] ?? 'ida').toString().toLowerCase();
    final es_ida = tramo == 'ida';
    final fecha = r['fecha'] ?? '';
    final dia = r['dia_semana'] ?? '';
    final origen = r['origen'] ?? '';
    final destino = r['destino'] ?? '';
    final tarifa = (r['tarifa'] as num?)?.toDouble() ?? 0.0;
    final medio = r['medio_transporte'] ?? 'Minibús';
    final actividad = r['tipo_actividad'] ?? 'Prácticas';
    final secuencia = (r['paradas_secuencia'] as List<dynamic>?) ?? [origen, destino];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: es_ida
                          ? BumandColores.AZUL_DIACONIA.withValues(alpha: 0.12)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      es_ida ? 'TRAMO IDA' : 'TRAMO VUELTA',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: es_ida ? BumandColores.AZUL_DIACONIA : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$dia, $fecha',
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Text(
                'Bs ${tarifa.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: BumandColores.AZUL_MARINO_SECUNDARIO,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Secuencia de paradas
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              for (int i = 0; i < secuencia.length; i++) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      i == 0
                          ? Icons.trip_origin
                          : i == secuencia.length - 1
                              ? Icons.place
                              : Icons.circle,
                      size: i == 0 || i == secuencia.length - 1 ? 14 : 6,
                      color: i == 0
                          ? BumandColores.AZUL_DIACONIA
                          : i == secuencia.length - 1
                              ? const Color(0xFFDC2626)
                              : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      secuencia[i].toString(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: i == 0 || i == secuencia.length - 1 ? FontWeight.bold : FontWeight.normal,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                if (i < secuencia.length - 1)
                  const Text('→', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
              ],
            ],
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  medio,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  actividad,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
                ),
              ),
              const Spacer(),
              Text(
                'Reembolso 80%: Bs ${(tarifa * 0.8).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0D9488)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
