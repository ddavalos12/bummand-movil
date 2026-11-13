import 'package:flutter/material.dart';

import '../../../nucleo/tema/colores.dart';

enum EstadoAccionEvaluacion {
  pendiente,
  completado,
  observado,
  esperando,
}

/// Par estandarizado de botones tipo píldora para pantallas de evaluación
/// en móvil (todos los roles: administrador, supervisor y becario).
///
/// Muestra el botón secundario outline "Revisar" (#00ABBD / #035683) junto a
/// un indicador/acción condicional según el estado:
/// - pendiente: píldora verde sólido (#059669)
/// - completado: píldora verde suave (#ECFDF5) con borde esmeralda (#34D399)
/// - observado: píldora rosa suave (#FFF1F2) con borde (#FDA4AF)
/// - esperando: píldora neutra informativa
class BotonesAccionEvaluacion extends StatelessWidget {
  final EstadoAccionEvaluacion estado;
  final bool mostrar_revisar;
  final String texto_revisar;
  final VoidCallback? al_revisar;
  final String texto_pendiente;
  final VoidCallback? al_ejecutar_pendiente;
  final IconData icono_pendiente;
  final String texto_completado;
  final VoidCallback? al_hacer_clic_completado;
  final String texto_observado;
  final VoidCallback? al_hacer_clic_observado;
  final String texto_esperando;
  final bool cargando;
  final bool expandir;
  final WrapAlignment alineacion;

  const BotonesAccionEvaluacion({
    super.key,
    required this.estado,
    this.mostrar_revisar = true,
    this.texto_revisar = "Revisar",
    this.al_revisar,
    this.texto_pendiente = "Aprobar",
    this.al_ejecutar_pendiente,
    this.icono_pendiente = Icons.verified_user_outlined,
    this.texto_completado = "Aprobado",
    this.al_hacer_clic_completado,
    this.texto_observado = "Observado",
    this.al_hacer_clic_observado,
    this.texto_esperando = "Pendiente",
    this.cargando = false,
    this.expandir = false,
    this.alineacion = WrapAlignment.end,
  });

  static const Color _verde_solido = Color(0xFF059669);
  static const Color _verde_suave_fondo = Color(0xFFECFDF5);
  static const Color _verde_suave_borde = Color(0xFF34D399);
  static const Color _verde_texto = Color(0xFF065F46);

  static const Color _rosa_suave_fondo = Color(0xFFFFF1F2);
  static const Color _rosa_suave_borde = Color(0xFFFDA4AF);
  static const Color _rosa_texto = Color(0xFF9F1239);
  static const Color _rosa_icono = Color(0xFFE11D48);

  Widget _construirBotonRevisar() {
    return OutlinedButton.icon(
      onPressed: al_revisar,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: BumandColores.azulMarinoSecundario,
        side: const BorderSide(
          color: BumandColores.azulCieloSuave,
          width: 1.2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
      ),
      icon: const Icon(
        Icons.visibility_outlined,
        size: 15,
        color: BumandColores.azulCieloSuave,
      ),
      label: Text(
        texto_revisar,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: BumandColores.azulMarinoSecundario,
        ),
      ),
    );
  }

  Widget _construirAccionCondicional() {
    switch (estado) {
      case EstadoAccionEvaluacion.pendiente:
        return ElevatedButton.icon(
          onPressed: cargando ? null : al_ejecutar_pendiente,
          style: ElevatedButton.styleFrom(
            backgroundColor: _verde_solido,
            foregroundColor: Colors.white,
            disabledBackgroundColor: _verde_solido.withValues(alpha: 0.6),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            minimumSize: const Size(0, 34),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: const StadiumBorder(),
          ),
          icon: cargando
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icono_pendiente, size: 15, color: Colors.white),
          label: Text(
            texto_pendiente,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );

      case EstadoAccionEvaluacion.completado:
        return _construirPildoraEstado(
          fondo: _verde_suave_fondo,
          borde: _verde_suave_borde,
          texto_color: _verde_texto,
          icono_color: _verde_solido,
          icono: Icons.verified_user_outlined,
          texto: texto_completado,
          al_tocar: cargando ? null : al_hacer_clic_completado,
        );

      case EstadoAccionEvaluacion.observado:
        return _construirPildoraEstado(
          fondo: _rosa_suave_fondo,
          borde: _rosa_suave_borde,
          texto_color: _rosa_texto,
          icono_color: _rosa_icono,
          icono: Icons.warning_amber_rounded,
          texto: texto_observado,
          al_tocar: cargando ? null : al_hacer_clic_observado,
        );

      case EstadoAccionEvaluacion.esperando:
        return _construirPildoraEstado(
          fondo: const Color(0xFFF8FAFC),
          borde: const Color(0xFFCBD5E1),
          texto_color: const Color(0xFF475569),
          icono_color: const Color(0xFF94A3B8),
          icono: Icons.schedule_rounded,
          texto: texto_esperando,
          al_tocar: null,
        );
    }
  }

  Widget _construirPildoraEstado({
    required Color fondo,
    required Color borde,
    required Color texto_color,
    required Color icono_color,
    required IconData icono,
    required String texto,
    required VoidCallback? al_tocar,
  }) {
    final contenido = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borde, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (cargando)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: icono_color,
              ),
            )
          else
            Icon(icono, size: 15, color: icono_color),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: texto_color,
            ),
          ),
        ],
      ),
    );

    if (al_tocar == null) return contenido;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: al_tocar,
        child: contenido,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiene_revisar = mostrar_revisar && al_revisar != null;
    final tiene_accion =
        estado != EstadoAccionEvaluacion.pendiente || al_ejecutar_pendiente != null;

    if (expandir) {
      return Row(
        children: [
          if (tiene_revisar) ...[
            Expanded(child: _construirBotonRevisar()),
            if (tiene_accion) const SizedBox(width: 8),
          ],
          if (tiene_accion) Expanded(child: _construirAccionCondicional()),
        ],
      );
    }

    return Wrap(
      alignment: alineacion,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        if (tiene_revisar) _construirBotonRevisar(),
        if (tiene_accion) _construirAccionCondicional(),
      ],
    );
  }
}
