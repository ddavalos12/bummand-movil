class VersiculoDiarioModelo {
  final String cita;
  final String libro;
  final int capitulo;
  final int versiculo;
  final String texto;
  final String version;
  final String tema;
  final String reflexion_diaconal;

  const VersiculoDiarioModelo({
    required this.cita,
    required this.libro,
    required this.capitulo,
    required this.versiculo,
    required this.texto,
    required this.version,
    required this.tema,
    required this.reflexion_diaconal,
  });

  factory VersiculoDiarioModelo.desdeJson(Map<String, dynamic> json) {
    return VersiculoDiarioModelo(
      cita: json['cita'] as String? ?? '',
      libro: json['libro'] as String? ?? '',
      capitulo: (json['capitulo'] as num?)?.toInt() ?? 0,
      versiculo: (json['versiculo'] as num?)?.toInt() ?? 0,
      texto: json['texto'] as String? ?? '',
      version: json['version'] as String? ?? 'Reina-Valera 1960 (RVR60)',
      tema: json['tema'] as String? ?? '',
      reflexion_diaconal: json['reflexion_diaconal'] as String? ?? '',
    );
  }

  Map<String, dynamic> aJson() {
    return {
      'cita': cita,
      'libro': libro,
      'capitulo': capitulo,
      'versiculo': versiculo,
      'texto': texto,
      'version': version,
      'tema': tema,
      'reflexion_diaconal': reflexion_diaconal,
    };
  }
}
