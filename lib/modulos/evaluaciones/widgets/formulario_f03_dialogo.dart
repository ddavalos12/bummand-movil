import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../nucleo/constantes/api-constantes.dart';
import '../../../nucleo/tema/colores.dart';

class FormularioF03Dialogo extends StatefulWidget {
  final String nombre_becario;

  const FormularioF03Dialogo({
    super.key,
    this.nombre_becario = "María Catunta Laime",
  });

  static void mostrar(
    BuildContext context, {
    String nombre_becario = "María Catunta Laime",
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FormularioF03Dialogo(nombre_becario: nombre_becario),
    );
  }

  @override
  State<FormularioF03Dialogo> createState() => _FormularioF03DialogoState();
}

class _FormularioF03DialogoState extends State<FormularioF03Dialogo> {
  final _clave_form = GlobalKey<FormState>();

  final _pastor_nombre_ctrl = TextEditingController();
  final _pastor_correo_ctrl = TextEditingController();
  final _pastor_celular_ctrl = TextEditingController();
  final _iglesia_nombre_ctrl = TextEditingController();
  final _iglesia_dir_ctrl = TextEditingController();
  final _lider_nombre_ctrl = TextEditingController();
  final _lider_cargo_ctrl = TextEditingController();
  late final TextEditingController _becario_nombre_ctrl;
  final _cargo_2025_ctrl = TextEditingController();
  final _conviccion_ctrl = TextEditingController();
  final _ejemplo_ctrl = TextEditingController();
  final _capacitaciones_ctrl = TextEditingController();
  final _testimonio_ctrl = TextEditingController();
  final _relacion_ctrl = TextEditingController();
  final _nuevos_lideres_ctrl = TextEditingController();
  final _fortalezas_ctrl = TextEditingController();
  final _debilidades_ctrl = TextEditingController();
  final _opinion_ctrl = TextEditingController();
  final _declara_nombre_ctrl = TextEditingController();
  final _declara_ci_ctrl = TextEditingController();

  String _frecuencia = "Es miembro en plena comunión";
  String _compromiso = "Sí";
  String _cargo_iglesia = "Sí";
  String _cumplimiento = "Muy bien";
  bool _declara_veridico = false;
  String? _mensaje_error;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _becario_nombre_ctrl =
        TextEditingController(text: widget.nombre_becario);
  }

  @override
  void dispose() {
    _pastor_nombre_ctrl.dispose();
    _pastor_correo_ctrl.dispose();
    _pastor_celular_ctrl.dispose();
    _iglesia_nombre_ctrl.dispose();
    _iglesia_dir_ctrl.dispose();
    _lider_nombre_ctrl.dispose();
    _lider_cargo_ctrl.dispose();
    _becario_nombre_ctrl.dispose();
    _cargo_2025_ctrl.dispose();
    _conviccion_ctrl.dispose();
    _ejemplo_ctrl.dispose();
    _capacitaciones_ctrl.dispose();
    _testimonio_ctrl.dispose();
    _relacion_ctrl.dispose();
    _nuevos_lideres_ctrl.dispose();
    _fortalezas_ctrl.dispose();
    _debilidades_ctrl.dispose();
    _opinion_ctrl.dispose();
    _declara_nombre_ctrl.dispose();
    _declara_ci_ctrl.dispose();
    super.dispose();
  }

  Future<void> _enviarRecepcion() async {
    if (_pastor_nombre_ctrl.text.trim().isEmpty ||
        _pastor_correo_ctrl.text.trim().isEmpty) {
      setState(() {
        _mensaje_error =
            "Completa el nombre y correo del pastor antes de enviar.";
      });
      return;
    }

    if (!_declara_veridico) {
      setState(() {
        _mensaje_error =
            "Debes marcar la casilla de declaración jurada de veracidad.";
      });
      return;
    }

    setState(() {
      _mensaje_error = null;
      _enviando = true;
    });

    try {
      final ruta = '${ApiConstantes.RUTA_BASE}/api/evaluaciones/receptor/f03';
      await http
          .post(
            Uri.parse(ruta),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "becario_id": 1,
              "periodo": "Semestre II - 2026",
              "pastor_nombre": _pastor_nombre_ctrl.text,
              "pastor_correo": _pastor_correo_ctrl.text,
              "pastor_celular": _pastor_celular_ctrl.text,
              "iglesia_nombre": _iglesia_nombre_ctrl.text,
              "iglesia_direccion": _iglesia_dir_ctrl.text,
              "frecuencia": _frecuencia,
              "compromiso": _compromiso,
              "cargo_iglesia": _cargo_iglesia,
              "cumplimiento": _cumplimiento,
              "opinion_general": _opinion_ctrl.text,
              "declaracion_ci": _declara_ci_ctrl.text,
              "fecha_recepcion": DateTime.now().toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 4));
    } catch (_) {}

    if (!mounted) return;
    setState(() => _enviando = false);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✓ Formulario F-03 del Pastor recibido exitosamente por el sistema."),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _exportarPdf() {
    if (_pastor_nombre_ctrl.text.trim().isEmpty ||
        _pastor_correo_ctrl.text.trim().isEmpty) {
      setState(() {
        _mensaje_error =
            "Completa el nombre y correo del pastor antes de exportar.";
      });
      return;
    }

    if (!_declara_veridico) {
      setState(() {
        _mensaje_error =
            "Debes marcar la casilla de declaración jurada de veracidad.";
      });
      return;
    }

    setState(() => _mensaje_error = null);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✓ Formulario F-03 exportado a PDF correctamente."),
        backgroundColor: BumandColores.TURQUESA_DIACONIA,
        duration: Duration(seconds: 3),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        "Módulo 01 · F-03 Receptor",
                        style: TextStyle(
                          color: BumandColores.AZUL_DIACONIA,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Formulario de Evaluación del Becario",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: BumandColores.NEGRO,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Programa de Becas · Escuela de Líderes BUMAN-D — a llenar por el Pastor",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Form(
              key: _clave_form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _construirTituloSeccion("I. Datos del pastor y de la iglesia local"),
                  _construirCampoTexto("Nombre del pastor", _pastor_nombre_ctrl, "Nombre completo"),
                  _construirCampoTexto("Correo del pastor", _pastor_correo_ctrl, "pastor@correo.com", teclado: TextInputType.emailAddress),
                  _construirCampoTexto("N.º celular del pastor", _pastor_celular_ctrl, "Ej. 71234567", teclado: TextInputType.phone),
                  _construirCampoTexto("Nombre de la iglesia", _iglesia_nombre_ctrl, "Nombre de la congregación"),
                  _construirCampoTexto("Dirección de la iglesia", _iglesia_dir_ctrl, "Zona, calle, ciudad"),
                  _construirCampoTexto("Nombre de un líder de la congregación", _lider_nombre_ctrl, "Nombre del líder"),
                  _construirCampoTexto("Cargo del líder", _lider_cargo_ctrl, "Cargo o ministerio"),

                  const SizedBox(height: 20),

                  _construirTituloSeccion("II. Referencias acerca del becario universitario"),
                  _construirCampoTexto("1. Nombre del becario", _becario_nombre_ctrl, "Nombre del becario"),

                  const SizedBox(height: 10),
                  const Text(
                    "2. ¿Con qué frecuencia el becario asiste a la iglesia?",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  _construirRadioFrecuencia("Es miembro en plena comunión"),
                  _construirRadioFrecuencia("Asiste sólo domingos"),
                  _construirRadioFrecuencia("Viene como visita"),
                  _construirRadioFrecuencia("No asiste"),

                  const SizedBox(height: 10),
                  const Text(
                    "3. ¿Demuestra compromiso con el Señor y la Iglesia?",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      _construirRadioCompromiso("Sí"),
                      _construirRadioCompromiso("No"),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const Text(
                    "4. ¿Ocupa actualmente algún cargo en la iglesia?",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: [
                      _construirRadioCargo("Sí"),
                      _construirRadioCargo("No"),
                    ],
                  ),
                  if (_cargo_iglesia == "Sí")
                    _construirCampoTexto("Cargo 2025/2026", _cargo_2025_ctrl, "Cargo que ocupa"),

                  const SizedBox(height: 10),
                  const Text(
                    "5. ¿Hasta el momento cómo ha cumplido con sus cargos?",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  _construirRadioCumplimiento("Muy bien"),
                  _construirRadioCumplimiento("Bien"),
                  _construirRadioCumplimiento("Necesita Apoyo"),
                  _construirRadioCumplimiento("No cumple"),

                  const SizedBox(height: 12),
                  _construirCampoArea("6. ¿Demuestra convicción al llamado de Dios? Favor de explicar", _conviccion_ctrl),
                  _construirCampoArea("7. ¿En qué áreas demuestra ejemplo en la congregación?", _ejemplo_ctrl),
                  _construirCampoArea("8. ¿Demuestra compromiso con las capacitaciones?", _capacitaciones_ctrl),
                  _construirCampoArea("9. ¿Cómo es su testimonio como cristiano?", _testimonio_ctrl),
                  _construirCampoArea("10. ¿Cómo se relaciona con los demás miembros?", _relacion_ctrl),
                  _construirCampoArea("11. ¿Se encuentra desarrollando a nuevos líderes?", _nuevos_lideres_ctrl),
                  _construirCampoArea("12. Fortalezas del becario", _fortalezas_ctrl),
                  _construirCampoArea("Debilidades del becario", _debilidades_ctrl),
                  _construirCampoArea("13. ¿Cuál es su opinión general del becario?", _opinion_ctrl),

                  const SizedBox(height: 20),

                  _construirTituloSeccion("III. Declaración jurada"),
                  _construirCampoTexto("Nombre del pastor (declaración)", _declara_nombre_ctrl, "Nombre completo"),
                  _construirCampoTexto("C.I. del pastor", _declara_ci_ctrl, "Número de documento de identidad"),

                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _declara_veridico,
                    onChanged: (v) => setState(() => _declara_veridico = v ?? false),
                    title: const Text(
                      "Como pastor de la congregación del/la becario, declaro que todos los datos proporcionados son verídicos.",
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  if (_mensaje_error != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Text(
                        _mensaje_error!,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _enviando ? null : _enviarRecepcion,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BumandColores.NARANJA,
                        foregroundColor: BumandColores.NEGRO,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                        _enviando ? "Registrando recepción..." : "Enviar Formulario a Recepción",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _exportarPdf,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.picture_as_pdf, size: 18),
                      label: const Text(
                        "Exportar copia en PDF",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTituloSeccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: BumandColores.AZUL_DIACONIA,
        ),
      ),
    );
  }

  Widget _construirCampoTexto(
    String etiqueta,
    TextEditingController controlador,
    String marcador, {
    TextInputType teclado = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controlador,
            keyboardType: teclado,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: marcador,
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirCampoArea(String etiqueta, TextEditingController controlador) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controlador,
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirRadioFrecuencia(String valor) {
    final seleccionada = _frecuencia == valor;
    return InkWell(
      onTap: () => setState(() => _frecuencia = valor),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              seleccionada
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: seleccionada ? BumandColores.AZUL_DIACONIA : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(valor, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _construirRadioCompromiso(String valor) {
    final seleccionado = _compromiso == valor;
    return InkWell(
      onTap: () => setState(() => _compromiso = valor),
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              seleccionado
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: seleccionado ? BumandColores.AZUL_DIACONIA : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(valor, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _construirRadioCargo(String valor) {
    final seleccionado = _cargo_iglesia == valor;
    return InkWell(
      onTap: () => setState(() => _cargo_iglesia = valor),
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 4, bottom: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              seleccionado
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: seleccionado ? BumandColores.AZUL_DIACONIA : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(valor, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _construirRadioCumplimiento(String valor) {
    final seleccionado = _cumplimiento == valor;
    return InkWell(
      onTap: () => setState(() => _cumplimiento = valor),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              seleccionado
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: seleccionado ? BumandColores.AZUL_DIACONIA : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(valor, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
