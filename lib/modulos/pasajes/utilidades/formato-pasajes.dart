class FormatoPasajes {
  static const _MESES = [
    "Enero",
    "Febrero",
    "Marzo",
    "Abril",
    "Mayo",
    "Junio",
    "Julio",
    "Agosto",
    "Septiembre",
    "Octubre",
    "Noviembre",
    "Diciembre",
  ];

  static const DIA_ENVIO_FORMULARIO = 24;

  static const diaEnvioFormulario = DIA_ENVIO_FORMULARIO;

  static double numero(dynamic valor) =>
      double.tryParse(valor?.toString() ?? "") ?? 0;

  static String bs(dynamic valor) => "Bs ${numero(valor).toStringAsFixed(2)}";

  static (int anio, int mes) parsearPeriodo(String periodo_str) {
    try {
      final limpio = periodo_str.trim().toLowerCase();

      // Formato YYYY-MM o YYYY/MM
      if (limpio.contains('-') || (limpio.contains('/') && !limpio.contains(' '))) {
        final sep = limpio.contains('-') ? '-' : '/';
        final partes = limpio.split(sep);
        if (partes.length == 2) {
          final p0 = int.tryParse(partes[0]);
          final p1 = int.tryParse(partes[1]);
          if (p0 != null && p1 != null) {
            if (p0 > 1000) {
              return (p0, p1.clamp(1, 12));
            } else {
              return (p1, p0.clamp(1, 12));
            }
          }
        }
      }

      // Nombres de meses en español
      const meses_es = {
        'enero': 1,
        'febrero': 2,
        'marzo': 3,
        'abril': 4,
        'mayo': 5,
        'junio': 6,
        'julio': 7,
        'agosto': 8,
        'septiembre': 9,
        'setiembre': 9,
        'octubre': 10,
        'noviembre': 11,
        'diciembre': 12,
      };

      int mes_encontrado = 0;
      for (final entrada in meses_es.entries) {
        if (limpio.contains(entrada.key)) {
          mes_encontrado = entrada.value;
          break;
        }
      }

      final match_anio = RegExp(r'\b(20\d\d)\b').firstMatch(limpio);
      final anio_encontrado = match_anio != null
          ? (int.tryParse(match_anio.group(1)!) ?? DateTime.now().year)
          : DateTime.now().year;

      if (mes_encontrado > 0) {
        return (anio_encontrado, mes_encontrado);
      }
    } catch (_) {}

    final hoy = DateTime.now();
    return (hoy.year, hoy.month);
  }

  static String periodo(String periodo_str) {
    final (anio, mes) = parsearPeriodo(periodo_str);
    if (mes >= 1 && mes <= 12) {
      return "${_MESES[mes - 1]} $anio";
    }
    return periodo_str;
  }

  static String diaMes(DateTime fecha) {
    return "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}";
  }

  static String periodoDe(DateTime fecha) =>
      "${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}";

  static String get periodoActual => periodoDe(DateTime.now());

  static DateTime fechaHabilitada(String periodo_str) {
    final (anio, mes) = parsearPeriodo(periodo_str);
    return DateTime(anio, mes, DIA_ENVIO_FORMULARIO);
  }

  static bool puedeEnviar(String periodo_str) {
    final hoy = DateTime.now();
    return !DateTime(
      hoy.year,
      hoy.month,
      hoy.day,
    ).isBefore(fechaHabilitada(periodo_str));
  }

  static String ddmmyyyy(DateTime f) =>
      "${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}";

  static String fechaCompleta(DateTime f) {
    const dias = [
      "Lunes",
      "Martes",
      "Miércoles",
      "Jueves",
      "Viernes",
      "Sábado",
      "Domingo",
    ];
    final dia_semana = dias[f.weekday - 1];
    final mes = _MESES[f.month - 1];
    return "$dia_semana, ${f.day} de $mes de ${f.year}";
  }

  static String fechaApi(DateTime fecha) =>
      "${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
}
