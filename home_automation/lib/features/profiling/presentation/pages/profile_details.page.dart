import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/profiling/presentation/providers/profile_providers.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation/features/devices/presentation/widgets/device_row_item.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';

class ProfileDetailsPage extends ConsumerWidget {
  static const String route = '/profile-details/:id';
  final String profileId;

  const ProfileDetailsPage({Key? key, required this.profileId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileWithDevicesAsyncValue = ref.watch(profileWithDevicesProvider(profileId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(profileWithDevicesAsyncValue.value?.$1.name ?? 'Profile Details'),
      ),
      body: SafeArea(
        child: profileWithDevicesAsyncValue.when(
          data: (data) {
            final (profile, profileDevices) = data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MainPageHeader(
                  icon: FlickyAnimatedIcons(
                    icon: FlickyAnimatedIconOptions.barprofile,
                    size: FlickyAnimatedIconSizes.large,
                    isSelected: true,
                  ),
                  title: 'Profile Details',
                ),
                Padding(
                  padding: HomeAutomationStyles.mediumPadding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('All Devices', style: Theme.of(context).textTheme.titleMedium),
                      Switch(
                        value: profile.isActive,
                        onChanged: (value) {
                          _toggleAllDevices(context, ref, profileId, value);
                        },
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
                            return _buildDeviceItem(context, ref, device);
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
        onPressed: () => _showAddDeviceDialog(context, ref, profileId),
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildDeviceItem(BuildContext context, WidgetRef ref, DeviceModel device) {
    final deviceAsyncValue = ref.watch(deviceStreamProvider((roomId: device.roomId, outletId: device.outletId, deviceId: device.id)));
    
    return deviceAsyncValue.when(
      data: (updatedDevice) => DeviceRowItem(
        device: updatedDevice,
        onTapDevice: (device) {
          _toggleDevice(context, ref, device);
        },
        onToggle: (bool value) {
          _toggleDevice(context, ref, updatedDevice);
        },
      ),
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
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
      await ref.read(profileRepositoryProvider).toggleAllDevicesInProfile(profileId, value, ref);
      
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
        // Refresh the profile to ensure UI is in sync
        ref.refresh(profileWithDevicesProvider(profileId));
      }
    }
  }

  void _showAddDeviceDialog(BuildContext context, WidgetRef ref, String profileId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddDeviceToProfileDialog(profileId: profileId);
      },
    );
  }
}

class AddDeviceToProfileDialog extends ConsumerWidget {
  final String profileId;

  const AddDeviceToProfileDialog({Key? key, required this.profileId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allDevicesAsyncValue = ref.watch(allDevicesProvider);

    return AlertDialog(
      title: Text('Add Device to Profile'),
      content: allDevicesAsyncValue.when(
        data: (devices) {
          print("Devices fetched: ${devices.length}");
          if (devices.isEmpty) {
            return Text('No devices available to add.');
          }
          return SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  title: Text(device.label),
                  subtitle: Text('Room: ${device.roomId}, Outlet: ${device.outletId}'),
                  onTap: () {
                    ref.read(profileRepositoryProvider).addDeviceToProfile(profileId, device.id);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          print("Error fetching devices: $error");
          return Center(child: Text('Error: $error'));
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
      ],
    );
  }
}
