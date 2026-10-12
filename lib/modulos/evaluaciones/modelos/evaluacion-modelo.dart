class DetalleModuloEvaluacion {
  final int modulo_id;
  final String nombre;
  final String evaluador_rol;
  final double peso_porcentaje;
  final double puntaje; // 0 - 100
  final double contribucion_ponderada;
  final String estado; // "pendiente", "completada", "observada"
  final String? observaciones;

  const DetalleModuloEvaluacion({
    required this.modulo_id,
    required this.nombre,
    required this.evaluador_rol,
    required this.peso_porcentaje,
    required this.puntaje,
    required this.contribucion_ponderada,
    required this.estado,
    this.observaciones,
  });

  factory DetalleModuloEvaluacion.desdeJson(Map<String, dynamic> json) {
    return DetalleModuloEvaluacion(
      modulo_id: json["modulo_id"] is int
          ? json["modulo_id"]
          : int.tryParse(json["modulo_id"]?.toString() ?? "0") ?? 0,
      nombre: json["nombre"]?.toString() ?? "Módulo formativo",
      evaluador_rol: json["evaluador_rol"]?.toString() ?? "Evaluador",
      peso_porcentaje:
          double.tryParse(json["peso_porcentaje"]?.toString() ?? "0") ?? 0.0,
      puntaje: double.tryParse(json["puntaje"]?.toString() ?? "0") ?? 0.0,
      contribucion_ponderada: double.tryParse(
            json["contribucion_ponderada"]?.toString() ?? "0",
          ) ??
          0.0,
      estado: json["estado"]?.toString() ?? "pendiente",
      observaciones: json["observaciones"]?.toString(),
    );
  }

  Map<String, dynamic> aJson() => {
    "modulo_id": modulo_id,
    "nombre": nombre,
    "evaluador_rol": evaluador_rol,
    "peso_porcentaje": peso_porcentaje,
    "puntaje": puntaje,
    "contribucion_ponderada": contribucion_ponderada,
    "estado": estado,
    "observaciones": observaciones,
  };
}

class EvaluacionConsolidadaModelo {
  final int becario_id;
  final int periodo_id;
  final String periodo_nombre;
  final double total_porcentual; // 0 - 100 pts
  final double total_vigesimal; // 0 - 20 pts
  final int modulos_evaluados;
  final int total_modulos;
  final List<DetalleModuloEvaluacion> desglose_modulos;

  const EvaluacionConsolidadaModelo({
    required this.becario_id,
    required this.periodo_id,
    this.periodo_nombre = "Gestión Semestral Activa",
    required this.total_porcentual,
    required this.total_vigesimal,
    required this.modulos_evaluados,
    this.total_modulos = 5,
    required this.desglose_modulos,
  });

  factory EvaluacionConsolidadaModelo.desdeJson(Map<String, dynamic> json) {
    final modulos_json = (json["desglose_modulos"] as List?) ?? [];
    final modulos = modulos_json
        .map((m) => DetalleModuloEvaluacion.desdeJson(m as Map<String, dynamic>))
        .toList();

    return EvaluacionConsolidadaModelo(
      becario_id: json["becario_id"] is int
          ? json["becario_id"]
          : int.tryParse(json["becario_id"]?.toString() ?? "1") ?? 1,
      periodo_id: json["periodo_id"] is int
          ? json["periodo_id"]
          : int.tryParse(json["periodo_id"]?.toString() ?? "1") ?? 1,
      periodo_nombre:
          json["periodo_nombre"]?.toString() ?? "Gestión Semestral Activa",
      total_porcentual:
          double.tryParse(json["total_porcentual"]?.toString() ?? "0") ?? 0.0,
      total_vigesimal:
          double.tryParse(json["total_vigesimal"]?.toString() ?? "0") ?? 0.0,
      modulos_evaluados: json["modulos_evaluados"] is int
          ? json["modulos_evaluados"]
          : modulos.where((m) => m.estado == "completada").length,
      total_modulos: json["total_modulos"] is int
          ? json["total_modulos"]
          : (modulos.isNotEmpty ? modulos.length : 5),
      desglose_modulos: modulos,
    );
  }

  static EvaluacionConsolidadaModelo modeloEjemplo() {
    return const EvaluacionConsolidadaModelo(
      becario_id: 1,
      periodo_id: 1,
      periodo_nombre: "II-2026 Diaconía IFD",
      total_porcentual: 88.5,
      total_vigesimal: 17.7,
      modulos_evaluados: 4,
      total_modulos: 5,
      desglose_modulos: [
        DetalleModuloEvaluacion(
          modulo_id: 1,
          nombre: "Liderazgo en la Iglesia (Formulario F-03)",
          evaluador_rol: "Pastor de la Congregación",
          peso_porcentaje: 25,
          puntaje: 92.0,
          contribucion_ponderada: 23.0,
          estado: "completada",
          observaciones: "Excelente compromiso en el ministerio juvenil y servicio dominical.",
        ),
        DetalleModuloEvaluacion(
          modulo_id: 2,
          nombre: "Autoevaluación Académica",
          evaluador_rol: "Estudiante Becario",
          peso_porcentaje: 20,
          puntaje: 85.0,
          contribucion_ponderada: 17.0,
          estado: "completada",
          observaciones: "Rendimiento universitario sobresaliente con materias aprobadas.",
        ),
        DetalleModuloEvaluacion(
          modulo_id: 3,
          nombre: "Evaluación del Mentor / Prácticas",
          evaluador_rol: "Supervisor Diaconía",
          peso_porcentaje: 25,
          puntaje: 90.0,
          contribucion_ponderada: 22.5,
          estado: "completada",
          observaciones: "Puntualidad impecable en la agencia y proactividad en tareas asignadas.",
        ),
        DetalleModuloEvaluacion(
          modulo_id: 4,
          nombre: "Evaluación Escuela de Líderes",
          evaluador_rol: "Facilitador Pastoral",
          peso_porcentaje: 15,
          puntaje: 88.0,
          contribucion_ponderada: 13.2,
          estado: "completada",
          observaciones: "Participación activa en los talleres y devocionales formativos.",
        ),
        DetalleModuloEvaluacion(
          modulo_id: 5,
          nombre: "Evaluación Socioeconómica",
          evaluador_rol: "Trabajador Social",
          peso_porcentaje: 15,
          puntaje: 85.0,
          contribucion_ponderada: 12.8,
          estado: "pendiente",
          observaciones: "En proceso de revisión de documentación socioeconómica del semestre.",
        ),
      ],
    );
  }
}
