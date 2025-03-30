import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/navigation/presentation/widgets/main_appbar.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/features/rooms/presentation/providers/room_providers.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/features/outlets/presentation/providers/outlet_providers.dart';
import 'package:home_automation/styles/flicky_icons_icons.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/outlets/presentation/widgets/add_outlet_sheet.dart';
import 'package:home_automation/helpers/utils.dart';
import 'package:home_automation/features/rooms/presentation/providers/room_providers.dart';
import 'package:home_automation/features/outlets/presentation/providers/add_outlet_providers.dart';
import 'package:home_automation/features/outlets/data/models/outlet.model.dart';
import 'package:home_automation/features/navigation/presentation/widgets/home_automation_bottombar.dart';

class RoomDetailsPage extends ConsumerWidget {
  static const String route = '/room-details/:id';

  final String roomId;

  const RoomDetailsPage({required this.roomId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsyncValue = ref.watch(roomStreamProvider(roomId));
    final outletsAsyncValue = ref.watch(outletListStreamProvider(roomId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: HomeAutomationAppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/rooms');
          },
        ),
        title: 'Room Details',
      ),
      body: roomAsyncValue.when(
        data: (room) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MainPageHeader(
              icon: FlickyAnimatedIcons(
                icon: FlickyAnimatedIconOptions.barrooms,
                size: FlickyAnimatedIconSizes.large,
                isSelected: true,
              ),
              title: room.name,
            ),
            Expanded(
              child: outletsAsyncValue.when(
                data: (outlets) => ListView.builder(
                  itemCount: outlets.length,
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  itemBuilder: (context, index) {
                    final outlet = outlets[index];
                    final devicesAsyncValue = ref.watch(deviceListStreamProvider((roomId: roomId, outletId: outlet.id)));
                    
                    return GestureDetector(
                      onTap: () => context.goNamed(
                        'devices',
                        pathParameters: {'roomId': room.id, 'outletId': outlet.id},
                      ),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark 
                            ? Color.fromARGB(255, 55, 55, 55) // Dark gray for dark mode
                            : colorScheme.surfaceVariant, // Original color for light mode
                          borderRadius: BorderRadius.circular(16),
                        ),
                        height: 150,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top row with icon and name
                            Row(
                              children: [
                                FlickyAnimatedIcons(
                                  icon: FlickyAnimatedIconOptions.barrooms,
                                  size: FlickyAnimatedIconSizes.small,
                                  isSelected: false,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  outlet.label,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Bottom section with device count, device icons, and delete button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Delete button on bottom left
                                TextButton.icon(
                                  onPressed: () => _showDeleteConfirmDialog(context, ref, outlet),
                                  icon: Icon(Icons.delete, color: Colors.red, size: 18),
                                  label: Text('Delete', style: TextStyle(color: Colors.red, fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    backgroundColor: Colors.red.withOpacity(0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    minimumSize: Size(0, 0),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                
                                // Device info on bottom right
                                devicesAsyncValue.when(
                                  data: (devices) {
                                    final deviceCount = devices.length;
                                    
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '$deviceCount ${deviceCount == 1 ? 'Device' : 'Devices'}',
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        if (deviceCount > 0)
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: _buildDeviceIcons(devices),
                                          ),
                                      ],
                                    );
                                  },
                                  loading: () => CircularProgressIndicator(),
                                  error: (error, stack) => Text('Error: $error', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                loading: () => Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error loading outlets: $error')),
              ),
            ),
          ],
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Utils.showUIModal(
            context,
            AddOutletSheet(roomId: roomId),
            onDismissed: () {
              ref.read(saveAddOutletProvider.notifier).resetValues();
            }
          );
        },
        child: Icon(Icons.add),
        heroTag: 'addOutlet',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: const HomeAutomationBottomBar(),
    );
  }

  Widget _buildDeviceIcons(List<DeviceModel> devices) {
    // Only show icons for devices in the list
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: devices.map((device) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FlickyAnimatedIcons(
            icon: device.iconOption,
            size: FlickyAnimatedIconSizes.small,
            isSelected: device.isSelected,
          ),
        );
      }).toList(),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, OutletModel outlet) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Outlet'),
          content: Text('Are you sure you want to delete "${outlet.label}"?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteOutlet(context, ref, outlet.id);
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteOutlet(BuildContext context, WidgetRef ref, String outletId) {
    try {
      ref.read(outletRepositoryProvider).removeOutlet(roomId, outletId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Outlet deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting outlet: $e')),
      );
    }
  }
}

