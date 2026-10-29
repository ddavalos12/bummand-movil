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

class BecarioAsignadoModulo3Modelo {
  final int becario_id;
  final String nombre;
  final String carrera;
  final String universidad;
  final String agencia;
  final String estado_evaluacion; // "pendiente", "completada"
  final double? puntaje_actual;
  final Map<String, dynamic>? evaluacion_previa;

  const BecarioAsignadoModulo3Modelo({
    required this.becario_id,
    required this.nombre,
    required this.carrera,
    this.universidad = "Universidad Mayor de San Andrés",
    required this.agencia,
    required this.estado_evaluacion,
    this.puntaje_actual,
    this.evaluacion_previa,
  });

  factory BecarioAsignadoModulo3Modelo.desdeJson(Map<String, dynamic> json) {
    return BecarioAsignadoModulo3Modelo(
      becario_id: json['becario_id'] is int
          ? json['becario_id']
          : int.tryParse(json['becario_id']?.toString() ?? '1') ?? 1,
      nombre: json['nombre']?.toString() ?? 'Becario Diaconía',
      carrera: json['carrera']?.toString() ?? 'Carrera Universitaria',
      universidad: json['universidad']?.toString() ?? 'Universidad Mayor de San Andrés',
      agencia: json['agencia']?.toString() ?? 'Agencia Central Diaconía',
      estado_evaluacion: json['estado_evaluacion']?.toString() ?? 'pendiente',
      puntaje_actual: json['puntaje_actual'] != null
          ? double.tryParse(json['puntaje_actual'].toString())
          : null,
      evaluacion_previa: json['evaluacion_previa'] is Map<String, dynamic>
          ? json['evaluacion_previa'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> aJson() => {
    'becario_id': becario_id,
    'nombre': nombre,
    'carrera': carrera,
    'universidad': universidad,
    'agencia': agencia,
    'estado_evaluacion': estado_evaluacion,
    'puntaje_actual': puntaje_actual,
    'evaluacion_previa': evaluacion_previa,
  };

  static List<BecarioAsignadoModulo3Modelo> listaEjemplo() {
    return [
      const BecarioAsignadoModulo3Modelo(
        becario_id: 1,
        nombre: 'María Catunta Laime',
        carrera: 'Ingeniería Comercial',
        universidad: 'Universidad Mayor de San Andrés',
        agencia: 'Agencia Central Diaconía',
        estado_evaluacion: 'pendiente',
      ),
      BecarioAsignadoModulo3Modelo(
        becario_id: 2,
        nombre: 'Juan Carlos Mamani Quispe',
        carrera: 'Administración de Empresas',
        universidad: 'Universidad Católica Boliviana',
        agencia: 'Agencia El Alto - Ceja',
        estado_evaluacion: 'completada',
        puntaje_actual: 94.0,
        evaluacion_previa: {
          'mentor': 'Lic. Carlos Mendoza',
          'becario': 'Juan Carlos Mamani Quispe',
          'agencia': 'Agencia El Alto - Ceja',
          'semestre': 'Semestre II - 2026',
          'calificaciones_1_18': {for (int i = 1; i <= 18; i++) i: (i % 3 == 0 ? 9 : 10)},
          'pregunta_19_apoyo': 'Demostró alta iniciativa en la atención de créditos de desarrollo y microfinanzas.',
          'pregunta_20_destacado': 'Lideró la digitalización de expedientes de mora con gran precisión.',
          'pregunta_21_sugerencias': 'Mantener talleres prácticos de Excel financiero avanzado.',
          'observaciones': 'Desempeño sobresaliente y gran vocación de servicio.',
        },
      ),
      const BecarioAsignadoModulo3Modelo(
        becario_id: 3,
        nombre: 'Ana Belén Flores Choque',
        carrera: 'Contaduría Pública',
        universidad: 'Universidad Pública de El Alto',
        agencia: 'Agencia Miraflores',
        estado_evaluacion: 'pendiente',
      ),
    ];
  }
}

class TareaEscuelaLideresModelo {
  final int numero;
  final String tema;
  final String descripcion;
  final double ponderacion;
  final String estado; // "pendiente", "entregado", "revisado"
  final String? evidencia_nombre;
  final String? fecha_entrega;
  final double? puntaje_obtenido; // 0 - 100 pts
  final String? retroalimentacion;

  const TareaEscuelaLideresModelo({
    required this.numero,
    required this.tema,
    required this.descripcion,
    required this.ponderacion,
    required this.estado,
    this.evidencia_nombre,
    this.fecha_entrega,
    this.puntaje_obtenido,
    this.retroalimentacion,
  });

  factory TareaEscuelaLideresModelo.desdeJson(Map<String, dynamic> json) {
    return TareaEscuelaLideresModelo(
      numero: json['numero'] is int
          ? json['numero']
          : int.tryParse(json['numero']?.toString() ?? '1') ?? 1,
      tema: json['tema']?.toString() ?? 'Tarea Formativa CETI',
      descripcion: json['descripcion']?.toString() ?? '',
      ponderacion: double.tryParse(json['ponderacion']?.toString() ?? '8.33') ?? 8.33,
      estado: json['estado']?.toString() ?? 'pendiente',
      evidencia_nombre: json['evidencia_nombre']?.toString(),
      fecha_entrega: json['fecha_entrega']?.toString(),
      puntaje_obtenido: json['puntaje_obtenido'] != null
          ? double.tryParse(json['puntaje_obtenido'].toString())
          : null,
      retroalimentacion: json['retroalimentacion']?.toString(),
    );
  }

  Map<String, dynamic> aJson() => {
    'numero': numero,
    'tema': tema,
    'descripcion': descripcion,
    'ponderacion': ponderacion,
    'estado': estado,
    'evidencia_nombre': evidencia_nombre,
    'fecha_entrega': fecha_entrega,
    'puntaje_obtenido': puntaje_obtenido,
    'retroalimentacion': retroalimentacion,
  };

  TareaEscuelaLideresModelo copiarCon({
    int? numero,
    String? tema,
    String? descripcion,
    double? ponderacion,
    String? estado,
    String? evidencia_nombre,
    String? fecha_entrega,
    double? puntaje_obtenido,
    String? retroalimentacion,
  }) {
    return TareaEscuelaLideresModelo(
      numero: numero ?? this.numero,
      tema: tema ?? this.tema,
      descripcion: descripcion ?? this.descripcion,
      ponderacion: ponderacion ?? this.ponderacion,
      estado: estado ?? this.estado,
      evidencia_nombre: evidencia_nombre ?? this.evidencia_nombre,
      fecha_entrega: fecha_entrega ?? this.fecha_entrega,
      puntaje_obtenido: puntaje_obtenido ?? this.puntaje_obtenido,
      retroalimentacion: retroalimentacion ?? this.retroalimentacion,
    );
  }

  static List<TareaEscuelaLideresModelo> catalogoCanonico() {
    return const [
      TareaEscuelaLideresModelo(
        numero: 1,
        tema: 'Liderazgo Servidor y Mayordomía Cristiana',
        descripcion: 'Presentación y aprobación de informe práctico sobre principios bíblicos de liderazgo servidor y mayordomía de recursos.',
        ponderacion: 8.33,
        estado: 'revisado',
        evidencia_nombre: 'ensayo_mayordomia_cristiana_v1.pdf',
        fecha_entrega: '12/08/2026',
        puntaje_obtenido: 95.0,
        retroalimentacion: 'Excelente profundidad teológica y aplicación al servicio diario en la agencia.',
      ),
      TareaEscuelaLideresModelo(
        numero: 2,
        tema: 'Misión Integral y Vocación Diaconal',
        descripcion: 'Estudio de caso sobre la proclamación y acción social de la Iglesia en comunidades vulnerables.',
        ponderacion: 8.33,
        estado: 'revisado',
        evidencia_nombre: 'caso_mision_integral_diaconal.pdf',
        fecha_entrega: '26/08/2026',
        puntaje_obtenido: 92.0,
        retroalimentacion: 'Muy buen análisis de la vocación diaconal transformadora.',
      ),
      TareaEscuelaLideresModelo(
        numero: 3,
        tema: 'Ética Profesional en el Ámbito Financiero y Social',
        descripcion: 'Informe de análisis sobre dilemas éticos cotidianos en el sector microfinanciero y decisiones con integridad.',
        ponderacion: 8.33,
        estado: 'revisado',
        evidencia_nombre: 'analisis_etica_profesional.pdf',
        fecha_entrega: '09/09/2026',
        puntaje_obtenido: 90.0,
        retroalimentacion: 'Reflexión sólida y coherente con los principios de Diaconía IFD.',
      ),
      TareaEscuelaLideresModelo(
        numero: 4,
        tema: 'Acompañamiento a Grupos Vulnerables',
        descripcion: 'Plan de acción para el acompañamiento socioespiritual a familias en situación de pobreza.',
        ponderacion: 8.33,
        estado: 'revisado',
        evidencia_nombre: 'plan_acompanamiento_vulnerables.pdf',
        fecha_entrega: '23/09/2026',
        puntaje_obtenido: 94.0,
        retroalimentacion: 'Propuesta práctica con alto valor humano y pastoral.',
      ),
      TareaEscuelaLideresModelo(
        numero: 5,
        tema: 'Resolución de Conflictos en la Comunidad Eclesial',
        descripcion: 'Guía práctica de mediación y reconciliación fundamentada en Mateo 18 y el amor fraternal.',
        ponderacion: 8.33,
        estado: 'revisado',
        evidencia_nombre: 'guia_resolucion_conflictos.pdf',
        fecha_entrega: '07/10/2026',
        puntaje_obtenido: 88.0,
        retroalimentacion: 'Buen enfoque pacificador y pastoral.',
      ),
      TareaEscuelaLideresModelo(
        numero: 6,
        tema: 'Diseño y Planificación de Proyectos de Servicio',
        descripcion: 'Diseño de un proyecto comunitario con marco lógico, cronograma de actividades y presupuesto social.',
        ponderacion: 8.33,
        estado: 'revisado',
        evidencia_nombre: 'proyecto_servicio_comunitario.pdf',
        fecha_entrega: '21/10/2026',
        puntaje_obtenido: 96.0,
        retroalimentacion: 'Proyecto ejemplar, articulado con rigurosidad y vocación.',
      ),
      TareaEscuelaLideresModelo(
        numero: 7,
        tema: 'Oración, Intercesión y Vida Devocional Comunitaria',
        descripcion: 'Bitácora devocional semestral y programa de intercesión por los becarios y beneficiarios.',
        ponderacion: 8.33,
        estado: 'entregado',
        evidencia_nombre: 'bitacora_devocional_semestral.pdf',
        fecha_entrega: '25/10/2026',
        puntaje_obtenido: null,
        retroalimentacion: null,
      ),
      TareaEscuelaLideresModelo(
        numero: 8,
        tema: 'Comunicación Asertiva y Testimonio Universitario',
        descripcion: 'Ensayo reflexivo sobre el testimonio cristiano en el aula universitaria y defensa de valores éticos.',
        ponderacion: 8.33,
        estado: 'entregado',
        evidencia_nombre: 'testimonio_universitario_fe.pdf',
        fecha_entrega: '27/10/2026',
        puntaje_obtenido: null,
        retroalimentacion: null,
      ),
      TareaEscuelaLideresModelo(
        numero: 9,
        tema: 'Finanzas Personales Bíblicas y Responsabilidad',
        descripcion: 'Plan financiero personal y presupuesto familiar aplicando mayordomía financiera.',
        ponderacion: 8.33,
        estado: 'pendiente',
        evidencia_nombre: null,
        fecha_entrega: null,
        puntaje_obtenido: null,
        retroalimentacion: null,
      ),
      TareaEscuelaLideresModelo(
        numero: 10,
        tema: 'Salud Mental y Manejo del Estrés en Época Académica',
        descripcion: 'Estrategias de autocuidado físico, emocional y espiritual durante exámenes y pasantías.',
        ponderacion: 8.33,
        estado: 'pendiente',
        evidencia_nombre: null,
        fecha_entrega: null,
        puntaje_obtenido: null,
        retroalimentacion: null,
      ),
      TareaEscuelaLideresModelo(
        numero: 11,
        tema: 'Discipulado Generacional y Mentoría a Nuevos Becarios',
        descripcion: 'Propuesta de acompañamiento a nuevos becarios ingresantes de primer año.',
        ponderacion: 8.33,
        estado: 'pendiente',
        evidencia_nombre: null,
        fecha_entrega: null,
        puntaje_obtenido: null,
        retroalimentacion: null,
      ),
      TareaEscuelaLideresModelo(
        numero: 12,
        tema: 'Evaluación Integral de Impacto Comunitario',
        descripcion: 'Informe de cierre semestral evaluando aprendizajes, retos espirituales y proyección pastoral.',
        ponderacion: 8.37,
        estado: 'pendiente',
        evidencia_nombre: null,
        fecha_entrega: null,
        puntaje_obtenido: null,
        retroalimentacion: null,
      ),
    ];
  }
}

