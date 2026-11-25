int calcularSegundosEntreHoras(String? hora_ingreso, String? hora_salida) {
  if (hora_ingreso == null || hora_salida == null) return 0;
  final segs_inicio = _parsearHoraASegundos(hora_ingreso);
  final segs_fin = _parsearHoraASegundos(hora_salida);
  if (segs_inicio == null || segs_fin == null) return 0;
  return segs_fin > segs_inicio ? segs_fin - segs_inicio : 0;
}

int? _parsearHoraASegundos(String hora) {
  final limpia = hora.trim();
  if (limpia.isEmpty) return null;
  final partes = limpia.split(':');
  if (partes.length < 2) return null;
  final hh = int.tryParse(partes[0]);
  final mm = int.tryParse(partes[1]);
  final ss_texto = partes.length >= 3 ? partes[2].split('.').first : '0';
  final ss = int.tryParse(ss_texto) ?? 0;
  if (hh == null || mm == null) return null;
  return hh * 3600 + mm * 60 + ss;
}

String formatearSegundosAHhmmss(int total_segundos) {
  final signo = total_segundos < 0 ? '-' : '';
  final abs = total_segundos.abs();
  final hh = abs ~/ 3600;
  final mm = (abs % 3600) ~/ 60;
  final ss = abs % 60;
  return '$signo${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
}

String formatearHorasDecimalAHhmmss(num? horas_decimal) {
  if (horas_decimal == null || horas_decimal.isNaN) return '00:00:00';
  final segs = (horas_decimal.toDouble() * 3600).round();
  return formatearSegundosAHhmmss(segs);
}

String formatearDuracionAsistencia({
  String? hora_ingreso,
  String? hora_salida,
  num? horas_decimal,
}) {
  final segs = calcularSegundosEntreHoras(hora_ingreso, hora_salida);
  if (segs > 0) return formatearSegundosAHhmmss(segs);
  if (horas_decimal != null && horas_decimal > 0) {
    return formatearHorasDecimalAHhmmss(horas_decimal);
  }
  return '00:00:00';
}

String normalizarHoraConSegundos(
  String? hora, {
  String valor_defecto = '--:--:--',
}) {
  if (hora == null || hora.trim().isEmpty) return valor_defecto;
  final partes = hora.trim().split(':');
  if (partes.length < 2) return valor_defecto;
  final hh = partes[0].padLeft(2, '0');
  final mm = partes[1].padLeft(2, '0');
  final ss_raw = partes.length >= 3 ? partes[2].split('.').first : '00';
  final ss = ss_raw.padLeft(2, '0');
  return '${hh.substring(hh.length - 2)}:${mm.substring(mm.length - 2)}:${ss.substring(ss.length - 2)}';
}
