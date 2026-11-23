class OpcionBienestarModelo {
  final String inciso;
  final String texto;

  const OpcionBienestarModelo({
    required this.inciso,
    required this.texto,
  });

  factory OpcionBienestarModelo.desdeJson(Map<String, dynamic> json) {
    return OpcionBienestarModelo(
      inciso: (json['inciso'] ?? json['letra'] ?? '').toString(),
      texto: (json['texto'] ?? json['descripcion'] ?? '').toString(),
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'inciso': inciso,
      'texto': texto,
    };
  }
}

class PreguntaBienestarModelo {
  final int numero_orden;
  final String titulo;
  final String enunciado;
  final String categoria;
  final List<OpcionBienestarModelo> opciones;

  const PreguntaBienestarModelo({
    required this.numero_orden,
    required this.titulo,
    required this.enunciado,
    required this.categoria,
    required this.opciones,
  });

  factory PreguntaBienestarModelo.desdeJson(Map<String, dynamic> json) {
    final opciones_json = json['opciones'] as List<dynamic>? ?? [];
    return PreguntaBienestarModelo(
      numero_orden: json['numero_orden'] is num
          ? (json['numero_orden'] as num).toInt()
          : int.tryParse(json['numero_orden']?.toString() ?? '0') ?? 0,
      titulo: (json['titulo'] ?? '').toString(),
      enunciado: (json['enunciado'] ?? json['pregunta'] ?? '').toString(),
      categoria: (json['categoria'] ?? 'Bienestar General').toString(),
      opciones: opciones_json
          .map((o) => OpcionBienestarModelo.desdeJson(o as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'numero_orden': numero_orden,
      'titulo': titulo,
      'enunciado': enunciado,
      'categoria': categoria,
      'opciones': opciones.map((o) => o.aJson()).toList(),
    };
  }
}
