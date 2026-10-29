import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../nucleo/utilidades/resultado.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../../../widgets-comunes/cargando-skeleton.dart';
import '../../../widgets-comunes/estado-vacio-widget.dart';
import '../../animaciones/animaciones.dart';
import '../../autenticacion/proveedores/autenticacion-proveedor.dart';
import '../modelos/cita-seguimiento-modelo.dart';
import '../modelos/versiculo-diario-modelo.dart';
import '../proveedores/devocionales-proveedor.dart';
import '../repositorios/devocionales-repositorio.dart';
import '../widgets/dar-cita-seguimiento-modal.dart';
import '../widgets/registrar-acuerdos-cita-modal.dart';
import '../widgets/selector-cita-biblica-dialogo.dart';

class DevocionalesPantalla extends ConsumerStatefulWidget {
  const DevocionalesPantalla({super.key});

  @override
  ConsumerState<DevocionalesPantalla> createState() =>
      _DevocionalesPantallaState();
}

class _DevocionalesPantallaState extends ConsumerState<DevocionalesPantalla> {
  bool _mostrar_celebracion = false;
  int? _filtro_becario_id;

  static const List<Map<String, dynamic>> SUPERVISADOS_LISTA = [
    {
      'id': 10,
      'nombre': 'María Catunta Laime',
      'carrera': 'Ing. Comercial',
      'sede': 'Central',
    },
    {
      'id': 11,
      'nombre': 'Carlos Mamani Choque',
      'carrera': 'Contaduría Pública',
      'sede': 'El Alto',
    },
    {
      'id': 12,
      'nombre': 'Ana Quispe Condori',
      'carrera': 'Enfermería',
      'sede': 'Central',
    },
    {
      'id': 13,
      'nombre': 'Joel Flores Ticona',
      'carrera': 'Trabajo Social',
      'sede': 'Viacha',
    },
    {
      'id': 14,
      'nombre': 'Ruth Mendoza Alarcón',
      'carrera': 'Derecho',
      'sede': 'Central',
    },
  ];

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
    final estado_auth = ref.watch(autenticacion_proveedor);
    final rol_crudo = (estado_auth.usuario?.rol ?? 'becario')
        .toString()
        .toLowerCase()
        .trim();
    final es_admin = rol_crudo == 'admin' || rol_crudo == 'administrador';
    final es_supervisor = rol_crudo == 'supervisor';

    if (es_admin) {
      return _construirVistaAdmin(context);
    }

    if (es_supervisor) {
      return _construirVistaSupervisor(context);
    }

    return _construirVistaBecario(context);
  }

  // 1. VISTA DE ACCESO RESTRINGIDO PARA ADMINISTRADOR
  Widget _construirVistaAdmin(BuildContext context) {
    return Scaffold(
      backgroundColor: BumandColores.FONDO,
      appBar: const BarraSuperiorBumand(
        titulo: 'Seguimiento y Retroalimentación',
        subtitulo: 'Acceso Restringido',
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 48,
                  color: BumandColores.AZUL_DIACONIA,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Módulo Exclusivo para Supervisor y Becarios',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: BumandColores.NEGRO,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Este espacio móvil está dedicado a las sesiones pastorales de seguimiento individualizado y retroalimentación formativa de los becarios.\n\nComo Administrador, puedes consultar y gestionar los consolidados y reportes globales desde el panel institucional web.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver al Menú Principal'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BumandColores.AZUL_DIACONIA,
                  side: const BorderSide(color: BumandColores.AZUL_DIACONIA),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. VISTA EXCLUSIVA PARA SUPERVISOR
  Widget _construirVistaSupervisor(BuildContext context) {
    final citas_async = ref.watch(citas_seguimiento_proveedor);
    final devocionales_async = ref.watch(devocionales_lista_proveedor);

    return Scaffold(
      backgroundColor: BumandColores.FONDO,
      appBar: const BarraSuperiorBumand(
        titulo: 'Seguimiento y Retroalimentación',
        subtitulo: 'Supervisión Diaconal y Citas',
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_cita_supervisor',
        onPressed: () => DarCitaSeguimientoModal.mostrar(context),
        backgroundColor: BumandColores.AZUL_DIACONIA,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Dar Cita a Supervisado'),
      ),
      body: RefreshIndicator(
        color: BumandColores.NARANJA_OSCURO,
        backgroundColor: BumandColores.AZUL_DIACONIA,
        onRefresh: () async {
          ref.invalidate(citas_seguimiento_proveedor);
          ref.invalidate(devocionales_lista_proveedor);
          await ref.read(citas_seguimiento_proveedor.future);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // Tarjeta de Bienvenida y Botón Destacado
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    BumandColores.azulMarinoSecundario,
                    BumandColores.AZUL_DIACONIA,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: BumandColores.azulMarinoSecundario.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.supervisor_account_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Panel de Supervisión Diaconal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Coordina encuentros pastorales, evalúa avances y registra acuerdos de crecimiento formativo con tu cohorte de becarios.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFFD6F1F7),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => DarCitaSeguimientoModal.mostrar(context),
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: const Text(
                        'Dar Cita a Supervisado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BumandColores.amarilloRadiante,
                        foregroundColor: BumandColores.azulMarinoSecundario,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Sección: Mis Becarios Supervisados
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mis Becarios Supervisados',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: BumandColores.AZUL_DIACONIA,
                  ),
                ),
                Text(
                  '${SUPERVISADOS_LISTA.length} en cohorte',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Chip Todos
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: _filtro_becario_id == null,
                      label: const Text('Todos'),
                      onSelected: (_) =>
                          setState(() => _filtro_becario_id = null),
                      selectedColor: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.15),
                      checkmarkColor: BumandColores.AZUL_DIACONIA,
                    ),
                  ),
                  ...SUPERVISADOS_LISTA.map((b) {
                    final seleccionado = _filtro_becario_id == b['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: Icon(
                          Icons.person_outline_rounded,
                          size: 16,
                          color: seleccionado
                              ? Colors.white
                              : BumandColores.AZUL_DIACONIA,
                        ),
                        backgroundColor: seleccionado
                            ? BumandColores.AZUL_DIACONIA
                            : Colors.white,
                        label: Text(
                          b['nombre'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: seleccionado
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _filtro_becario_id =
                                seleccionado ? null : (b['id'] as int);
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sección: Citas de Seguimiento Agendadas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Citas de Seguimiento Agendadas',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: BumandColores.AZUL_DIACONIA,
                  ),
                ),
                citas_async.maybeWhen(
                  data: (res) {
                    final citas = res.datos ?? [];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${citas.length} registradas',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: BumandColores.AZUL_DIACONIA,
                        ),
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Lista de Citas
            citas_async.when(
              data: (res) {
                var citas = res.datos ?? [];
                if (_filtro_becario_id != null) {
                  citas = citas
                      .where((c) => c.becario_id == _filtro_becario_id)
                      .toList();
                }

                if (citas.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.event_busy_rounded,
                          size: 40,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'No hay citas agendadas',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Utiliza el botón superior para agendar una sesión con tus becarios.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () =>
                              DarCitaSeguimientoModal.mostrar(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Agendar Cita Ahora'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: citas.map((c) {
                    final es_realizada = c.esta_realizada;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: es_realizada
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFE2E8F0),
                        ),
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
                          // Cabecera de la Cita: Nombre y Estado
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.person_rounded,
                                        size: 18,
                                        color: BumandColores.AZUL_DIACONIA,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        c.becario_nombre,
                                        style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: es_realizada
                                      ? const Color(0xFFDCFCE7)
                                      : (c.esta_reprogramada
                                          ? const Color(0xFFFEF3C7)
                                          : const Color(0xFFE0F2FE)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  c.estado.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: es_realizada
                                        ? const Color(0xFF15803D)
                                        : (c.esta_reprogramada
                                            ? const Color(0xFFB45309)
                                            : BumandColores.azulMarinoSecundario),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Fecha, Hora y Modalidad
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${c.fecha_cita} • ${c.hora_cita}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                c.es_presencial
                                    ? Icons.business_rounded
                                    : Icons.videocam_rounded,
                                size: 14,
                                color: c.es_presencial
                                    ? BumandColores.AZUL_DIACONIA
                                    : BumandColores.azulCieloSuave,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  c.lugar_o_enlace,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Motivo
                          Text(
                            c.motivo_retroalimentacion,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF334155),
                              height: 1.3,
                            ),
                          ),

                          // Cita Bíblica
                          if (c.cita_biblica != null &&
                              c.cita_biblica!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_stories_rounded,
                                    size: 13,
                                    color: Color(0xFF15803D),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    c.cita_biblica!,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Acuerdos registrados si existen
                          if (c.acuerdos_retroalimentacion != null &&
                              c.acuerdos_retroalimentacion!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.handshake_rounded,
                                        size: 14,
                                        color: Color(0xFF0D9488),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'Acuerdos Alcanzados:',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0D9488),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c.acuerdos_retroalimentacion!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Botón para Registrar Acuerdos
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () =>
                                    RegistrarAcuerdosCitaModal.mostrar(
                                  context,
                                  cita: c,
                                ),
                                icon: Icon(
                                  es_realizada
                                      ? Icons.edit_note_rounded
                                      : Icons.check_circle_outline_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  es_realizada
                                      ? 'Editar Acuerdos'
                                      : 'Registrar Acuerdos',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: BumandColores.AZUL_DIACONIA,
                                  side: const BorderSide(
                                    color: BumandColores.AZUL_DIACONIA,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (err, _) => Center(child: Text('Error al cargar citas: $err')),
            ),
            const SizedBox(height: 20),

            // Sección: Bitácora de Reflexiones de Supervisados
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bitácora de Reflexiones de Supervisados',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: BumandColores.AZUL_DIACONIA,
                  ),
                ),
                devocionales_async.maybeWhen(
                  data: (res) => Text(
                    '${res.datos?.length ?? 0} registros',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            devocionales_async.when(
              data: (res) {
                final devs = res.datos ?? [];
                if (devs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No hay devocionales recientes registrados por los becarios.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  );
                }
                return Column(
                  children: devs.map((d) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                d.cita_biblica,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: BumandColores.AZUL_DIACONIA,
                                ),
                              ),
                              Text(
                                d.fecha,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d.titulo,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            d.reflexion,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  _mostrarDetalleDevocional(context, d),
                              child: const Text('Ver Detalle y Acompañar'),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => CargandoSkeleton.lista(cantidad: 2, alto_item: 90),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // 3. VISTA PARA BECARIO (CONSERVA 100% RETROCOMPATIBILIDAD CON TESTS EXISTENTES)
  Widget _construirVistaBecario(BuildContext context) {
    final devocionales_async = ref.watch(devocionales_lista_proveedor);
    final versiculo_async = ref.watch(versiculo_diario_proveedor);
    final citas_async = ref.watch(citas_seguimiento_proveedor);

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
              ref.invalidate(citas_seguimiento_proveedor);
              await ref.read(devocionales_lista_proveedor.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // Versículo del Día (Crucial para tests existentes)
                _construirTarjetaVersiculoDelDia(versiculo_async),
                const SizedBox(height: 16),

                // Sección: Mis Citas de Seguimiento con mi Supervisor (TAREA-16)
                _construirSeccionCitasBecario(context, citas_async),
                const SizedBox(height: 16),

                // Historial de Devocionales (Crucial para tests existentes)
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

  // Sección de Citas para el Becario
  Widget _construirSeccionCitasBecario(
    BuildContext context,
    AsyncValue<Resultado<List<CitaSeguimientoModelo>>> citas_async,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Mis Citas de Seguimiento con mi Supervisor',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: BumandColores.AZUL_DIACONIA,
                ),
              ),
            ),
            const SizedBox(width: 8),
            citas_async.maybeWhen(
              data: (res) {
                final citas = res.datos ?? [];
                if (citas.isEmpty) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${citas.length} agendadas',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: BumandColores.AZUL_DIACONIA,
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 10),
        citas_async.when(
          data: (res) {
            final citas = res.datos ?? [];
            if (citas.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No tienes citas agendadas actualmente con tu supervisor pastoral.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: citas.map((c) {
                final es_realizada = c.esta_realizada;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: es_realizada
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFE2E8F0),
                    ),
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
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.support_agent_rounded,
                                  size: 16,
                                  color: BumandColores.AZUL_DIACONIA,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                c.supervisor_nombre,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: es_realizada
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              c.estado.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: es_realizada
                                  ? const Color(0xFF15803D)
                                  : BumandColores.azulMarinoSecundario,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${c.fecha_cita} a las ${c.hora_cita}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            c.es_presencial
                                ? Icons.business_rounded
                                : Icons.videocam_rounded,
                            size: 14,
                            color: c.es_presencial
                                ? BumandColores.AZUL_DIACONIA
                                : BumandColores.azulCieloSuave,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              c.lugar_o_enlace,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Motivo: ${c.motivo_retroalimentacion}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF334155),
                        ),
                      ),
                      if (c.cita_biblica != null &&
                          c.cita_biblica!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_stories_rounded,
                              size: 13,
                              color: Color(0xFF0369A1),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              c.cita_biblica!,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0369A1),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (c.acuerdos_retroalimentacion != null &&
                          c.acuerdos_retroalimentacion!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.handshake_rounded,
                                    size: 14,
                                    color: Color(0xFF15803D),
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Acuerdos y compromisos:',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c.acuerdos_retroalimentacion!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ],
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
                SizedBox(width: 8),
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
