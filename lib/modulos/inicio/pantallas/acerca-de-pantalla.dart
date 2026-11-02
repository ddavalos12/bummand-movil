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
            // 1. Tarjeta Hero Institucional
            _construirHeroInstitucional(),
            const SizedBox(height: 16),

            // 2. Misión y Visión
            _construirMisionVision(),
            const SizedBox(height: 16),

            // 3. Los Tres Principios Diaconales
            _construirTresPrincipios(),
            const SizedBox(height: 16),


            // 4. Línea de Tiempo Histórica
            _construirLineaTiempo(),
            const SizedBox(height: 16),

            // 5. Sede Central y Contacto
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BumandColores.grisClaro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: BumandColores.amarilloRadiante,
              ),
              const SizedBox(width: 8),
              const Expanded(
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
