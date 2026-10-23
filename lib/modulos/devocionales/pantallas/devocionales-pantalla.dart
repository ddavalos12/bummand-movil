import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../../../widgets-comunes/cargando-skeleton.dart';
import '../../../widgets-comunes/estado-vacio-widget.dart';
import '../../animaciones/animaciones.dart';
import '../modelos/versiculo-diario-modelo.dart';
import '../proveedores/devocionales-proveedor.dart';
import '../repositorios/devocionales-repositorio.dart';
import '../widgets/selector-cita-biblica-dialogo.dart';

class DevocionalesPantalla extends ConsumerStatefulWidget {
  const DevocionalesPantalla({super.key});

  @override
  ConsumerState<DevocionalesPantalla> createState() =>
      _DevocionalesPantallaState();
}

class _DevocionalesPantallaState extends ConsumerState<DevocionalesPantalla> {
  bool _mostrar_celebracion = false;

  void _mostrarDetalleDevocional(BuildContext context, DevocionalModelo d) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Hero(
          tag: 'hero-devocional-${d.id}',
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: BumandColores.AZUL_DIACONIA.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            d.cita_biblica,
                            style: const TextStyle(
                              color: BumandColores.AZUL_DIACONIA,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          d.fecha,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      d.titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: BumandColores.NEGRO,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Reflexión Bíblica:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: BumandColores.AZUL_DIACONIA,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d.reflexion,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Petición y Oración:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: BumandColores.NARANJA_OSCURO,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d.oracion_peticion,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    if (d.comentario_pastoral != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.church_outlined,
                                  size: 16,
                                  color: Color(0xFF15803D),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Acompañamiento Pastoral:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              d.comentario_pastoral!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF166534),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cerrar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _abrirFormularioNuevoDevocional({
    String? cita_inicial,
    String? titulo_inicial,
  }) {
    final cita_ctrl = TextEditingController(text: cita_inicial ?? '');
    final titulo_ctrl = TextEditingController(text: titulo_inicial ?? '');
    final reflexion_ctrl = TextEditingController();
    final oracion_ctrl = TextEditingController();
    final form_key = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: form_key,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nuevo Devocional',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: BumandColores.AZUL_DIACONIA,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cita_ctrl,
                  readOnly: true,
                  onTap: () async {
                    final seleccion = await SelectorCitaBiblicaDialogo.mostrar(
                      ctx,
                      cita_inicial: cita_ctrl.text.isNotEmpty
                          ? cita_ctrl.text
                          : 'Filipenses 4:13',
                    );
                    if (seleccion != null) {
                      cita_ctrl.text = seleccion;
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Cita bíblica canónica',
                    hintText: 'Toca para seleccionar libro, capítulo y rango',
                    prefixIcon: const Icon(Icons.auto_stories_outlined),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.tune_outlined,
                        color: BumandColores.AZUL_DIACONIA,
                      ),
                      tooltip: 'Selector canónico de pasaje bíblico',
                      onPressed: () async {
                        final seleccion =
                            await SelectorCitaBiblicaDialogo.mostrar(
                          ctx,
                          cita_inicial: cita_ctrl.text.isNotEmpty
                              ? cita_ctrl.text
                              : 'Filipenses 4:13',
                        );
                        if (seleccion != null) {
                          cita_ctrl.text = seleccion;
                        }
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => v?.trim().isEmpty ?? true
                      ? 'Seleccione una cita bíblica'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titulo_ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Tema o título de la meditación',
                    prefixIcon: Icon(Icons.title_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: reflexion_ctrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reflexión espiritual y aplicación',
                    prefixIcon: Icon(Icons.edit_note_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: oracion_ctrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Motivo o petición de oración',
                    prefixIcon: Icon(Icons.favorite_border),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () async {
                    if (form_key.currentState?.validate() ?? false) {
                      final repo = ref.read(devocionales_repositorio_proveedor);
                      await repo.guardarDevocional(
                        cita_biblica: cita_ctrl.text.trim(),
                        titulo: titulo_ctrl.text.trim(),
                        reflexion: reflexion_ctrl.text.trim(),
                        oracion_peticion: oracion_ctrl.text.trim(),
                      );
                      ref.invalidate(devocionales_lista_proveedor);
                      if (!mounted) return;
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      setState(() => _mostrar_celebracion = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Devocional registrado con éxito'),
                          backgroundColor: BumandColores.AZUL_DIACONIA,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Guardar Devocional'),
                  style: FilledButton.styleFrom(
                    backgroundColor: BumandColores.AZUL_DIACONIA,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devocionales_async = ref.watch(devocionales_lista_proveedor);
    final versiculo_async = ref.watch(versiculo_diario_proveedor);

    return Scaffold(
      backgroundColor: BumandColores.FONDO,
      appBar: const BarraSuperiorBumand(
        titulo: 'Devocionales y Vida Espiritual',
        subtitulo: 'Reflexión y formación diaconal',
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: BumandColores.NARANJA_OSCURO,
            backgroundColor: BumandColores.AZUL_DIACONIA,
            onRefresh: () async {
              ref.invalidate(devocionales_lista_proveedor);
              ref.invalidate(versiculo_diario_proveedor);
              await ref.read(devocionales_lista_proveedor.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _construirTarjetaVersiculoDelDia(versiculo_async),
                const SizedBox(height: 16),
                devocionales_async.when(
                  data: (res) {
                    final devocionales = res.datos ?? [];
                    if (devocionales.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 80),
                        child: EstadoVacioWidget(
                          titulo: 'No tienes devocionales registrados',
                          mensaje:
                              'Presiona el botón + o "Meditar y Registrar" para registrar tu meditación bíblica y crecimiento diaconal.',
                          icono: Icons.menu_book_outlined,
                          texto_boton_accion: 'Nuevo devocional',
                          alPresionarAccion: _abrirFormularioNuevoDevocional,
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Historial de Devocionales',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: BumandColores.AZUL_DIACONIA,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: BumandColores.AZUL_DIACONIA.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${devocionales.length} registrados',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: BumandColores.AZUL_DIACONIA,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(devocionales.length, (index) {
                          final d = devocionales[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: ElementoEscalonado(
                              indice: index,
                              hijo: Hero(
                                tag: 'hero-devocional-${d.id}',
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: TarjetaSpotlight(
                                    color_luz: const Color(0x2817B4C4),
                                    padding: const EdgeInsets.all(16),
                                    alPresionar: () =>
                                        _mostrarDetalleDevocional(context, d),
                                    hijo: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: BumandColores
                                                    .AZUL_DIACONIA
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                d.cita_biblica,
                                                style: const TextStyle(
                                                  color: BumandColores
                                                      .AZUL_DIACONIA,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              d.fecha,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          d.titulo,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: BumandColores.NEGRO,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          d.reflexion,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade800,
                                            height: 1.3,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.favorite,
                                              size: 16,
                                              color: BumandColores.NARANJA,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Oración: ${d.oracion_peticion}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                  color: BumandColores
                                                      .NARANJA_OSCURO,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (d.comentario_pastoral != null) ...[
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0FDF4),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: const Color(0xFF86EFAC),
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Icon(
                                                  Icons.church_outlined,
                                                  size: 18,
                                                  color: Color(0xFF15803D),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text(
                                                        'Respuesta Pastoral:',
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 11,
                                                          color:
                                                              Color(0xFF15803D),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        d.comentario_pastoral!,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Color(0xFF166534),
                                                        ),
                                                      ),
                                                    ],
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
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 70),
                      ],
                    );
                  },
                  loading: () =>
                      CargandoSkeleton.lista(cantidad: 3, alto_item: 130),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ],
            ),
          ),
          RafagaCelebracion(
            activo: _mostrar_celebracion,
            alTerminar: () => setState(() => _mostrar_celebracion = false),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_devocional',
        onPressed: _abrirFormularioNuevoDevocional,
        backgroundColor: BumandColores.AZUL_DIACONIA,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Devocional'),
      ),
    );
  }

  Widget _construirTarjetaVersiculoDelDia(
    AsyncValue<VersiculoDiarioModelo> versiculo_async,
  ) {
    final versiculo = versiculo_async.value ??
        const VersiculoDiarioModelo(
          cita: 'Filipenses 4:13',
          libro: 'Filipenses',
          capitulo: 4,
          versiculo: 13,
          texto: 'Todo lo puedo en Cristo que me fortalece.',
          version: 'Reina-Valera 1960 (RVR60)',
          tema: 'Fortaleza y Servicio',
          reflexion_diaconal:
              'En cada labor y apoyo formativo dentro de Diaconía, Cristo es quien renueva nuestras capacidades para servir con excelencia.',
        );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F2B48),
            BumandColores.AZUL_DIACONIA,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2B48).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: BumandColores.NARANJA_OSCURO.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: BumandColores.NARANJA.withValues(alpha: 0.5),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 14,
                      color: BumandColores.NARANJA,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'VERSÍCULO DEL DÍA',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: BumandColores.NARANJA,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Período Formativo',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '«${versiculo.texto}»',
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                versiculo.cita,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: BumandColores.TURQUESA_DIACONIA,
                ),
              ),
              Text(
                ' • ${versiculo.version}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: BumandColores.NARANJA,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        versiculo.tema,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: BumandColores.NARANJA,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        versiculo.reflexion_diaconal,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _abrirFormularioNuevoDevocional(
                  cita_inicial: versiculo.cita,
                  titulo_inicial: '${versiculo.tema} - Meditación',
                );
              },
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text(
                'Meditar y Registrar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: BumandColores.TURQUESA_DIACONIA,
                foregroundColor: BumandColores.NEGRO,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
