class OrdenConfirmacionModelo {
  final bool activa;
  final bool confirmada_este_mes;
  final String periodo;
  final String mensaje_admin;
  final DateTime? fecha_limite;

  const OrdenConfirmacionModelo({
    required this.activa,
    required this.confirmada_este_mes,
    required this.periodo,
    required this.mensaje_admin,
    this.fecha_limite,
  });

  factory OrdenConfirmacionModelo.desdeMapa(Map<String, dynamic> mapa) {
    return OrdenConfirmacionModelo(
      activa: mapa['activa'] == true || mapa['orden_activa'] == true,
      confirmada_este_mes: mapa['confirmada_este_mes'] == true ||
          mapa['confirmado'] == true,
      periodo: mapa['periodo']?.toString() ?? 'Octubre 2026',
      mensaje_admin: mapa['mensaje_admin']?.toString() ??
          'La administración central de Diaconía IFD requiere la confirmación mensual de tus datos de contacto.',
      fecha_limite: mapa['fecha_limite'] != null
          ? DateTime.tryParse(mapa['fecha_limite'].toString())
          : null,
    );
  }

  OrdenConfirmacionModelo copiarCon({
    bool? activa,
    bool? confirmada_este_mes,
    String? periodo,
    String? mensaje_admin,
    DateTime? fecha_limite,
  }) {
    return OrdenConfirmacionModelo(
      activa: activa ?? this.activa,
      confirmada_este_mes: confirmada_este_mes ?? this.confirmada_este_mes,
      periodo: periodo ?? this.periodo,
      mensaje_admin: mensaje_admin ?? this.mensaje_admin,
      fecha_limite: fecha_limite ?? this.fecha_limite,
    );
  }
}
