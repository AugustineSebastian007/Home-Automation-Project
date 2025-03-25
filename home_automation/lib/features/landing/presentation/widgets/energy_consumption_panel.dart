import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/landing/presentation/providers/landing_providers.dart';
import 'package:home_automation/features/landing/presentation/widgets/energy_consumption_column.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:intl/intl.dart';
import 'package:home_automation/features/landing/data/models/energy_consumption_value.dart';

class EnergyConsumptionPanel extends ConsumerWidget {
  const EnergyConsumptionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final energyConsumptionAsync = ref.watch(energyConsumptionProvider);
    final energySavingModeAsync = ref.watch(energySavingModeProvider);

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
            child: Row(
              children: [
                Icon(Icons.energy_savings_leaf,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('My Energy Consumption (kW)',
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  )
                ),
                const Spacer(),
                energySavingModeAsync.when(
                  data: (isEnabled) => Row(
                    children: [
                      Text(
                        'Energy Saving',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Switch(
                        value: isEnabled,
                        onChanged: (value) {
                          try {
                            ref.read(toggleEnergySavingModeProvider(value));
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to toggle energy saving mode: $e'),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (error, __) => Row(
                    children: [
                      Text(
                        'Energy Saving',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                        onPressed: () => ref.invalidate(energySavingModeProvider),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Active devices count
          energyConsumptionAsync.when(
            data: (energy) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.devices,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Devices: ${energy.activeDevicesCount} active / ${energy.totalDevicesCount} total',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.refresh,
                      color: Theme.of(context).colorScheme.primary,
                      size: 18,
                    ),
                    onPressed: () => ref.invalidate(energyConsumptionProvider),
                  ),
                ],
              ),
            ),
            loading: () => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                children: [
                  const SizedBox(
                    height: 16, 
                    width: 16, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Updating device data...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Error loading devices',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => ref.invalidate(energyConsumptionProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          
          // Energy consumption summary
          energyConsumptionAsync.when(
            data: (energy) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem(
                    context, 
                    'Total', 
                    '${energy.totalConsumption.toStringAsFixed(1)} kW'
                  ),
                  _buildSummaryItem(
                    context, 
                    'Peak', 
                    '${energy.peakConsumption.toStringAsFixed(1)} kW'
                  ),
                  _buildSummaryItem(
                    context, 
                    'Average', 
                    '${energy.averageConsumption.toStringAsFixed(1)} kW'
                  ),
                ],
              ),
            ),
            loading: () => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem(context, 'Total', '…'),
                  _buildSummaryItem(context, 'Peak', '…'),
                  _buildSummaryItem(context, 'Average', '…'),
                ],
              ),
            ),
            error: (error, stack) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSummaryItem(context, 'Total', '0.0 kW'),
                  _buildSummaryItem(context, 'Peak', '0.0 kW'),
                  _buildSummaryItem(context, 'Average', '0.0 kW'),
                ],
              ),
            ),
          ),
          
          // Daily consumption title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Weekly Energy Usage',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const Spacer(),
                energyConsumptionAsync.when(
                  data: (energy) {
                    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                    final todayConsumption = energy.dailyConsumption[todayStr] ?? 0.0;
                    return Text(
                      'Today: ${todayConsumption.toStringAsFixed(1)} kW',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: todayConsumption > 50 
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.secondary,
                      ),
                    );
                  },
                  loading: () => const Text('Loading...'),
                  error: (_, __) => const Text('--'),
                ),
              ],
            ),
          ),
          
          // Energy consumption chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: energyConsumptionAsync.when(
                data: (energyConsumption) {
                  if (energyConsumption.values?.isEmpty ?? true) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('No energy data available'),
                          const SizedBox(height: 2),
                          ElevatedButton(
                            onPressed: () => ref.invalidate(energyConsumptionProvider),
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  // Extract information about device active hours
                  final deviceRuntime = <String, double>{};
                  final deviceConsumption = <String, double>{};
                  final weeklyData = <String, List<EnergyConsumptionValue>>{};
                  
                  // Group values by day of week for the weekly view
                  for (final value in energyConsumption.values ?? []) {
                    if (value.deviceId != null && value.deviceName != null) {
                      deviceRuntime[value.deviceName!] = (deviceRuntime[value.deviceName!] ?? 0) + (value.hoursActive ?? 0);
                      deviceConsumption[value.deviceName!] = (deviceConsumption[value.deviceName!] ?? 0) + (value.value ?? 0);
                    }
                    
                    // Group by day for the weekly chart
                    final day = value.day ?? '';
                    if (!weeklyData.containsKey(day)) {
                      weeklyData[day] = [];
                    }
                    weeklyData[day]!.add(value);
                  }
                  
                  // Convert to display format - combine all device values for each day
                  final displayValues = <EnergyConsumptionValue>[];
                  
                  weeklyData.forEach((day, values) {
                    // Sum values for the day
                    double totalForDay = 0;
                    for (var value in values) {
                      totalForDay += value.value ?? 0;
                    }
                    
                    // Create day entry with null safety
                    if (values.isNotEmpty && values.first.timestamp != null) {
                      displayValues.add(EnergyConsumptionValue(
                        day: day,
                        value: totalForDay,
                        aboveThreshold: totalForDay > 10,
                        timestamp: values.first.timestamp,
                      ));
                    }
                  });
                  
                  // Sort by timestamp with null safety
                  displayValues.sort((a, b) => 
                    (a.timestamp ?? DateTime.now()).compareTo(b.timestamp ?? DateTime.now())
                  );
                  
                  // Sort devices by runtime
                  final sortedDevices = deviceRuntime.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  
                  return Column(
                    children: [
                      // Display top active devices if available
                      if (sortedDevices.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Most Active Devices',
                                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Show top 2 most active devices
                              for (int i = 0; i < sortedDevices.length && i < 2; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${sortedDevices[i].key}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${sortedDevices[i].value.toStringAsFixed(1)} hrs | ${deviceConsumption[sortedDevices[i].key]?.toStringAsFixed(2) ?? "0"} kW',
                                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      
                      // Chart
                      Expanded(
                        child: displayValues.isEmpty
                          ? Center(child: Text('No weekly data available'))
                          : LayoutBuilder(
                        builder: (context, constraints) {
                          return ListView.builder(
                            padding: const EdgeInsets.only(left: 16),
                            scrollDirection: Axis.horizontal,
                                    itemCount: displayValues.length,
                            itemBuilder: (context, index) {
                              return SizedBox(
                                        width: constraints.maxWidth / 5, // Show 5 columns at a time (weekly data)
                                child: ConsumptionColumn(
                                          consumption: displayValues[index]
                                ),
                              );
                            },
                          );
                        }
                          ),
                      ),
                    ],
                  );
                },
                loading: () => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        height: 32,
                        width: 32,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Calculating energy consumption...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 32,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load energy data',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (error != null) 
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                          child: Text(
                            error.toString().length > 100 
                                ? '${error.toString().substring(0, 100)}...' 
                                : error.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => ref.invalidate(energyConsumptionProvider),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Energy saving recommendations
          energySavingModeAsync.when(
            data: (isEnabled) => isEnabled ? _buildEnergySavingRecommendations(context, ref) : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEnergySavingRecommendations(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      padding: const EdgeInsets.all(8),
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
                Icons.tips_and_updates,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Energy Saving Tips',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '• Turn off devices when not in use',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            '• Consider replacing high-consumption devices',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            '• Avoid running devices for extended periods',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String title, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}