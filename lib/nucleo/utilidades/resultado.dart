class Resultado<T> {
  final bool exito;
  final T? datos;
  final String? error;

  Resultado({required this.exito, this.datos, this.error});

  factory Resultado.exitoso(T datos) => Resultado(exito: true, datos: datos);
  factory Resultado.fallido(String error) =>
      Resultado(exito: false, error: error);
}
