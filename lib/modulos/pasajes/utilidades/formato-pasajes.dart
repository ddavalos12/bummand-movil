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

  static String periodo(String periodo_str) {
    final partes = periodo_str.split("-");
    if (partes.length != 2) return periodo_str;
    final mes = int.tryParse(partes[1]) ?? 0;
    if (mes < 1 || mes > 12) return periodo_str;
    return "${_MESES[mes - 1]} ${partes[0]}";
  }

  static String diaMes(DateTime fecha) {
    return "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}";
  }

  static String periodoDe(DateTime fecha) =>
      "${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}";

  static String get periodoActual => periodoDe(DateTime.now());

  static DateTime fechaHabilitada(String periodo_str) {
    final p = periodo_str.split("-").map(int.parse).toList();
    return DateTime(p[0], p[1], DIA_ENVIO_FORMULARIO);
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

  static String fechaApi(DateTime fecha) =>
      "${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}";
}
