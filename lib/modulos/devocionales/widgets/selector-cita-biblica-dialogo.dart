import 'package:flutter/material.dart';
import '../../../nucleo/tema/colores.dart';

class SelectorCitaBiblicaDialogo extends StatefulWidget {
  final String cita_inicial;

  const SelectorCitaBiblicaDialogo({
    super.key,
    this.cita_inicial = 'Filipenses 4:13',
  });

  static Future<String?> mostrar(
    BuildContext context, {
    String cita_inicial = 'Filipenses 4:13',
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SelectorCitaBiblicaDialogo(cita_inicial: cita_inicial),
    );
  }

  @override
  State<SelectorCitaBiblicaDialogo> createState() =>
      _SelectorCitaBiblicaDialogoState();
}

class _SelectorCitaBiblicaDialogoState
    extends State<SelectorCitaBiblicaDialogo> {
  static const List<Map<String, dynamic>> LIBROS = [
    // Nuevo Testamento
    {'nombre': 'Mateo', 'testamento': 'NT', 'capitulos': 28},
    {'nombre': 'Marcos', 'testamento': 'NT', 'capitulos': 16},
    {'nombre': 'Lucas', 'testamento': 'NT', 'capitulos': 24},
    {'nombre': 'Juan', 'testamento': 'NT', 'capitulos': 21},
    {'nombre': 'Hechos', 'testamento': 'NT', 'capitulos': 28},
    {'nombre': 'Romanos', 'testamento': 'NT', 'capitulos': 16},
    {'nombre': '1 Corintios', 'testamento': 'NT', 'capitulos': 16},
    {'nombre': '2 Corintios', 'testamento': 'NT', 'capitulos': 13},
    {'nombre': 'Gálatas', 'testamento': 'NT', 'capitulos': 6},
    {'nombre': 'Efesios', 'testamento': 'NT', 'capitulos': 6},
    {'nombre': 'Filipenses', 'testamento': 'NT', 'capitulos': 4},
    {'nombre': 'Colosenses', 'testamento': 'NT', 'capitulos': 4},
    {'nombre': '1 Tesalonicenses', 'testamento': 'NT', 'capitulos': 5},
    {'nombre': '2 Tesalonicenses', 'testamento': 'NT', 'capitulos': 3},
    {'nombre': '1 Timoteo', 'testamento': 'NT', 'capitulos': 6},
    {'nombre': '2 Timoteo', 'testamento': 'NT', 'capitulos': 4},
    {'nombre': 'Tito', 'testamento': 'NT', 'capitulos': 3},
    {'nombre': 'Filemón', 'testamento': 'NT', 'capitulos': 1},
    {'nombre': 'Hebreos', 'testamento': 'NT', 'capitulos': 13},
    {'nombre': 'Santiago', 'testamento': 'NT', 'capitulos': 5},
    {'nombre': '1 Pedro', 'testamento': 'NT', 'capitulos': 5},
    {'nombre': '2 Pedro', 'testamento': 'NT', 'capitulos': 3},
    {'nombre': '1 Juan', 'testamento': 'NT', 'capitulos': 5},
    {'nombre': '2 Juan', 'testamento': 'NT', 'capitulos': 1},
    {'nombre': '3 Juan', 'testamento': 'NT', 'capitulos': 1},
    {'nombre': 'Judas', 'testamento': 'NT', 'capitulos': 1},
    {'nombre': 'Apocalipsis', 'testamento': 'NT', 'capitulos': 22},

    // Antiguo Testamento
    {'nombre': 'Génesis', 'testamento': 'AT', 'capitulos': 50},
    {'nombre': 'Éxodo', 'testamento': 'AT', 'capitulos': 40},
    {'nombre': 'Levítico', 'testamento': 'AT', 'capitulos': 27},
    {'nombre': 'Números', 'testamento': 'AT', 'capitulos': 36},
    {'nombre': 'Deuteronomio', 'testamento': 'AT', 'capitulos': 34},
    {'nombre': 'Josué', 'testamento': 'AT', 'capitulos': 24},
    {'nombre': 'Jueces', 'testamento': 'AT', 'capitulos': 21},
    {'nombre': 'Rut', 'testamento': 'AT', 'capitulos': 4},
    {'nombre': '1 Samuel', 'testamento': 'AT', 'capitulos': 31},
    {'nombre': '2 Samuel', 'testamento': 'AT', 'capitulos': 24},
    {'nombre': '1 Reyes', 'testamento': 'AT', 'capitulos': 22},
    {'nombre': '2 Reyes', 'testamento': 'AT', 'capitulos': 25},
    {'nombre': '1 Crónicas', 'testamento': 'AT', 'capitulos': 29},
    {'nombre': '2 Crónicas', 'testamento': 'AT', 'capitulos': 36},
    {'nombre': 'Esdras', 'testamento': 'AT', 'capitulos': 10},
    {'nombre': 'Nehemías', 'testamento': 'AT', 'capitulos': 13},
    {'nombre': 'Ester', 'testamento': 'AT', 'capitulos': 10},
    {'nombre': 'Job', 'testamento': 'AT', 'capitulos': 42},
    {'nombre': 'Salmos', 'testamento': 'AT', 'capitulos': 150},
    {'nombre': 'Proverbios', 'testamento': 'AT', 'capitulos': 31},
    {'nombre': 'Eclesiastés', 'testamento': 'AT', 'capitulos': 12},
    {'nombre': 'Cantares', 'testamento': 'AT', 'capitulos': 8},
    {'nombre': 'Isaías', 'testamento': 'AT', 'capitulos': 66},
    {'nombre': 'Jeremías', 'testamento': 'AT', 'capitulos': 52},
    {'nombre': 'Lamentaciones', 'testamento': 'AT', 'capitulos': 5},
    {'nombre': 'Ezequiel', 'testamento': 'AT', 'capitulos': 48},
    {'nombre': 'Daniel', 'testamento': 'AT', 'capitulos': 12},
    {'nombre': 'Oseas', 'testamento': 'AT', 'capitulos': 14},
    {'nombre': 'Joel', 'testamento': 'AT', 'capitulos': 3},
    {'nombre': 'Amós', 'testamento': 'AT', 'capitulos': 9},
    {'nombre': 'Abdías', 'testamento': 'AT', 'capitulos': 1},
    {'nombre': 'Jonás', 'testamento': 'AT', 'capitulos': 4},
    {'nombre': 'Miqueas', 'testamento': 'AT', 'capitulos': 7},
    {'nombre': 'Nahúm', 'testamento': 'AT', 'capitulos': 3},
    {'nombre': 'Habacuc', 'testamento': 'AT', 'capitulos': 3},
    {'nombre': 'Sofonías', 'testamento': 'AT', 'capitulos': 3},
    {'nombre': 'Hageo', 'testamento': 'AT', 'capitulos': 2},
    {'nombre': 'Zacarías', 'testamento': 'AT', 'capitulos': 14},
    {'nombre': 'Malaquías', 'testamento': 'AT', 'capitulos': 4},
  ];

  late String _libro_seleccionado;
  late TextEditingController _capitulo_ctrl;
  late TextEditingController _versiculo_inicio_ctrl;
  late TextEditingController _versiculo_fin_ctrl;
  bool _es_rango = false;

  @override
  void initState() {
    super.initState();
    _desglosarCita(widget.cita_inicial);
  }

  void _desglosarCita(String cita) {
    final patron = RegExp(r'^(.+?)\s+(\d+):(\d+)(?:-(\d+))?$');
    final match = patron.firstMatch(cita.trim());

    if (match != null) {
      final libro_texto = match.group(1)?.trim() ?? 'Filipenses';
      final cap = match.group(2) ?? '4';
      final v_ini = match.group(3) ?? '13';
      final v_fin = match.group(4);

      final encontrado = LIBROS.firstWhere(
        (l) =>
            (l['nombre'] as String).toLowerCase() == libro_texto.toLowerCase(),
        orElse: () => LIBROS[10], // Filipenses
      );

      _libro_seleccionado = encontrado['nombre'] as String;
      _capitulo_ctrl = TextEditingController(text: cap);
      _versiculo_inicio_ctrl = TextEditingController(text: v_ini);
      _versiculo_fin_ctrl = TextEditingController(text: v_fin ?? '');
      _es_rango = v_fin != null && v_fin.isNotEmpty;
    } else {
      _libro_seleccionado = 'Filipenses';
      _capitulo_ctrl = TextEditingController(text: '4');
      _versiculo_inicio_ctrl = TextEditingController(text: '13');
      _versiculo_fin_ctrl = TextEditingController(text: '');
      _es_rango = false;
    }
  }

  @override
  void dispose() {
    _capitulo_ctrl.dispose();
    _versiculo_inicio_ctrl.dispose();
    _versiculo_fin_ctrl.dispose();
    super.dispose();
  }

  String get _citaGenerada {
    final cap = int.tryParse(_capitulo_ctrl.text) ?? 1;
    final v_ini = int.tryParse(_versiculo_inicio_ctrl.text) ?? 1;
    final v_fin = int.tryParse(_versiculo_fin_ctrl.text);

    if (_es_rango && v_fin != null && v_fin > v_ini) {
      return '$_libro_seleccionado $cap:$v_ini-$v_fin';
    }
    return '$_libro_seleccionado $cap:$v_ini';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_stories,
                    color: BumandColores.AZUL_DIACONIA,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Selector de Pasaje Bíblico',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: BumandColores.AZUL_DIACONIA,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Banner con Cita Resultante en Vivo
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cita Canónica:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      _citaGenerada,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: BumandColores.AZUL_DIACONIA,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Selector de Libro Canónico
              DropdownButtonFormField<String>(
                initialValue: _libro_seleccionado,
                decoration: InputDecoration(
                  labelText: 'Libro de la Biblia',
                  prefixIcon: const Icon(Icons.menu_book),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: LIBROS.map((l) {
                  final es_nt = l['testamento'] == 'NT';
                  return DropdownMenuItem<String>(
                    value: l['nombre'] as String,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l['nombre'] as String),
                        Text(
                          es_nt ? ' (NT)' : ' (AT)',
                          style: TextStyle(
                            fontSize: 11,
                            color: es_nt
                                ? BumandColores.AZUL_DIACONIA
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _libro_seleccionado = val;
                      _capitulo_ctrl.text = '1';
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Capítulo y Versículo Inicio
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _capitulo_ctrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Capítulo',
                        prefixIcon: const Icon(Icons.format_list_numbered),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _versiculo_inicio_ctrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _es_rango ? 'De Versículo' : 'Versículo',
                        prefixIcon: const Icon(Icons.pin),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Checkbox de Rango de Versículos
              CheckboxListTile(
                value: _es_rango,
                title: const Text(
                  '¿Incluir rango de versículos?',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Ejemplo: del versículo 1 al 5',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                contentPadding: EdgeInsets.zero,
                activeColor: BumandColores.AZUL_DIACONIA,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (val) {
                  setState(() {
                    _es_rango = val ?? false;
                    if (_es_rango && _versiculo_fin_ctrl.text.isEmpty) {
                      final inicio =
                          int.tryParse(_versiculo_inicio_ctrl.text) ?? 1;
                      _versiculo_fin_ctrl.text = '${inicio + 2}';
                    }
                  });
                },
              ),

              if (_es_rango) ...[
                TextField(
                  controller: _versiculo_fin_ctrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Hasta Versículo (Fin de Rango)',
                    prefixIcon: const Icon(Icons.arrow_forward),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 14),

              // Botón de Confirmación
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context, _citaGenerada);
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Aplicar Cita Bíblica'),
                style: FilledButton.styleFrom(
                  backgroundColor: BumandColores.AZUL_DIACONIA,
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
}
