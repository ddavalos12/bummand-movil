enum TipoAsistencia {
  practicas('practicas', 'Registro de Prácticas'),
  escuelaLideres('escuela_lideres', 'Escuela de Líderes'),
  accionesServicio('acciones_servicio', 'Acciones de Servicio');

  final String valor;
  final String etiqueta;

  const TipoAsistencia(this.valor, this.etiqueta);

  static String etiquetaDe(String valor) {
    return TipoAsistencia.values
        .firstWhere(
          (e) => e.valor == valor,
          orElse: () => TipoAsistencia.practicas,
        )
        .etiqueta;
  }
}
