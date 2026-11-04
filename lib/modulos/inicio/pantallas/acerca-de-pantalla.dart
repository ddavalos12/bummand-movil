import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nucleo/tema/colores.dart';
import '../../../widgets-comunes/barra-superior-bumand.dart';

class AcercaDePantalla extends ConsumerStatefulWidget {
  const AcercaDePantalla({super.key});

  @override
  ConsumerState<AcercaDePantalla> createState() => _AcercaDePantallaState();
}

class _AcercaDePantallaState extends ConsumerState<AcercaDePantalla> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BumandColores.fondo,
      appBar: const BarraSuperiorBumand(
        titulo: "Acerca de Nosotros",
        subtitulo: "Diaconía FRIF-IFD · BUMAND",
        mostrar_perfil: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Tarjeta Hero Institucional con Versículo Colosenses 3:23
            _construirHeroInstitucional(),
            const SizedBox(height: 16),

            // 2. ¿Quiénes Somos?
            _construirQuienesSomos(),
            const SizedBox(height: 16),

            // 3. Objetivo, Visión y Misión Institucional
            _construirObjetivoVisionMision(),
            const SizedBox(height: 16),

            // 4. Los 4 Componentes del Programa BUMAND
            _construirCuatroComponentes(),
            const SizedBox(height: 16),

            // 5. Los Tres Principios Diaconales
            _construirTresPrincipios(),
            const SizedBox(height: 16),

            // 6. Historia y Trayectoria Institucional (1981 – 2026)
            _construirLineaTiempo(),
            const SizedBox(height: 16),

            // 7. Sede Central y Contacto
            _construirSedeCentral(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _construirHeroInstitucional() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            BumandColores.azulMarinoSecundario,
            BumandColores.azulMarinoProfundo,
            BumandColores.azulPetroleo,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: BumandColores.azulMarinoSecundario.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: BumandColores.amarilloRadiante,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Inversión Social · Diaconía FRIF-IFD",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: BumandColores.amarilloRadiante.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: BumandColores.amarilloRadiante.withValues(alpha: 0.4),
                  ),
                ),
                child: const Text(
                  "Desde 1981",
                  style: TextStyle(
                    color: BumandColores.amarilloRadiante,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text(
            "BUMAND",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Becarios Universitarios Misión Alianza Noruega de Diaconía",
            style: TextStyle(
              color: BumandColores.amarilloRadiante,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Programa de inversión social de Diaconía FRIF-IFD integrado desde 2019. Empodera a estudiantes universitarios de escasos recursos mediante formación integral en liderazgo diaconal, combinando fe, competencias técnicas y vocación de servicio.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),

          // Chips de impacto institucional
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _construirChipImpacto("25 becarios activos", "La Paz y El Alto"),
              _construirChipImpacto("+65 beneficiados", "47% mujeres"),
              _construirChipImpacto("Sede Diaconía", "Desde 2019"),
            ],
          ),
          const SizedBox(height: 14),

          // Lema Bíblico Oficial: Colosenses 3:23
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  color: BumandColores.amarilloRadiante,
                  size: 22,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "«Y todo lo que hagáis, hacedlo de corazón, como para el Señor y no para los hombres.»",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Colosenses 3:23 · Lema Institucional BUMAND",
                        style: TextStyle(
                          color: BumandColores.amarilloRadiante,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirChipImpacto(String titulo, String subtitulo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitulo,
            style: const TextStyle(
              color: BumandColores.amarilloRadiante,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirQuienesSomos() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BumandColores.grisClaro),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_alt_rounded,
                color: BumandColores.azulMarinoProfundo,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                "¿Quiénes somos?",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: BumandColores.azulMarinoSecundario,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "BUMAND es un programa de capacitación en liderazgo de servicio, dirigido a estudiantes universitarios cristianos evangélicos, de escasos recursos, que tienen gran potencial de formarse como líderes diaconales, para ser agentes de cambio en la familia, la iglesia y la comunidad.",
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF334155),
              height: 1.45,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Inició sus reuniones y actividades de formación en las instalaciones de la Misión Alianza de Noruega (ex fábrica de vidrios); posteriormente, tras su integración en 2019 a Diaconía FRIF-IFD, las reuniones y talleres pasaron a realizarse en las oficinas de la institución.",
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirObjetivoVisionMision() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: BumandColores.grisClaro),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.track_changes_rounded,
                color: BumandColores.amarilloRadiante,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Objetivo del Programa",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: BumandColores.azulMarinoSecundario,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "«La escuela de liderazgo Diaconal busca formar líderes cristianos comprometidos con el Reino de Dios, desde una fuerte espiritualidad, para que desde su testimonio de vida y el ejercicio de su liderazgo, transformen positivamente su entorno en la perspectiva del reino.»",
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: BumandColores.grisClaro),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.visibility_rounded,
                color: BumandColores.azulCieloSuave,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Visión",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: BumandColores.azulMarinoSecundario,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "«Líderes graduados con vocación de servicio, involucrados plenamente en su contexto social, haciendo uso inteligente y relevante de su entrenamiento, su profesión y liderazgo para la gloria de Dios.»",
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: BumandColores.grisClaro),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.flag_rounded,
                color: BumandColores.azulMarinoProfundo,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Misión",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: BumandColores.azulMarinoSecundario,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "«Los becarios capacitados, comprometidos y motivados por la Palabra de Dios y el Espíritu Santo a un liderazgo de servicio en su contexto social e iglesia local.»",
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _construirCuatroComponentes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BumandColores.grisClaro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.dashboard_customize_rounded,
                size: 18,
                color: BumandColores.azulMarinoProfundo,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Los 4 Componentes del Programa",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: BumandColores.azulMarinoSecundario,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Ejes formativos integrales definidos en el marco fundacional de BUMAND:",
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _construirCardComponente(
            numero: "1",
            titulo: "Escuela de Líderes",
            descripcion:
                "Ciclo formativo basado en el módulo CETI-Iglesia y el estudio del libro de Howard Snyder: «La Comunidad del Rey», generando un cambio en la visión de la iglesia como agente de transformación del Reino con hechos de misericordia e impacto social.",
            color: BumandColores.azulMarinoProfundo,
            icono: Icons.menu_book_rounded,
          ),
          const SizedBox(height: 10),
          _construirCardComponente(
            numero: "2",
            titulo: "Prácticas Pre-Profesionales",
            descripcion:
                "Apoyo en la cualificación profesional y técnica de los becarios dentro de la institución y el mercado laboral, generando impacto positivo en su persona, familia, iglesia y comunidad sobre la plataforma del servicio.",
            color: BumandColores.azulCieloSuave,
            icono: Icons.work_outline_rounded,
          ),
          const SizedBox(height: 10),
          _construirCardComponente(
            numero: "3",
            titulo: "Liderazgo en la Iglesia",
            descripcion:
                "Eje central enfocado en potenciar el liderazgo y compromiso cristiano para servir en su congregación local y en todo el entorno comunitario donde se desenvuelve el estudiante.",
            color: BumandColores.amarilloRadiante,
            icono: Icons.church_rounded,
          ),
          const SizedBox(height: 10),
          _construirCardComponente(
            numero: "4",
            titulo: "Acciones de Servicio",
            descripcion:
                "«Si no te cuesta, no lo valoras». El programa no se limita al aporte económico; fomenta una actitud de esfuerzo, trabajo pre-profesional y servicio activo y solidario en favor de la comunidad.",
            color: BumandColores.azulPetroleo,
            icono: Icons.volunteer_activism_rounded,
          ),
        ],
      ),
    );
  }

  Widget _construirCardComponente({
    required String numero,
    required String titulo,
    required String descripcion,
    required Color color,
    required IconData icono,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BumandColores.grisClaro),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(icono, color: color, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$numero. $titulo",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: color == BumandColores.amarilloRadiante
                        ? const Color(0xFFB45309)
                        : color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  descripcion,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF334155),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirTresPrincipios() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BumandColores.grisClaro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: BumandColores.amarilloRadiante,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Los Tres Principios Diaconales",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: BumandColores.azulMarinoSecundario,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Pilares fundacionales que rigen el actuar de Diaconía FRIF-IFD y la formación del becario:",
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _construirCardPrincipio(
            "1. Compartir la Fe",
            "Comunión cristiana en congregaciones locales, devocionales y testimonio vivo.",
            BumandColores.amarilloRadiante,
            const Color(0xFFFFFBEB),
            icono: "🕊️",
          ),
          const SizedBox(height: 10),
          _construirCardPrincipio(
            "2. Combatir la Pobreza",
            "Inclusión social, becas universitarias y oportunidades formativas integrales.",
            BumandColores.azulMarinoProfundo,
            const Color(0xFFF0F9FF),
            icono: "🌱",
          ),
          const SizedBox(height: 10),
          _construirCardPrincipio(
            "3. Promover la Justicia",
            "Equidad, trato digno, ética transparente y servicio activo al prójimo.",
            BumandColores.azulCieloSuave,
            const Color(0xFFF0FDFA),
            icono: "⚖️",
          ),
        ],
      ),
    );
  }

  Widget _construirCardPrincipio(
    String titulo,
    String desc,
    Color color_borde,
    Color fondo, {
    String? icono,
  }) {
    final Color color_texto = color_borde == BumandColores.amarilloRadiante
        ? const Color(0xFFB45309)
        : (color_borde == BumandColores.azulCieloSuave
            ? const Color(0xFF00808E)
            : color_borde);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BumandColores.grisClaro),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color_borde,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color_texto,
                        ),
                      ),
                      if (icono != null)
                        Text(
                          icono,
                          style: const TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF334155),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirLineaTiempo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BumandColores.grisClaro),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Historia y Trayectoria Institucional (1981 – 2026)",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: BumandColores.azulMarinoSecundario,
            ),
          ),
          SizedBox(height: 10),
          _HitoHistorialWidget(
            gestion: "1981 – 1982",
            titulo: "Origen del Programa con Berit Helgøy Kloster",
            detalle:
                "Nace en la Misión Alianza de Noruega para apoyar a jóvenes universitarios desde el proyecto de patrocinio.",
          ),
          _HitoHistorialWidget(
            gestion: "1983 – 1984",
            titulo: "Reafirmación de Becas Universitarias",
            detalle:
                "Consolidado por Carlos Tamayo para fortalecer las iglesias con profesionales cristianos y brindar apoyo sociofinanciero.",
          ),
          _HitoHistorialWidget(
            gestion: "2019",
            titulo: "Integración a Diaconía FRIF-IFD",
            detalle:
                "Adopción institucional como programa de inversión social, trasladando encuentros a las oficinas de Diaconía.",
          ),
          _HitoHistorialWidget(
            gestion: "Presente",
            titulo: "Impacto Activo y Consolidación",
            detalle:
                "25 becarios en La Paz y El Alto, +65 egresados (47% mujeres) y plataforma digital institucional.",
            es_ultimo: true,
          ),
        ],
      ),
    );
  }

  Widget _construirSedeCentral() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BumandColores.grisClaro),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_city_rounded,
                color: BumandColores.azulMarinoProfundo,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                "Sede Central Diaconía FRIF-IFD",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: BumandColores.azulMarinoSecundario,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "Av. Juan Pablo II N° 2540 (Bloques A y B), El Alto, La Paz, Bolivia.\nCoordenadas: -16.50005, -68.17345 (Tolerancia: 120m)\nContacto Oficial: coordinacion@bumand.bo",
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF475569),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _HitoHistorialWidget extends StatelessWidget {
  final String gestion;
  final String titulo;
  final String detalle;
  final bool es_ultimo;

  const _HitoHistorialWidget({
    required this.gestion,
    required this.titulo,
    required this.detalle,
    this.es_ultimo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: es_ultimo
                    ? BumandColores.amarilloRadiante
                    : BumandColores.azulMarinoProfundo,
                shape: BoxShape.circle,
              ),
            ),
            if (!es_ultimo)
              Container(
                width: 2,
                height: 36,
                color: const Color(0xFFCBD5E1),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$gestion · $titulo",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  detalle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
