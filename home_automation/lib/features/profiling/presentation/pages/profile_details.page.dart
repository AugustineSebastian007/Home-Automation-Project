import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/profiling/presentation/providers/profile_providers.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation/features/devices/presentation/providers/rtdb_device_providers.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/devices/data/models/rtdb_device.model.dart';
import 'package:home_automation/features/navigation/providers/navigation_providers.dart';
import 'package:home_automation/features/landing/presentation/responsiveness/landing_page_responsive.config.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/landing/presentation/pages/home.page.dart';
import 'package:home_automation/features/rooms/presentation/pages/rooms.page.dart';
import 'package:home_automation/features/camera/presentation/pages/camera_footage.page.dart';
import 'package:home_automation/features/profiling/presentation/pages/profiling.page.dart';
import 'package:home_automation/features/settings/presentation/pages/settings.page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:home_automation/features/landing/presentation/pages/auth_page.dart';

class ProfileDetailsPage extends ConsumerStatefulWidget {
  static const String route = '/profile-details/:id/:memberId';
  final String profileId;
  final String memberId;

  const ProfileDetailsPage({
    Key? key, 
    required this.profileId,
    required this.memberId,
  }) : super(key: key);

  @override
  ConsumerState<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends ConsumerState<ProfileDetailsPage> {
  @override
  void initState() {
    super.initState();
    // Schedule the invalidation for the next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(profileWithDevicesProvider);
        ref.read(selectedProfileIdProvider.notifier).state = widget.profileId;
        
        // Refresh RTDB devices when page opens
        ref.read(rtdbDevicesRefreshProvider.future);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(profileWithDevicesProvider((widget.memberId, widget.profileId)));
      ref.read(selectedProfileIdProvider.notifier).state = null;
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileWithDevicesAsyncValue = ref.watch(
      profileWithDevicesProvider((widget.memberId, widget.profileId))
    );
    final barItems = ref.watch(bottomBarVMProvider);
    final config = LandingPageResponsiveConfig.landingPageConfig(context);

    return Scaffold(
      body: SafeArea(
        child: profileWithDevicesAsyncValue.when(
          data: (data) {
            final (profile, profileDevices) = data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCustomHeader(context, profile.name),
                Padding(
                  padding: HomeAutomationStyles.mediumPadding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("All Devices", style: Theme.of(context).textTheme.titleMedium),
                      Container(
                        height: 44,
                        alignment: Alignment.center,
                        child: Switch(
                          value: profile.isActive,
                          onChanged: (value) {
                            _toggleAllDevices(context, ref, widget.profileId, value);
                          },
                          activeColor: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: profileDevices.isEmpty
                      ? Center(child: Text('No devices added to this profile'))
                      : ListView.builder(
                          itemCount: profileDevices.length,
                          padding: HomeAutomationStyles.mediumPadding,
                          itemBuilder: (context, index) {
                            final device = profileDevices[index];
                            return _buildDeviceItem(context, ref, device, index);
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDeviceDialog(context, ref, widget.profileId, widget.memberId),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Container(
        padding: HomeAutomationStyles.xsmallPadding,
        color: config.bottomBarBg,
        child: Flex(
          direction: config.bottomBarDirection,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: barItems.map((e) {
            return Container(
              margin: const EdgeInsets.only(bottom: HomeAutomationStyles.smallSize),
              child: IconButton(
                onPressed: () {
                  // Direct navigation using context instead of the tabNav
                  switch (e.route) {
                    case HomePage.route:
                      context.go(HomePage.route);
                      break;
                    case RoomsPage.route:
                      context.go(RoomsPage.route);
                      break;
                    case CameraFootagePage.route:
                      context.go(CameraFootagePage.route);
                      break;
                    case ProfilingPage.route:
                      context.go(ProfilingPage.route);
                      break;
                    case SettingsPage.route:
                      context.go(SettingsPage.route);
                      break;
                  }
                },
                icon: FlickyAnimatedIcons(
                  icon: e.iconOption,
                  isSelected: e.isSelected,
                )
              ),
            );
          }).toList()
          .animate(
            interval: 200.ms
          ).slideY(
            begin: 1, end: 0,
            duration: 0.5.seconds,
            curve: Curves.easeInOut
          ),
        ),
      ),
    );
  }

  Widget _buildCustomHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.only(
        top: 8.0,
        left: 8.0,
        right: 8.0,
        bottom: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status bar height row
          SizedBox(
            height: 4,
          ),
          // Top bar with icons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                iconSize: 24,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlickyAnimatedIcons(
                icon: FlickyAnimatedIconOptions.lightbulb,
                size: FlickyAnimatedIconSizes.small,
                isSelected: true,
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                iconSize: 24,
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  GoRouter.of(context).go(AuthPage.route);
                },
              ),
            ],
          ),
          SizedBox(height: 24),
          // Profile title section with FlickyAnimatedIcons
          Row(
            children: [
              FlickyAnimatedIcons(
                icon: FlickyAnimatedIconOptions.lightbulb,
                size: FlickyAnimatedIconSizes.large,
                isSelected: true,
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ).animate().fadeIn(
        duration: 0.5.seconds,
        curve: Curves.easeInOut
      ),
    );
  }

  Widget _buildDeviceItem(BuildContext context, WidgetRef ref, DeviceModel device, int index) {
    // Check if this is an RTDB device (based on id convention we established)
    final bool isRtdbDevice = device.id.startsWith('rtdb_');
    
    if (isRtdbDevice) {
      // For RTDB devices, use the RTDB stream provider
      final rtdbDeviceId = device.id.substring(5); // Remove 'rtdb_' prefix
      final rtdbDeviceAsync = ref.watch(rtdbDeviceStreamProvider(rtdbDeviceId));
      
      return rtdbDeviceAsync.when(
        data: (rtdbDevice) {
          if (rtdbDevice == null) {
            // Return a styled unavailable device card
            return _buildUnavailableDeviceCard(context, rtdbDeviceId, index);
          }
          return _buildRtdbDeviceCard(context, ref, rtdbDevice, index);
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildUnavailableDeviceCard(context, rtdbDeviceId, index),
      );
    } else {
      // For normal Firestore devices
      final deviceAsyncValue = ref.watch(deviceStreamProvider((roomId: device.roomId, outletId: device.outletId, deviceId: device.id)));
      
      return deviceAsyncValue.when(
        data: (updatedDevice) => _buildDeviceCard(context, ref, updatedDevice, index),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      );
    }
  }

  Widget _buildDeviceCard(BuildContext context, WidgetRef ref, DeviceModel device, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: HomeAutomationStyles.smallSize),
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
        color: colorScheme.secondary.withOpacity(0.15),
        child: InkWell(
          onTap: () => _toggleDevice(context, ref, device),
          splashColor: colorScheme.secondary.withOpacity(0.25),
          highlightColor: colorScheme.secondary.withOpacity(0.25),
          child: Padding(
            padding: HomeAutomationStyles.mediumPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FlickyAnimatedIcons(
                  icon: device.iconOption,
                  isSelected: device.isSelected,
                ),
                HomeAutomationStyles.smallHGap,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.label,
                        style: textTheme.labelMedium!.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Room: ${device.roomId.split('-').first} | ID: ${device.id.substring(0, 8)}...',
                        style: textTheme.bodySmall!.copyWith(
                          color: colorScheme.secondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Material(
                    color: colorScheme.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
                    child: InkWell(
                      onTap: () => _showRemoveDeviceConfirmation(context, ref, device),
                      borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
                      splashColor: colorScheme.error.withOpacity(0.2),
                      highlightColor: colorScheme.error.withOpacity(0.1),
                      child: Icon(
                        Icons.delete_rounded,
                        color: colorScheme.error,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 44,
                  alignment: Alignment.center,
                  child: Switch(
                    value: device.isSelected,
                    onChanged: (value) {
                      _toggleDevice(context, ref, device);
                    },
                    activeColor: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate(
        delay: (index * 0.125).seconds,
      ).slideY(
        begin: 0.5, end: 0,
        duration: 0.5.seconds,
        curve: Curves.easeInOut
      ).fadeIn(
        duration: 0.5.seconds,
        curve: Curves.easeInOut
      ),
    );
  }

  Widget _buildRtdbDeviceCard(BuildContext context, WidgetRef ref, RTDBDeviceModel device, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Extract room name from the device ID
    final parts = device.id.split('_');
    String roomName = '';
    if (parts.length > 2) {
      roomName = parts.sublist(1, parts.length - 1).join(' ');
      // Capitalize first letter
      if (roomName.isNotEmpty) {
        roomName = roomName[0].toUpperCase() + roomName.substring(1);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: HomeAutomationStyles.smallSize),
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
        color: colorScheme.secondary.withOpacity(0.15),
        child: InkWell(
          onTap: () {
            // Toggle the device on tap
            ref.read(rtdbDeviceToggleProvider.notifier)
                .toggleDevice(device);
          },
          splashColor: colorScheme.secondary.withOpacity(0.25),
          highlightColor: colorScheme.secondary.withOpacity(0.25),
          child: Padding(
            padding: HomeAutomationStyles.mediumPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FlickyAnimatedIcons(
                  icon: device.iconOption,
                  isSelected: device.isSelected,
                ),
                HomeAutomationStyles.smallHGap,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            device.label,
                            style: textTheme.labelMedium!.copyWith(
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 5),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'RTDB',
                              style: textTheme.bodySmall!.copyWith(
                                color: Colors.blue,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'In $roomName',
                              style: textTheme.bodySmall!.copyWith(
                                color: colorScheme.secondary.withOpacity(0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (device.deviceType == 'fan' && device.isSelected)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: EdgeInsets.only(left: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Speed: ${device.controlValue}',
                                style: textTheme.bodySmall!.copyWith(
                                  color: colorScheme.secondary,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 44,
                  alignment: Alignment.center,
                  child: Switch(
                    value: device.isSelected,
                    onChanged: (value) async {
                      try {
                        await ref.read(rtdbDeviceToggleProvider.notifier)
                            .setDeviceState(device, value);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to toggle device: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    activeColor: colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(
      delay: (index * 0.05).seconds,
    ).slideY(
      begin: 0.5, end: 0,
      duration: 0.5.seconds,
      curve: Curves.easeInOut
    ).fadeIn(
      duration: 0.5.seconds,
      curve: Curves.easeInOut
    );
  }

  void _toggleDevice(BuildContext context, WidgetRef ref, DeviceModel device) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Toggling ${device.label}...'),
        duration: Duration(seconds: 1),
      ),
    );
    ref.read(deviceToggleVMProvider.notifier).toggleDevice(device);
  }

  void _showRemoveDeviceConfirmation(BuildContext context, WidgetRef ref, DeviceModel device) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.delete_rounded,
              color: colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              'Remove Device',
              style: TextStyle(
                color: colorScheme.error,
              ),
            ),
          ],
        ),
        content: Text('Are you sure you want to remove "${device.label}" from this profile? The device will not be deleted from your home.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 16),
                        Text('Removing device...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
                
                // Get profile and remove device
                final profileData = await ref.read(
                  profileProvider((widget.memberId, widget.profileId)).future
                );
                
                // Create new profile with device removed
                List<String> updatedDeviceIds = List.from(profileData.deviceIds);
                updatedDeviceIds.remove(device.id);
                
                // Update profile
                await ref.read(profileRepositoryProvider).updateProfile(
                  widget.memberId, 
                  profileData.copyWith(deviceIds: updatedDeviceIds)
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Device "${device.label}" removed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove device: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _toggleAllDevices(BuildContext context, WidgetRef ref, String profileId, bool value) async {
    // Show initial loading snackbar
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars(); // Clear any existing snackbars
    
    final loadingSnackBar = SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: 16),
          Text('Toggling all devices...'),
        ],
      ),
      duration: Duration(seconds: 15), // Longer duration as we're processing
    );
    
    scaffoldMessenger.showSnackBar(loadingSnackBar);
    
    try {
      // Refresh RTDB devices first
      await ref.read(rtdbDevicesRefreshProvider.future);
      
      // Toggle all devices
      await ref.read(profileRepositoryProvider)
          .toggleAllDevicesInProfile(widget.memberId, profileId, value, ref);
      
      // Force refresh of devices in UI
      ref.invalidate(allDevicesStreamProvider);
      ref.invalidate(rtdbDevicesStreamProvider);
      
      // Re-fetch profile with devices
      await ref.refresh(profileWithDevicesProvider((widget.memberId, profileId))).value;
      
      if (context.mounted) {
        scaffoldMessenger.clearSnackBars();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('All devices ${value ? 'activated' : 'deactivated'} successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        scaffoldMessenger.clearSnackBars();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Some devices failed to toggle'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: () => _toggleAllDevices(context, ref, profileId, value),
            ),
          ),
        );
        
        // Force refresh again to get the current state
        ref.invalidate(allDevicesStreamProvider);
        ref.invalidate(rtdbDevicesStreamProvider);
        await ref.refresh(profileWithDevicesProvider((widget.memberId, profileId))).value;
      }
    }
  }

  void _showAddDeviceDialog(BuildContext context, WidgetRef ref, String profileId, String memberId) {
    // Refresh RTDB devices before showing the dialog
    ref.read(rtdbDevicesRefreshProvider.future);
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Device to Profile'),
          content: Container(
            width: double.maxFinite,
            child: _buildDeviceSelector(context, ref, profileId, memberId),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeviceSelector(BuildContext context, WidgetRef ref, String profileId, String memberId) {
    // Get both Firestore and RTDB devices
    final firestoreDevicesAsync = ref.watch(allDevicesStreamProvider);
    final rtdbDevicesAsync = ref.watch(rtdbDevicesStreamProvider);
    final profileAsync = ref.watch(profileProvider((memberId, profileId)));
    
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Firestore Devices', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 10),
          firestoreDevicesAsync.when(
            data: (devices) => profileAsync.when(
              data: (profile) {
                final availableDevices = devices.where(
                  (device) => !profile.deviceIds.contains(device.id)
                ).toList();
                
                if (availableDevices.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('No available Firestore devices'),
                  );
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: availableDevices.length,
                  itemBuilder: (context, index) {
                    final device = availableDevices[index];
                    return ListTile(
                      title: Text(device.label),
                      trailing: IconButton(
                        icon: Icon(Icons.add_circle),
                        onPressed: () async {
                          await ref.read(profileRepositoryProvider).addDeviceToProfile(
                            memberId,
                            profileId,
                            device.id,
                          );
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => CircularProgressIndicator(),
              error: (error, stackTrace) => Text('Error: $error'),
            ),
            loading: () => CircularProgressIndicator(),
            error: (error, stackTrace) => Text('Error: $error'),
          ),
          
          SizedBox(height: 20),
          Divider(),
          SizedBox(height: 10),
          
          Text('Realtime Database Devices', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 10),
          rtdbDevicesAsync.when(
            data: (rtdbDevices) => profileAsync.when(
              data: (profile) {
                // Convert RTDB devices to device IDs with prefix
                final rtdbDeviceIds = rtdbDevices.map((d) => 'rtdb_${d.id}').toList();
                
                // Filter out devices already in the profile
                final availableRtdbDevices = rtdbDevices.where(
                  (device) => !profile.deviceIds.contains('rtdb_${device.id}')
                ).toList();
                
                if (availableRtdbDevices.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('No available RTDB devices'),
                  );
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: availableRtdbDevices.length,
                  itemBuilder: (context, index) {
                    final device = availableRtdbDevices[index];
                    return ListTile(
                      title: Text(device.label),
                      subtitle: Text('Type: ${device.deviceType}'),
                      trailing: IconButton(
                        icon: Icon(Icons.add_circle),
                        onPressed: () async {
                          await ref.read(profileRepositoryProvider).addDeviceToProfile(
                            memberId,
                            profileId,
                            'rtdb_${device.id}', // Add with the rtdb_ prefix
                          );
                          
                          // Refresh RTDB devices after adding a device
                          await ref.read(rtdbDevicesRefreshProvider.future);
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => CircularProgressIndicator(),
              error: (error, stackTrace) => Text('Error: $error'),
            ),
            loading: () => CircularProgressIndicator(),
            error: (error, stackTrace) => Text('Error: $error'),
          ),
        ],
      ),
    );
  }

  // New method to display unavailable RTDB devices with a better UI
  Widget _buildUnavailableDeviceCard(BuildContext context, String deviceId, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // Extract device type and location from ID for better display
    final parts = deviceId.split('_');
    final deviceType = parts.isNotEmpty ? parts[0] : 'unknown';
    final roomName = parts.length > 1 ? parts[1].replaceAll('_', ' ') : '';
    
    // Choose icon based on device type
    final deviceIcon = deviceType == 'light' 
        ? FlickyAnimatedIconOptions.lightbulb 
        : deviceType == 'fan' 
            ? FlickyAnimatedIconOptions.fan 
            : FlickyAnimatedIconOptions.bolt;
            
    // Create a friendly name
    final deviceName = deviceType.substring(0, 1).toUpperCase() + deviceType.substring(1);
    final roomDisplay = roomName.isNotEmpty ? 'in $roomName' : '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: HomeAutomationStyles.smallSize),
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
        color: colorScheme.error.withOpacity(0.1),
        child: Padding(
          padding: HomeAutomationStyles.mediumPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FlickyAnimatedIcons(
                icon: deviceIcon,
                isSelected: false,
              ),
              HomeAutomationStyles.smallHGap,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$deviceName $roomDisplay',
                      style: textTheme.labelMedium!.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 12,
                          color: colorScheme.error,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Device unavailable',
                          style: textTheme.bodySmall!.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Row of action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Refresh button
                  IconButton(
                    icon: Icon(Icons.refresh, color: colorScheme.error),
                    tooltip: 'Refresh device',
                    onPressed: () async {
                      // Show refresh indicator
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 16),
                              Text('Refreshing devices...'),
                            ],
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      
                      // Do a complete refresh of RTDB devices
                      await ref.read(rtdbDevicesRefreshProvider.future);
                      
                      // Invalidate the specific device stream to force a re-fetch
                      ref.invalidate(rtdbDeviceStreamProvider(deviceId));
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).clearSnackBars();
                      }
                    },
                  ),
                  // Remove button
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    tooltip: 'Remove from profile',
                    onPressed: () {
                      _removeDeviceFromProfile(context, ref, 'rtdb_$deviceId');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate(
      delay: (index * 0.05).seconds,
    ).slideY(
      begin: 0.5, end: 0,
      duration: 0.5.seconds,
      curve: Curves.easeInOut
    ).fadeIn(
      duration: 0.5.seconds,
      curve: Curves.easeInOut
    );
  }

  // Method to remove a device from the profile
  void _removeDeviceFromProfile(BuildContext context, WidgetRef ref, String deviceId) {
    final colorScheme = Theme.of(context).colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Unavailable Device'),
        content: Text('Do you want to remove this unavailable device from the profile?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                // Show loading indicator
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 16),
                        Text('Removing device...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
                
                // Get current profile
                final profileData = await ref.read(
                  profileProvider((widget.memberId, widget.profileId)).future
                );
                
                // Create updated list without this device
                final updatedDeviceIds = List<String>.from(profileData.deviceIds)
                  ..remove(deviceId);
                
                // Update profile
                final updatedProfile = profileData.copyWith(
                  deviceIds: updatedDeviceIds,
                );
                
                await ref.read(profileRepositoryProvider)
                    .updateProfile(widget.memberId, updatedProfile);
                
                // Refresh RTDB devices after removing a device
                await ref.read(rtdbDevicesRefreshProvider.future);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Device removed from profile'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error removing device: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text('Remove'),
          ),
        ],
      ),
    );
  }
}
