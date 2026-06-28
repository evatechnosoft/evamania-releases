/// A km-based maintenance task, e.g. "Lastik — her 8000 km".
class MaintenanceItem {
  final String id;
  String name;

  /// Service interval in km.
  double intervalKm;

  /// Odometer reading (km) at the last service.
  double lastServiceKm;

  String? note;
  bool enabled;

  MaintenanceItem({
    required this.id,
    required this.name,
    required this.intervalKm,
    this.lastServiceKm = 0,
    this.note,
    this.enabled = true,
  });

  /// Km driven since the last service, given the current odometer.
  double drivenSince(double currentOdoKm) =>
      (currentOdoKm - lastServiceKm).clamp(0, double.infinity);

  /// Km remaining until next service (negative = overdue).
  double remainingKm(double currentOdoKm) =>
      intervalKm - drivenSince(currentOdoKm);

  /// 0..1 progress toward the next service (clamped).
  double progress(double currentOdoKm) =>
      intervalKm <= 0 ? 0 : (drivenSince(currentOdoKm) / intervalKm).clamp(0, 1);

  bool isDue(double currentOdoKm) => remainingKm(currentOdoKm) <= 0;

  /// "Service done now": reset the baseline to the current odometer.
  void markServiced(double currentOdoKm) => lastServiceKm = currentOdoKm;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'intervalKm': intervalKm,
        'lastServiceKm': lastServiceKm,
        'note': note,
        'enabled': enabled,
      };

  factory MaintenanceItem.fromJson(Map<String, dynamic> j) => MaintenanceItem(
        id: j['id'] as String,
        name: j['name'] as String,
        intervalKm: (j['intervalKm'] as num).toDouble(),
        lastServiceKm: (j['lastServiceKm'] as num?)?.toDouble() ?? 0,
        note: j['note'] as String?,
        enabled: j['enabled'] as bool? ?? true,
      );

  /// Sensible starter set for an EV two-wheeler.
  static List<MaintenanceItem> defaults() => [
        MaintenanceItem(id: 'tire', name: 'Lastik kontrol', intervalKm: 8000),
        MaintenanceItem(id: 'brake', name: 'Fren balatası', intervalKm: 6000),
        MaintenanceItem(id: 'belt', name: 'Kayış/zincir', intervalKm: 5000),
        MaintenanceItem(
            id: 'general', name: 'Genel bakım', intervalKm: 10000),
      ];
}
