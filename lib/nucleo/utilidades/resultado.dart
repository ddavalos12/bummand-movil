import '../errores/error-bumand.dart';

class Resultado<T> {
  final bool exito;
  final T? datos;
  final String? error;
  final ErrorBumand? error_bumand;

  const Resultado({
    required this.exito,
    this.datos,
    this.error,
    this.error_bumand,
  });

  factory Resultado.exitoso(T datos) => Resultado(exito: true, datos: datos);

  factory Resultado.fallido(String error, {ErrorBumand? error_bumand}) =>
      Resultado(
        exito: false,
        error: error,
        error_bumand: error_bumand,
      );

  factory Resultado.desdeErrorBumand(ErrorBumand error_bumand) => Resultado(
        exito: false,
        error: error_bumand.mensaje,
        error_bumand: error_bumand,
      );
}
