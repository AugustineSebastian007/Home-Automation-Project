import 'dart:async';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/presentation/providers/add_device_providers.dart';
import 'package:home_automation/helpers/utils.dart';
import 'package:http/http.dart' as http;
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/shared/models/device_response.model.dart';
import 'package:collection/collection.dart';
import 'package:home_automation/features/devices/presentation/providers/room_providers.dart';
import 'package:home_automation/features/devices/data/models/outlet.model.dart';

class DeviceService {

  final Ref ref;
  const DeviceService(this.ref);

  Future<DeviceResponse> toggleDevice(DeviceModel device) async {
    try {
      final selectedRoom = ref.read(roomValueProvider);
      final outletListAsyncValue = selectedRoom != null
          ? ref.watch(outletListProvider(selectedRoom.id))
          : const AsyncValue<List<OutletModel>>.loading();
      final selectedOutlet = await outletListAsyncValue.when(
        data: (outlets) => outlets.firstWhereOrNull((o) => o.id == device.outlet),
        loading: () => null,
        error: (_, __) => null,
      );

      if (selectedOutlet == null) {
        Utils.showMessageOnSnack('Outlet not found.', 'Please try again.');
        return DeviceResponse(statusCode: 0, success: false);
      }

      var url = Uri.http(selectedOutlet.ip, 'relay/${selectedOutlet.id}', {'turn': (device.isSelected ? 'off' : 'on')});
      var response = await http.get(url).timeout(2.seconds);
      return DeviceResponse(statusCode: response.statusCode, success: response.statusCode == 200);
    }
    on TimeoutException {
      Utils.showMessageOnSnack('Timeout issue.', 'Please try again.');
      return DeviceResponse(statusCode: 0, success: false);
    }
    on Exception {
      Utils.showMessageOnSnack('Issue during toggle.', 'Please try again.');
      return DeviceResponse(statusCode: 0, success: false);
    }
    
  }
}