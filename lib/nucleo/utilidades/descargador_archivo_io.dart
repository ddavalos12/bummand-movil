import 'dart:io';

Future<bool> descargarBytesPdf(List<int> bytes, String nombre_archivo) async {
  try {
    final nombre_seguro = nombre_archivo.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    Directory directorio = Directory('/storage/emulated/0/Download');
    if (!await directorio.exists()) {
      directorio = Directory.systemTemp;
    }
    final archivo = File('${directorio.path}/$nombre_seguro');
    await archivo.writeAsBytes(bytes, flush: true);
    return true;
  } catch (_) {
    try {
      final nombre_seguro = nombre_archivo.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final archivo = File('${Directory.systemTemp.path}/$nombre_seguro');
      await archivo.writeAsBytes(bytes, flush: true);
      return true;
    } catch (_) {
      return false;
    }
  }
}

Future<bool> abrirUrlEnNavegador(String url) async => false;
