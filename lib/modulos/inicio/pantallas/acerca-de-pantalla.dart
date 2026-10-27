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
  int _perspectiva_seleccionada = 0; // 0: Becario, 1: Mentor, 2: Institucional

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
            // 1. Tarjeta Hero Institucional
            _construirHeroInstitucional(),
            const SizedBox(height: 16),

            // 2. Cifras de Impacto al 24 de Octubre de 2026
            _construirMallaImpacto(),
            const SizedBox(height: 16),

            // 3. Selector de Perspectiva por Rol
            _construirSelectorPerspectiva(),
            const SizedBox(height: 16),

            // 4. Misión y Visión
            _construirMisionVision(),
            const SizedBox(height: 16),

            // 5. Los Tres Principios Diaconales
            _construirTresPrincipios(),
            const SizedBox(height: 16),

            // 6. Matriz de Evaluación 360° (100 Pts)
            _construirMatriz360(),
            const SizedBox(height: 16),

            // 7. Línea de Tiempo Histórica
            _construirLineaTiempo(),
            const SizedBox(height: 16),

            // 8. Sede Central y Contacto
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
                      "Regulado por ASFI",
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
                  "24 Octubre 2026",
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
            "Becas Universitarias con Misión y Acción Diaconal",
            style: TextStyle(
              color: BumandColores.amarilloRadiante,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Programa social de la Fundación Diaconía Fondo Rotativo de Inversión y Fomento (Diaconía FRIF-IFD). Formamos líderes con excelencia profesional, principios cristianos y vocación de servicio integral.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),

          // Lema Bíblico
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  color: BumandColores.amarilloRadiante,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "«Junto a aguas de reposo me pastoreará... me guiará por sendas de justicia por amor de su nombre.»",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Salmos 23:2-3 · Lema Fundacional",
                        style: TextStyle(
                          color: BumandColores.amarilloRadiante,
                          fontSize: 10,
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

  Widget _construirMallaImpacto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Cifras Institucionales (Al 24 de Octubre de 2026)",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: BumandColores.azulMarinoSecundario,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _construirKpiCard(
                titulo: "Sedes y Agencias",
                valor: "72",
                detalle: "WGS84 a nivel nacional",
                color_acento: BumandColores.azulMarinoSecundario,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _construirKpiCard(
                titulo: "Becarios Activos",
                valor: "23",
                detalle: "Gestión oficial II-2026",
                color_acento: BumandColores.azulMarinoProfundo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _construirKpiCard(
                titulo: "Iglesias Aliadas",
                valor: "17",
                detalle: "Pastores con Formulario F-03",
                color_acento: BumandColores.amarilloRadiante,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _construirKpiCard(
                titulo: "Digitalización",
                valor: "100%",
                detalle: "+250 hojas/mes erradicadas",
                color_acento: BumandColores.azulPetroleo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _construirKpiCard({
    required String titulo,
    required String valor,
    required String detalle,
    required Color color_acento,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BumandColores.grisClaro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color_acento,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detalle,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirSelectorPerspectiva() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BumandColores.grisClaro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Perspectiva por Rol Institucional",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: BumandColores.azulMarinoSecundario,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _construirBotonPestana(0, "Becario"),
              const SizedBox(width: 6),
              _construirBotonPestana(1, "Supervisor"),
              const SizedBox(width: 6),
              _construirBotonPestana(2, "Directiva"),
            ],
          ),
          const SizedBox(height: 12),
          if (_perspectiva_seleccionada == 0) ...[
            _construirPuntoPerspectiva(
              "Apoyo Económico Directo",
              "Bs. 650 para nivel universitario y Bs. 250 para nivel técnico mensual.",
              Icons.monetization_on_rounded,
              BumandColores.azulMarinoProfundo,
            ),
            _construirPuntoPerspectiva(
              "Reembolso del 80% de Pasajes",
              "Liquidación exacta en tramos de minibús, micro y Mi Teleférico.",
              Icons.directions_bus_rounded,
              BumandColores.azulCieloSuave,
            ),
            _construirPuntoPerspectiva(
              "Escuela de Líderes (CETI)",
              "Talleres teológicos los viernes a las 14:30 y 12 tareas en Classroom.",
              Icons.menu_book_rounded,
              BumandColores.amarilloRadiante,
            ),
          ] else if (_perspectiva_seleccionada == 1) ...[
            _construirPuntoPerspectiva(
              "Rúbrica Likert 18+3",
              "Evaluación sobre 20 pts: 18 ítems de desempeño (1-10) y 3 cualitativos.",
              Icons.checklist_rounded,
              BumandColores.azulMarinoSecundario,
            ),
            _construirPuntoPerspectiva(
              "Trazabilidad de Pasajes 👁️",
              "Auditoría visual de calles declaradas y paradas en campo.",
              Icons.visibility_rounded,
              BumandColores.azulPetroleo,
            ),
            _construirPuntoPerspectiva(
              "Firma Digital Canvas",
              "Aprobación de horas con valor legal para auditoría interna.",
              Icons.draw_rounded,
              BumandColores.azulMarinoProfundo,
            ),
          ] else ...[
            _construirPuntoPerspectiva(
              "Radar Geodésico Haversine",
              "Validación satelital con radio de 50m a 120m en 72 sedes.",
              Icons.radar_rounded,
              BumandColores.azulPetroleo,
            ),
            _construirPuntoPerspectiva(
              "Sábana Semestral 14 Columnas",
              "Consolidado general de los 5 módulos formativos y dictamen.",
              Icons.table_chart_rounded,
              BumandColores.azulMarinoSecundario,
            ),
            _construirPuntoPerspectiva(
              "Bienestar Universitario (26 Preguntas)",
              "Cuestionario psicoemocional con semáforo preventivo.",
              Icons.favorite_rounded,
              BumandColores.azulCieloSuave,
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirBotonPestana(int indice, String etiqueta) {
    final activo = _perspectiva_seleccionada == indice;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _perspectiva_seleccionada = indice),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: activo
                ? BumandColores.azulMarinoProfundo
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            etiqueta,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: activo ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirPuntoPerspectiva(
    String titulo,
    String desc,
    IconData icono,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF334155),
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: "$titulo: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirMisionVision() {
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
                      "Misión Institucional",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: BumandColores.azulMarinoSecundario,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "«Entidad financiera con principios cristianos que aporta al progreso integral de nuestros clientes y desarrolla la inclusión de la población vulnerable a través de soluciones financieras integrales en áreas urbanas y rurales.»",
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
                Icons.explore_rounded,
                color: BumandColores.azulCieloSuave,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Visión Institucional",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: BumandColores.azulMarinoSecundario,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "«Ser una institución líder en la inclusión financiera, prestando soluciones financieras integrales de calidad con trato digno al cliente y respeto a los valores culturales, con una visión diaconal.»",
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

  Widget _construirTresPrincipios() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BumandColores.grisClaro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Los Tres Principios Diaconales",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: BumandColores.azulMarinoSecundario,
            ),
          ),
          const SizedBox(height: 10),
          _construirCardPrincipio(
            "1. Compartir la Fe",
            "Comunión cristiana en congregaciones locales, devocionales y testimonio vivo.",
            BumandColores.amarilloRadiante,
            const Color(0xFFFFFBEB),
          ),
          const SizedBox(height: 8),
          _construirCardPrincipio(
            "2. Combatir la Pobreza",
            "Inclusión social, becas universitarias y oportunidades formativas integrales.",
            BumandColores.azulMarinoProfundo,
            const Color(0xFFF0F9FF),
          ),
          const SizedBox(height: 8),
          _construirCardPrincipio(
            "3. Promover la Justicia",
            "Equidad, trato digno, ética transparente y servicio activo al prójimo.",
            BumandColores.azulCieloSuave,
            const Color(0xFFF0FDFA),
          ),
        ],
      ),
    );
  }

  Widget _construirCardPrincipio(
    String titulo,
    String desc,
    Color color_borde,
    Color fondo,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: color_borde, width: 4),
          top: const BorderSide(color: BumandColores.grisClaro),
          right: const BorderSide(color: BumandColores.grisClaro),
          bottom: const BorderSide(color: BumandColores.grisClaro),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color_borde == BumandColores.amarilloRadiante
                  ? const Color(0xFFB45309)
                  : color_borde,
            ),
          ),
          const SizedBox(height: 2),
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
    );
  }

  Widget _construirMatriz360() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BumandColores.grisClaro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Matriz de Evaluación 360° (100 Pts)",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: BumandColores.azulMarinoSecundario,
            ),
          ),
          const SizedBox(height: 10),
          _construirFilaModulo(
            "M1: Desempeño Académico",
            "20 pts",
            "Kardex universitario y materias",
            BumandColores.azulMarinoProfundo,
          ),
          _construirFilaModulo(
            "M2: Liderazgo Eclesial",
            "20 pts",
            "Formulario F-03 pastor de iglesia",
            BumandColores.azulCieloSuave,
          ),
          _construirFilaModulo(
            "M3: Prácticas Diaconía (PP²)",
            "20 pts",
            "Rúbrica 18+3 del mentor laboral",
            BumandColores.azulMarinoSecundario,
          ),
          _construirFilaModulo(
            "M4: Escuela de Líderes CETI",
            "20 pts",
            "12 tareas y talleres de viernes",
            BumandColores.amarilloRadiante,
          ),
          _construirFilaModulo(
            "M5: Bienestar Socioeconómico",
            "20 pts",
            "Cuestionario de 26 preguntas",
            BumandColores.azulPetroleo,
          ),
          const Divider(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                "≥70: Óptimo",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF059669),
                ),
              ),
              Text(
                "51-69: Condicionado",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD97706),
                ),
              ),
              Text(
                "≤50: Pérdida",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _construirFilaModulo(
    String nombre,
    String puntos,
    String desc,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              puntos,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color == BumandColores.amarilloRadiante
                    ? const Color(0xFFB45309)
                    : color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            "Trayectoria Histórica (2015 – 2026)",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: BumandColores.azulMarinoSecundario,
            ),
          ),
          SizedBox(height: 10),
          _HitoHistorialWidget(
            gestion: "2015 – 2018",
            titulo: "Creación del Fondo BUMAND",
            detalle: "Fondo rotativo en Diaconía para colegiaturas y sustento de becarios.",
          ),
          _HitoHistorialWidget(
            gestion: "2019 – 2023",
            titulo: "Alianza CETI y Expansión",
            detalle: "Más de 50 graduados y talleres teológicos semanales.",
          ),
          _HitoHistorialWidget(
            gestion: "2024 – 2025",
            titulo: "Proyecto de Grado UMSA",
            detalle: "Convenio Informática UMSA para digitalizar +250 formularios/mes.",
          ),
          _HitoHistorialWidget(
            gestion: "2026",
            titulo: "Consolidación Multiplataforma",
            detalle: "App Flutter + Web Next.js con GPS satelital Haversine y cierre II-2026.",
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
