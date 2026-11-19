/// Fechas de negocio de Colombia (UTC-5), independientes de la zona del equipo.
class FechaNegocio {
  static DateTime dia(DateTime fecha) =>
      DateTime.utc(fecha.year, fecha.month, fecha.day);

  static DateTime hoy([DateTime? instante]) => dia(
    (instante ?? DateTime.now()).toUtc().subtract(const Duration(hours: 5)),
  );

  static bool valida(DateTime? fecha) =>
      fecha != null && fecha.year >= 1 && fecha.year <= 9999;

  static String clave(DateTime fecha) =>
      '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

  static String mostrar(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
}
