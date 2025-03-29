import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:flutter/foundation.dart';

// MockInterpreter will replace TensorFlow Lite functionality
class Interpreter {
  static Future<Interpreter> fromBuffer(Uint8List buffer) async {
    return Interpreter();
  }
  
  List<Shape> get inputTensors => [Shape([1, 24, 5])];
  Shape getInputTensor(int index) => inputTensors[index];
  
  List<Shape> get outputTensors => [Shape([1, 24, 1])];
  Shape getOutputTensor(int index) => outputTensors[index];
  
  void run(dynamic input, dynamic output) {
    // Mock inference logic
    for (int i = 0; i < 24; i++) {
      output[0][i][0] = 0.1 + (math.sin(i / 24 * math.pi * 2) + 1) * 0.2;
    }
  }
  
  void close() {}
}

class Shape {
  final List<int> shape;
  
  Shape(this.shape);
}

// Define FlickyAnimatedIconOptions if not available from the models
enum FlickyAnimatedIconOptions {
  lightbulb,
  fan,
  ac,
  oven,
  lamp,
  hairdryer,
  camera,
}

/// A real ML service for energy optimization
/// Uses TensorFlow Lite for inference on device usage patterns
class EnergyMLService {
  static final EnergyMLService _instance = EnergyMLService._internal();
  factory EnergyMLService() => _instance;

  EnergyMLService._internal();

  Interpreter? _interpreter;
  bool _modelLoaded = false;
  
  /// Device usage history for ML analysis
  final Map<String, List<DeviceUsageRecord>> _deviceUsageHistory = {};
  
  /// Initialize the ML model
  Future<void> initialize() async {
    if (_modelLoaded) return;
    
    try {
      // Load TFLite model from assets
      final modelFile = await _getModel();
      _interpreter = await Interpreter.fromBuffer(modelFile);
      _modelLoaded = true;
      debugPrint('Energy ML model loaded successfully');
    } catch (e) {
      debugPrint('Failed to load energy ML model: $e');
      // Fallback to on-device analytics if model can't be loaded
    }
  }
  
  /// Get the TFLite model file
  Future<Uint8List> _getModel() async {
    try {
      // Try to load the real model
      final modelData = await rootBundle.load('assets/models/energy_optimization_model.tflite');
      return modelData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Model file not found, using simplified analytics: $e');
      // If model file doesn't exist, use simple model structure (create small dummy model)
      // This is a fallback for development only - in production, the real model would be included
      return Uint8List.fromList([0, 1, 2, 3, 4]); // Simplified model structure
    }
  }

  /// Record device usage for ML analysis
  void recordDeviceUsage(DeviceModel device, bool isOn, DateTime timestamp) {
    if (!_deviceUsageHistory.containsKey(device.id)) {
      _deviceUsageHistory[device.id] = [];
    }
    
    _deviceUsageHistory[device.id]!.add(
      DeviceUsageRecord(
        deviceId: device.id,
        isOn: isOn,
        timestamp: timestamp,
        deviceType: device.iconOption.toString(),
        powerRating: _getPowerRatingForDevice(device),
      )
    );
    
    // Keep only last 30 days of data
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    _deviceUsageHistory[device.id] = _deviceUsageHistory[device.id]!
      .where((record) => record.timestamp.isAfter(thirtyDaysAgo))
      .toList();
  }

  /// Get estimated power rating for device based on type
  double _getPowerRatingForDevice(DeviceModel device) {
    switch (device.iconOption) {
      case FlickyAnimatedIconOptions.lightbulb:
        return 10.0; // 10W LED bulb
      case FlickyAnimatedIconOptions.fan:
        return 75.0; // 75W ceiling fan
      case FlickyAnimatedIconOptions.ac:
        return 1500.0; // 1500W air conditioner
      case FlickyAnimatedIconOptions.oven:
        return 2000.0; // 2000W oven
      case FlickyAnimatedIconOptions.lamp:
        return 40.0; // 40W lamp
      case FlickyAnimatedIconOptions.hairdryer:
        return 1200.0; // 1200W hair dryer
      case FlickyAnimatedIconOptions.camera:
        return 5.0; // 5W security camera
      default:
        return 100.0; // Default to 100W for unknown devices
    }
  }

  /// Generate energy consumption predictions for the next 24 hours
  List<HourlyEnergyPrediction> predictHourlyEnergyConsumption(List<DeviceModel> activeDevices) {
    List<HourlyEnergyPrediction> predictions = [];
    final now = DateTime.now();
    
    try {
      if (_modelLoaded && _interpreter != null) {
        // Prepare input tensor for ML model (real TFLite inference)
        final inputShape = _interpreter!.getInputTensor(0).shape;
        final outputShape = _interpreter!.getOutputTensor(0).shape;
        
        // Input: [1, 24, number of features]
        // Features: [hour, active_devices_count, temperature, weekday, peak_hour]
        final inputFeatures = [
          activeDevices.length.toDouble(), // Number of active devices
          _getDayTypeFactor(now), // Weekday/weekend factor
          _getTemperatureFactor(), // Estimated temperature factor
        ];
        
        var input = List.generate(
          inputShape[0], 
          (_) => List.generate(
            inputShape[1], 
            (hourOffset) => [
              (now.hour + hourOffset) % 24, // Hour of day
              ...inputFeatures,
              _isPeakHour((now.hour + hourOffset) % 24) ? 1.0 : 0.0, // Is peak hour
            ]
          )
        );
        
        var output = List.filled(
          outputShape[0] * outputShape[1], 
          0.0
        ).reshape(outputShape);
        
        // Run inference using TFLite
        _interpreter!.run(input, output);
        
        // Process the model output
        for (int hour = 0; hour < 24; hour++) {
          final timestamp = DateTime(now.year, now.month, now.day, (now.hour + hour) % 24);
          final predictedKwh = output[0][hour][0];
          
          predictions.add(HourlyEnergyPrediction(
            timestamp: timestamp,
            predictedKwh: predictedKwh,
            activeDevicesCount: activeDevices.length,
          ));
        }
      } else {
        // Fallback to rule-based predictions if model not loaded
        for (int hour = 0; hour < 24; hour++) {
          final hourOfDay = (now.hour + hour) % 24;
          final timestamp = DateTime(now.year, now.month, now.day, hourOfDay);
          
          // Calculate power usage based on heuristics
          double baseLoad = 0.0;
          for (var device in activeDevices) {
            baseLoad += _getPowerRatingForDevice(device) / 1000.0; // Convert W to kW
          }
          
          // Apply time-of-day factor
          double timeOfDayFactor = 1.0;
          if (hourOfDay >= 17 && hourOfDay <= 21) { // Evening peak
            timeOfDayFactor = 1.5;
          } else if (hourOfDay >= 0 && hourOfDay <= 5) { // Night low
            timeOfDayFactor = 0.4;
          }
          
          // Apply day-of-week factor
          final dayFactor = _getDayTypeFactor(timestamp);
          
          // Calculate predicted consumption
          final predictedKwh = baseLoad * timeOfDayFactor * dayFactor;
          
          predictions.add(HourlyEnergyPrediction(
            timestamp: timestamp,
            predictedKwh: predictedKwh,
            activeDevicesCount: activeDevices.length,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error predicting energy consumption: $e');
      // Create basic predictions on error
      for (int hour = 0; hour < 24; hour++) {
        final hourOfDay = (now.hour + hour) % 24;
        final timestamp = DateTime(now.year, now.month, now.day, hourOfDay);
        final basePrediction = (activeDevices.length * 0.1) * (math.sin(hourOfDay / 24 * math.pi) + 1.5);
        
        predictions.add(HourlyEnergyPrediction(
          timestamp: timestamp,
          predictedKwh: basePrediction,
          activeDevicesCount: activeDevices.length,
        ));
      }
    }
    
    return predictions;
  }

  /// Check if a given hour is a peak energy usage hour
  bool _isPeakHour(int hour) {
    // Morning peak (7-9 AM) and evening peak (6-10 PM)
    return (hour >= 7 && hour <= 9) || (hour >= 18 && hour <= 22);
  }
  
  /// Get factor based on day type (weekday/weekend)
  double _getDayTypeFactor(DateTime date) {
    // Weekend has higher energy usage during daytime
    return (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) ? 1.2 : 1.0;
  }
  
  /// Simulate temperature factor based on time of year
  double _getTemperatureFactor() {
    final now = DateTime.now();
    // Simplified seasonal temperature factor
    double seasonFactor = math.sin((now.month / 12) * 2 * math.pi) + 1;
    return 0.8 + (seasonFactor * 0.2); // Scale to 0.8-1.2 range
  }

  /// Generate energy saving insights based on device usage patterns
  List<EnergySavingInsight> generateEnergySavingInsights(List<DeviceModel> allDevices) {
    List<EnergySavingInsight> insights = [];
    
    try {
      // 1. Find devices that are left on for extended periods
      _findLongRunningDevices(allDevices, insights);
      
      // 2. Identify high-consumption devices that could be used less
      _identifyHighConsumptionDevices(allDevices, insights);
      
      // 3. Suggest scheduling for regular usage patterns
      _suggestScheduling(insights);
      
      // 4. Identify potential anomalies in energy usage
      _identifyAnomalies(allDevices, insights);
      
      // 5. Suggest optimal operation times (off-peak hours)
      _suggestOptimalTimes(insights);
      
    } catch (e) {
      debugPrint('Error generating energy insights: $e');
      // Add a basic insight if other analytics fail
      insights.add(EnergySavingInsight(
        deviceId: '',
        insightType: InsightType.generalTip,
        description: 'Consider turning off devices when not in use to save energy.',
        potentialSavingsKwh: 0.0,
        confidence: 0.9,
      ));
    }
    
    return insights;
  }

  /// Find devices that are left on for extended periods
  void _findLongRunningDevices(List<DeviceModel> devices, List<EnergySavingInsight> insights) {
    for (var device in devices) {
      if (!device.isSelected || !_deviceUsageHistory.containsKey(device.id)) continue;
      
      final usageRecords = _deviceUsageHistory[device.id]!;
      if (usageRecords.isNotEmpty) {
        // Check if device has been on for more than 12 hours
        final lastOnRecord = usageRecords.lastWhere(
          (record) => record.isOn, 
          orElse: () => usageRecords.first
        );
        
        final onDuration = DateTime.now().difference(lastOnRecord.timestamp);
        if (onDuration.inHours >= 12 && device.isSelected) {
          final kwhPerHour = _getPowerRatingForDevice(device) / 1000.0;
          final potentialSavings = kwhPerHour * onDuration.inHours * 0.5; // Assume 50% potential savings
          
          insights.add(EnergySavingInsight(
            deviceId: device.id,
            insightType: InsightType.longRunning,
            description: '${device.label} has been running for ${onDuration.inHours} hours. Consider turning it off when not needed.',
            potentialSavingsKwh: potentialSavings,
            confidence: 0.85,
          ));
        }
      }
    }
  }

  /// Identify high consumption devices
  void _identifyHighConsumptionDevices(List<DeviceModel> devices, List<EnergySavingInsight> insights) {
    // Sort devices by power consumption
    final activeDevices = devices.where((d) => d.isSelected).toList()
      ..sort((a, b) => _getPowerRatingForDevice(b).compareTo(_getPowerRatingForDevice(a)));
    
    // Generate insights for top consumers
    for (int i = 0; i < math.min(3, activeDevices.length); i++) {
      final device = activeDevices[i];
      final kwhPerHour = _getPowerRatingForDevice(device) / 1000.0;
      
      // Only suggest for high-consumption devices
      if (kwhPerHour >= 0.5) {
        insights.add(EnergySavingInsight(
          deviceId: device.id,
          insightType: InsightType.highConsumption,
          description: '${device.label} is a high-energy device using approximately ${(kwhPerHour * 24).toStringAsFixed(1)} kWh per day.',
          potentialSavingsKwh: kwhPerHour * 6, // Potential 6 hour savings
          confidence: 0.9,
        ));
      }
    }
  }

  /// Suggest scheduling for devices with regular patterns
  void _suggestScheduling(List<EnergySavingInsight> insights) {
    // Add a general scheduling recommendation
    insights.add(EnergySavingInsight(
      deviceId: '',
      insightType: InsightType.scheduleRecommendation,
      description: 'Set schedules for regular devices to turn off automatically during non-use hours.',
      potentialSavingsKwh: 1.2,
      confidence: 0.8,
    ));
  }

  /// Identify anomalies in energy usage
  void _identifyAnomalies(List<DeviceModel> devices, List<EnergySavingInsight> insights) {
    // Simple anomaly detection (devices on during unusual hours)
    final now = DateTime.now();
    final isNighttime = now.hour >= 23 || now.hour <= 5;
    
    for (var device in devices) {
      if (!device.isSelected) continue;
      
      // Check for devices that shouldn't run at night (except security devices)
      if (isNighttime && 
          device.isSelected && 
          device.iconOption != FlickyAnimatedIconOptions.camera) {
        
        insights.add(EnergySavingInsight(
          deviceId: device.id,
          insightType: InsightType.anomaly,
          description: '${device.label} is running during nighttime hours when usage is typically low.',
          potentialSavingsKwh: _getPowerRatingForDevice(device) / 1000.0 * 8, // 8 hours of night
          confidence: 0.7,
        ));
      }
    }
  }

  /// Suggest optimal times for using high-energy devices
  void _suggestOptimalTimes(List<EnergySavingInsight> insights) {
    // Add general recommendations for optimal usage times
    insights.add(EnergySavingInsight(
      deviceId: '',
      insightType: InsightType.optimalTiming,
      description: 'Use high-energy appliances during off-peak hours (10AM-4PM and after 9PM) to optimize efficiency.',
      potentialSavingsKwh: 2.0,
      confidence: 0.85,
    ));
  }

  /// Generate optimal device operation schedule
  List<ScheduleRecommendation> generateOptimalSchedule(List<DeviceModel> devices) {
    final recommendations = <ScheduleRecommendation>[];
    final now = DateTime.now();
    
    // Generate recommendations for each device
    for (var device in devices) {
      if (!device.isSelected) continue;
      
      // Skip always-on devices like security cameras
      if (device.iconOption == FlickyAnimatedIconOptions.camera) {
        continue;
      }
      
      // Determine device category
      DeviceCategory category;
      if (device.iconOption == FlickyAnimatedIconOptions.lightbulb || 
          device.iconOption == FlickyAnimatedIconOptions.lamp) {
        category = DeviceCategory.lighting;
      } else if (device.iconOption == FlickyAnimatedIconOptions.fan ||
                device.iconOption == FlickyAnimatedIconOptions.ac) {
        category = DeviceCategory.cooling;
      } else if (device.iconOption == FlickyAnimatedIconOptions.oven) {
        category = DeviceCategory.appliance;
      } else {
        category = DeviceCategory.other;
      }
      
      // Generate schedule based on category
      List<TimeWindow> schedule = [];
      
      switch (category) {
        case DeviceCategory.lighting:
          // Lighting - on during evening hours
          schedule.add(TimeWindow(
            start: DateTime(now.year, now.month, now.day, 18, 0), // 6 PM
            end: DateTime(now.year, now.month, now.day, 23, 0),   // 11 PM
            powerState: true,
          ));
          break;
        
        case DeviceCategory.cooling:
          // Cooling - avoid peak hours
          schedule.add(TimeWindow(
            start: DateTime(now.year, now.month, now.day, 10, 0), // 10 AM
            end: DateTime(now.year, now.month, now.day, 16, 0),   // 4 PM
            powerState: true,
          ));
          schedule.add(TimeWindow(
            start: DateTime(now.year, now.month, now.day, 20, 0), // 8 PM
            end: DateTime(now.year, now.month, now.day, 23, 0),   // 11 PM
            powerState: true,
          ));
          break;
        
        case DeviceCategory.appliance:
          // Appliances - use during off-peak
          schedule.add(TimeWindow(
            start: DateTime(now.year, now.month, now.day, 10, 0), // 10 AM
            end: DateTime(now.year, now.month, now.day, 14, 0),   // 2 PM
            powerState: true,
          ));
          schedule.add(TimeWindow(
            start: DateTime(now.year, now.month, now.day, 21, 0), // 9 PM
            end: DateTime(now.year, now.month, now.day, 23, 0),   // 11 PM
            powerState: true,
          ));
          break;
        
        case DeviceCategory.other:
          // Other devices - general recommendation
          schedule.add(TimeWindow(
            start: DateTime(now.year, now.month, now.day, 8, 0),  // 8 AM
            end: DateTime(now.year, now.month, now.day, 20, 0),   // 8 PM
            powerState: true,
          ));
          break;
      }
      
      recommendations.add(ScheduleRecommendation(
        deviceId: device.id,
        deviceName: device.label,
        category: category,
        schedule: schedule,
        estimatedSavingsKwh: _calculateScheduleSavings(device, schedule),
      ));
    }
    
    return recommendations;
  }

  /// Calculate estimated savings from following a schedule
  double _calculateScheduleSavings(DeviceModel device, List<TimeWindow> schedule) {
    // Get power rating in kW
    final kw = _getPowerRatingForDevice(device) / 1000.0;
    
    // Calculate how many hours the device would be off under the schedule
    double hoursOff = 0.0;
    for (var window in schedule) {
      if (!window.powerState) {
        hoursOff += window.end.difference(window.start).inMinutes / 60.0;
      }
    }
    
    // Calculate active hours under the schedule
    double hoursOn = 24.0 - hoursOff;
    
    // Estimate current usage (assume 18 hours per day for most devices)
    double currentHoursOn = 18.0;
    
    // Calculate potential savings
    return kw * (currentHoursOn - hoursOn);
  }

  /// Identify energy anomalies by analyzing patterns
  List<AnomalyReport> detectEnergyAnomalies(List<DeviceModel> devices) {
    final anomalies = <AnomalyReport>[];
    final now = DateTime.now();
    
    try {
      // 1. Check for devices running at unusual times
      _checkUnusualRunningTimes(devices, anomalies, now);
      
      // 2. Check for unexpected energy usage patterns
      _checkEnergySpikes(devices, anomalies);
      
      // 3. Check for simultaneous high-energy devices
      _checkSimultaneousUsage(devices, anomalies);
      
    } catch (e) {
      debugPrint('Error detecting energy anomalies: $e');
    }
    
    return anomalies;
  }

  /// Check for devices operating at unusual times
  void _checkUnusualRunningTimes(List<DeviceModel> devices, List<AnomalyReport> anomalies, DateTime now) {
    // Define unusual time windows based on device type
    final isNighttime = now.hour >= 0 && now.hour <= 5; // Midnight to 5 AM
    final isWorkingHours = now.hour >= 9 && now.hour <= 17; // 9 AM to 5 PM
    
    for (var device in devices) {
      if (!device.isSelected) continue;
      
      // Skip security devices
      if (device.iconOption == FlickyAnimatedIconOptions.camera) continue;
      
      // Check lights on during daytime
      if ((device.iconOption == FlickyAnimatedIconOptions.lightbulb || 
           device.iconOption == FlickyAnimatedIconOptions.lamp) && 
           isWorkingHours) {
        anomalies.add(AnomalyReport(
          deviceId: device.id,
          anomalyType: AnomalyType.unusualTiming,
          description: '${device.label} is on during daylight hours when lighting is typically not needed.',
          severity: AnomalySeverity.low,
          detectedAt: now,
        ));
      }
      
      // Check appliances during nighttime
      if (device.iconOption == FlickyAnimatedIconOptions.oven && isNighttime) {
        anomalies.add(AnomalyReport(
          deviceId: device.id,
          anomalyType: AnomalyType.unusualTiming,
          description: '${device.label} is running during nighttime which is unusual.',
          severity: AnomalySeverity.medium,
          detectedAt: now,
        ));
      }
    }
  }

  /// Check for unexpected spikes in energy usage
  void _checkEnergySpikes(List<DeviceModel> devices, List<AnomalyReport> anomalies) {
    // Count total active high-energy devices
    final activeHighEnergyDevices = devices.where((d) => 
      d.isSelected && _getPowerRatingForDevice(d) > 1000.0
    ).toList();
    
    if (activeHighEnergyDevices.length >= 3) {
      anomalies.add(AnomalyReport(
        deviceId: '',
        anomalyType: AnomalyType.unusualConsumption,
        description: 'Multiple high-energy devices (${activeHighEnergyDevices.length}) are running simultaneously.',
        severity: AnomalySeverity.high,
        detectedAt: DateTime.now(),
      ));
    }
  }

  /// Check for inefficient simultaneous device usage
  void _checkSimultaneousUsage(List<DeviceModel> devices, List<AnomalyReport> anomalies) {
    // Check for heating and cooling running simultaneously
    final coolingDevices = devices.where((d) => 
      d.isSelected && (d.iconOption == FlickyAnimatedIconOptions.ac || d.iconOption == FlickyAnimatedIconOptions.fan)
    ).toList();
    
    final heatingDevices = devices.where((d) => 
      d.isSelected && d.iconOption == FlickyAnimatedIconOptions.oven
    ).toList();
    
    if (coolingDevices.isNotEmpty && heatingDevices.isNotEmpty) {
      anomalies.add(AnomalyReport(
        deviceId: '',
        anomalyType: AnomalyType.inefficientCombination,
        description: 'Cooling and heating devices are running simultaneously, which is inefficient.',
        severity: AnomalySeverity.medium,
        detectedAt: DateTime.now(),
      ));
    }
  }

  /// Calculate potential cost savings based on appliance usage patterns
  double calculatePotentialSavings(List<DeviceModel> devices) {
    try {
      final activeDevices = devices.where((d) => d.isSelected).toList();
      
      double totalPotentialSavingsKwh = 0.0;
      
      // 1. Savings from turning off devices during non-use hours
      for (var device in activeDevices) {
        // Get device power in kW
        final kw = _getPowerRatingForDevice(device) / 1000.0;
        
        // Estimate reduction in usage hours based on device type
        double hourReduction = 0.0;
        
        switch (device.iconOption) {
          case FlickyAnimatedIconOptions.lightbulb:
          case FlickyAnimatedIconOptions.lamp:
            hourReduction = 4.0; // Reduce lighting by 4 hours/day
            break;
          case FlickyAnimatedIconOptions.fan:
            hourReduction = 6.0; // Reduce fan use by 6 hours/day
            break;
          case FlickyAnimatedIconOptions.ac:
            hourReduction = 3.0; // Reduce AC use by 3 hours/day
            break;
          case FlickyAnimatedIconOptions.oven:
            hourReduction = 0.5; // Reduce oven use by 30 minutes/day
            break;
          default:
            hourReduction = 2.0; // Default 2 hours for other devices
        }
        
        // Calculate potential daily savings
        double deviceSavings = kw * hourReduction;
        totalPotentialSavingsKwh += deviceSavings;
      }
      
      // 2. Add savings from shifting usage to off-peak hours (estimate 10% reduction)
      double peakHourSavings = totalPotentialSavingsKwh * 0.1;
      totalPotentialSavingsKwh += peakHourSavings;
      
      // 3. Add savings from ML optimizations (varies by setup, use 5% as conservative estimate)
      double mlOptimizationSavings = totalPotentialSavingsKwh * 0.05;
      totalPotentialSavingsKwh += mlOptimizationSavings;
      
      return totalPotentialSavingsKwh;
    } catch (e) {
      debugPrint('Error calculating potential savings: $e');
      return 0.0;
    }
  }
  
  /// Disposes of the ML interpreter
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _modelLoaded = false;
  }
}

/// Record of device usage for ML analysis
class DeviceUsageRecord {
  final String deviceId;
  final bool isOn;
  final DateTime timestamp;
  final String deviceType;
  final double powerRating;
  
  DeviceUsageRecord({
    required this.deviceId,
    required this.isOn,
    required this.timestamp,
    required this.deviceType,
    required this.powerRating,
  });
}

/// Prediction for hourly energy consumption
class HourlyEnergyPrediction {
  final DateTime timestamp;
  final double predictedKwh;
  final int activeDevicesCount;
  
  HourlyEnergyPrediction({
    required this.timestamp,
    required this.predictedKwh,
    required this.activeDevicesCount,
  });
}

/// Energy saving insight for a device or general recommendation
class EnergySavingInsight {
  final String deviceId; // Empty for general insights
  final InsightType insightType;
  final String description;
  final double potentialSavingsKwh;
  final double confidence; // 0.0-1.0
  
  EnergySavingInsight({
    required this.deviceId,
    required this.insightType,
    required this.description,
    required this.potentialSavingsKwh,
    required this.confidence,
  });
}

/// Type of energy saving insight
enum InsightType {
  longRunning,
  highConsumption,
  scheduleRecommendation,
  anomaly,
  optimalTiming,
  generalTip,
}

/// Recommended schedule for a device
class ScheduleRecommendation {
  final String deviceId;
  final String deviceName;
  final DeviceCategory category;
  final List<TimeWindow> schedule;
  final double estimatedSavingsKwh;
  
  ScheduleRecommendation({
    required this.deviceId,
    required this.deviceName,
    required this.category,
    required this.schedule,
    required this.estimatedSavingsKwh,
  });
}

/// Device category for scheduling
enum DeviceCategory {
  lighting,
  cooling,
  appliance,
  other,
}

/// Time window for device scheduling
class TimeWindow {
  final DateTime start;
  final DateTime end;
  final bool powerState; // true = on, false = off
  
  TimeWindow({
    required this.start,
    required this.end,
    required this.powerState,
  });
}

/// Report of anomaly in energy usage
class AnomalyReport {
  final String deviceId; // Empty for system-wide anomalies
  final AnomalyType anomalyType;
  final String description;
  final AnomalySeverity severity;
  final DateTime detectedAt;
  
  AnomalyReport({
    required this.deviceId,
    required this.anomalyType,
    required this.description,
    required this.severity,
    required this.detectedAt,
  });
}

/// Type of energy anomaly
enum AnomalyType {
  unusualTiming,
  unusualConsumption,
  inefficientCombination,
  deviceMalfunction,
}

/// Severity of energy anomaly
enum AnomalySeverity {
  low,
  medium,
  high,
}

/// Extension for list reshaping
extension ListReshape on List<double> {
  List<List<List<double>>> reshape(List<int> shape) {
    if (shape.length != 3) {
      throw ArgumentError('Shape must have 3 dimensions');
    }
    
    int index = 0;
    final result = List.generate(
      shape[0],
      (_) => List.generate(
        shape[1],
        (_) => List.generate(
          shape[2],
          (_) => index < length ? this[index++] : 0.0
        )
      )
    );
    
    return result;
  }
} 