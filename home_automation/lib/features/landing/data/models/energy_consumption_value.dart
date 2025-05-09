class EnergyConsumptionValue {

  String? day;
  double? value;
  bool? aboveThreshold;
  String? deviceId;
  String? deviceName;
  DateTime? timestamp;
  double? hoursActive;

  EnergyConsumptionValue({
    this.day, this.value, this.aboveThreshold,
    this.deviceId, this.deviceName, this.timestamp,
    this.hoursActive
  });
}