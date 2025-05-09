import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation/features/energy/services/energy_ml_service.dart';

/// Provider for the Energy ML Service
final energyMLServiceProvider = Provider<EnergyMLService>((ref) {
  final mlService = EnergyMLService();
  // Initialize the ML service
  mlService.initialize();
  return mlService;
});

/// Provider that combines all device providers into one list
final allDevicesProvider = FutureProvider<List<DeviceModel>>((ref) async {
  // For simplicity, we'll just use mainRoomDevicesProvider
  final mainRoomDevices = await ref.watch(mainRoomDevicesProvider.future);
  
  // Return the devices directly
  return mainRoomDevices;
});

/// Provider for device usage recording
final deviceUsageRecorderProvider = Provider<void>((ref) {
  final mlService = ref.watch(energyMLServiceProvider);
  final devicesAsync = ref.watch(allDevicesProvider);
  
  // Record device usage when device states change
  devicesAsync.whenData((devices) {
    if (devices.isNotEmpty) {
      for (var device in devices) {
        mlService.recordDeviceUsage(device, device.isSelected, DateTime.now());
      }
    }
  });
  
  return;
});

/// Provider for energy consumption predictions
final energyPredictionsProvider = FutureProvider.autoDispose<List<HourlyEnergyPrediction>>((ref) async {
  final mlService = ref.watch(energyMLServiceProvider);
  final devices = await ref.watch(allDevicesProvider.future);
  
  // Get active devices
  final activeDevices = devices.where((d) => d.isSelected).toList();
  
  // Generate predictions
  return mlService.predictHourlyEnergyConsumption(activeDevices);
});

/// Provider for energy saving insights
final energySavingInsightsProvider = FutureProvider.autoDispose<List<EnergySavingInsight>>((ref) async {
  final mlService = ref.watch(energyMLServiceProvider);
  final devices = await ref.watch(allDevicesProvider.future);
  
  // Generate insights
  return mlService.generateEnergySavingInsights(devices);
});

/// Provider for optimal device schedule
final optimalScheduleProvider = FutureProvider.autoDispose<List<ScheduleRecommendation>>((ref) async {
  final mlService = ref.watch(energyMLServiceProvider);
  final devices = await ref.watch(allDevicesProvider.future);
  
  // Generate optimal schedule
  return mlService.generateOptimalSchedule(devices);
});

/// Provider for energy anomaly detection
final energyAnomaliesProvider = FutureProvider.autoDispose<List<AnomalyReport>>((ref) async {
  final mlService = ref.watch(energyMLServiceProvider);
  final devices = await ref.watch(allDevicesProvider.future);
  
  // Detect anomalies
  return mlService.detectEnergyAnomalies(devices);
});

/// Provider for potential cost savings calculation
final energyCostSimulationProvider = FutureProvider.autoDispose<double>((ref) async {
  final mlService = ref.watch(energyMLServiceProvider);
  final devices = await ref.watch(allDevicesProvider.future);
  
  // Calculate potential savings
  return mlService.calculatePotentialSavings(devices);
}); 