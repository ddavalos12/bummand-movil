import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../modelos/refrigerio-modelo.dart';
import '../proveedores/refrigerios-proveedor.dart';
import '../widgets/constancia-recojo-modal.dart';
import '../widgets/dialogo-confirmar-recojo.dart';

class RefrigeriosPantalla extends ConsumerWidget {
  const RefrigeriosPantalla({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refrigerios = ref.watch(refrigerios_filtrados_proveedor);
    final refrigerio_activo = ref.watch(refrigerio_activo_hoy_proveedor);
    final total_recogidos = ref.watch(total_refrigerios_recogidos_proveedor);
    final total_programados = ref.watch(total_refrigerios_programados_proveedor);
    final porcentaje = ref.watch(porcentaje_recojo_proveedor);
    final filtro_estado = ref.watch(filtro_estado_recojo_proveedor);

    return Scaffold(
      backgroundColor: BumandColores.fondo,
      appBar: const BarraSuperiorBumand(
        titulo: 'Mis Refrigerios',
        subtitulo: 'Registro y Constancia de Recojo',
        mostrar_perfil: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(refrigerios_proveedor);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
          children: [
            // Tarjeta Hero del Refrigerio Activo de la Jornada
            if (refrigerio_activo != null) ...[
              _construirHeroRefrigerioActivo(context, refrigerio_activo),
              const SizedBox(height: 16),
            ],

            // Métricas del Becario
            Row(
              children: [
                Expanded(
                  child: _construirTarjetaMetrica(
                    titulo: 'RACIONES RECOGIDAS',
                    valor: '$total_recogidos de $total_programados',
                    color_valor: BumandColores.azulMarinoSecundario,
                    subtitulo: 'Conformidad digital',
                    icono: Icons.check_circle_outline_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _construirTarjetaMetrica(
                    titulo: 'ASISTENCIA / RECOJO',
                    valor: '$porcentaje%',
                    color_valor: const Color(0xFF059669),
                    subtitulo: 'Viernes formativos',
                    icono: Icons.trending_up_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Barra de Búsqueda
            Container(
              decoration: BoxDecoration(
                color: BumandColores.blanco,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BumandColores.grisClaro),
              ),
              child: TextField(
                onChanged: (val) {
                  ref
                      .read(filtro_busqueda_refrigerios_proveedor.notifier)
                      .actualizar(val);
                },
                style: GoogleFonts.montserrat(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar por menú, jornada o sede...',
                  hintStyle: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: BumandColores.grisMedio,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: BumandColores.grisMedio,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Chips de Filtro
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _construirChipFiltro(
                    etiqueta: 'Todos',
                    seleccionado: filtro_estado == null,
                    alTocar: () => ref
                        .read(filtro_estado_recojo_proveedor.notifier)
                        .seleccionar(null),
                  ),
                  const SizedBox(width: 8),
                  _construirChipFiltro(
                    etiqueta: 'Recogidos',
                    seleccionado: filtro_estado == 'recogido',
                    alTocar: () => ref
                        .read(filtro_estado_recojo_proveedor.notifier)
                        .seleccionar('recogido'),
                  ),
                  const SizedBox(width: 8),
                  _construirChipFiltro(
                    etiqueta: 'Pendientes',
                    seleccionado: filtro_estado == 'pendiente',
                    alTocar: () => ref
                        .read(filtro_estado_recojo_proveedor.notifier)
                        .seleccionar('pendiente'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Encabezado de la lista
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Historial de Refrigerios Asignados',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: BumandColores.azulMarinoSecundario,
                  ),
                ),
                Text(
                  '${refrigerios.length} registros',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: BumandColores.textoSecundario,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Lista de Tarjetas
            if (refrigerios.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BumandColores.blanco,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: BumandColores.grisClaro),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.search_off_rounded,
                      size: 40,
                      color: BumandColores.grisMedio,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No se encontraron refrigerios',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: BumandColores.negro,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...refrigerios.map(
                (item) => _construirTarjetaHistorial(context, item),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _construirHeroRefrigerioActivo(BuildContext context, RefrigerioModelo item) {
    final ya_recogido = item.recogido;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: ya_recogido
              ? [
                  BumandColores.azulMarinoSecundario,
                  BumandColores.azulMarinoProfundo,
                ]
              : [
                  BumandColores.azulMarinoProfundo,
                  const Color(0xFF024E79),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: BumandColores.azulMarinoProfundo.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera del Hero
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ya_recogido
                      ? const Color(0xFF10B981)
                      : BumandColores.amarilloRadiante,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ya_recogido ? 'RACIÓN RECOGIDA' : 'DISPONIBLE PARA RECOJO',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: ya_recogido
                        ? BumandColores.blanco
                        : BumandColores.azulMarinoSecundario,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: Color(0xFFD6F1F7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.horario_distribucion,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFFD6F1F7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Título de la jornada
          Text(
            item.evento_o_jornada,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: BumandColores.blanco,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.apartment_rounded,
                size: 14,
                color: Color(0xFF90D5E4),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${item.sede_nombre} · ${item.bloque}',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: const Color(0xFFE0F7FA),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Menú Detallado
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BumandColores.blanco.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: BumandColores.blanco.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.restaurant_rounded,
                  color: BumandColores.amarilloRadiante,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menú del Día:',
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD6F1F7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.menu_detalle,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: BumandColores.blanco,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Botón Principal de Acción
          if (!ya_recogido) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: BumandColores.amarilloRadiante,
                foregroundColor: BumandColores.azulMarinoSecundario,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 2,
              ),
              onPressed: () => DialogoConfirmarRecojo.mostrar(context, item),
              icon: const Icon(Icons.how_to_reg_rounded, size: 20),
              label: Text(
                'Registrar que Recogí mi Refrigerio',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF34D399).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF34D399),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Recogido (${item.hora_recojo ?? "Hoy"})',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: BumandColores.blanco,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BumandColores.blanco,
                    side: const BorderSide(color: BumandColores.blanco),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  ),
                  onPressed: () => ConstanciaRecojoModal.mostrar(context, item),
                  icon: const Icon(Icons.receipt_long_rounded, size: 16),
                  label: Text(
                    'Ver Constancia',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirTarjetaMetrica({
    required String titulo,
    required String valor,
    required Color color_valor,
    required String subtitulo,
    required IconData icono,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BumandColores.blanco,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BumandColores.grisClaro),
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
            children: [
              Icon(icono, size: 14, color: color_valor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  titulo,
                  style: GoogleFonts.montserrat(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: BumandColores.textoSecundario,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color_valor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              color: BumandColores.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirChipFiltro({
    required String etiqueta,
    required bool seleccionado,
    required VoidCallback alTocar,
  }) {
    return InkWell(
      onTap: alTocar,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: seleccionado
              ? BumandColores.azulMarinoProfundo
              : BumandColores.blanco,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: seleccionado
                ? BumandColores.azulMarinoProfundo
                : BumandColores.grisClaro,
          ),
        ),
        child: Text(
          etiqueta,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: seleccionado ? BumandColores.blanco : BumandColores.negro,
          ),
        ),
      ),
    );
  }

  Widget _construirTarjetaHistorial(BuildContext context, RefrigerioModelo item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BumandColores.blanco,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BumandColores.grisClaro),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: Icono, Jornada y Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: item.recogido
                      ? const Color(0xFFD1FAE5)
                      : BumandColores.azulMarinoProfundo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  item.recogido
                      ? Icons.check_circle_outline_rounded
                      : Icons.lunch_dining_rounded,
                  color: item.recogido
                      ? const Color(0xFF059669)
                      : BumandColores.azulMarinoProfundo,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.evento_o_jornada,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: BumandColores.azulMarinoSecundario,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 11,
                          color: BumandColores.grisMedio,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.fecha,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: BumandColores.textoSecundario,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('·', style: TextStyle(color: BumandColores.grisMedio)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${item.sede_nombre} (${item.bloque})',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: BumandColores.textoSecundario,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _construirBadgeEstado(item.recogido),
            ],
          ),
          const SizedBox(height: 10),

          // Menú entregado
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: BumandColores.fondo,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.restaurant_menu_rounded,
                  size: 14,
                  color: BumandColores.azulCieloSuave,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.menu_detalle,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: BumandColores.negro,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: BumandColores.grisClaro),
          const SizedBox(height: 10),

          // Pie de tarjeta con responsable y botón
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Despachó: ${item.responsable_entrega}',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: BumandColores.textoSecundario,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.recogido) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: BumandColores.azulCieloSuave),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => ConstanciaRecojoModal.mostrar(context, item),
                  icon: const Icon(
                    Icons.receipt_long_rounded,
                    size: 14,
                    color: BumandColores.azulMarinoProfundo,
                  ),
                  label: Text(
                    'Ver Constancia',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: BumandColores.azulMarinoProfundo,
                    ),
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BumandColores.azulMarinoProfundo,
                    foregroundColor: BumandColores.blanco,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    elevation: 0,
                  ),
                  onPressed: () => DialogoConfirmarRecojo.mostrar(context, item),
                  icon: const Icon(Icons.how_to_reg_rounded, size: 14),
                  label: Text(
                    'Recoger',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirBadgeEstado(bool recogido) {
    if (recogido) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFD1FAE5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'Recogido',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF065F46),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Pendiente',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF92400E),
        ),
      ),
    );
  }
}
