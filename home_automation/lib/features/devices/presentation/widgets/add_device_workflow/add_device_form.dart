import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/data/models/outlet.model.dart';
import 'package:home_automation/features/devices/presentation/providers/add_device_providers.dart';
import 'package:home_automation/features/devices/presentation/widgets/add_device_workflow/device_type_selection_panel.dart';
import 'package:home_automation/styles/flicky_icons_icons.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:collection/collection.dart';

class AddDeviceForm extends ConsumerWidget {

  final Function onSave;
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
    final outletListAsyncValue = ref.watch(outletListProvider);
    final selectedOutlet = ref.watch(outletValueProvider);

    return outletListAsyncValue.when(
      data: (outlets) {
        // Now you can safely use outlets
        return _buildForm(
          context,
          ref,
          outlets,
          selectedOutlet,
          colorScheme,
          textTheme,
          deviceNameCtrl,
          isFormValid,
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error loading outlets: $error'),
    );
  }

  Widget _buildForm(
    BuildContext context,
    WidgetRef ref,
    List<OutletModel> outlets,
    OutletModel? selectedOutlet,
    ColorScheme colorScheme,
    TextTheme textTheme,
    TextEditingController deviceNameCtrl,
    bool isFormValid,
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
                    DropdownButtonFormField<OutletModel>(
                      value: selectedOutlet,
                      items: outlets.map((outlet) => DropdownMenuItem(
                        value: outlet,
                        child: Text(outlet.label),
                      )).toList(),
                      onChanged: (OutletModel? value) {
                        ref.read(outletValueProvider.notifier).state = value;
                      },
                      decoration: InputDecoration(labelText: 'Select Outlet'),
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
                final deviceName = ref.read(deviceNameValueProvider);
                final deviceTypes = ref.read(deviceTypeSelectionVMProvider);
                final selectedDeviceType = deviceTypes.firstWhereOrNull((device) => device.isSelected);
                final selectedOutlet = ref.read(outletValueProvider);

                if (selectedDeviceType == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a device type')),
                  );
                  return;
                }

                final newDevice = DeviceModel(
                  iconOption: selectedDeviceType.iconOption,
                  label: deviceName,
                  isSelected: false,
                  outlet: selectedOutlet?.id != null ? int.tryParse(selectedOutlet!.id.toString()) ?? 0 : 0,
                );

                try {
                  await ref.read(deviceRepositoryProvider).addDevice(newDevice);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Device added successfully')),
                  );
                  // Navigate back or clear form
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