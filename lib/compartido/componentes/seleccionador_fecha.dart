import 'package:flutter/material.dart';
import '../../nucleo/tema/colores.dart';

class SeleccionadorFecha extends StatelessWidget {
  final DateTime fecha;
  final ValueChanged<DateTime> onCambiada;
  final String etiqueta;
  final DateTime? primeraFecha;
  final DateTime? ultimaFecha;

  const SeleccionadorFecha({
    super.key,
    required this.fecha,
    required this.onCambiada,
    this.etiqueta = "Fecha",
    this.primeraFecha,
    this.ultimaFecha,
  });

  Future<void> _elegirFecha(BuildContext context) async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: fecha,
      firstDate: primeraFecha ?? DateTime(hoy.year - 5),
      lastDate: ultimaFecha ?? DateTime(hoy.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: BumandColores.TURQUESA_DIACONIA,
              onPrimary: BumandColores.BLANCO,
              onSurface: BumandColores.NEGRO,
            ),
          ),
          child: child!,
        );
      },
    );
    if (elegida != null) {
      onCambiada(elegida);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE3DCCB), width: 1.5),
      ),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: BumandColores.TURQUESA_DIACONIA),
        title: Text(etiqueta, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        subtitle: Text(
          "${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}",
          style: const TextStyle(fontWeight: FontWeight.bold, color: BumandColores.AZUL_DIACONIA),
        ),
        trailing: const Icon(Icons.edit_calendar, color: Colors.black54),
        onTap: () => _elegirFecha(context),
      ),
    );
  }
}

class SeleccionadorHora extends StatelessWidget {
  final TimeOfDay hora;
  final ValueChanged<TimeOfDay> onCambiada;
  final String etiqueta;

  const SeleccionadorHora({
    super.key,
    required this.hora,
    required this.onCambiada,
    this.etiqueta = "Hora",
  });

  Future<void> _elegirHora(BuildContext context) async {
    final elegida = await showTimePicker(
      context: context,
      initialTime: hora,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: BumandColores.TURQUESA_DIACONIA,
              onPrimary: BumandColores.BLANCO,
              onSurface: BumandColores.NEGRO,
            ),
          ),
          child: child!,
        );
      },
    );
    if (elegida != null) {
      onCambiada(elegida);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE3DCCB), width: 1.5),
      ),
      child: ListTile(
        leading: const Icon(Icons.access_time, color: BumandColores.TURQUESA_DIACONIA),
        title: Text(etiqueta, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        subtitle: Text(
          hora.format(context),
          style: const TextStyle(fontWeight: FontWeight.bold, color: BumandColores.AZUL_DIACONIA),
        ),
        trailing: const Icon(Icons.edit, color: Colors.black54),
        onTap: () => _elegirHora(context),
      ),
    );
  }
}

class SeleccionadorFechaHora extends StatelessWidget {
  final DateTime fecha;
  final TimeOfDay hora;
  final ValueChanged<DateTime> onFechaCambiada;
  final ValueChanged<TimeOfDay> onHoraCambiada;
  final String etiquetaFecha;
  final String etiquetaHora;
  final DateTime? primeraFecha;
  final DateTime? ultimaFecha;

  const SeleccionadorFechaHora({
    super.key,
    required this.fecha,
    required this.hora,
    required this.onFechaCambiada,
    required this.onHoraCambiada,
    this.etiquetaFecha = "Fecha",
    this.etiquetaHora = "Hora",
    this.primeraFecha,
    this.ultimaFecha,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SeleccionadorFecha(
            fecha: fecha,
            onCambiada: onFechaCambiada,
            etiqueta: etiquetaFecha,
            primeraFecha: primeraFecha,
            ultimaFecha: ultimaFecha,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: SeleccionadorHora(
            hora: hora,
            onCambiada: onHoraCambiada,
            etiqueta: etiquetaHora,
          ),
        ),
      ],
    );
  }
}
