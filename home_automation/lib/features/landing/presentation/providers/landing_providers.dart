import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async'; // Add this for TimeoutException
import 'package:home_automation/features/landing/data/models/home_tile_option.dart';
import 'package:home_automation/features/landing/data/repositories/energy_consumption_data.repository.dart';
import 'package:home_automation/features/landing/data/repositories/home_tile_options.repository.dart';
import 'package:home_automation/features/landing/presentation/viewmodels/home_tile_options.viewmodel.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation/features/landing/data/models/energy_consumption.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/landing/data/models/energy_consumption_value.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:firebase_core/firebase_core.dart';

final homeTileOptionsRepositoryProvider = Provider((ref) {
  return HomeTileOptionsRepository();
});

final homeTileOptionsVMProvider = StateNotifierProvider<HomeTileOptionsViewmodel, List<HomeTileOption>>((ref) {
  final options = ref.read(homeTileOptionsRepositoryProvider).getHomeTileOptions();
  return HomeTileOptionsViewmodel(options, ref);
});

final homeTileOptionsProvider = Provider((ref) {
  return [];
});

// General provider for the repository with error handling
final energyConsumptionRepositoryProvider = Provider((ref) {
  try {
    final devicesRepository = ref.watch(deviceRepositoryProvider);
    return EnergyConsumptionDataRepository(devicesRepository, ref);
  } catch (e) {
    print("Error creating energy repository: $e");
    // Return a repository without dependencies in case of error
  return EnergyConsumptionDataRepository();
  }
});

// Device changes provider - auto-refreshes when device list changes
final deviceChangesProvider = StreamProvider<List<DeviceModel>>((ref) {
  final repository = ref.watch(deviceRepositoryProvider);
  return repository.streamAllDevices();
});

// Provider for energy consumption data with proper Firebase connection
final energyConsumptionProvider = FutureProvider.autoDispose<EnergyConsumption>((ref) async {
  try {
    final devicesRepository = ref.read(deviceRepositoryProvider);
    
    // Get devices from both sources
    List<DeviceModel> devices = [];
    
    // 1. Get devices from stream
    try {
      final streamDevices = await devicesRepository.streamAllDevices().first;
      devices.addAll(streamDevices);
      print("Got ${streamDevices.length} devices from stream");
    } catch (e) {
      print("Error getting stream devices: $e");
    }
    
    // 2. Get devices from main room
    try {
      final mainRoomDevices = await devicesRepository.streamMainRoomDevices().first;
      
      // Add main room devices if not already in list
      for (var device in mainRoomDevices) {
        if (!devices.any((d) => d.id == device.id)) {
          devices.add(device);
        }
      }
      
      if (mainRoomDevices.isNotEmpty) {
        print("Got ${mainRoomDevices.length} devices from main room");
      }
    } catch (e) {
      print("Error getting main room devices: $e");
    }
    
    // 3. Try to update device states from Firebase real-time database
    try {
      // Skip Firebase connection if no devices were found
      if (devices.isEmpty) {
        print("No devices to update from Firebase");
      } else {
        print("Initializing Firebase app for device state updates");
        
        // Initialize Firebase with the same settings as in DummyMainHallPage
        const String uniqueAppName = "tempFirebaseApp";
        FirebaseApp? app;
        
        try {
          app = Firebase.app(uniqueAppName);
        } catch (e) {
          app = await Firebase.initializeApp(
            name: uniqueAppName,
            options: const FirebaseOptions(
              databaseURL: 'https://home-automation-78d43-default-rtdb.asia-southeast1.firebasedatabase.app',
              apiKey: 'AIzaSyALytw5DzSOWXSKdMJgRqTthL4IeowTDxc',
              projectId: 'home-automation-78d43',
              messagingSenderId: '872253796110',
              appId: '1:872253796110:web:bc95c78cf47ad1e10ff15f',
              storageBucket: 'home-automation-78d43.appspot.com',
            ),
          );
        }
        
        // Get database instance for this app
        final database = FirebaseDatabase.instanceFor(app: app);
        
        print("Attempting to connect to Firebase at path: outlets/living_room/devices");
        final dbRef = database.ref('outlets/living_room/devices');
        
        // Use timeout to avoid hanging
        final snapshot = await dbRef.get().timeout(const Duration(seconds: 5), 
          onTimeout: () {
            print("Firebase query timed out");
            throw TimeoutException("Firebase query timed out");
          }
        );
        
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          print("Firebase data: ${data.keys.join(', ')}");
          
          // Update device states based on Firebase data
          for (var i = 0; i < devices.length; i++) {
            var device = devices[i];
            
            // Check if the device is a light (relay)
            if (device.label.toLowerCase().contains('light')) {
              final match = RegExp(r'Light (\d+)').firstMatch(device.label);
              if (match != null) {
                final relayNumber = match.group(1);
                final relayKey = 'relay$relayNumber';
                
                if (data.containsKey(relayKey)) {
                  final isOn = data[relayKey] as bool? ?? false;
                  print("${device.label} state from Firebase: $isOn");
                  devices[i] = device.copyWith(isSelected: isOn);
                }
              }
            }
            // Check if the device is a fan
            else if (device.label.toLowerCase().contains('fan')) {
              if (data.containsKey('fan') && data['fan'] is Map) {
                final fanData = data['fan'] as Map<dynamic, dynamic>;
                final isOn = (fanData['speed'] as int? ?? 0) > 0;
                print("Fan state from Firebase: $isOn");
                devices[i] = device.copyWith(isSelected: isOn);
              }
            }
          }
          
          print("Updated device states from Firebase real-time database");
        } else {
          print("No data found in Firebase at the specified path");
        }
        
        // Clean up Firebase app
        try {
          await Firebase.app(uniqueAppName).delete();
        } catch (e) {
          print("Error cleaning up Firebase app: $e");
        }
      }
    } catch (e) {
      print("Error updating device states from Firebase: $e");
      // Continue with the existing device states
    }
    
    // Log all devices with their updated states
    for (var device in devices) {
      print("Final device: ${device.label} (${device.isSelected ? 'ON' : 'OFF'})");
    }
    
    // Count total and active devices
    final totalCount = devices.length;
    final activeCount = devices.where((d) => d.isSelected).length;
    
    print("FINAL COUNT: Found $activeCount active devices out of $totalCount total devices");
    
    // Generate chart data based on active devices
    final values = _generateEnergyValues(activeCount);
    
    // Calculate consumption metrics
    double totalConsumption = 0.0;
    double peakConsumption = 0.0;
    double averageConsumption = 0.0;
    
    if (values.isNotEmpty) {
      totalConsumption = values.fold(0, (sum, item) => sum + (item.value ?? 0));
      peakConsumption = values.map((v) => v.value ?? 0).reduce((a, b) => a > b ? a : b);
      averageConsumption = totalConsumption / values.length;
    }
    
    // Generate daily consumption data
    Map<String, double> dailyConsumption = {};
    final today = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dateStr = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
      dailyConsumption[dateStr] = activeCount * (5 + (day.day % 5)); // Variation based on day
    }
    
    return EnergyConsumption(
      values: values,
      totalConsumption: totalConsumption,
      peakConsumption: peakConsumption,
      averageConsumption: averageConsumption,
      activeDevicesCount: activeCount,
      totalDevicesCount: totalCount,
      dailyConsumption: dailyConsumption,
    );
  } catch (e) {
    print("Error in energy consumption provider: $e");
    // Return a minimal valid object instead of throwing
    return EnergyConsumption(
      values: [],
      totalConsumption: 0,
      peakConsumption: 0,
      averageConsumption: 0,
      activeDevicesCount: 0,
      totalDevicesCount: 0,
      dailyConsumption: {},
    );
  }
});

// Helper method to generate energy values for the chart - now weekly instead of hourly
List<EnergyConsumptionValue> _generateEnergyValues(int activeDevices) {
  final List<EnergyConsumptionValue> values = [];
  final now = DateTime.now();
  
  // List of weekday names for better labels
  final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  
  // Generate data for the last 7 days
  for (int i = 6; i >= 0; i--) {
    final day = now.subtract(Duration(days: i));
    final weekdayIndex = day.weekday - 1; // 0 = Monday, 6 = Sunday
    
    // Base consumption plus some variation based on weekday
    // Higher consumption on weekends, lower on weekdays
    double baseConsumption = activeDevices * 1.5;
    
    // Weekday/weekend factor (higher on weekend)
    double dayFactor = (weekdayIndex >= 5) ? 1.8 : 1.0; // Weekend vs weekday
    
    // Activity factor based on day of week (mid-week tends to have more activity)
    double activityFactor = 0.8;
    if (weekdayIndex == 2 || weekdayIndex == 3) { // Wed, Thu
      activityFactor = 1.2; // Higher mid-week
    } else if (weekdayIndex >= 5) { // Weekend
      activityFactor = 1.5; // Highest on weekend
    }
    
    // Add some consistent but pseudo-random variation based on the day
    double randomFactor = 0.9 + ((day.day * 7) % 30) / 100;
    
    double consumption = baseConsumption * dayFactor * activityFactor * randomFactor;
    
    values.add(EnergyConsumptionValue(
      day: weekdays[weekdayIndex],
      value: double.parse(consumption.toStringAsFixed(1)),
      aboveThreshold: consumption > 10.0, // Adjusted threshold for daily values
      timestamp: day,
    ));
  }
  
  return values;
}

// Helper to convert string to icon option enum
FlickyAnimatedIconOptions _getIconOptionFromString(String iconName) {
  try {
    return FlickyAnimatedIconOptions.values.firstWhere(
      (o) => o.name == iconName,
      orElse: () => FlickyAnimatedIconOptions.bolt
    );
  } catch (e) {
    return FlickyAnimatedIconOptions.bolt;
  }
}

// Provider for energy saving mode status with fallback
final energySavingModeProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    return await ref.read(energyConsumptionRepositoryProvider).getEnergySavingModeStatus();
  } catch (e) {
    print("Error in energySavingModeProvider: $e");
    return false;
  }
});

// Provider for toggling energy saving mode with error handling
final toggleEnergySavingModeProvider = FutureProvider.autoDispose.family<void, bool>((ref, enabled) async {
  try {
    await ref.read(energyConsumptionRepositoryProvider).toggleEnergySavingMode(enabled);
    // Refresh the energy consumption data
    ref.invalidate(energyConsumptionProvider);
    // Refresh the energy saving mode status
    ref.invalidate(energySavingModeProvider);
  } catch (e) {
    print("Error in toggleEnergySavingModeProvider: $e");
    // Re-throw to be caught by the UI
    throw e;
  }
});

// Provider for getting long-running devices
final longRunningDevicesProvider = FutureProvider<List<String>>((ref) async {
  try {
    return await ref.read(energyConsumptionRepositoryProvider).getLongRunningDevices();
  } catch (e) {
    print("Error in longRunningDevicesProvider: $e");
    return [];
  }
});

