/// A lightweight instantaneous telemetry snapshot fed to the alarm engine and
/// voice assistant. Feed it the same values you already read from the
/// controller / BMS over BLE (FarDriver / Votol / JK / Daly / ANT). Every field
/// is optional — rules simply skip fields that are null.
///
/// Intentionally standalone (no dependency on the ride-tracking module) so this
/// feature can be used on its own.
class RiderTelemetry {
  final double? speedKmh;
  final double? rpm;
  final double? voltage;
  final double? current; // A (negative = regen)
  final double? soc; // %
  final double? remainingAh;
  final int? cellMinMv;
  final int? cellMaxMv;
  final double? motorTempC;
  final double? controllerTempC;
  final double? batteryTempC;

  /// Active fault/error labels right now (e.g. decoded FarDriver bits).
  final List<String> faults;

  const RiderTelemetry({
    this.speedKmh,
    this.rpm,
    this.voltage,
    this.current,
    this.soc,
    this.remainingAh,
    this.cellMinMv,
    this.cellMaxMv,
    this.motorTempC,
    this.controllerTempC,
    this.batteryTempC,
    this.faults = const [],
  });

  double? get powerW =>
      (voltage != null && current != null) ? voltage! * current! : null;

  int? get cellDeltaMv =>
      (cellMinMv != null && cellMaxMv != null) ? cellMaxMv! - cellMinMv! : null;

  /// Resolves a numeric value for an [AlarmField]. Kept here so the engine has
  /// a single mapping point.
  double? value(AlarmField f) {
    switch (f) {
      case AlarmField.speedKmh:
        return speedKmh;
      case AlarmField.rpm:
        return rpm;
      case AlarmField.voltage:
        return voltage;
      case AlarmField.current:
        return current;
      case AlarmField.powerW:
        return powerW;
      case AlarmField.soc:
        return soc;
      case AlarmField.remainingAh:
        return remainingAh;
      case AlarmField.cellDeltaMv:
        return cellDeltaMv?.toDouble();
      case AlarmField.motorTempC:
        return motorTempC;
      case AlarmField.controllerTempC:
        return controllerTempC;
      case AlarmField.batteryTempC:
        return batteryTempC;
    }
  }
}

/// Telemetry fields an alarm rule can watch.
enum AlarmField {
  speedKmh,
  rpm,
  voltage,
  current,
  powerW,
  soc,
  remainingAh,
  cellDeltaMv,
  motorTempC,
  controllerTempC,
  batteryTempC,
}

extension AlarmFieldLabel on AlarmField {
  /// Short Turkish label used in spoken/printed messages.
  String get label {
    switch (this) {
      case AlarmField.speedKmh:
        return 'hız';
      case AlarmField.rpm:
        return 'devir';
      case AlarmField.voltage:
        return 'voltaj';
      case AlarmField.current:
        return 'akım';
      case AlarmField.powerW:
        return 'güç';
      case AlarmField.soc:
        return 'batarya';
      case AlarmField.remainingAh:
        return 'kalan kapasite';
      case AlarmField.cellDeltaMv:
        return 'hücre farkı';
      case AlarmField.motorTempC:
        return 'motor sıcaklığı';
      case AlarmField.controllerTempC:
        return 'sürücü sıcaklığı';
      case AlarmField.batteryTempC:
        return 'batarya sıcaklığı';
    }
  }
}
