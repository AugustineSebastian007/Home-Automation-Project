import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'dart:async';

// Define AC related providers
class ACSettings {
  final String mode;
  final int temperature;
  final String fanSpeed;
  final bool swing;
  
  ACSettings({
    required this.mode,
    required this.temperature,
    required this.fanSpeed,
    required this.swing,
  });
  
  ACSettings copyWith({
    String? mode,
    int? temperature,
    String? fanSpeed,
    bool? swing,
  }) {
    return ACSettings(
      mode: mode ?? this.mode,
      temperature: temperature ?? this.temperature,
      fanSpeed: fanSpeed ?? this.fanSpeed,
      swing: swing ?? this.swing,
    );
  }
}

class DeviceDetailsPanel extends ConsumerWidget {
  final DeviceModel device;
  const DeviceDetailsPanel({super.key, required this.device});

  // Add state providers to track selected modes
  static final acSettingsProvider = StateProvider<ACSettings>((ref) => 
    ACSettings(
      mode: 'Cool', 
      temperature: 24, // Default temperature 24°C
      fanSpeed: 'Auto',
      swing: false,
    )
  );
  static final fanModeProvider = StateProvider<String>((ref) => 'Normal');
  static final timerProvider = StateProvider<String?>((ref) => null);
  static final timerRemainingProvider = StateProvider<int?>((ref) => null); // Remaining time in seconds
  static final timerActiveProvider = StateProvider<bool>((ref) => false);
  static final timerStartTimeProvider = StateProvider<DateTime?>((ref) => null);
  static final timerDurationProvider = StateProvider<int>((ref) => 0); // Duration in seconds

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDeviceSaving = ref.watch(deviceToggleVMProvider);
    // Create a state provider for device-specific controls
    final deviceControlValueProvider = StateProvider<int>((ref) => device.outlet);

    print("Device data in DeviceDetailsPanel: ${device.toJson()}");

    if (device.id.isEmpty || device.id == 'error' || device.id == 'not_found') {
      print("Warning: Invalid device data in DeviceDetailsPanel");
      return Center(
        child: Text("Error: Invalid device data. Please try reloading the device list.",
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final selectionColor = device.isSelected ? colorScheme.primary : colorScheme.secondary;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
                        color: selectionColor.withOpacity(0.125)
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 20),
                            FlickyAnimatedIcons(
                              key: ValueKey(device.iconOption),
                              icon: device.iconOption,
                              size: FlickyAnimatedIconSizes.x2large,
                              isSelected: device.isSelected,
                            ),
                            Text(device.label,
                              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                                color: selectionColor,
                                fontSize: 32.0,
                              )
                            ),
                            SizedBox(height: 24),
                            
                            // Add device-specific controls inside the main container
                            if (device.isSelected)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: _buildDeviceSpecificControls(context, ref, deviceControlValueProvider),
                            ),
                            
                            SizedBox(height: 8),
                            isDeviceSaving
                              ? const CircularProgressIndicator()
                              : GestureDetector(
                                  onTap: () async {
                                    try {
                                      await ref.read(deviceToggleVMProvider.notifier).toggleDevice(device);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Device toggled successfully'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error toggling device: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: Icon(
                                    device.isSelected ? Icons.toggle_on : Icons.toggle_off,
                                    color: selectionColor,
                                    size: HomeAutomationStyles.x2largeIconSize,
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  HomeAutomationStyles.mediumVGap,
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton(
                        onPressed: !device.isSelected && !isDeviceSaving
                          ? () async {
                              await ref.read(deviceListVMProvider.notifier).removeDevice(device);
                            }
                          : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Remove This Device')
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      }
    );
  }
  
  Widget _buildDeviceSpecificControls(BuildContext context, WidgetRef ref, StateProvider<int> controlValueProvider) {
    // Get current control value
    final controlValue = ref.watch(controlValueProvider);
    final colorScheme = Theme.of(context).colorScheme;
    
    // Watch current modes
    final selectedFanMode = ref.watch(fanModeProvider);
    final selectedTimer = ref.watch(timerProvider);
    
    // Handle different device types
    switch (device.iconOption) {
      case FlickyAnimatedIconOptions.ac:
        // Get AC settings
        final acSettings = ref.watch(acSettingsProvider);
        
        // Temperature control for AC
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Temperature Control', 
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontSize: 20.0,
              ),
            ),
            SizedBox(height: 4),
            
            // Temperature display and controls
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Temperature display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: Colors.white, size: 28),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: acSettings.temperature > 16 ? () {
                          ref.read(acSettingsProvider.notifier).state = 
                            acSettings.copyWith(temperature: acSettings.temperature - 1);
                        } : null,
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${acSettings.temperature}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 2),
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '°C',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: acSettings.temperature < 30 ? () {
                          ref.read(acSettingsProvider.notifier).state = 
                            acSettings.copyWith(temperature: acSettings.temperature + 1);
                        } : null,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Temperature range indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('16°C', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                      Expanded(
                        child: _ResponsiveSlider(
                          initialValue: acSettings.temperature.toDouble(),
                          min: 16,
                          max: 30,
                          divisions: 14,
                          labelGenerator: (value) => '${value.toInt()}°C',
                          onChangeEnd: (value) {
                            // Update provider state and save only when sliding ends
                            ref.read(acSettingsProvider.notifier).state = 
                              acSettings.copyWith(temperature: value.toInt());
                            _saveDeviceControlValue(ref, value.toInt());
                          },
                        ),
                      ),
                      Text('30°C', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                    ],
                  ),
                ],
              ),
            ),
            
            HomeAutomationStyles.smallVGap,
            
            // Fan speed and additional controls
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fan Speed', style: TextStyle(color: Colors.white, fontSize: 16)),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        height: 48,
                        child: DropdownButton<String>(
                          value: acSettings.fanSpeed,
                          isExpanded: true,
                          dropdownColor: Color(0xFF1B3425),
                          itemHeight: 50,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                          icon: Icon(Icons.arrow_drop_down, color: Colors.white, size: 28),
                          underline: SizedBox(),
                          isDense: false,
                          menuMaxHeight: 200,
                          onChanged: (value) {
                            if (value != null) {
                              ref.read(acSettingsProvider.notifier).state = 
                                acSettings.copyWith(fanSpeed: value);
                            }
                          },
                          items: ['Auto', 'Low', 'Medium', 'High', 'Turbo'].map((speed) {
                            return DropdownMenuItem<String>(
                              value: speed,
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  speed,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: speed == acSettings.fanSpeed ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          selectedItemBuilder: (BuildContext context) {
                            return ['Auto', 'Low', 'Medium', 'High', 'Turbo'].map<Widget>((String item) {
                              return Container(
                                alignment: Alignment.centerLeft,
                                constraints: const BoxConstraints(minWidth: 100),
                                child: Text(
                                  item,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                // Swing toggle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Swing', style: TextStyle(color: Colors.white, fontSize: 16)),
                      SizedBox(height: 4),
                      InkWell(
                        onTap: () {
                          ref.read(acSettingsProvider.notifier).state = 
                            acSettings.copyWith(swing: !acSettings.swing);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: acSettings.swing ? Colors.green.withOpacity(0.6) : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          height: 48,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                acSettings.swing ? Icons.waves : Icons.waves_outlined, 
                                color: Colors.white
                              ),
                              SizedBox(width: 8),
                              Text(
                                acSettings.swing ? 'ON' : 'OFF', 
                                style: TextStyle(color: Colors.white)
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            HomeAutomationStyles.smallVGap,
            
            // Mode buttons
            Text('Mode', 
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontSize: 20.0,
              ),
            ),
            SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildModeButton(
                    context, 
                    ref, 
                    'Cool', 
                    Icons.ac_unit, 
                    colorScheme,
                    isSelected: acSettings.mode == 'Cool',
                    onTap: () => ref.read(acSettingsProvider.notifier).state = 
                      acSettings.copyWith(mode: 'Cool')
                  ),
                  _buildModeButton(
                    context, 
                    ref, 
                    'Fan', 
                    Icons.wind_power, 
                    colorScheme,
                    isSelected: acSettings.mode == 'Fan',
                    onTap: () => ref.read(acSettingsProvider.notifier).state = 
                      acSettings.copyWith(mode: 'Fan')
                  ),
                  _buildModeButton(
                    context, 
                    ref, 
                    'Heat', 
                    Icons.whatshot, 
                    colorScheme,
                    isSelected: acSettings.mode == 'Heat',
                    onTap: () => ref.read(acSettingsProvider.notifier).state = 
                      acSettings.copyWith(mode: 'Heat')
                  ),
                  _buildModeButton(
                    context, 
                    ref, 
                    'Auto', 
                    Icons.auto_mode, 
                    colorScheme,
                    isSelected: acSettings.mode == 'Auto',
                    onTap: () => ref.read(acSettingsProvider.notifier).state = 
                      acSettings.copyWith(mode: 'Auto')
                  ),
                  _buildModeButton(
                    context, 
                    ref, 
                    'Dry', 
                    Icons.water_drop, 
                    colorScheme,
                    isSelected: acSettings.mode == 'Dry',
                    onTap: () => ref.read(acSettingsProvider.notifier).state = 
                      acSettings.copyWith(mode: 'Dry')
                  ),
                ],
              ),
            ),
          ],
        );

      case FlickyAnimatedIconOptions.fan:
        // Speed control for fan
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fan Speed', 
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontSize: 20.0,
              ),
            ),
            HomeAutomationStyles.smallVGap,
            _ResponsiveSlider(
              initialValue: controlValue.toDouble(),
              min: 0,
              max: 5,
              divisions: 5,
              labelGenerator: (value) => _getFanSpeedLabel(value.toInt()),
              onChangeEnd: (value) {
                // Update state provider and save device when sliding ends
                ref.read(controlValueProvider.notifier).state = value.toInt();
                _saveDeviceControlValue(ref, value.toInt());
              },
            ),
            Center(
              child: Text(
                _getFanSpeedLabel(controlValue),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 18.0,
                ),
              ),
            ),
            HomeAutomationStyles.smallVGap,
            // Fan mode options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAnimatedFanModeButton(
                  context, 
                  ref, 
                  'Normal', 
                  Icons.air_rounded, 
                  colorScheme,
                  isSelected: selectedFanMode == 'Normal',
                  onTap: () => ref.read(fanModeProvider.notifier).state = 'Normal'
                ),
                _buildAnimatedFanModeButton(
                  context, 
                  ref, 
                  'Natural', 
                  Icons.waves, 
                  colorScheme,
                  isSelected: selectedFanMode == 'Natural',
                  onTap: () => ref.read(fanModeProvider.notifier).state = 'Natural'
                ),
                _buildAnimatedFanModeButton(
                  context, 
                  ref, 
                  'Sleep', 
                  Icons.nightlight_rounded, 
                  colorScheme,
                  isSelected: selectedFanMode == 'Sleep',
                  onTap: () => ref.read(fanModeProvider.notifier).state = 'Sleep'
                ),
              ],
            ),
          ],
        );

      case FlickyAnimatedIconOptions.lightbulb:
      case FlickyAnimatedIconOptions.lamp:
      case FlickyAnimatedIconOptions.flickybulb:
        // Brightness control for lights
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Brightness', 
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontSize: 20.0,
              ),
            ),
            HomeAutomationStyles.smallVGap,
            Row(
              children: [
                Icon(Icons.brightness_low, color: Colors.white),
                Expanded(
                  child: _ResponsiveSlider(
                    initialValue: controlValue.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    labelGenerator: (value) => '${value.toInt()}%',
                    onChangeEnd: (value) {
                      // Update state provider and save device when sliding ends
                      ref.read(controlValueProvider.notifier).state = value.toInt();
                      _saveDeviceControlValue(ref, value.toInt());
                    },
                  ),
                ),
                Icon(Icons.brightness_high, color: Colors.white),
              ],
            ),
            HomeAutomationStyles.smallVGap,
            // Light presets
            Text('Presets', 
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontSize: 20.0,
              ),
            ),
            HomeAutomationStyles.smallVGap,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPresetButton(context, ref, 'Day', 80, colorScheme, isSelected: controlValue == 80),
                _buildPresetButton(context, ref, 'Evening', 50, colorScheme, isSelected: controlValue == 50),
                _buildPresetButton(context, ref, 'Night', 20, colorScheme, isSelected: controlValue == 20),
              ],
            ),
          ],
        );
        
      case FlickyAnimatedIconOptions.hairdryer:
        // Control for common electrical devices (instead of just hairdryer)
        // Ensure controlValue is within valid range for the slider
        final powerValue = controlValue < 1 ? 1 : controlValue > 5 ? 5 : controlValue;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Power Mode', 
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontSize: 20.0,
              ),
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildHeatLevelButton(context, ref, 'Economy', 1, controlValue, colorScheme),
                _buildHeatLevelButton(context, ref, 'Standard', 2, controlValue, colorScheme),
                _buildHeatLevelButton(context, ref, 'High Power', 3, controlValue, colorScheme),
              ],
            ),
            SizedBox(height: 8),
            Text('Intensity', 
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontSize: 20.0,
              ),
            ),
            SizedBox(height: 4),
            _ResponsiveSlider(
              initialValue: powerValue.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              labelGenerator: (value) => '${(value * 20).toInt()}%',
              onChangeEnd: (value) {
                // Update state provider and save device when sliding ends
                ref.read(controlValueProvider.notifier).state = value.toInt();
                _saveDeviceControlValue(ref, value.toInt());
              },
            ),
            SizedBox(height: 8),
            Text('Timer', 
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontSize: 20.0,
              ),
            ),
            SizedBox(height: 4),
            // Timer status display
            if (selectedTimer != null)
              _buildTimerDisplay(context, ref),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTimerButton(
                  context, 
                  ref, 
                  '30m', 
                  colorScheme, 
                  isSelected: selectedTimer == '30m',
                  onTap: () => _startTimer(ref, '30m', 30 * 60) // 30 minutes in seconds
                ),
                _buildTimerButton(
                  context, 
                  ref, 
                  '1h', 
                  colorScheme, 
                  isSelected: selectedTimer == '1h',
                  onTap: () => _startTimer(ref, '1h', 60 * 60) // 1 hour in seconds
                ),
                _buildTimerButton(
                  context, 
                  ref, 
                  '2h', 
                  colorScheme, 
                  isSelected: selectedTimer == '2h',
                  onTap: () => _startTimer(ref, '2h', 2 * 60 * 60) // 2 hours in seconds
                ),
                _buildTimerButton(
                  context, 
                  ref, 
                  'Custom', 
                  colorScheme, 
                  isSelected: selectedTimer == 'Custom',
                  onTap: () => _showCustomTimerDialog(context, ref)
                ),
              ],
            ),
          ],
        );
        
      default:
        // Generic controls for other devices
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Power Level', 
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontSize: 20.0,
              ),
            ),
            HomeAutomationStyles.smallVGap,
            // Energy level options
            Text('Energy Mode', 
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontSize: 16.0,
              ),
            ),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEnergyLevelButton(context, ref, 'Eco', 1, controlValue, controlValueProvider),
                _buildEnergyLevelButton(context, ref, 'Normal', 5, controlValue, controlValueProvider),
                _buildEnergyLevelButton(context, ref, 'High', 8, controlValue, controlValueProvider),
                _buildEnergyLevelButton(context, ref, 'Max', 10, controlValue, controlValueProvider),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fine Adjustment', 
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 16.0,
                  ),
                ),
                Text('${controlValue >= 1 ? (controlValue * 10).toInt() : 10}%', 
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            _ResponsiveSlider(
              initialValue: controlValue > 0 ? controlValue.toDouble() : 1.0,
              min: 1,
              max: 10,
              divisions: 9,
              labelGenerator: (value) => '${(value * 10).toInt()}%',
              onChangeEnd: (value) {
                // Update state provider and save to device when sliding ends
                ref.read(controlValueProvider.notifier).state = value.toInt();
                _saveDeviceControlValue(ref, value.toInt());
              },
            ),
          ],
        );
    }
  }
  
  String _getFanSpeedLabel(int speed) {
    switch (speed) {
      case 0: return 'Off';
      case 1: return 'Very Low';
      case 2: return 'Low';
      case 3: return 'Medium';
      case 4: return 'High';
      case 5: return 'Turbo';
      default: return 'Unknown';
    }
  }
  
  void _saveDeviceControlValue(WidgetRef ref, int newValue) {
    // Use the DeviceToggleViewModel to update the control value
    try {
      ref.read(deviceToggleVMProvider.notifier).updateDeviceControlValue(device, newValue);
    } catch (e) {
      print("Error updating device control value: $e");
      // Show error message
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Text('Error updating device: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  Widget _buildModeButton(BuildContext context, WidgetRef ref, String label, IconData icon, ColorScheme colorScheme, {bool isSelected = false, VoidCallback? onTap}) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          shape: CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (onTap != null) {
                onTap();
              }
              
              // Show feedback message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label mode selected'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            splashColor: Colors.greenAccent.withOpacity(0.5),
            highlightColor: Colors.green.withOpacity(0.3),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected 
                    ? [Colors.green.withOpacity(0.7), Colors.green.withOpacity(0.9)]
                    : [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: isSelected
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
              ),
              width: 52,
              height: 52,
              child: Center(
                child: AnimatedRotation(
                  duration: Duration(seconds: 2),
                  turns: label == 'Normal' || label == 'Fan' ? 1 : 0,
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white, 
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 14.0,
        )),
      ],
    );
  }
  
  Widget _buildPresetButton(BuildContext context, WidgetRef ref, String label, int value, ColorScheme colorScheme, {bool isSelected = false}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Colors.white.withOpacity(0.2),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.1), 
            width: isSelected ? 2 : 1,
          ),
        ),
        elevation: isSelected ? 5 : 3,
        shadowColor: Colors.black.withOpacity(0.3),
        textStyle: TextStyle(
          fontSize: 16.0, 
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      onPressed: () {
        ref.read(StateProvider<int>((ref) => device.outlet).notifier).state = value;
        _saveDeviceControlValue(ref, value);
      },
      child: Text(label),
    );
  }
  
  Widget _buildHeatLevelButton(BuildContext context, WidgetRef ref, String label, int value, int currentValue, ColorScheme colorScheme) {
    final isSelected = value == currentValue;
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green : Colors.white.withOpacity(0.2),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: BorderSide(
              color: isSelected ? Colors.greenAccent.withOpacity(0.5) : Colors.white.withOpacity(0.1),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          elevation: isSelected ? 5 : 3,
          shadowColor: Colors.black.withOpacity(0.3),
          textStyle: TextStyle(fontSize: 16.0, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
        ),
        onPressed: () {
          ref.read(StateProvider<int>((ref) => device.outlet).notifier).state = value;
          _saveDeviceControlValue(ref, value);
        },
        child: Text(label),
      ),
    );
  }
  
  Widget _buildTimerButton(BuildContext context, WidgetRef ref, String label, ColorScheme colorScheme, {bool isSelected = false, VoidCallback? onTap}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : Colors.white.withOpacity(0.2),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.1), 
            width: isSelected ? 2 : 1,
          ),
        ),
        elevation: isSelected ? 5 : 3,
        shadowColor: Colors.black.withOpacity(0.3),
        textStyle: TextStyle(
          fontSize: 16.0, 
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      onPressed: () {
        if (onTap != null) {
          onTap();
        }
          
        // Handle timer selection
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label timer set'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Text(label),
    );
  }

  Widget _buildAnimatedFanModeButton(BuildContext context, WidgetRef ref, String label, IconData icon, ColorScheme colorScheme, {bool isSelected = false, VoidCallback? onTap}) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          shape: CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              if (onTap != null) {
                onTap();
              }
              
              // Handle mode selection
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label mode selected'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            splashColor: Colors.greenAccent.withOpacity(0.5),
            highlightColor: Colors.green.withOpacity(0.3),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected 
                    ? [Colors.green.withOpacity(0.7), Colors.green.withOpacity(0.9)]
                    : [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: isSelected
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
              ),
              width: 64,
              height: 64,
              child: Center(
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 32,
                    key: ValueKey(icon),
                  ),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white, 
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 16.0,
        )),
      ],
    );
  }

  // Helper method to start a timer
  void _startTimer(WidgetRef ref, String label, int seconds) {
    // Store the current time and duration
    ref.read(timerProvider.notifier).state = label;
    ref.read(timerDurationProvider.notifier).state = seconds;
    ref.read(timerStartTimeProvider.notifier).state = DateTime.now();
    ref.read(timerRemainingProvider.notifier).state = seconds;
    ref.read(timerActiveProvider.notifier).state = true;
    
    ScaffoldMessenger.of(ref.context).showSnackBar(
      SnackBar(
        content: Text('$label timer started'),
        duration: Duration(seconds: 1),
      ),
    );
  }
  
  // Helper method to show custom timer dialog
  void _showCustomTimerDialog(BuildContext context, WidgetRef ref) {
    int hours = 0;
    int minutes = 15;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Set Custom Timer'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Hours: $hours', style: TextStyle(fontSize: 16)),
                  Slider(
                    value: hours.toDouble(),
                    min: 0,
                    max: 12,
                    divisions: 12,
                    label: '$hours',
                    onChanged: (value) {
                      setState(() {
                        hours = value.toInt();
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  Text('Minutes: $minutes', style: TextStyle(fontSize: 16)),
                  Slider(
                    value: minutes.toDouble(),
                    min: 0,
                    max: 59,
                    divisions: 59,
                    label: '$minutes',
                    onChanged: (value) {
                      setState(() {
                        minutes = value.toInt();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final totalSeconds = (hours * 60 * 60) + (minutes * 60);
                    if (totalSeconds > 0) {
                      _startTimer(ref, 'Custom', totalSeconds);
                    }
                    Navigator.pop(context);
                  },
                  child: Text('Start'),
                ),
              ],
            );
          }
        );
      },
    );
  }
  
  // Helper method to reset the timer
  void _resetTimer(WidgetRef ref) {
    ref.read(timerProvider.notifier).state = null;
    ref.read(timerRemainingProvider.notifier).state = null;
    ref.read(timerStartTimeProvider.notifier).state = null;
    ref.read(timerDurationProvider.notifier).state = 0;
    ref.read(timerActiveProvider.notifier).state = false;
    
    ScaffoldMessenger.of(ref.context).showSnackBar(
      SnackBar(
        content: Text('Timer reset'),
        duration: Duration(seconds: 1),
      ),
    );
  }
  
  // Method to build timer display
  Widget _buildTimerDisplay(BuildContext context, WidgetRef ref) {
    final startTime = ref.watch(timerStartTimeProvider);
    final timerDuration = ref.watch(timerDurationProvider);
    final isActive = ref.watch(timerActiveProvider);
    final selectedTimer = ref.watch(timerProvider);
    
    if (startTime == null || !isActive || timerDuration <= 0) {
      return Container(); // Return empty container if no timer is active
    }
    
    // Calculate initial remaining time
    final now = DateTime.now();
    final elapsedSeconds = now.difference(startTime).inSeconds;
    final initialRemainingSeconds = timerDuration - elapsedSeconds;
    
    if (initialRemainingSeconds <= 0) {
      // Schedule a callback to reset the timer state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isActive) {
          _resetTimer(ref);
          // Show notification that timer has finished
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Timer finished!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
      return Container(); // Return empty until reset in next frame
    }
    
    return _TimerDisplayWidget(
      startTime: startTime,
      totalDuration: timerDuration,
      onTimerFinished: () => _resetTimer(ref),
    );
  }

  // Helper method for energy level selection buttons
  Widget _buildEnergyLevelButton(BuildContext context, WidgetRef ref, String label, int value, int currentValue, StateProvider<int> valueProvider) {
    // Determine if this button represents the current value or a value close to it
    final isSelected = value == currentValue;
    final isApproximate = (value - 1 <= currentValue && currentValue <= value + 1) && !isSelected;
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.green : 
                       isApproximate ? Colors.green.withOpacity(0.3) : 
                       Colors.white.withOpacity(0.2),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(
            color: isSelected ? Colors.white : 
                   isApproximate ? Colors.green.withOpacity(0.5) : 
                   Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        elevation: isSelected ? 5 : 3,
        shadowColor: Colors.black.withOpacity(0.3),
        textStyle: TextStyle(
          fontSize: 15.0, 
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      onPressed: () {
        ref.read(valueProvider.notifier).state = value;
        _saveDeviceControlValue(ref, value);
        
        // Show feedback message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label mode selected (${value * 10}%)'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Text(label),
    );
  }

  // Responsive slider that only updates local state during sliding
  Widget _ResponsiveSlider({
    required double initialValue,
    required double min,
    required double max,
    required int divisions,
    required String Function(double) labelGenerator,
    required Function(double) onChangeEnd,
  }) {
    return _ResponsiveSliderWidget(
      initialValue: initialValue,
      min: min,
      max: max,
      divisions: divisions,
      labelGenerator: labelGenerator,
      onChangeEnd: onChangeEnd,
    );
  }
}

// Stateful widget for responsive slider
class _ResponsiveSliderWidget extends StatefulWidget {
  final double initialValue;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) labelGenerator;
  final Function(double) onChangeEnd;
  
  const _ResponsiveSliderWidget({
    required this.initialValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.labelGenerator,
    required this.onChangeEnd,
  });
  
  @override
  State<_ResponsiveSliderWidget> createState() => _ResponsiveSliderWidgetState();
}

class _ResponsiveSliderWidgetState extends State<_ResponsiveSliderWidget> {
  late double currentValue;
  
  @override
  void initState() {
    super.initState();
    currentValue = widget.initialValue;
  }
  
  @override
  void didUpdateWidget(_ResponsiveSliderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update currentValue if the initialValue changes from outside
    if (oldWidget.initialValue != widget.initialValue) {
      setState(() {
        currentValue = widget.initialValue;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: Colors.green,
        inactiveTrackColor: Colors.white.withOpacity(0.3),
        thumbColor: Colors.white,
        overlayColor: Colors.white.withOpacity(0.2),
        trackHeight: 6.0,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 24.0),
        tickMarkShape: SliderTickMarkShape.noTickMark,
        showValueIndicator: ShowValueIndicator.always,
      ),
      child: Slider(
        value: currentValue,
        min: widget.min,
        max: widget.max,
        divisions: widget.divisions,
        label: widget.labelGenerator(currentValue),
        onChanged: (value) {
          // Only update local state for smooth sliding
          setState(() {
            currentValue = value;
          });
        },
        onChangeEnd: (value) {
          // Only call the callback when sliding ends
          widget.onChangeEnd(value);
        },
      ),
    );
  }
}

// Separate stateful widget for timer display to handle its own updates
class _TimerDisplayWidget extends StatefulWidget {
  final DateTime startTime;
  final int totalDuration;
  final VoidCallback onTimerFinished;
  
  const _TimerDisplayWidget({
    required this.startTime,
    required this.totalDuration,
    required this.onTimerFinished,
  });

  @override
  State<_TimerDisplayWidget> createState() => _TimerDisplayWidgetState();
}

class _TimerDisplayWidgetState extends State<_TimerDisplayWidget> {
  Timer? _timer;
  late int _remainingSeconds;
  
  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  void _calculateRemainingTime() {
    final now = DateTime.now();
    final elapsedSeconds = now.difference(widget.startTime).inSeconds;
    _remainingSeconds = widget.totalDuration - elapsedSeconds;
    
    if (_remainingSeconds <= 0) {
      _remainingSeconds = 0;
      widget.onTimerFinished();
    }
  }
  
  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateRemainingTime();
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Format the remaining time
    final hours = _remainingSeconds ~/ 3600;
    final minutes = (_remainingSeconds % 3600) ~/ 60;
    final seconds = _remainingSeconds % 60;
    
    String timeDisplay = '';
    if (hours > 0) {
      timeDisplay = '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      timeDisplay = '${minutes}m ${seconds}s';
    } else {
      timeDisplay = '${seconds}s';
    }
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Time Remaining:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh, size: 18),
                label: Text('Reset'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.7),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size(80, 36),
                ),
                onPressed: widget.onTimerFinished,
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer, color: Colors.white),
              SizedBox(width: 8),
              Text(
                timeDisplay,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          LinearProgressIndicator(
            value: _remainingSeconds / widget.totalDuration,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ],
      ),
    );
  }
}