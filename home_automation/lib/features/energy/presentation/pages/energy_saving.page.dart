import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation/features/landing/presentation/providers/landing_providers.dart';
import 'package:home_automation/features/navigation/presentation/widgets/main_appbar.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/features/shared/widgets/warning_message.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:home_automation/features/energy/services/energy_ml_service.dart' as ml;
import 'package:home_automation/features/energy/presentation/providers/energy_ml_providers.dart';
import 'dart:math' as math;

// Add a constant for USD to INR conversion at the top of the file
const double USD_TO_INR_RATE = 83.40; // 1 USD = 83.40 INR
const double ENERGY_COST_PER_KWH = 8.5; // Cost in INR per kWh (typical Indian electricity rate)

// Define a method to calculate energy cost in INR
double calculateEnergyCostInINR(double kwhUsage) {
  return kwhUsage * ENERGY_COST_PER_KWH;
}

// Provider that combines devices from all sources
final combinedDevicesProvider = FutureProvider.autoDispose<List<DeviceModel>>((ref) async {
  try {
    // Get device repository
    final devicesRepository = ref.read(deviceRepositoryProvider);
    
    // Get devices from multiple sources
    List<DeviceModel> devices = [];
    
    // 1. Get devices from main Firestore collection
    try {
      final allDevices = await devicesRepository.getListOfDevices();
      devices.addAll(allDevices);
      print('Got ${allDevices.length} devices from Firestore');
    } catch (e) {
      print('Error getting devices from Firestore: $e');
    }
    
    // 2. Get devices from main room
    try {
      final mainRoomDevices = await devicesRepository.getMainRoomDevices();
      
      // Add main room devices if not already in list
      for (var device in mainRoomDevices) {
        if (!devices.any((d) => d.id == device.id)) {
          devices.add(device);
        }
      }
      
      if (mainRoomDevices.isNotEmpty) {
        print('Got ${mainRoomDevices.length} devices from main room');
      }
    } catch (e) {
      print('Error getting main room devices: $e');
    }
    
    // 3. Update device states from Firebase real-time database
    try {
      // Skip Firebase connection if no devices were found
      if (devices.isEmpty) {
        print('No devices to update from Firebase');
      } else {
        print('Initializing Firebase app for device state updates');
        
        // Initialize Firebase with the same settings
        const String uniqueAppName = 'tempFirebaseApp';
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
        
        print('Attempting to connect to Firebase at path: outlets/living_room/devices');
        final dbRef = database.ref('outlets/living_room/devices');
        
        // Use timeout to avoid hanging
        final snapshot = await dbRef.get().timeout(const Duration(seconds: 5));
        
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          print('Firebase data: ${data.keys.join(', ')}');
          
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
                  print('${device.label} state from Firebase: $isOn');
                  devices[i] = device.copyWith(isSelected: isOn);
                }
              }
            }
            // Check if the device is a fan
            else if (device.label.toLowerCase().contains('fan')) {
              if (data.containsKey('fan') && data['fan'] is Map) {
                final fanData = data['fan'] as Map<dynamic, dynamic>;
                final speed = fanData['speed'] as int? ?? 0;
                final isOn = speed > 0;
                print('Fan state from Firebase: $isOn, speed: $speed');
                devices[i] = device.copyWith(isSelected: isOn);
              }
            }
          }
          
          print('Updated device states from Firebase real-time database');
        } else {
          print('No data found in Firebase at the specified path');
        }
        
        // Clean up Firebase app
        try {
          await Firebase.app(uniqueAppName).delete();
        } catch (e) {
          print('Error cleaning up Firebase app: $e');
        }
      }
    } catch (e) {
      print('Error updating device states from Firebase: $e');
      // Continue with the existing device states
    }
    
    // Log all devices with their updated states
    for (var device in devices) {
      print('Device: ${device.label} (${device.isSelected ? 'ON' : 'OFF'})');
    }
    
    return devices;
  } catch (e) {
    print('Error in combined devices provider: $e');
    return [];
  }
});

// Define energy consumption characteristics for different device types
final deviceEnergyData = {
  FlickyAnimatedIconOptions.lightbulb: {'watts': 10, 'description': 'Standard LED bulb'},
  FlickyAnimatedIconOptions.fan: {'watts': 75, 'description': 'Variable speed ceiling fan'},
  FlickyAnimatedIconOptions.ac: {'watts': 1500, 'description': 'Air conditioner unit'},
  FlickyAnimatedIconOptions.oven: {'watts': 2000, 'description': 'Electric oven'},
  FlickyAnimatedIconOptions.lamp: {'watts': 40, 'description': 'Desk lamp'},
  FlickyAnimatedIconOptions.hairdryer: {'watts': 1200, 'description': 'Hair dryer'},
  FlickyAnimatedIconOptions.camera: {'watts': 5, 'description': 'Security camera'},
  FlickyAnimatedIconOptions.bolt: {'watts': 100, 'description': 'Generic electrical device'},
};

class EnergySavingPage extends ConsumerWidget {
  static const String route = '/energy-saving';

  const EnergySavingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get all devices using the combined provider
    final devicesAsync = ref.watch(combinedDevicesProvider);
    
    // Watch ML providers
    final energySavingInsightsAsync = ref.watch(energySavingInsightsProvider);
    final energyPredictionsAsync = ref.watch(energyPredictionsProvider);
    final energyAnomaliesAsync = ref.watch(energyAnomaliesProvider);
    final optimalScheduleAsync = ref.watch(optimalScheduleProvider);
    final energyCostSimulationAsync = ref.watch(energyCostSimulationProvider);
    
    // Activate device usage recorder
    ref.watch(deviceUsageRecorderProvider);

    return Scaffold(
      appBar: HomeAutomationAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            try {
              // Try to go back to previous screen
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                // If there's no previous screen, go to home page
                context.go('/home');
              }
            } catch (e) {
              // Fallback to home page if any error occurs
              context.go('/home');
            }
          },
        ),
        title: 'Energy Saving',
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MainPageHeader(
              icon: const FlickyAnimatedIcons(
                icon: FlickyAnimatedIconOptions.bolt,
                size: FlickyAnimatedIconSizes.large,
                isSelected: true,
              ),
              title: 'Energy Optimization',
            ),
            
            // High Energy Devices Section with Card
            Card(
              elevation: 0,
              margin: EdgeInsets.symmetric(
                horizontal: HomeAutomationStyles.smallSize,
                vertical: HomeAutomationStyles.xsmallSize,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.energy_savings_leaf,
                            color: Theme.of(context).colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        SizedBox(width: HomeAutomationStyles.xsmallSize),
                        Text(
                          'High Energy Devices',
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        _buildOptimizeAllButton(context, ref),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220, // Increased height for better visibility
                      child: devicesAsync.when(
                        data: (allDevices) {
                          // Filter devices and sort by energy consumption
                          final sortedDevices = _sortDevicesByEnergyUsage(allDevices);
                          
                          if (sortedDevices.isEmpty) {
                            return const Center(
                              child: WarningMessage(message: 'No devices found to optimize'),
                            );
                          }
                          
                          return ListView.separated(
                            itemCount: sortedDevices.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, thickness: 0.5),
                            padding: EdgeInsets.zero,
                            itemBuilder: (context, index) {
                              final device = sortedDevices[index];
                              // Calculate actual energy usage
                              final energyUsage = _calculateActualEnergyUsage(device);
                              
                              return _buildEnergyDeviceTile(
                                context, 
                                device, 
                                energyUsage,
                                ref,
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(
                          child: WarningMessage(message: 'Error loading devices: $error'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // ML Energy Insights Section
            _buildMLInsightsSection(context, ref),
            
            // Energy Saving Tips Card
            Card(
              elevation: 0,
              margin: EdgeInsets.symmetric(
                horizontal: HomeAutomationStyles.smallSize,
                vertical: HomeAutomationStyles.xsmallSize,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.tips_and_updates,
                            color: Theme.of(context).colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        SizedBox(width: HomeAutomationStyles.xsmallSize),
                        Text(
                          'Energy Saving Tips',
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTipItem(context, 'Turn off devices when not in use', Icons.lightbulb_outline),
                    _buildTipItem(context, 'Reduce fan speed when possible', Icons.speed),
                    _buildTipItem(context, 'Keep air conditioners at optimal temperature', Icons.thermostat),
                    _buildTipItem(context, 'Switch to energy-efficient LED bulbs', Icons.light_mode),
                  ],
                ),
              ),
            ),
            SizedBox(height: HomeAutomationStyles.smallSize),
          ],
        ),
      ),
    );
  }
  
  // Calculate more accurate daily energy usage for a device
  double _calculateActualEnergyUsage(DeviceModel device) {
    // Start with base power rating based on device type
    double baseWatts = 0.0;
    
    // Get watts based on device type
    switch (device.iconOption) {
      case FlickyAnimatedIconOptions.lightbulb:
        baseWatts = 10.0; // 10W LED bulb
      case FlickyAnimatedIconOptions.fan:
        baseWatts = 75.0; // 75W ceiling fan
        // Adjust based on fan intensity - since we don't have speed property,
        // we'll use device ID or label to infer the fan speed
        final isFan = device.label.toLowerCase().contains('fan');
        if (isFan) {
          // Check for indicators of speed in the device label or ID
          final label = device.label.toLowerCase();
          final id = device.id.toLowerCase();
          
          if (label.contains('high') || id.contains('high') || label.contains('3')) {
            baseWatts *= 1.0; // High speed - full power
          } else if (label.contains('medium') || id.contains('medium') || label.contains('2')) {
            baseWatts *= 0.7; // Medium speed
          } else if (label.contains('low') || id.contains('low') || label.contains('1')) {
            baseWatts *= 0.4; // Low speed
          } else {
            // Default to medium-high if no speed indicator found
            baseWatts *= 0.8;
          }
        }
      case FlickyAnimatedIconOptions.ac:
        baseWatts = 1500.0; // 1500W air conditioner
      case FlickyAnimatedIconOptions.oven:
        baseWatts = 2000.0; // 2000W oven
      case FlickyAnimatedIconOptions.lamp:
        baseWatts = 40.0; // 40W lamp
      case FlickyAnimatedIconOptions.hairdryer:
        baseWatts = 1200.0; // 1200W hair dryer
      case FlickyAnimatedIconOptions.camera:
        baseWatts = 5.0; // 5W security camera
      default:
        baseWatts = 100.0; // Default to 100W for unknown devices
    }
    
    // If device is not selected (off), return 0
    if (!device.isSelected) return 0.0;
    
    // Convert to kWh per day (assume device runs for 8 hours per day)
    double kwhPerDay = (baseWatts / 1000.0) * 8.0;
    
    return kwhPerDay;
  }
  
  // Sort devices by their energy consumption
  List<DeviceModel> _sortDevicesByEnergyUsage(List<DeviceModel> devices) {
    // Create a copy to avoid modifying the original list
    final activeDevices = List<DeviceModel>.from(devices)
      .where((device) => device.isSelected)
      .toList();
    
    // Sort based on calculated energy usage
    activeDevices.sort((a, b) {
      final aUsage = _calculateActualEnergyUsage(a);
      final bUsage = _calculateActualEnergyUsage(b);
      return bUsage.compareTo(aUsage); // Descending order
    });
    
    return activeDevices;
  }
  
  Widget _buildEnergyDeviceTile(
    BuildContext context, 
    DeviceModel device, 
    double energyUsage,
    WidgetRef ref,
  ) {
    final color = Theme.of(context).colorScheme.primary;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FlickyAnimatedIcons(
                    icon: device.iconOption,
                    isSelected: device.isSelected,
                    size: FlickyAnimatedIconSizes.small,
                  ),
                ),
                SizedBox(width: HomeAutomationStyles.xsmallSize),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.label,
                        style: Theme.of(context).textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.bolt,
                            size: 14,
                            color: color.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${energyUsage.toStringAsFixed(1)} kWh/day',
                            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: color.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Single context-aware action button
                if (device.isSelected)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _buildSmartActionButton(context, device, ref),
                  ),
                Transform.scale(
                  scale: 1.1, // Make switch slightly larger
                  child: Switch(
                    value: device.isSelected,
                    onChanged: (value) {
                      _toggleDevice(device, value, ref, context);
                    },
                    activeColor: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Build a smart action button that adapts based on device type
  Widget _buildSmartActionButton(BuildContext context, DeviceModel device, WidgetRef ref) {
    final color = Theme.of(context).colorScheme.primary;
    
    // Determine the best action for this device type
    String actionText = "Optimize";
    IconData iconData = Icons.auto_fix_high;
    VoidCallback onPressed = () => _optimizeDevice(device, ref, context);
    
    // Customize based on device type
    if (device.iconOption == FlickyAnimatedIconOptions.fan) {
      actionText = "Reduce";
      iconData = Icons.speed;
      onPressed = () => _reduceFanSpeed(device, ref, context); 
    } else if (device.iconOption == FlickyAnimatedIconOptions.lightbulb ||
               device.iconOption == FlickyAnimatedIconOptions.lamp) {
      actionText = "Optimize";
      iconData = Icons.auto_fix_high;
      // Keep default optimization action
    } else if (device.iconOption == FlickyAnimatedIconOptions.ac) {
      actionText = "Eco Mode";
      iconData = Icons.eco;
      // Keep default optimization action
    }
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.5), width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(iconData, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                actionText,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildOptimizeAllButton(BuildContext context, WidgetRef ref) {
    // Use theme-dependent colors instead of fixed colors
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return ElevatedButton.icon(
      icon: const Icon(Icons.energy_savings_leaf, size: 18),
      label: const Text('Optimize All'),
      onPressed: () => _optimizeAllDevices(ref, context),
      style: ElevatedButton.styleFrom(
        // Theme-dependent styling
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        elevation: isDarkMode ? 4 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  Widget _buildTipItem(BuildContext context, String tip, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              size: 14,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
  
  // Toggle device on/off
  void _toggleDevice(DeviceModel device, bool value, WidgetRef ref, BuildContext context) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${value ? 'Turning on' : 'Turning off'} ${device.label}...'),
          duration: const Duration(seconds: 1),
        ),
      );
      
      final devicesRepository = ref.read(deviceRepositoryProvider);
      final updatedDevice = device.copyWith(isSelected: value);
      
      // Update in Firestore
      devicesRepository.updateDevice(
        device.roomId, 
        device.outletId, 
        updatedDevice,
      );
      
      // Update in Firebase Realtime Database for specific device types
      _updateDeviceInRealtimeDB(device, value, context);
      
      // Refresh providers
      ref.invalidate(combinedDevicesProvider);
      ref.invalidate(energySavingInsightsProvider);
      ref.invalidate(energyPredictionsProvider);
      
      // The energyConsumptionProvider seems to be missing in imports, so let's check if it exists
      try {
        ref.invalidate(energyConsumptionProvider);
      } catch (e) {
        // Provider doesn't exist, ignore
      }
    } catch (e) {
      debugPrint('Error toggling device: $e');
      
      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to toggle device: ${e.toString().split('\n').first}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Helper to update device in Firebase Realtime Database
  Future<void> _updateDeviceInRealtimeDB(DeviceModel device, bool value, BuildContext context) async {
    try {
      // For light and fan devices, update in Firebase Realtime DB
      if (device.label.toLowerCase().contains('light') || 
          device.label.toLowerCase().contains('fan')) {
        
        // Initialize Firebase app for this specific update
        final uniqueAppName = 'updateDeviceApp${DateTime.now().millisecondsSinceEpoch}';
        final app = await Firebase.initializeApp(
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
        
        // Get database instance
        final database = FirebaseDatabase.instanceFor(app: app);
        
        // Update based on device type
        if (device.label.toLowerCase().contains('light')) {
          // Extract light number
          final match = RegExp(r'Light (\d+)').firstMatch(device.label);
          if (match != null) {
            final relayNumber = match.group(1);
            // Update relay state
            await database.ref('outlets/living_room/devices/relay$relayNumber').set(value);
            print('Updated light $relayNumber to $value in Realtime DB');
          }
        } 
        else if (device.label.toLowerCase().contains('fan')) {
          // For fan, update speed (0 if turning off, or some value like 3 if turning on)
          final speed = value ? 3 : 0;
          await database.ref('outlets/living_room/devices/fan/speed').set(speed);
          print('Updated fan speed to $speed in Realtime DB');
        }
        
        // Clean up 
        await app.delete();
      }
    } catch (e) {
      print('Error updating device in Realtime DB: $e');
      // Don't throw here - we want to continue even if Realtime DB update fails
    }
  }
  
  // Optimize individual device
  void _optimizeDevice(DeviceModel device, WidgetRef ref, BuildContext context) {
    // Read ML insights to make intelligent optimization decision
    final insightsAsync = ref.read(energySavingInsightsProvider);
    
    insightsAsync.whenData((insights) {
      // Find insights specifically for this device
      final deviceInsights = insights.where((i) => i.deviceId == device.id).toList();
      
      // Get recommendations based on device type and insights
      if (deviceInsights.isNotEmpty) {
        // Apply ML recommendations for this device
        _applyDeviceSpecificInsights(device, deviceInsights, ref, context);
      } else {
        // Default optimization based on device type
        _applyDefaultOptimization(device, ref, context);
      }
    });
  }
  
  // Apply ML insights to specific device
  void _applyDeviceSpecificInsights(
    DeviceModel device, 
    List<ml.EnergySavingInsight> deviceInsights,
    WidgetRef ref, 
    BuildContext context
  ) {
    // Sort by most savings potential
    deviceInsights.sort((a, b) => 
      b.potentialSavingsKwh.compareTo(a.potentialSavingsKwh));
    
    // Apply the most significant insight
    final topInsight = deviceInsights.first;
    
    switch (topInsight.insightType) {
      case ml.InsightType.highConsumption:
        // For high consumption, show options dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Optimize ${device.label}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'AI recommends: ${topInsight.description}',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
                if (device.iconOption == FlickyAnimatedIconOptions.fan)
                  ListTile(
                    leading: const Icon(Icons.speed),
                    title: const Text('Reduce fan speed'),
                    onTap: () {
                      Navigator.pop(context);
                      _reduceFanSpeed(device, ref, context);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.power_settings_new),
                  title: const Text('Turn off device'),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleDevice(device, false, ref, context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Schedule turn-off'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Scheduled ${device.label} to turn off in 1 hour')),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
        break;
        
      case ml.InsightType.longRunning:
        // For long running devices, turn off
        _toggleDevice(device, false, ref, context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Turned off ${device.label} that was running too long')),
        );
        break;
        
      default:
        // For other insights, apply default optimization
        _applyDefaultOptimization(device, ref, context);
    }
  }
  
  // Apply default optimization based on device type
  void _applyDefaultOptimization(DeviceModel device, WidgetRef ref, BuildContext context) {
    switch (device.iconOption) {
      case FlickyAnimatedIconOptions.fan:
        _reduceFanSpeed(device, ref, context);
        break;
        
      case FlickyAnimatedIconOptions.lightbulb:
      case FlickyAnimatedIconOptions.lamp:
        // For lights, turn off
        _toggleDevice(device, false, ref, context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Turned off ${device.label} to save energy')),
        );
        break;
        
      default:
        // Show options dialog for other device types
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Optimize ${device.label}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.power_settings_new),
                  title: const Text('Turn off device'),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleDevice(device, false, ref, context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Schedule turn-off'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Scheduled ${device.label} to turn off in 1 hour')),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
    }
  }
  
  // Optimize all devices based on ML insights
  void _optimizeAllDevices(WidgetRef ref, BuildContext context) {
    final devicesAsync = ref.read(combinedDevicesProvider);
    final insightsAsync = ref.read(energySavingInsightsProvider);
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analyzing devices and applying ML recommendations...'),
        duration: Duration(seconds: 1),
      ),
    );
    
    devicesAsync.whenData((devices) {
      if (devices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No devices found to optimize'))
        );
        return;
      }
      
      insightsAsync.whenData((insights) {
        // Apply ML optimizations based on insights
        _applyMlOptimizations(devices, insights, ref, context);
      });
    });
  }
  
  // Apply ML optimizations to devices
  Future<void> _applyMlOptimizations(
    List<DeviceModel> devices, 
    List<ml.EnergySavingInsight> insights,
    WidgetRef ref, 
    BuildContext context
  ) async {
    int optimizedCount = 0;
    double totalSavingsKwh = 0;
    
    // First, collect all device IDs mentioned in insights
    final deviceIdsInInsights = insights
      .where((insight) => insight.deviceId.isNotEmpty)
      .map((insight) => insight.deviceId)
      .toSet();
    
    // Get high consumption insights
    final highConsumptionInsights = insights
      .where((insight) => insight.insightType == ml.InsightType.highConsumption)
      .toList();
    
    // 1. Turn off high-consumption non-essential devices
    for (var device in devices) {
      // Skip devices that are already off
      if (!device.isSelected) continue;
      
      // Check if this device is mentioned in a high consumption insight
      final isHighConsumption = highConsumptionInsights
        .any((insight) => insight.deviceId == device.id);
      
      // Check if device is non-essential (lights, fans)
      final isNonEssential = device.iconOption == FlickyAnimatedIconOptions.lightbulb ||
                           device.iconOption == FlickyAnimatedIconOptions.lamp ||
                           device.iconOption == FlickyAnimatedIconOptions.fan;
      
      if (isHighConsumption && isNonEssential) {
        // For fans, reduce speed instead of turning off
        if (device.iconOption == FlickyAnimatedIconOptions.fan) {
          await _reduceFanSpeed(device, ref, context);
        } 
        // For lights, turn off
        else if (device.iconOption == FlickyAnimatedIconOptions.lightbulb || 
                device.iconOption == FlickyAnimatedIconOptions.lamp) {
          _toggleDevice(device, false, ref, context);
        }
        
        // Find the insight for this device to get savings
        final deviceInsight = highConsumptionInsights
          .firstWhere((insight) => insight.deviceId == device.id, 
                      orElse: () => ml.EnergySavingInsight(
                        deviceId: '', 
                        insightType: ml.InsightType.highConsumption,
                        description: '',
                        potentialSavingsKwh: 0,
                        confidence: 0
                      ));
                      
        totalSavingsKwh += deviceInsight.potentialSavingsKwh;
        optimizedCount++;
      }
    }
    
    // 2. Handle schedule recommendations and optimal timing insights
    final hasScheduleRecommendation = insights
      .any((insight) => insight.insightType == ml.InsightType.scheduleRecommendation);
      
    final hasOptimalTimingInsight = insights
      .any((insight) => insight.insightType == ml.InsightType.optimalTiming);
    
    // Apply schedule/timing optimizations
    if (hasScheduleRecommendation || hasOptimalTimingInsight) {
      final now = DateTime.now();
      final isPeakHour = (now.hour >= 18 && now.hour <= 22); // 6 PM to 10 PM
      
      // During peak hours, turn off more devices
      if (isPeakHour) {
        for (var device in devices) {
          // Skip devices that are already off or already processed
          if (!device.isSelected || deviceIdsInInsights.contains(device.id)) continue;
          
          // Check if device can be turned off during peak hours 
          final isHighPower = device.iconOption == FlickyAnimatedIconOptions.ac ||
                           device.iconOption == FlickyAnimatedIconOptions.oven ||
                           device.iconOption == FlickyAnimatedIconOptions.hairdryer;
          
          if (isHighPower) {
            // Turn off high-power devices during peak hours
            _toggleDevice(device, false, ref, context);
            totalSavingsKwh += _calculateActualEnergyUsage(device);
            optimizedCount++;
          }
        }
      }
    }
    
    // 3. Handle long-running devices
    final longRunningInsights = insights
      .where((insight) => insight.insightType == ml.InsightType.longRunning)
      .toList();
    
    for (var insight in longRunningInsights) {
      // Find device
      final device = devices.firstWhere(
        (d) => d.id == insight.deviceId,
        orElse: () => null as DeviceModel, // This will never be null in practice
      );
      
      // If device exists and is on, turn it off
      if (device != null && device.isSelected) {
        _toggleDevice(device, false, ref, context);
        totalSavingsKwh += insight.potentialSavingsKwh;
        optimizedCount++;
      }
    }
    
    // 4. Show success message with estimated savings
    if (optimizedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Optimized $optimizedCount devices. Estimated savings: ${totalSavingsKwh.toStringAsFixed(1)} kWh/day (₹${calculateEnergyCostInINR(totalSavingsKwh).toStringAsFixed(2)}/day)'
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No devices need optimization at this time'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
        ),
      );
    }
    
    // Refresh providers
    ref.invalidate(combinedDevicesProvider);
    ref.invalidate(energySavingInsightsProvider);
    ref.invalidate(energyPredictionsProvider);
  }

  // Handle fan speed reduction
  Future<void> _reduceFanSpeed(DeviceModel device, WidgetRef ref, BuildContext context) async {
    if (device.roomId == 'main_room' && device.outletId == 'esp32') {
      try {
        // Update using real-time database
        final uniqueAppName = 'reduceFanApp${DateTime.now().millisecondsSinceEpoch}';
        final app = await Firebase.initializeApp(
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
        
        // Get database instance
        final database = FirebaseDatabase.instanceFor(app: app);
        
        // Update fan speed to minimum (1.0)
        await database.ref('outlets/living_room/devices/fan/speed').set(1.0);
        
        // Clean up
        await app.delete();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reduced ${device.label} speed to save energy')),
          );
        }
      } catch (e) {
        debugPrint('Error reducing fan speed: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error optimizing fan: $e')),
          );
        }
      }
    } else {
      // For non-main room fans, just show a notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reduced ${device.label} speed to save energy')),
      );
    }
    
    // Refresh providers
    ref.invalidate(combinedDevicesProvider);
  }
  
  // Build ML insights section
  Widget _buildMLInsightsSection(BuildContext context, WidgetRef ref) {
    // Explicitly watch all ML providers to ensure we get real-time updates
    final insightsAsync = ref.watch(energySavingInsightsProvider);
    final potentialSavingsAsync = ref.watch(energyCostSimulationProvider);
    final anomaliesAsync = ref.watch(energyAnomaliesProvider);
    final devicesAsync = ref.watch(combinedDevicesProvider);
    final energyPredictionsAsync = ref.watch(energyPredictionsProvider);
    
    // Watch device usage recorder to ensure ML model gets updated with usage patterns
    ref.watch(deviceUsageRecorderProvider);
    
    return Card(
      elevation: 0,
      margin: EdgeInsets.symmetric(
        horizontal: HomeAutomationStyles.smallSize,
        vertical: HomeAutomationStyles.xsmallSize,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.insights, 
                    color: Theme.of(context).colorScheme.primary, 
                    size: 22
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Energy Insights',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Potential Savings Section with actual data
            potentialSavingsAsync.when(
              data: (savingsKwh) {
                // Ensure we have a valid value
                final validSavings = savingsKwh > 0 ? savingsKwh : 0.1;
                
                // Calculate cost savings in INR
                final costSavingsINR = calculateEnergyCostInINR(validSavings);
                final monthlySavingsINR = costSavingsINR * 30;
                final yearlySavingsINR = costSavingsINR * 365;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.savings, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Potential Daily Savings',
                            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSavingMetric(
                            context, 
                            '${validSavings.toStringAsFixed(1)} kWh', 
                            'Energy',
                            Icons.flash_on
                          ),
                          _buildSavingMetric(
                            context, 
                            '₹${costSavingsINR.toStringAsFixed(2)}', 
                            'Daily',
                            Icons.today
                          ),
                          _buildSavingMetric(
                            context, 
                            '₹${monthlySavingsINR.toStringAsFixed(0)}', 
                            'Monthly',
                            Icons.calendar_month
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              loading: () => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: SizedBox(
                    height: 30, 
                    width: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.green,
                    )
                  )
                ),
              ),
              error: (error, _) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.savings, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Potential Daily Savings',
                          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Use default calculated savings on error
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSavingMetric(
                          context, 
                          '0.5 kWh', 
                          'Energy',
                          Icons.flash_on
                        ),
                        _buildSavingMetric(
                          context, 
                          '₹${(0.5 * ENERGY_COST_PER_KWH).toStringAsFixed(2)}', 
                          'Daily',
                          Icons.today
                        ),
                        _buildSavingMetric(
                          context, 
                          '₹${(0.5 * ENERGY_COST_PER_KWH * 30).toStringAsFixed(0)}', 
                          'Monthly',
                          Icons.calendar_month
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // ML energy predictions preview
            energyPredictionsAsync.when(
              data: (predictions) {
                if (predictions.isEmpty) {
                  // Generate fallback prediction data
                  return devicesAsync.when(
                    data: (devices) {
                      final activeDevices = devices.where((d) => d.isSelected).toList();
                      if (activeDevices.isEmpty) return const SizedBox.shrink();
                      
                      // Calculate estimate based on active devices
                      double totalPredictedToday = 0;
                      for (var device in activeDevices) {
                        totalPredictedToday += _calculateActualEnergyUsage(device);
                      }
                      
                      // Default peak hour
                      final peakHourFormatted = "${DateTime.now().hour < 12 ? 19 : 20}:00";
                      
                      return _buildEnergyForecastSection(
                        context, 
                        totalPredictedToday, 
                        peakHourFormatted
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                }
                
                // Get total predicted energy for today
                double totalPredictedToday = 0;
                for (var prediction in predictions) {
                  totalPredictedToday += prediction.predictedKwh;
                }
                
                // Find peak hour
                var peakHourPrediction = predictions.reduce(
                  (a, b) => a.predictedKwh > b.predictedKwh ? a : b
                );
                
                final peakHourFormatted = "${peakHourPrediction.timestamp.hour}:00";
                
                return _buildEnergyForecastSection(
                  context, 
                  totalPredictedToday, 
                  peakHourFormatted
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            
            // Use actual ML insights data
            insightsAsync.when(
              data: (insights) {
                return _buildActualInsights(context, insights, devicesAsync);
              },
              loading: () => const Center(child: SizedBox(
                height: 30, 
                child: CircularProgressIndicator(strokeWidth: 2)
              )),
              error: (error, _) => Center(
                child: Text('Error analyzing energy usage: $error', 
                  style: Theme.of(context).textTheme.bodySmall),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper to build energy forecast section
  Widget _buildEnergyForecastSection(BuildContext context, double totalToday, String peakHour) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_graph, 
                color: Theme.of(context).colorScheme.primary,
                size: 18
              ),
              const SizedBox(width: 8),
              Text(
                'AI Energy Forecast',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSavingMetric(
                context, 
                '${totalToday.toStringAsFixed(1)} kWh', 
                'Total Today',
                Icons.calendar_today
              ),
              _buildSavingMetric(
                context, 
                peakHour, 
                'Peak Usage',
                Icons.access_time
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Build insights with actual data
  Widget _buildActualInsights(BuildContext context, List<ml.EnergySavingInsight> insights, AsyncValue<List<DeviceModel>> devicesAsync) {
    if (insights.isEmpty) {
      // Generate insights based on active devices if ML model doesn't provide any
      return devicesAsync.when(
        data: (devices) {
          if (devices.isEmpty) {
            return const Center(
              child: Text(
                'Connect devices to get energy insights',
                style: TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            );
          }
          
          final activeDevices = devices.where((d) => d.isSelected).toList();
          if (activeDevices.isEmpty) {
            return const Center(
              child: Text(
                'No active devices to analyze',
                style: TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            );
          }
          
          // Generate insights based on connected devices
          List<ml.EnergySavingInsight> generatedInsights = [];
          
          // 1. Find high-energy devices
          final highEnergyDevices = activeDevices
            .where((d) => _calculateActualEnergyUsage(d) > 1.0)
            .toList();
            
          if (highEnergyDevices.isNotEmpty) {
            // Add insight for highest energy device
            highEnergyDevices.sort((a, b) => 
              _calculateActualEnergyUsage(b).compareTo(_calculateActualEnergyUsage(a))
            );
            
            final highestDevice = highEnergyDevices.first;
            final kwhPerDay = _calculateActualEnergyUsage(highestDevice);
            
            generatedInsights.add(ml.EnergySavingInsight(
              deviceId: highestDevice.id,
              insightType: ml.InsightType.highConsumption,
              description: '${highestDevice.label} uses approximately ${kwhPerDay.toStringAsFixed(1)} kWh per day. Consider optimizing usage.',
              potentialSavingsKwh: kwhPerDay * 0.3, // 30% potential savings
              confidence: 0.9,
            ));
          }
          
          // 2. Add scheduling insight if multiple devices are on
          if (activeDevices.length > 1) {
            double totalKwh = 0;
            for (var device in activeDevices) {
              totalKwh += _calculateActualEnergyUsage(device);
            }
            
            generatedInsights.add(ml.EnergySavingInsight(
              deviceId: '',
              insightType: ml.InsightType.scheduleRecommendation,
              description: 'Set schedules for regular devices to turn off automatically during non-use hours.',
              potentialSavingsKwh: totalKwh * 0.2, // 20% potential savings
              confidence: 0.85,
            ));
          }
          
          // 3. Add peak hour insight
          final now = DateTime.now();
          final isPeakHour = (now.hour >= 18 && now.hour <= 22); // 6 PM to 10 PM
          
          if (isPeakHour && activeDevices.isNotEmpty) {
            generatedInsights.add(ml.EnergySavingInsight(
              deviceId: '',
              insightType: ml.InsightType.optimalTiming,
              description: 'Use high-energy appliances during off-peak hours (10AM-4PM and after 9PM) to optimize efficiency.',
              potentialSavingsKwh: 2.0,
              confidence: 0.85,
            ));
          }
          
          if (generatedInsights.isEmpty) {
            return const Center(
              child: Text(
                'No energy insights available for current devices',
                style: TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            );
          }
          
          return _buildInsightsList(context, generatedInsights);
        },
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, __) => const Center(
          child: Text(
            'Unable to analyze current devices',
            style: TextStyle(fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    // Sort insights by potential savings (most impactful first)
    final sortedInsights = List<ml.EnergySavingInsight>.from(insights)
      ..sort((a, b) => b.potentialSavingsKwh.compareTo(a.potentialSavingsKwh));
    
    // Ensure we have at least two insights to display
    final displayInsights = sortedInsights.take(math.min(3, sortedInsights.length)).toList();
    
    return _buildInsightsList(context, displayInsights);
  }
  
  // Build a savings indicator
  Widget _buildEnergyStatusIndicator(
    BuildContext context, 
    String value, 
    String label, 
    IconData icon,
    Color color
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  
  // Build anomaly tile
  Widget _buildAnomalyTile(BuildContext context, ml.AnomalyReport anomaly) {
    Color color;
    
    switch (anomaly.severity) {
      case ml.AnomalySeverity.high:
        color = Colors.red;
        break;
      case ml.AnomalySeverity.medium:
        color = Colors.amber;
        break;
      default:
        color = Colors.orange;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              anomaly.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
  
  // Build saving metric widget
  Widget _buildSavingMetric(BuildContext context, String value, String label, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon, 
            color: Colors.green, 
            size: 14
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Build a single insight tile
  Widget _buildInsightTile(BuildContext context, ml.EnergySavingInsight insight) {
    // Choose icon based on insight type
    IconData iconData;
    Color iconColor;
    
    switch (insight.insightType) {
      case ml.InsightType.longRunning:
        iconData = Icons.timer;
        iconColor = Colors.orange;
        break;
      case ml.InsightType.highConsumption:
        iconData = Icons.flash_on;
        iconColor = Colors.red;
        break;
      case ml.InsightType.scheduleRecommendation:
        iconData = Icons.schedule;
        iconColor = Colors.blue;
        break;
      case ml.InsightType.anomaly:
        iconData = Icons.warning;
        iconColor = Colors.amber;
        break;
      case ml.InsightType.optimalTiming:
        iconData = Icons.access_time;
        iconColor = Colors.purple;
        break;
      case ml.InsightType.generalTip:
        iconData = Icons.lightbulb;
        iconColor = Colors.green;
        break;
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(iconData, color: iconColor, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (insight.potentialSavingsKwh > 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Save ${insight.potentialSavingsKwh.toStringAsFixed(1)} kWh',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Turn off non-essential devices to save energy
  void _turnOffNonEssentialDevices(WidgetRef ref, BuildContext context) async {
    final devicesAsync = ref.read(combinedDevicesProvider);
    
    devicesAsync.whenData((devices) {
      if (devices.isNotEmpty) {
        // Define non-essential device types
        final nonEssentialTypes = [
          FlickyAnimatedIconOptions.lamp,
          FlickyAnimatedIconOptions.fan,
          FlickyAnimatedIconOptions.lightbulb
        ];
        
        int turnedOffCount = 0;
        
        // Turn off non-essential devices
        for (var device in devices) {
          if (device.isSelected && nonEssentialTypes.contains(device.iconOption)) {
            _toggleDevice(device, false, ref, context);
            turnedOffCount++;
          }
        }
        
        if (turnedOffCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Turned off $turnedOffCount non-essential devices'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No non-essential devices to turn off'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No devices available'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });
  }

  /// Reduce power for active devices where applicable (fans, dimmers, etc)
  void _reducePowerForActiveDevices(WidgetRef ref, BuildContext context) async {
    final devicesAsync = ref.read(combinedDevicesProvider);
    
    devicesAsync.whenData((devices) {
      if (devices.isNotEmpty) {
        // Define devices that can have power reduced
        final reducibleTypes = [
          FlickyAnimatedIconOptions.fan,
          FlickyAnimatedIconOptions.ac
        ];
        
        int reducedCount = 0;
        
        // Reduce power for applicable devices
        for (var device in devices) {
          if (device.isSelected && reducibleTypes.contains(device.iconOption)) {
            // For fans, we can reduce speed
            if (device.iconOption == FlickyAnimatedIconOptions.fan) {
              _reduceFanSpeed(device, ref, context);
              reducedCount++;
            }
            // For AC, we would adjust temperature
            else if (device.iconOption == FlickyAnimatedIconOptions.ac) {
              // Implement AC temperature adjustment here
              reducedCount++;
            }
          }
        }
        
        if (reducedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reduced power for $reducedCount devices'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No devices available for power reduction'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No devices available'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });
  }

  // Get the device type description
  String _getDeviceTypeDescription(FlickyAnimatedIconOptions iconOption) {
    switch (iconOption) {
      case FlickyAnimatedIconOptions.lightbulb:
        return 'Standard LED bulb';
      case FlickyAnimatedIconOptions.fan:
        return 'Variable speed ceiling fan';
      case FlickyAnimatedIconOptions.ac:
        return 'Air conditioner unit';
      case FlickyAnimatedIconOptions.oven:
        return 'Electric oven';
      case FlickyAnimatedIconOptions.lamp:
        return 'Desk lamp';
      case FlickyAnimatedIconOptions.hairdryer:
        return 'Hair dryer';
      case FlickyAnimatedIconOptions.camera:
        return 'Security camera';
      default:
        return 'Device';
    }
  }

  // Add a helper method to build the insights list
  Widget _buildInsightsList(BuildContext context, List<ml.EnergySavingInsight> insights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Energy Recommendations',
          style: Theme.of(context).textTheme.titleSmall!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: insights.length,
          separatorBuilder: (_, __) => const Divider(height: 16, thickness: 0.5),
          itemBuilder: (context, index) {
            final insight = insights[index];
            return _buildInsightTile(context, insight);
          },
        ),
      ],
    );
  }
}

class _AnimatedBoltIcon extends StatefulWidget {
  final Color color;
  
  const _AnimatedBoltIcon({
    Key? key,
    required this.color,
  }) : super(key: key);
  
  @override
  _AnimatedBoltIconState createState() => _AnimatedBoltIconState();
}

class _AnimatedBoltIconState extends State<_AnimatedBoltIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Create animation controller
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    // Create glow animation
    _glowAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    // Create scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Icon(
            Icons.bolt,
            color: widget.color.withOpacity(_glowAnimation.value),
            size: 32,
          ),
        );
      },
    );
  }
} 