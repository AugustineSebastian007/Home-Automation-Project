import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/outlets/data/models/outlet.model.dart';
import 'package:home_automation/features/devices/presentation/providers/add_device_providers.dart';
import 'package:home_automation/features/devices/presentation/widgets/add_device_workflow/device_type_selection_panel.dart';
import 'package:home_automation/styles/flicky_icons_icons.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:collection/collection.dart';
import 'package:home_automation/features/rooms/data/models/room.model.dart';
import 'package:home_automation/features/rooms/presentation/providers/room_providers.dart';

class AddDeviceForm extends ConsumerWidget {

  final VoidCallback onSave;
  const AddDeviceForm({
    required this.onSave,
    super.key
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final deviceNameCtrl = ref.read(deviceNameFieldProvider);
    final isFormValid = ref.watch(formValidationProvider);
    final userRoomsAsyncValue = ref.watch(userRoomsProvider);
    final selectedRoom = ref.watch(roomValueProvider) as RoomModel?;
    final outletListAsyncValue = selectedRoom != null
        ? ref.watch(outletListProvider(selectedRoom.id))
        : const AsyncValue<List<OutletModel>>.loading();
    final selectedOutlet = ref.watch(outletValueProvider);

    return userRoomsAsyncValue.when(
      data: (rooms) {
        return _buildForm(
          context,
          ref,
          rooms,
          selectedRoom,
          selectedOutlet,
          colorScheme,
          textTheme,
          deviceNameCtrl,
          isFormValid,
          outletListAsyncValue,
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error loading rooms: $error'),
    );
  }

  Widget _buildForm(
    BuildContext context,
    WidgetRef ref,
    List<RoomModel> rooms,
    RoomModel? selectedRoom,
    String? selectedOutlet,
    ColorScheme colorScheme,
    TextTheme textTheme,
    TextEditingController deviceNameCtrl,
    bool isFormValid,
    AsyncValue<List<OutletModel>> outletListAsyncValue,
  ) {
    return Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: HomeAutomationStyles.largePadding.copyWith(
                  bottom: 0
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          FlickyIcons.oven, 
                          size: HomeAutomationStyles.mediumIconSize,
                          color: colorScheme.primary
                        ),
                        HomeAutomationStyles.smallHGap,
                        Text('Add New Device', style: textTheme.headlineSmall!.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        )),
                      ],
                    ),
                    HomeAutomationStyles.mediumVGap,
                    Container(
                      padding: HomeAutomationStyles.smallPadding,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(HomeAutomationStyles.xsmallRadius),
                        color: colorScheme.secondary.withOpacity(0.25)
                      ),
                      child: TextFormField(
                        controller: deviceNameCtrl,
                        style: textTheme.displayMedium,
                        // validator: (String? name) {
                        //   final isFieldValid = ref.read(deviceNameValidatorProvider(name!));
                        //   return !isFieldValid ? 'Device name already exists' : null;
                        // },
                        decoration: InputDecoration(
                          errorText: ref.watch(deviceExistsValidatorProvider) ? 'Device name already exists' : null,
                          errorStyle: TextStyle(fontSize: 10, color: colorScheme.primary),
                          focusedErrorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                            )
                          ),
                          errorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                            )
                          )
                        ),
                        onChanged: (value) {
                          ref.read(deviceNameValueProvider.notifier).state = value;
                        },
                      ),
                    ),
                    HomeAutomationStyles.mediumVGap,
                    Text('Type of Device', 
                      style: textTheme.labelMedium!.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      )
                    ),
                    HomeAutomationStyles.mediumVGap,
                    const DeviceTypeSelectionPanel(),
                    HomeAutomationStyles.mediumVGap,
                    DropdownButtonFormField<RoomModel>(
                      value: selectedRoom,
                      items: rooms.map((room) => DropdownMenuItem(
                        value: room,
                        child: Text(room.name),
                      )).toList(),
                      onChanged: (RoomModel? value) {
                        ref.read(roomValueProvider.notifier).state = value;
                      },
                      decoration: InputDecoration(labelText: 'Select Room'),
                    ),
                    HomeAutomationStyles.mediumVGap,
                    if (selectedRoom != null)
                      outletListAsyncValue.when(
                        data: (outlets) {
                          return DropdownButtonFormField<OutletModel>(
                            value: selectedOutlet != null ? outlets.firstWhereOrNull((outlet) => outlet.id == selectedOutlet) : null,
                            items: outlets.map((outlet) => DropdownMenuItem(
                              value: outlet,
                              child: Text(outlet.label),
                            )).toList(),
                            onChanged: (OutletModel? value) {
                              ref.read(outletValueProvider.notifier).state = value?.id;
                            },
                            decoration: InputDecoration(labelText: 'Select Outlet'),
                          );
                        },
                        loading: () => CircularProgressIndicator(),
                        error: (error, stack) => Text('Error loading outlets: $error'),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: HomeAutomationStyles.largePadding,
            child: ElevatedButton(
              onPressed: isFormValid ? () async {
                final deviceTypes = ref.read(deviceTypeSelectionVMProvider);
                final selectedDeviceType = deviceTypes.firstWhereOrNull((device) => device.isSelected);
                final selectedOutlet = ref.read(outletValueProvider);

                if (selectedDeviceType == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a device type')),
                  );
                  return;
                }

                if (selectedOutlet == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select an outlet')),
                  );
                  return;
                }

                try {
                  await ref.read(saveAddDeviceVMProvider.notifier).saveDevice();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Device added successfully')),
                  );
                  onSave(); // Call the onSave callback
                } catch (e) {
                  print('Error adding device: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add device. Please try again.')),
                  );
                }
              } : null,
              child: const Text('Add Device')
            ),
          )
        ],
      ),
    );
  }
}