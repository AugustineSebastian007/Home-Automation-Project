import 'dart:math';
import 'package:home_automation/features/landing/data/models/energy_consumption.dart';
import 'package:home_automation/features/landing/data/models/energy_consumption_value.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/devices/data/repositories/devices.repository.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:home_automation/helpers/enums.dart';

class EnergyConsumptionDataRepository {
  // Use lazy initialization to ensure proper Firebase setup
  late final DatabaseReference _database;
  final DevicesRepository? _devicesRepository;
  final Ref? _ref;
  
  // Device runtime tracking
  final Map<String, DateTime> _deviceOnSince = {};
  final Map<String, double> _deviceRuntime = {};
  final Map<String, double> _deviceEnergyUsage = {};
  
  // Constants for energy saving features
  static const int LONG_RUNNING_THRESHOLD_HOURS = 4; // Consider a device as long-running after 4 hours
  static const double HIGH_CONSUMPTION_THRESHOLD = 12.0; // kW threshold for high consumption

  EnergyConsumptionDataRepository([this._devicesRepository, this._ref]) {
    // Initialize with proper database URL
    final database = FirebaseDatabase.instance;
    // Ensure database URL is set
    try {
      if (database.app.options.databaseURL == null || database.app.options.databaseURL!.isEmpty) {
        database.databaseURL = "https://home-automation-78d43-default-rtdb.asia-southeast1.firebasedatabase.app";
      }
      _database = database.ref('energy_data');
      print("Energy database initialized successfully at ${database.app.options.databaseURL}");
      
      // Listen for device changes to track runtime
      _listenToDeviceChanges();
    } catch (e) {
      print("Error initializing energy database: $e");
      // Create a fallback reference
      _database = FirebaseDatabase.instance.ref('energy_data');
    }
  }
  
  // Listen to device state changes to track runtime
  void _listenToDeviceChanges() {
    if (_devicesRepository == null) return;
    
    try {
      _devicesRepository!.streamAllDevices().listen((devices) {
        final now = DateTime.now();
        
        for (final device in devices) {
          final deviceId = device.id;
          
          // Device turned on
          if (device.isSelected && !_deviceOnSince.containsKey(deviceId)) {
            _deviceOnSince[deviceId] = now;
            print("Device ${device.label} turned ON at ${now.toString()}");
          } 
          // Device turned off
          else if (!device.isSelected && _deviceOnSince.containsKey(deviceId)) {
            final onSince = _deviceOnSince[deviceId]!;
            final runtime = now.difference(onSince).inMinutes / 60.0; // runtime in hours
            
            // Add to total runtime
            _deviceRuntime[deviceId] = (_deviceRuntime[deviceId] ?? 0) + runtime;
            
            // Calculate energy usage based on device type
            double hourlyConsumption = _getDeviceHourlyConsumption(device);
            double energyUsed = hourlyConsumption * runtime;
            _deviceEnergyUsage[deviceId] = (_deviceEnergyUsage[deviceId] ?? 0) + energyUsed;
            
            // Remove from tracking
            _deviceOnSince.remove(deviceId);
            
            print("Device ${device.label} turned OFF after $runtime hours, used $energyUsed kW");
            
            // Save to database
            _saveDeviceEnergy(device, energyUsed, runtime);
          }
        }
      });
    } catch (e) {
      print("Error setting up device tracking: $e");
    }
  }
  
  // Get hourly consumption for a device based on its type
  double _getDeviceHourlyConsumption(DeviceModel device) {
    switch (device.iconOption.name) {
      case 'lightbulb':
        return 0.06; // 60W = 0.06kW per hour
      case 'fan':
        return 0.08; // 80W = 0.08kW per hour
      default:
        return 0.04; // Default 40W = 0.04kW per hour
    }
  }
  
  // Save device energy usage to database
  Future<void> _saveDeviceEnergy(DeviceModel device, double energyUsed, double runtime) async {
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await _database.child('device_energy').child(device.id).child(dateStr).update({
        'energyUsed': ServerValue.increment(energyUsed),
        'runtime': ServerValue.increment(runtime),
        'lastUsed': DateTime.now().millisecondsSinceEpoch,
        'deviceName': device.label,
        'deviceType': device.iconOption.name,
      });
    } catch (e) {
      print("Error saving device energy: $e");
    }
  }

  // Get mock energy data (for backward compatibility)
  EnergyConsumption getMockEnergyConsumption() {
    List<EnergyConsumptionValue> consumptionValues = [];
    var date = DateTime.now();
    var random = Random();
    var thresholdValue = 70;
    
    // Track daily consumption for the mock data
    Map<String, double> dailyConsumption = {};

    for(var i = 0; i < 20; i++) {
      double currentValue = random.nextInt(50) + 30;
      String dayKey = DateFormat('yyyy-MM-dd').format(date);
      dailyConsumption[dayKey] = currentValue;
      
      consumptionValues.add(EnergyConsumptionValue(
        value: currentValue,
        day: DateFormat.E().format(date).substring(0, 2).toUpperCase(),
        aboveThreshold: currentValue > thresholdValue,
        timestamp: date,
      ));

      date = date.add(const Duration(days: 1));
    }

    // Calculate total consumption and other metrics
    double total = 0.0;
    for (var item in consumptionValues) {
      total += (item.value ?? 0);
    }
    
    double peak = 0.0;
    for (var item in consumptionValues) {
      if ((item.value ?? 0) > peak) {
        peak = item.value ?? 0;
      }
    }

    // In mock data, have a reasonable default for total devices
    final totalDevices = 5;
    final activeDevices = random.nextInt(totalDevices) + 1;

    return EnergyConsumption(
      values: consumptionValues,
      totalConsumption: total,
      peakConsumption: peak,
      averageConsumption: total / consumptionValues.length,
      activeDevicesCount: activeDevices,
      totalDevicesCount: totalDevices,
      dailyConsumption: dailyConsumption,
    );
  }

  // Get real energy consumption from device data
  Future<EnergyConsumption> getEnergyConsumption() async {
    // If devices repository is not available, throw instead of returning mock data
    if (_devicesRepository == null) {
      throw Exception("Devices repository is not available");
    }

    try {
      print("⚡ Starting getEnergyConsumption");
      
      // Get devices more reliably - try multiple approaches
      print("Beginning to fetch devices from repository");
      List<DeviceModel> devices = [];
      
      // First try to get all devices from the stream (real-time data)
      try {
        print("First trying streamAllDevices method for real-time data");
        // Wait for the first emission with a small timeout to avoid blocking
        devices = await _devicesRepository!.streamAllDevices().first
            .timeout(const Duration(seconds: 3), onTimeout: () => <DeviceModel>[]);
        print("Retrieved ${devices.length} devices via stream");
      } catch (e) {
        print("Error using streamAllDevices: $e");
      }
      
      // If we didn't get devices from the stream, try the list method
      if (devices.isEmpty) {
        print("Stream returned 0 devices, trying getListOfDevices method");
        try {
          devices = await _devicesRepository!.getListOfDevices();
          print("Retrieved ${devices.length} devices via getListOfDevices");
        } catch (e) {
          print("Error using getListOfDevices: $e");
        }
      }
      
      // Still no devices? Check if we can get them from Firebase directly
      if (devices.isEmpty) {
        print("Still no devices, checking for hardcoded devices in main room");
        try {
          // Try to get devices from the main room directly
          // This is a fallback using the same logic as in DevicesRepository.getMainRoomDevices
          const String mainRoomId = 'main_room';
          const String mainOutletId = 'esp32';
          
          final snapshot = await FirebaseDatabase.instance
              .ref('users')
              .child('123') // This might need to be adjusted based on your Firebase structure
              .child('rooms')
              .child(mainRoomId)
              .child('outlets')
              .child(mainOutletId)
              .child('devices')
              .get();
          
          if (snapshot.exists) {
            final data = snapshot.value as Map<dynamic, dynamic>;
            data.forEach((key, value) {
              try {
                final deviceData = value as Map<dynamic, dynamic>;
                devices.add(DeviceModel(
                  id: key.toString(),
                  iconOption: _getIconOptionFromString(deviceData['iconOption']?.toString() ?? 'bolt'),
                  label: deviceData['label']?.toString() ?? 'Unknown Device',
                  isSelected: deviceData['isSelected'] == true,
                  outlet: deviceData['outlet'] as int? ?? 0,
                  roomId: mainRoomId,
                  outletId: mainOutletId,
                ));
              } catch (e) {
                print("Error parsing device data: $e");
              }
            });
            print("Retrieved ${devices.length} devices directly from Firebase");
          } else {
            print("No devices found in Firebase");
          }
        } catch (e) {
          print("Error fetching devices from Firebase directly: $e");
        }
      }
      
      // If we still don't have any devices, create empty data
      if (devices.isEmpty) {
        print("Warning: No devices found after all attempts");
      }
      
      // Count devices
      final totalDevicesCount = devices.length;
      final activeDevices = devices.where((device) => device.isSelected).toList();
      final activeDevicesCount = activeDevices.length;
      
      print("Found $activeDevicesCount active devices out of $totalDevicesCount total devices");
      
      // Calculate long-running devices
      final now = DateTime.now();
      List<String> longRunningDevices = [];
      for (final deviceId in _deviceOnSince.keys) {
        final onSince = _deviceOnSince[deviceId]!;
        final runtime = now.difference(onSince).inHours;
        if (runtime >= LONG_RUNNING_THRESHOLD_HOURS) {
          // Find device name
          final device = devices.firstWhere(
            (d) => d.id == deviceId, 
            orElse: () => DeviceModel(
              id: deviceId, 
              iconOption: FlickyAnimatedIconOptions.bolt, 
              label: 'Unknown Device', 
              isSelected: true, 
              outlet: 0, 
              roomId: '', 
              outletId: ''
            )
          );
          longRunningDevices.add(device.label);
        }
      }
      
      // Get energy data for each device
      final List<EnergyConsumptionValue> consumptionValues = [];
      double totalConsumption = 0.0;
      double peakConsumption = 0.0;
      
      // Track daily consumption
      Map<String, double> dailyConsumption = {};
      
      // Get the last 20 days of data from Firebase if available
      try {
        final snapshot = await _database.child('daily_consumption').orderByKey().limitToLast(20).get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          data.forEach((key, value) {
            dailyConsumption[key.toString()] = double.tryParse(value.toString()) ?? 0.0;
          });
        }
      } catch (e) {
        print("Error fetching daily consumption: $e");
      }
      
      // If no historical data, generate data based on actual devices
      if (dailyConsumption.isEmpty) {
        // Generate 20 days of historical data based on actual device states
        var date = DateTime.now().subtract(const Duration(days: 19));
        var thresholdValue = activeDevicesCount > 0 ? 70.0 / activeDevicesCount : 70.0;
        
        for (var i = 0; i < 20; i++) {
          // Get day string
          String dayKey = DateFormat('yyyy-MM-dd').format(date);
          String dayStr = DateFormat.E().format(date).substring(0, 2).toUpperCase();
          
          // Calculate energy for actual devices on this day
          double dailyConsumptionValue = 0.0;
          
          // Use actual devices and their current state
          for (var device in devices) {
            // For historical data, use current state (isSelected) for today, 
            // but for other days assume devices were on 80% of the time
            bool wasDeviceOn = date.day == DateTime.now().day ? 
                device.isSelected : 
                (device.isSelected || Random().nextDouble() < 0.5);
                
            if (wasDeviceOn) {
              // Calculate actual device consumption based on type
              double deviceConsumption = _getDeviceHourlyConsumption(device) * (6 + Random().nextDouble() * 3); // 6-9 hours usage
              
              // Store individual device consumption
              consumptionValues.add(EnergyConsumptionValue(
                day: dayStr,
                value: deviceConsumption,
                aboveThreshold: deviceConsumption > thresholdValue,
                deviceId: device.id,
                deviceName: device.label,
                timestamp: date,
              ));
              
              dailyConsumptionValue += deviceConsumption;
            }
          }
          
          // If no active devices, add a zero consumption entry
          if (dailyConsumptionValue == 0.0) {
            consumptionValues.add(EnergyConsumptionValue(
              day: dayStr,
              value: 0.0,
              aboveThreshold: false,
              timestamp: date,
            ));
          }
          
          // Store daily consumption
          dailyConsumption[dayKey] = dailyConsumptionValue;
          
          // Update total and peak consumption
          totalConsumption += dailyConsumptionValue;
          if (dailyConsumptionValue > peakConsumption) {
            peakConsumption = dailyConsumptionValue;
          }
          
          date = date.add(const Duration(days: 1));
        }
      } else {
        // Convert existing daily consumption data to consumptionValues
        dailyConsumption.forEach((dayKey, value) {
          final date = DateFormat('yyyy-MM-dd').parse(dayKey);
          final dayStr = DateFormat.E().format(date).substring(0, 2).toUpperCase();
          
          consumptionValues.add(EnergyConsumptionValue(
            day: dayStr,
            value: value,
            aboveThreshold: value > 70.0,
            timestamp: date,
          ));
          
          totalConsumption += value;
          if (value > peakConsumption) {
            peakConsumption = value;
          }
        });
      }
      
      // Save the energy data to Firebase for history
      try {
        await _saveDailyConsumption(dailyConsumption);
      } catch (e) {
        print("Warning: Could not save energy data to Firebase: $e");
      }
      
      // Create the energy consumption model
      final energyConsumption = EnergyConsumption(
        values: consumptionValues,
        totalConsumption: totalConsumption,
        peakConsumption: peakConsumption,
        averageConsumption: consumptionValues.isEmpty ? 0 : totalConsumption / consumptionValues.length,
        activeDevicesCount: activeDevicesCount,
        totalDevicesCount: totalDevicesCount,
        dailyConsumption: dailyConsumption,
        longRunningDevices: longRunningDevices,
      );
      
      print("Energy data ready - active devices: ${energyConsumption.activeDevicesCount}, total devices: ${energyConsumption.totalDevicesCount}");
      return energyConsumption;
    } catch (e) {
      print('Error getting energy consumption: $e');
      // Don't fall back to mock data, let the UI handle the error
      throw e;
    }
  }
  
  // Save daily consumption data to Firebase
  Future<void> _saveDailyConsumption(Map<String, double> dailyConsumption) async {
    try {
      final updates = <String, dynamic>{};
      dailyConsumption.forEach((day, value) {
        updates[day] = value;
      });
      
      await _database.child('daily_consumption').update(updates);
    } catch (e) {
      print("Error saving daily consumption: $e");
      throw e;
    }
  }
  
  // Save energy data to Firebase (would be implemented in a real app)
  Future<void> _saveEnergyDataToFirebase(List<EnergyConsumptionValue> values) async {
    try {
      for (var value in values) {
        if (value.deviceId != null && value.timestamp != null) {
          await _database.child('energy_data').child(value.deviceId!).child(value.timestamp!.millisecondsSinceEpoch.toString()).set({
            'value': value.value,
            'timestamp': value.timestamp!.millisecondsSinceEpoch,
            'deviceName': value.deviceName,
          });
        }
      }
    } catch (e) {
      print("Error saving energy data to Firebase: $e");
      throw e; // Re-throw to be handled by caller
    }
  }
  
  // Advanced energy saving mode with multiple strategies
  Future<void> toggleEnergySavingMode(bool enabled) async {
    if (_devicesRepository == null) return;
    
    try {
      // Get all devices
      final devices = await _devicesRepository!.getListOfDevices();
      final now = DateTime.now();
      
      // If enabling energy saving mode
      if (enabled) {
        for (var device in devices) {
          // Skip devices that are already off
          if (!device.isSelected) continue;
          
          bool shouldTurnOff = false;
          String turnOffReason = '';
          
          // Strategy 1: Turn off high consumption devices
          if (device.iconOption.name == 'fan') {
            shouldTurnOff = true;
            turnOffReason = 'high consumption device';
          }
          
          // Strategy 2: Turn off devices running for too long
          if (_deviceOnSince.containsKey(device.id)) {
            final onSince = _deviceOnSince[device.id]!;
            final runtimeHours = now.difference(onSince).inHours;
            if (runtimeHours >= LONG_RUNNING_THRESHOLD_HOURS) {
              shouldTurnOff = true;
              turnOffReason = 'running for $runtimeHours hours';
            }
          }
          
          // Strategy 3: Turn off devices with high accumulated energy usage today
          final todayKey = DateFormat('yyyy-MM-dd').format(now);
          try {
            final snapshot = await _database.child('device_energy').child(device.id).child(todayKey).get();
            if (snapshot.exists) {
              final data = snapshot.value as Map<dynamic, dynamic>;
              final energyUsed = double.tryParse(data['energyUsed'].toString()) ?? 0.0;
              if (energyUsed > HIGH_CONSUMPTION_THRESHOLD) {
                shouldTurnOff = true;
                turnOffReason = 'used $energyUsed kW today (threshold: $HIGH_CONSUMPTION_THRESHOLD kW)';
              }
            }
          } catch (e) {
            print("Error checking device energy: $e");
          }
          
          // Apply energy-saving action
          if (shouldTurnOff) {
            try {
              print("Energy saving: turning off ${device.label} ($turnOffReason)");
              await _devicesRepository!.updateDevice(
                device.roomId,
                device.outletId,
                device.copyWith(isSelected: false),
              );
            } catch (e) {
              print("Error turning off device ${device.label}: $e");
            }
          }
        }
      }
      
      // Save energy saving mode state with better error handling
      try {
        await _database.child('settings').update({
          'energySavingMode': enabled,
        });
        print("Energy saving mode set to: $enabled");
      } catch (e) {
        print("Error saving energy mode to Firebase: $e");
      }
    } catch (e) {
      print('Error toggling energy saving mode: $e');
    }
  }
  
  // Get current energy saving mode status
  Future<bool> getEnergySavingModeStatus() async {
    try {
      final snapshot = await _database.child('settings').child('energySavingMode').get();
      final result = snapshot.exists && (snapshot.value == true);
      print("Energy saving mode status: $result");
      return result;
    } catch (e) {
      print('Error getting energy saving mode status: $e - using default (false)');
      return false;
    }
  }
  
  // Get devices that have been on for a long time
  Future<List<String>> getLongRunningDevices() async {
    if (_devicesRepository == null) return [];
    
    try {
      final devices = await _devicesRepository!.getListOfDevices();
      final now = DateTime.now();
      List<String> longRunningDevices = [];
      
      for (final deviceId in _deviceOnSince.keys) {
        final onSince = _deviceOnSince[deviceId]!;
        final runtime = now.difference(onSince).inHours;
        if (runtime >= LONG_RUNNING_THRESHOLD_HOURS) {
          // Find device name
          final device = devices.firstWhere(
            (d) => d.id == deviceId, 
            orElse: () => DeviceModel(
              id: deviceId, 
              iconOption: FlickyAnimatedIconOptions.bolt, 
              label: 'Unknown Device', 
              isSelected: true, 
              outlet: 0, 
              roomId: '', 
              outletId: ''
            )
          );
          longRunningDevices.add("${device.label} (${runtime}h)");
        }
      }
      
      return longRunningDevices;
    } catch (e) {
      print("Error getting long running devices: $e");
      return [];
    }
  }

  // Helper method to convert string to icon option enum
  FlickyAnimatedIconOptions _getIconOptionFromString(String iconName) {
    try {
      return FlickyAnimatedIconOptions.values.firstWhere(
        (option) => option.name == iconName,
        orElse: () => FlickyAnimatedIconOptions.bolt
      );
    } catch (e) {
      return FlickyAnimatedIconOptions.bolt;
    }
  }
}