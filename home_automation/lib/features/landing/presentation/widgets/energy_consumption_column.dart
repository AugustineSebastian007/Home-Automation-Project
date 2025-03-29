import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:home_automation/features/landing/data/models/energy_consumption_value.dart';
import 'dart:math' as Math;

class ConsumptionColumn extends StatelessWidget {

  final EnergyConsumptionValue consumption;
  const ConsumptionColumn({Key? key, required this.consumption }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasDeviceInfo = consumption.deviceId != null && consumption.deviceName != null;
    final value = consumption.value ?? 0.0;
    // Ensure we have a minimum display height even for very small values
    final displayValue = value < 0.1 ? 0.1 : value;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Tooltip(
            message: hasDeviceInfo 
              ? 'Device: ${consumption.deviceName}\n'
                'Value: ${value.toStringAsFixed(2)} kW\n'
                'Hours active: ${consumption.hoursActive?.toStringAsFixed(1) ?? "Unknown"}'
              : 'Value: ${value.toStringAsFixed(2)} kW',
            child: Container(
              margin: const EdgeInsets.all(10),
              width: 35,
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(50)
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate height as percentage of available space with minimum size
                  // Use logarithmic scale for better visualization of different values
                  final double heightPercentage = value <= 0.0 
                    ? 0.0 
                    : (0.05 + (Math.log(1 + displayValue) / Math.log(100))) * 1.0;
                  final double columnHeight = heightPercentage * constraints.maxHeight;
                  
                  return Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(top: 10),
                        width: constraints.maxWidth,
                        height: columnHeight.clamp(5.0, constraints.maxHeight), // Min height of 5
                        decoration: BoxDecoration(
                          color: consumption.aboveThreshold! ? 
                            Theme.of(context).colorScheme.primary.withOpacity(0.5) :
                              Theme.of(context).colorScheme.tertiary,
                          borderRadius: BorderRadius.circular(50)
                        ),
                        child: Text(
                          value < 0.1 ? '${value.toStringAsFixed(2)}' : '${value.toStringAsFixed(1)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12
                          )
                        ),
                      ).animate().scaleY(
                        alignment: Alignment.bottomCenter,
                        begin: 0.5, end: 1,
                        duration: 0.5.seconds,
                        curve: Curves.easeInOut,
                      ).fadeIn(
                        duration: 0.5.seconds,
                        curve: Curves.easeInOut,
                      ),
                      
                      // Device indicator dot if this is for a specific device
                      if (hasDeviceInfo)
                        Positioned(
                          top: 5,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                }
              ),
            ),
          ),
        ),
        Text(consumption.day!,
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Show first letter of device name if available
        if (hasDeviceInfo)
          Text(
            consumption.deviceName!.substring(0, 1),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
      ].animate(
        interval: 250.ms,
      ).scaleXY(
        alignment: Alignment.bottomCenter,
        begin: 0.5, end: 1,
        duration: 0.5.seconds,
        curve: Curves.easeInOut,
      ).fadeIn(
        duration: 0.5.seconds,
        curve: Curves.easeInOut,
      )
    );
  }
}