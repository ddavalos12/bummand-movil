import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../nucleo/tema/colores.dart';
import '../modulos/autenticacion/proveedores/autenticacion-proveedor.dart';
import '../modulos/autenticacion/pantallas/inicio-sesion-pantalla.dart';
import '../modulos/autenticacion/pantallas/mi-perfil-pantalla.dart';
import '../modulos/notificaciones/pantallas/notificaciones-pantalla.dart';
import '../modulos/inicio/pantallas/acerca-de-pantalla.dart';


class _VersiculoDiarioData {
  final String referencia;
  final String texto;
  final String tema;
  final String reflexion;

  const _VersiculoDiarioData({
    required this.referencia,
    required this.texto,
    required this.tema,
    required this.reflexion,
  });
}

class BarraSuperiorBumand extends ConsumerWidget implements PreferredSizeWidget {
  final String titulo;
  final String? subtitulo;
  final List<Widget>? acciones_adicionales;
  final bool mostrar_logos;
  final bool mostrar_perfil;
  final bool mostrar_versiculo_diario;
  final VoidCallback? alTocarLogo;

  const BarraSuperiorBumand({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acciones_adicionales,
    this.mostrar_logos = true,
    this.mostrar_perfil = true,
    this.mostrar_versiculo_diario = true,
    this.alTocarLogo,
  });

  static const List<_VersiculoDiarioData> _VERSICULOS_DIARIOS = [
    _VersiculoDiarioData(
      referencia: "Josué 1:9",
      texto: "«Mira que te mando que te esfuerces y seas valiente; no temas ni desmayes, porque Jehová tu Dios estará contigo en dondequiera que vayas.»",
      tema: "Valentía y Confianza",
      reflexion: "La vocación diaconal nos llama a avanzar con valor inquebrantable, sabiendo que el Señor guía y respalda cada paso de servicio al prójimo.",
    ),
    _VersiculoDiarioData(
      referencia: "Salmos 23:1-2",
      texto: "«Jehová es mi pastor; nada me faltará. En lugares de delicados pastos me hará descansar; junto a aguas de reposo me pastoreará.»",
      tema: "Provisión y Descanso",
      reflexion: "En medio de las exigencias universitarias y laborales, Dios es nuestra fuente inagotable de paz, dirección y descanso.",
    ),
    _VersiculoDiarioData(
      referencia: "Colosenses 3:23-24",
      texto: "«Y todo lo que hagáis, hacedlo de corazón, como para el Señor y no para los hombres; sabiendo que del Señor recibiréis la recompensa de la herencia, porque a Cristo el Señor servís.»",
      tema: "Lema BUMAND · Servicio de Corazón",
      reflexion: "Cada tarea académica, práctica profesional y proyecto comunitario es una ofrenda viva de excelencia consagrada a Cristo.",
    ),
    _VersiculoDiarioData(
      referencia: "Filipenses 4:13",
      texto: "«Todo lo puedo en Cristo que me fortalece.»",
      tema: "Fortaleza en Cristo",
      reflexion: "Los desafíos de la vida estudiantil y el liderazgo social se superan gracias a la fortaleza que el Señor renueva cada amanecer.",
    ),
    _VersiculoDiarioData(
      referencia: "Proverbios 3:5-6",
      texto: "«Fíate de Jehová de todo tu corazón, y no te apoyes en tu propia prudencia. Reconócelo en todos tus caminos, y él enderezará tus veredas.»",
      tema: "Sabiduría y Dirección",
      reflexion: "Subordinar nuestros planes a la voluntad divina transforma decisiones difíciles en trayectorias de fruto y bendición.",
    ),
    _VersiculoDiarioData(
      referencia: "Jeremías 29:11",
      texto: "«Porque yo sé los pensamientos que tengo acerca de vosotros, dice Jehová, pensamientos de paz, y no de mal, para daros el fin que esperáis.»",
      tema: "Futuro y Esperanza",
      reflexion: "Dios concibió un propósito transformador para tu formación universitaria y tu vocación de liderazgo solidario.",
    ),
    _VersiculoDiarioData(
      referencia: "Isaías 41:10",
      texto: "«No temas, porque yo estoy contigo; no desmayes, porque yo soy tu Dios que te esfuerzo; siempre te ayudaré, siempre te sustentaré con la diestra de mi justicia.»",
      tema: "Sustento Divino",
      reflexion: "Frente a exámenes o circunstancias imprevistas, la mano protectora del Creador sostiene tu andar con total fidelidad.",
    ),
    _VersiculoDiarioData(
      referencia: "Mateo 5:14-16",
      texto: "«Vosotros sois la luz del mundo; una ciudad asentada sobre un monte no se puede esconder... Así alumbre vuestra luz delante de los hombres, para que vean vuestras buenas obras, y glorifiquen a vuestro Padre que está en los cielos.»",
      tema: "Luz y Testimonio",
      reflexion: "La presencia del becario universitario refleja transparencia, rectitud y solidaridad en las aulas y en la comunidad.",
    ),
    _VersiculoDiarioData(
      referencia: "1 Timoteo 4:12",
      texto: "«Ninguno tenga en poco tu juventud, sino sé ejemplo de los creyentes en palabra, conducta, amor, espíritu, fe y pureza.»",
      tema: "Liderazgo Joven Ejemplar",
      reflexion: "La juventud es la mejor temporada para inspirar a otros con integridad de vida, servicio compasivo y pureza de corazón.",
    ),
    _VersiculoDiarioData(
      referencia: "Romanos 12:2",
      texto: "«No os conforméis a este siglo, sino transformaos por medio de la renovación de vuestro entendimiento, para que comprobéis cuál sea la buena voluntad de Dios, agradable y perfecta.»",
      tema: "Renovación Mental y Ética",
      reflexion: "La educación superior con principios diaconales renueva la mente para promover justicia social y equidad.",
    ),
    _VersiculoDiarioData(
      referencia: "Gálatas 6:9",
      texto: "«No nos cansemos, pues, de hacer bien; porque a su tiempo segaremos, si no desmayamos.»",
      tema: "Perseverancia en el Bien",
      reflexion: "La constancia en el servicio desinteresado y la ayuda mutua genera frutos profundos y duraderos en la sociedad.",
    ),
    _VersiculoDiarioData(
      referencia: "Salmos 119:105",
      texto: "«Lámpara es a mis pies tu palabra, y lumbrera a mi camino.»",
      tema: "Guía por la Palabra",
      reflexion: "Las Escrituras orientan el criterio ético y moral del estudiante frente a los dilemas del mundo moderno.",
    ),
    _VersiculoDiarioData(
      referencia: "Miqueas 6:8",
      texto: "«Oh hombre, él te ha declarado lo que es bueno, y qué pide Jehová de ti: solamente hacer justicia, y amar misericordia, y humillarte ante tu Dios.»",
      tema: "Justicia, Misericordia y Humildad",
      reflexion: "El corazón del liderazgo de servicio: actuar con equidad, manifestar ternura activa y caminar en humildad ante Dios.",
    ),
    _VersiculoDiarioData(
      referencia: "Proverbios 16:3",
      texto: "«Encomienda a Jehová tus obras, y tus pensamientos serán afirmados.»",
      tema: "Proyectos en Manos de Dios",
      reflexion: "Al consagrar tus metas académicas y laborales al Señor, Él concede serenidad, foco y solidez a tus pensamientos.",
    ),
    _VersiculoDiarioData(
      referencia: "2 Timoteo 1:7",
      texto: "«Porque no nos ha dado Dios espíritu de cobardía, sino de poder, de amor y de dominio propio.»",
      tema: "Poder, Amor y Dominio Propio",
      reflexion: "El servidor del Reino actúa con serenidad, compasión genuina y firme autocontrol en toda coyuntura.",
    ),
    _VersiculoDiarioData(
      referencia: "Salmos 37:5",
      texto: "«Encomienda a Jehová tu camino, y confía en él; y él hará.»",
      tema: "Confianza Incondicional",
      reflexion: "Descansa tus anhelos y futuro profesional en el Señor; su respaldo oportuno jamás defrauda a los suyos.",
    ),
    _VersiculoDiarioData(
      referencia: "Mateo 20:28",
      texto: "«Como el Hijo del Hombre no vino para ser servido, sino para servir, y para dar su vida en rescate por muchos.»",
      tema: "Modelo de Liderazgo Siervo",
      reflexion: "La verdadera grandeza se expresa en la disposición a lavar los pies y atender con humildad las necesidades de los demás.",
    ),
    _VersiculoDiarioData(
      referencia: "Santiago 1:5",
      texto: "«Y si alguno de vosotros tiene falta de sabiduría, pídala a Dios, el cual da a todos abundantemente y sin reproche, y le será dada.»",
      tema: "Sabiduría Práctica",
      reflexion: "Ante situaciones complejas de estudio o convivencia, la sabiduría celestial está disponible mediante la oración sincera.",
    ),
    _VersiculoDiarioData(
      referencia: "Hebreos 13:16",
      texto: "«Y de hacer bien y de la ayuda mutua no os olvidéis; porque de tales sacrificios se agrada Dios.»",
      tema: "Solidaridad y Ayuda Mutua",
      reflexion: "La fraternidad comunitaria y el apoyo entre compañeros son ofrendas gratas que honran el corazón del Padre.",
    ),
    _VersiculoDiarioData(
      referencia: "1 Pedro 4:10",
      texto: "«Cada uno según el don que ha recibido, minístrelo a los otros, como buenos administradores de la multiforme gracia de Dios.»",
      tema: "Mayordomía de Dones",
      reflexion: "Las habilidades científicas, técnicas y espirituales recibidas existen para enriquecer y bendecir a nuestra comunidad.",
    ),
  ];

  static void mostrarDialogoVersiculoDiario(BuildContext context) {
    final random = math.Random();
    int indiceActual = random.nextInt(_VERSICULOS_DIARIOS.length);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, actualizarEstadoDialogo) {
          final versiculo = _VERSICULOS_DIARIOS[indiceActual];

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabecera institucional Diaconía FRIF-IFD
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                    decoration: const BoxDecoration(
                      gradient: _DEGRADADO_DIACONIA,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Versículo Bíblico Diario",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Reina-Valera 1960 · Diaconía FRIF-IFD",
                                style: TextStyle(
                                  color: Color(0xFFD6F1F7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                          tooltip: "Cerrar",
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),

                  // Cuerpo con Versículo, Referencia y Reflexión Diaconal
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Chip de Tema
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 13,
                                  color: BumandColores.AZUL_DIACONIA,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  versiculo.tema,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: BumandColores.AZUL_DIACONIA,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Referencia bíblica destacada
                          Row(
                            children: [
                              const Icon(
                                Icons.bookmark_added_rounded,
                                size: 18,
                                color: BumandColores.AZUL_DIACONIA,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                versiculo.referencia,
                                style: const TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w900,
                                  color: BumandColores.AZUL_DIACONIA,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Texto Bíblico RVR1960
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.format_quote_rounded,
                                  color: BumandColores.AZUL_DIACONIA,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    versiculo.texto,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.45,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFF1E293B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Reflexión Diaconal formativa
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 18,
                                  color: Color(0xFFD97706),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Reflexión Diaconal",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFB45309),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        versiculo.reflexion,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          height: 1.35,
                                          color: Color(0xFF78350F),
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
                    ),
                  ),

                  // Botones de Acción
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              actualizarEstadoDialogo(() {
                                int nuevo;
                                do {
                                  nuevo = math.Random().nextInt(_VERSICULOS_DIARIOS.length);
                                } while (_VERSICULOS_DIARIOS.length > 1 && nuevo == indiceActual);
                                indiceActual = nuevo;
                              });
                            },
                            icon: const Text("🎲", style: TextStyle(fontSize: 13)),
                            label: const Text(
                              "Otro versículo al azar",
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: BumandColores.AZUL_DIACONIA,
                              side: const BorderSide(color: BumandColores.AZUL_DIACONIA),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: BumandColores.AZUL_DIACONIA,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          ),
                          child: const Text(
                            "Cerrar",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _mostrarDialogoVersiculoDiarioAzar(BuildContext context) {
    mostrarDialogoVersiculoDiario(context);
  }

  Widget _construirBotonVersiculoDiario(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _mostrarDialogoVersiculoDiarioAzar(context),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 13,
                color: BumandColores.AZUL_DIACONIA,
              ),
              SizedBox(width: 3.5),
              Text(
                "Versículo Diario",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: BumandColores.AZUL_DIACONIA,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _DEGRADADO_DIACONIA = LinearGradient(
    colors: [BumandColores.AZUL_DIACONIA, BumandColores.TURQUESA_DIACONIA],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Size get preferredSize => const Size.fromHeight(74);

  void _mostrarDialogoCorreosAlternativos(BuildContext context, WidgetRef ref) {
    final usuario = ref.read(autenticacion_proveedor).usuario;
    final controlador_correo = TextEditingController(
      text: usuario?.correo_alternativo ?? '',
    );
    String? error_dialogo;
    bool guardando = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, actualizarEstadoDialogo) {
          final correos_adicionales = <String>{
            if (usuario?.correo_alternativo != null &&
                usuario!.correo_alternativo!.trim().isNotEmpty)
              usuario.correo_alternativo!.trim(),
            ...(usuario?.correos_adicionales ?? const <String>[]),
          }.where((c) => c != (usuario?.correo ?? "")).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.alternate_email_rounded,
                  color: BumandColores.AZUL_DIACONIA,
                  size: 22,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Correos de Inicio de Sesión",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: BumandColores.AZUL_DIACONIA,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Puedes iniciar sesión con tu correo principal o vincular un correo alternativo (personal o institucional).",
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: BumandColores.AZUL_DIACONIA,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Principal: ${usuario?.correo ?? 'becario@bumand.bo'}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (correos_adicionales.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    for (final c in correos_adicionales)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.mark_email_read_outlined,
                              size: 15,
                              color: Color(0xFF0D9488),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Alternativo: $c",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF0F766E),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: controlador_correo,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Correo alternativo de acceso",
                      hintText: "ejemplo@diaconia.bo",
                      errorText: error_dialogo,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: guardando ? null : () => Navigator.of(ctx).pop(),
                child: const Text("Cancelar"),
              ),
              FilledButton(
                onPressed: guardando
                    ? null
                    : () async {
                        actualizarEstadoDialogo(() {
                          guardando = true;
                          error_dialogo = null;
                        });
                        final res = await ref
                            .read(autenticacion_proveedor.notifier)
                            .actualizarCorreoAlternativo(
                              controlador_correo.text,
                            );
                        if (!ctx.mounted) return;
                        if (res.exito) {
                          Navigator.of(ctx).pop();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  res.datos ??
                                      "Correo alternativo actualizado",
                                ),
                                backgroundColor: const Color(0xFF059669),
                              ),
                            );
                          }
                        } else {
                          actualizarEstadoDialogo(() {
                            guardando = false;
                            error_dialogo = res.error;
                          });
                        }
                      },
                child: const Text("Guardar correo"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _mostrarDialogoPerfil(BuildContext context, WidgetRef ref) {
    final estado_auth = ref.read(autenticacion_proveedor);
    final usuario = estado_auth.usuario;
    final correos_alternativos = <String>{
      if (usuario?.correo_alternativo != null &&
          usuario!.correo_alternativo!.trim().isNotEmpty)
        usuario.correo_alternativo!.trim(),
      ...(usuario?.correos_adicionales ?? const <String>[]),
    }.where((c) => c != (usuario?.correo ?? "")).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: const BoxConstraints(
        maxWidth: 580,
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.88,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: BumandColores.AZUL_DIACONIA,
                        child: Text(
                          (usuario?.nombre.isNotEmpty ?? false)
                              ? usuario!.nombre.substring(0, 1).toUpperCase()
                              : "B",
                          style: const TextStyle(
                            color: BumandColores.NARANJA,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              usuario?.nombre ?? "Usuario Becario",
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: BumandColores.AZUL_DIACONIA,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              usuario?.correo ?? "becario@bumand.bo",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (correos_alternativos.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                "Alternativo(s): ${correos_alternativos.join(' · ')}",
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: BumandColores.AZUL_DIACONIA.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                (usuario?.rol ?? "becario").toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: BumandColores.AZUL_DIACONIA,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: BumandColores.AZUL_DIACONIA.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.manage_accounts_rounded,
                        color: BumandColores.AZUL_DIACONIA,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      "Mi Perfil y Seguridad de Cuenta",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: BumandColores.NEGRO,
                      ),
                    ),
                    subtitle: const Text(
                      "Nombre, correo(s), contraseña y datos personales",
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MiPerfilPantalla()),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: BumandColores.azulCieloSuave.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.alternate_email_rounded,
                        color: BumandColores.AZUL_DIACONIA,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      "Correos de Inicio de Sesión",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: BumandColores.NEGRO,
                      ),
                    ),
                    subtitle: Text(
                      correos_alternativos.isNotEmpty
                          ? "Alternativo activo: ${correos_alternativos.first}"
                          : "Vincular correo alternativo o institucional de acceso",
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _mostrarDialogoCorreosAlternativos(context, ref);
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: BumandColores.azulMarinoSecundario.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: BumandColores.azulMarinoSecundario,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      "Acerca de Nosotros",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: BumandColores.NEGRO,
                      ),
                    ),
                    subtitle: const Text(
                      "Diaconía FRIF-IFD · Principios e historia",
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AcercaDePantalla(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 4),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      "Cerrar sesión corporativa",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: const Text(
                      "Finalizar sesión en este dispositivo",
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () async {
                      final navegador = Navigator.of(context, rootNavigator: true);
                      final notificador = ref.read(autenticacion_proveedor.notifier);
                      Navigator.of(ctx).pop();
                      try {
                        await notificador.cerrarSesion();
                      } finally {
                        navegador.pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const InicioSesionPantalla(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool puede_retroceder = Navigator.of(context).canPop();
    final bool mostrar_boton_versiculo = mostrar_versiculo_diario && !puede_retroceder;

    return AppBar(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 74,
      titleSpacing: mostrar_boton_versiculo ? 6 : NavigationToolbar.kMiddleSpacing,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: _DEGRADADO_DIACONIA),
      ),
      title: mostrar_boton_versiculo
          ? Row(
              children: [
                _construirBotonVersiculoDiario(context),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitulo != null)
                        Text(
                          subtitulo!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFFD6F1F7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                if (subtitulo != null)
                  Text(
                    subtitulo!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: Color(0xFFD6F1F7),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
      actions: [
        ...?acciones_adicionales,
        if (mostrar_logos) ...[
          // Logo BUMAND Blanco oficial interactivo
          GestureDetector(
            onTap: () {
              if (alTocarLogo != null) {
                alTocarLogo!();
              } else {
                ref.read(menu_principal_proveedor.notifier).alternar();
              }
            },
            child: Tooltip(
              message: "Menú principal",
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SvgPicture.asset(
                  'assets/logos/logo-bumand-dorado-blanco.svg',
                  height: 20,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Logo Diaconía IFD oficial en cápsula blanca de alta visibilidad
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: SvgPicture.asset(
              'assets/logos/logo-diaconia-color.svg',
              height: 14,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 2),
        ],
        if (mostrar_perfil) ...[
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 20),
            tooltip: "Notificaciones y códigos",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificacionesPantalla(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 22),
            tooltip: "Mi perfil y sesión",
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            visualDensity: VisualDensity.compact,
            onPressed: () => _mostrarDialogoPerfil(context, ref),
          ),
        ],
        const SizedBox(width: 4),
      ],
    );
  }
}

class MenuPrincipalNotificador extends Notifier<bool> {
  @override
  bool build() => false;

  void alternar() => state = !state;
  void mostrar() => state = true;
  void ocultar() => state = false;
}

final menu_principal_proveedor =
    NotifierProvider<MenuPrincipalNotificador, bool>(
  MenuPrincipalNotificador.new,
);

