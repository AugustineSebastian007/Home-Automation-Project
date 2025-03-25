import 'package:home_automation/features/landing/data/models/energy_consumption_value.dart';

class EnergyConsumption {

  List<EnergyConsumptionValue>? values = [];
  double totalConsumption = 0.0;
  double peakConsumption = 0.0;
  double averageConsumption = 0.0;
  bool energySavingMode = false;
  int activeDevicesCount = 0;
  int totalDevicesCount = 0;
  Map<String, double> dailyConsumption = {};
  List<String> longRunningDevices = [];

  EnergyConsumption({
    this.values,
    this.totalConsumption = 0.0,
    this.peakConsumption = 0.0,
    this.averageConsumption = 0.0,
    this.energySavingMode = false,
    this.activeDevicesCount = 0,
    this.totalDevicesCount = 0,
    this.dailyConsumption = const {},
    this.longRunningDevices = const [],
  });
}