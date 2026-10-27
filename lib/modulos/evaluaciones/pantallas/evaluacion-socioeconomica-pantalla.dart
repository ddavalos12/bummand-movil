import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';
import '../../autenticacion/proveedores/autenticacion-proveedor.dart';
import '../modelos/pregunta-bienestar-modelo.dart';
import '../proveedores/evaluaciones-proveedor.dart';
import '../repositorios/evaluaciones-repositorio.dart';

class EvaluacionSocioeconomicaPantalla extends ConsumerStatefulWidget {
  const EvaluacionSocioeconomicaPantalla({super.key});

  @override
  ConsumerState<EvaluacionSocioeconomicaPantalla> createState() =>
      _EvaluacionSocioeconomicaPantallaState();
}

class _EvaluacionSocioeconomicaPantallaState
    extends ConsumerState<EvaluacionSocioeconomicaPantalla> {
  static const Color _AZUL_PROFUNDO = BumandColores.azulMarinoProfundo;
  static const Color _TURQUESA_INSTITUCIONAL = BumandColores.azulCieloSuave;
  static const Color _DORADO_DIACONIA = BumandColores.amarilloRadiante;
  static const Color _FONDO_PANTALLA = BumandColores.fondo;
  static const Color _BORDE_SUAVE = BumandColores.grisClaro;

  static const List<String> _CATEGORIAS_FILTRO = [
    "Todas (26)",
    "Hogar y Economía",
    "Salud y Servicios",
    "Convivencia",
    "Universidad y Futuro",
  ];

  final EvaluacionesRepositorio _repositorio = EvaluacionesRepositorio();
  final TextEditingController _observaciones_ctrl = TextEditingController();

  List<PreguntaBienestarModelo> _preguntas =
      PreguntaBienestarModelo.catalogoCanonico();
  final Map<int, String> _respuestas = {};
  String _categoria_seleccionada = "Todas (26)";
  bool _enviando = false;
  bool _enviado_exitosamente = false;

  @override
  void initState() {
    super.initState();
    _sincronizarCatalogoPreguntas();
  }

  @override
  void dispose() {
    _observaciones_ctrl.dispose();
    super.dispose();
  }

  bool _tieneCambiosSinGuardar() {
    return _respuestas.isNotEmpty && !_enviado_exitosamente;
  }

  Future<void> _sincronizarCatalogoPreguntas() async {
    try {
      final resultado = await _repositorio.obtenerCuestionarioBienestar();
      if (!mounted) return;
      if (resultado.exito &&
          resultado.datos != null &&
          resultado.datos!.isNotEmpty) {
        setState(() {
          _preguntas = resultado.datos!;
        });
      }
    } catch (_) {
      // Mantiene el catálogo canónico local en modo offline
    }
  }

  bool _perteneceACategoriaFiltro(
    PreguntaBienestarModelo pregunta,
    String filtro,
  ) {
    if (filtro == "Todas (26)") return true;

    final cat = pregunta.categoria.toLowerCase();
    final orden = pregunta.numero_orden;

    switch (filtro) {
      case "Hogar y Economía":
        return cat.contains("econom") ||
            cat.contains("legal") ||
            const [1, 2, 3, 4, 5, 16].contains(orden);
      case "Salud y Servicios":
        return cat.contains("salud") ||
            cat.contains("vivienda") ||
            cat.contains("transporte") ||
            const [6, 7, 8, 9, 10, 11, 12, 13, 14].contains(orden);
      case "Convivencia":
        return cat.contains("convivencia") ||
            cat.contains("entorno") ||
            cat.contains("educación") ||
            cat.contains("desarrollo") ||
            const [15, 17, 18, 19, 20].contains(orden);
      case "Universidad y Futuro":
        return cat.contains("universitario") ||
            const [21, 22, 23, 24, 25, 26].contains(orden);
      default:
        return true;
    }
  }

  List<PreguntaBienestarModelo> _obtenerPreguntasFiltradas() {
    return _preguntas
        .where((p) => _perteneceACategoriaFiltro(p, _categoria_seleccionada))
        .toList();
  }

  void _autocompletarDemostracion() {
    setState(() {
      for (final preg in _preguntas) {
        if (preg.opciones.isEmpty) continue;
        // Para las preguntas 21-26 la opción D refleja el mayor entusiasmo/planificación;
        // para las preguntas 1-20 la opción A refleja condiciones favorables.
        final tiene_inciso_d = preg.opciones.any((o) => o.inciso == "D");
        if (preg.numero_orden >= 21 && tiene_inciso_d) {
          _respuestas[preg.numero_orden] = "D";
        } else {
          _respuestas[preg.numero_orden] = preg.opciones.first.inciso;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Se completaron las 26 respuestas de demostración del cuestionario.",
        ),
        backgroundColor: _AZUL_PROFUNDO,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _limpiarRespuestas() {
    setState(() {
      _respuestas.clear();
      _observaciones_ctrl.clear();
    });
  }

  Future<bool> _confirmarSalidaSinGuardar() async {
    if (!_tieneCambiosSinGuardar()) return true;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Respuestas sin enviar",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          "Tienes ${_respuestas.length} de ${_preguntas.length} preguntas respondidas sin enviar. ¿Deseas salir sin guardar tu Evaluación Socioeconómica?",
          style: const TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Continuar respondiendo"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text("Salir sin guardar"),
          ),
        ],
      ),
    );

    return confirmar ?? false;
  }

  Future<void> _enviarEvaluacionSocioeconomica() async {
    if (_respuestas.length < _preguntas.length) {
      final faltantes = _preguntas.length - _respuestas.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Por favor responde todas las preguntas. Faltan $faltantes de ${_preguntas.length}.",
          ),
          backgroundColor: BumandColores.amarilloRadiante,
        ),
      );
      return;
    }

    setState(() => _enviando = true);

    final estado_auth = ref.read(autenticacion_proveedor);
    final becario_id = estado_auth.usuario?.id ?? 1;

    final respuestas_dto = <String, dynamic>{
      for (final entry in _respuestas.entries)
        "pregunta_${entry.key}": entry.value,
    };

    final resultado = await _repositorio.enviarEvaluacionSocioeconomica(
      becario_id: becario_id,
      periodo_id: 1,
      respuestas: respuestas_dto,
      observaciones: _observaciones_ctrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _enviando = false);

    if (resultado.exito) {
      setState(() => _enviado_exitosamente = true);
      ref.invalidate(evaluacion_consolidada_proveedor);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "✓ Evaluación Socioeconómica (26/26) enviada exitosamente a Bienestar Universitario.",
          ),
          backgroundColor: BumandColores.azulMarinoProfundo,
          duration: Duration(seconds: 3),
        ),
      );

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resultado.error ?? "No se pudo enviar la evaluación socioeconómica.",
          ),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final respondidas_conteo = _respuestas.length;
    final total_preguntas = _preguntas.length;
    final valor_progreso =
        total_preguntas > 0 ? (respondidas_conteo / total_preguntas) : 0.0;
    final preguntas_filtradas = _obtenerPreguntasFiltradas();

    return PopScope(
      canPop: !_tieneCambiosSinGuardar(),
      onPopInvokedWithResult: (did_pop, _) async {
        if (did_pop) return;
        final salir = await _confirmarSalidaSinGuardar();
        if (salir && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: _FONDO_PANTALLA,
        appBar: const BarraSuperiorBumand(
          titulo: "Evaluación Socioeconómica",
          subtitulo: "Cuestionario de Bienestar · 26 preguntas",
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _construirPanelProgresoYFiltros(
                    respondidas_conteo: respondidas_conteo,
                    total_preguntas: total_preguntas,
                    valor_progreso: valor_progreso,
                  ),
                  const SizedBox(height: 12),
                  ...preguntas_filtradas.map(_construirTarjetaPregunta),
                  const SizedBox(height: 6),
                  _construirSeccionObservaciones(),
                ],
              ),
            ),
            _construirBarraInferiorEnvio(
              respondidas_conteo: respondidas_conteo,
              total_preguntas: total_preguntas,
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirPanelProgresoYFiltros({
    required int respondidas_conteo,
    required int total_preguntas,
    required double valor_progreso,
  }) {
    final completado = respondidas_conteo == total_preguntas && total_preguntas > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _BORDE_SUAVE),
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
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      completado
                          ? Icons.check_circle_rounded
                          : Icons.pending_actions_rounded,
                      size: 18,
                      color: completado
                          ? BumandColores.azulMarinoProfundo
                          : _AZUL_PROFUNDO,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Respondidas: $respondidas_conteo de $total_preguntas preguntas",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _AZUL_PROFUNDO,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (respondidas_conteo > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: _limpiarRespuestas,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.restart_alt_rounded,
                                  size: 13,
                                  color: Color(0xFF475569),
                                ),
                                SizedBox(width: 3),
                                Text(
                                  "Reiniciar",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    InkWell(
                      onTap: _autocompletarDemostracion,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _DORADO_DIACONIA.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _DORADO_DIACONIA),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_fix_high_rounded,
                              size: 13,
                              color: _AZUL_PROFUNDO,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Autocompletar demostración (26/26)",
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: _AZUL_PROFUNDO,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: valor_progreso,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                completado ? BumandColores.azulMarinoProfundo : _TURQUESA_INSTITUCIONAL,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _CATEGORIAS_FILTRO.map((categoria) {
                final seleccionada = _categoria_seleccionada == categoria;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(categoria),
                    selected: seleccionada,
                    onSelected: (_) {
                      setState(() {
                        _categoria_seleccionada = categoria;
                      });
                    },
                    selectedColor: _AZUL_PROFUNDO,
                    backgroundColor: const Color(0xFFF8FAFC),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          seleccionada ? FontWeight.bold : FontWeight.w500,
                      color: seleccionada
                          ? Colors.white
                          : const Color(0xFF334155),
                    ),
                    side: BorderSide(
                      color: seleccionada ? _AZUL_PROFUNDO : _BORDE_SUAVE,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTarjetaPregunta(PreguntaBienestarModelo pregunta) {
    final respuesta_seleccionada = _respuestas[pregunta.numero_orden];
    final esta_respondida = respuesta_seleccionada != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: esta_respondida
              ? _TURQUESA_INSTITUCIONAL.withValues(alpha: 0.65)
              : _BORDE_SUAVE,
          width: esta_respondida ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: esta_respondida
                      ? BumandColores.azulMarinoProfundo
                      : _AZUL_PROFUNDO,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${pregunta.numero_orden}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pregunta.titulo,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: BumandColores.NEGRO,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            pregunta.categoria,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pregunta.enunciado,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF334155),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: pregunta.opciones.map((opcion) {
              final es_seleccionada = respuesta_seleccionada == opcion.inciso;
              return Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    setState(() {
                      _respuestas[pregunta.numero_orden] = opcion.inciso;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: es_seleccionada
                          ? _AZUL_PROFUNDO.withValues(alpha: 0.08)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: es_seleccionada
                            ? _AZUL_PROFUNDO
                            : const Color(0xFFE2E8F0),
                        width: es_seleccionada ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: es_seleccionada
                                ? _AZUL_PROFUNDO
                                : Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: es_seleccionada
                                  ? _AZUL_PROFUNDO
                                  : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Text(
                            "${opcion.inciso})",
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: es_seleccionada
                                  ? Colors.white
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            opcion.texto,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: es_seleccionada
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: es_seleccionada
                                  ? _AZUL_PROFUNDO
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        if (es_seleccionada)
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: _AZUL_PROFUNDO,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _construirSeccionObservaciones() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _BORDE_SUAVE),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.notes_rounded,
                size: 18,
                color: _AZUL_PROFUNDO,
              ),
              SizedBox(width: 6),
              Text(
                "Observaciones adicionales para Trabajo Social (opcional)",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _AZUL_PROFUNDO,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _observaciones_ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  "Si deseas ampliar información sobre tu situación familiar, médica o académica, escríbelo aquí...",
              hintStyle: const TextStyle(fontSize: 12),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _BORDE_SUAVE),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _BORDE_SUAVE),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirBarraInferiorEnvio({
    required int respondidas_conteo,
    required int total_preguntas,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: _BORDE_SUAVE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _enviando ? null : _enviarEvaluacionSocioeconomica,
            style: ElevatedButton.styleFrom(
              backgroundColor: _DORADO_DIACONIA,
              foregroundColor: BumandColores.azulMarinoSecundario,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: _enviando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: BumandColores.NEGRO,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              _enviando
                  ? "Enviando cuestionario..."
                  : "Enviar Evaluación Socioeconómica ($respondidas_conteo/$total_preguntas)",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
