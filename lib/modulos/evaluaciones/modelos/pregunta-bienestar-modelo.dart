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

  /// Catálogo canónico oficial con las 26 preguntas de Cuestionario_bienestar_universitario.pdf
  static List<PreguntaBienestarModelo> catalogoCanonico() {
    return const [
      PreguntaBienestarModelo(
        numero_orden: 1,
        titulo: 'Ingresos del hogar',
        enunciado: '¿Los ingresos de su hogar alcanzan para cubrir las necesidades básicas?',
        categoria: 'Economía Familiar',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Alcanzan y permiten ahorrar'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Alcanzan con dificultad'),
          OpcionBienestarModelo(inciso: 'C', texto: 'No alcanzan'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 2,
        titulo: 'Ahorros familiares',
        enunciado: '¿Su familia cuenta con ahorros para emergencias?',
        categoria: 'Economía Familiar',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Sí, suficientes'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Sí, pero son insuficientes'),
          OpcionBienestarModelo(inciso: 'C', texto: 'No tiene ahorros'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 3,
        titulo: 'Fuentes de ingreso',
        enunciado: '¿Cuántas fuentes de ingreso tiene su hogar?',
        categoria: 'Economía Familiar',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Dos o más fuentes estables'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Una fuente estable'),
          OpcionBienestarModelo(inciso: 'C', texto: 'Solo ingresos ocasionales o ninguno'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 4,
        titulo: 'Capacidad para generar ingresos',
        enunciado: '¿Qué capacidad tiene para generar ingresos?',
        categoria: 'Economía Familiar',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Constante'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Irregular'),
          OpcionBienestarModelo(inciso: 'C', texto: 'Muchas dificultades'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 5,
        titulo: 'Documentación de identidad',
        enunciado: '¿Los integrantes de su hogar cuentan con cédula de identidad vigente?',
        categoria: 'Legal y Ciudadanía',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Todos'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Solo algunos'),
          OpcionBienestarModelo(inciso: 'C', texto: 'Ninguno'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 6,
        titulo: 'Acceso a agua potable',
        enunciado: '¿Su hogar tiene acceso a agua potable?',
        categoria: 'Vivienda y Servicios',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Sí, todos los días'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Sí, pero con interrupciones'),
          OpcionBienestarModelo(inciso: 'C', texto: 'No tiene acceso'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 7,
        titulo: 'Atención médica',
        enunciado: '¿Puede recibir atención médica cuando la necesita?',
        categoria: 'Salud',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Sí, oportunamente'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Sí, con dificultades'),
          OpcionBienestarModelo(inciso: 'C', texto: 'No puedo recibirla'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 8,
        titulo: 'Alimentación',
        enunciado: '¿Con qué frecuencia su familia consume alimentos variados y nutritivos?',
        categoria: 'Salud y Nutrición',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Todos los días'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Algunos días'),
          OpcionBienestarModelo(inciso: 'C', texto: 'Casi nunca'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 9,
        titulo: 'Salud dental',
        enunciado: '¿En qué estado se encuentra su salud dental?',
        categoria: 'Salud',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Sin molestias'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Molestias ocasionales o tratamientos pendientes'),
          OpcionBienestarModelo(inciso: 'C', texto: 'Dolor frecuente o problemas sin atender'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 10,
        titulo: 'Vacunación',
        enunciado: '¿Los integrantes de su hogar tienen las vacunas que les corresponden según su edad?',
        categoria: 'Salud',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Todos al día'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Algunos pendientes'),
          OpcionBienestarModelo(inciso: 'C', texto: 'Ninguno al día'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 11,
        titulo: 'Seguridad de la vivienda',
        enunciado: '¿Su vivienda ofrece condiciones de seguridad para vivir?',
        categoria: 'Vivienda y Servicios',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Buen estado'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Daños menores'),
          OpcionBienestarModelo(inciso: 'C', texto: 'Daños que ponen en riesgo'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 12,
        titulo: 'Servicios sanitarios',
        enunciado: '¿Su hogar dispone de baño y un sistema adecuado para eliminar las aguas residuales?',
        categoria: 'Vivienda y Servicios',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Sí, ambos funcionan'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Presentan problemas'),
          OpcionBienestarModelo(inciso: 'C', texto: 'No dispone'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 13,
        titulo: 'Electricidad',
        enunciado: '¿Su hogar cuenta con electricidad?',
        categoria: 'Vivienda y Servicios',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Sí, constante'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Cortes frecuentes'),
          OpcionBienestarModelo(inciso: 'C', texto: 'No cuenta'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 14,
        titulo: 'Transporte público',
        enunciado: '¿Puede acceder al transporte público cuando lo necesita?',
        categoria: 'Transporte y Movilidad',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Sí, fácilmente'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Con dificultades de distancia, horario o costo'),
          OpcionBienestarModelo(inciso: 'C', texto: 'No puedo acceder'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 15,
        titulo: 'Lectura y comprensión',
        enunciado: '¿Puede leer y comprender un texto cotidiano, como un aviso o una instrucción?',
        categoria: 'Educación y Habilidades',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Sí, sin dificultad'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Con alguna dificultad'),
          OpcionBienestarModelo(inciso: 'C', texto: 'No puedo hacerlo'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 16,
        titulo: 'Organización económica',
        enunciado: '¿Cómo organiza los ingresos y gastos de su hogar?',
        categoria: 'Economía Familiar',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Elaboro presupuesto y control'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Parcialmente'),
          OpcionBienestarModelo(inciso: 'C', texto: 'No llevo control'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 17,
        titulo: 'Seguridad personal',
        enunciado: '¿Qué tan seguro se siente en su vida cotidiana?',
        categoria: 'Entorno y Convivencia',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Seguro la mayor parte del tiempo'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Inseguro en algunas situaciones'),
          OpcionBienestarModelo(inciso: 'C', texto: 'Inseguro con frecuencia'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 18,
        titulo: 'Resolución de conflictos familiares',
        enunciado: '¿Cómo suelen resolver los conflictos en su familia?',
        categoria: 'Entorno y Convivencia',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Mediante diálogo y acuerdos'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Con discusiones y dificultad'),
          OpcionBienestarModelo(inciso: 'C', texto: 'Quedan sin resolver'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 19,
        titulo: 'Violencia intrafamiliar',
        enunciado: '¿En su hogar se presentan situaciones de violencia física, psicológica o sexual?',
        categoria: 'Entorno y Convivencia',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'No se presentan'),
          OpcionBienestarModelo(inciso: 'B', texto: 'En alguna ocasión'),
          OpcionBienestarModelo(inciso: 'C', texto: 'De manera frecuente'),
          OpcionBienestarModelo(inciso: 'D', texto: 'Prefiero no responder'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 20,
        titulo: 'Autonomía personal',
        enunciado: '¿Puede tomar decisiones sobre su vida y sus actividades?',
        categoria: 'Desarrollo Personal',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Sí, con autonomía'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Solo en algunos aspectos'),
          OpcionBienestarModelo(inciso: 'C', texto: 'Otras personas deciden por mí'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 21,
        titulo: 'Motivación y satisfacción con los estudios',
        enunciado: '¿Cuál es tu nivel de motivación y satisfacción con tus estudios universitarios?',
        categoria: 'Bienestar Universitario',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Considero abandonar mis estudios'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Estudio con desánimo y dudas frecuentes'),
          OpcionBienestarModelo(inciso: 'C', texto: 'Siento satisfacción moderada con mi carrera'),
          OpcionBienestarModelo(inciso: 'D', texto: 'Me entusiasma estudiar y lo relaciono con mis metas'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 22,
        titulo: 'Condiciones y recursos para estudiar',
        enunciado: '¿Cuenta con condiciones y recursos adecuados para estudiar (espacio, libros, conectividad)?',
        categoria: 'Bienestar Universitario',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Sin espacio ni materiales adecuados'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Recursos muy limitados e intermitentes'),
          OpcionBienestarModelo(inciso: 'C', texto: 'Recursos suficientes en la mayoría de los casos'),
          OpcionBienestarModelo(inciso: 'D', texto: 'Espacio adecuado y todos los recursos necesarios'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 23,
        titulo: 'Libertad para expresar opiniones',
        enunciado: '¿Siente libertad para expresar sus opiniones e ideas en su entorno de estudio y hogar?',
        categoria: 'Bienestar Universitario',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Evito expresarme por temor a represalias o rechazo'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Me cuesta expresar mis opiniones abiertamente'),
          OpcionBienestarModelo(inciso: 'C', texto: 'Puedo expresarme con relativa confianza'),
          OpcionBienestarModelo(inciso: 'D', texto: 'Me expreso con plena libertad y soy escuchado'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 24,
        titulo: 'Metas durante la carrera — Corto plazo',
        enunciado: '¿Tiene definidas sus metas académicas durante la carrera (corto plazo)?',
        categoria: 'Bienestar Universitario',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Desorientado, sin metas claras'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Tengo ideas vagas sobre lo que quiero lograr'),
          OpcionBienestarModelo(inciso: 'C', texto: 'Tengo objetivos definidos para este semestre'),
          OpcionBienestarModelo(inciso: 'D', texto: 'Plan bien definido con cursos, proyectos y metas claras'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 25,
        titulo: 'Transición al mundo laboral — Mediano plazo',
        enunciado: '¿Cómo visualiza su transición al mundo laboral al egresar (mediano plazo)?',
        categoria: 'Bienestar Universitario',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'No sé qué hacer al salir de la carrera'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Siento mucha incertidumbre sobre encontrar empleo'),
          OpcionBienestarModelo(inciso: 'C', texto: 'Tengo identificadas áreas de interés laboral'),
          OpcionBienestarModelo(inciso: 'D', texto: 'Estrategia clara y metas profesionales definidas'),
        ],
      ),
      PreguntaBienestarModelo(
        numero_orden: 26,
        titulo: 'Visión de desarrollo profesional — Largo plazo',
        enunciado: '¿Cuál es su visión de desarrollo profesional y especialización (largo plazo)?',
        categoria: 'Bienestar Universitario',
        opciones: [
          OpcionBienestarModelo(inciso: 'A', texto: 'Incertidumbre total sobre el futuro profesional'),
          OpcionBienestarModelo(inciso: 'B', texto: 'Espero conseguir cualquier trabajo estable'),
          OpcionBienestarModelo(inciso: 'C', texto: 'Tengo interés en posgrados o emprendimientos'),
          OpcionBienestarModelo(inciso: 'D', texto: 'Plan claro que combina trabajo, posgrado y servicio a la comunidad'),
        ],
      ),
    ];
  }
}
