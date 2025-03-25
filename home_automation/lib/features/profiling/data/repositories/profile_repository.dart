import 'package:home_automation/features/profiling/data/models/profile.model.dart';
import 'package:home_automation/features/shared/services/firestore.service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';

class ProfileRepository {
  final FirestoreService _firestoreService;

  ProfileRepository(this._firestoreService);

  Stream<List<ProfileModel>> streamProfiles() {
    return _firestoreService.streamProfiles();
  }

  Stream<ProfileModel> streamProfile(String memberId, String profileId) {
    return _firestoreService.streamProfile(memberId, profileId);
  }

  Future<void> addProfile(String memberId, ProfileModel profile) async {
    await _firestoreService.addProfile(memberId, profile);
  }

  Future<void> updateProfile(String memberId, ProfileModel profile) async {
    await _firestoreService.updateProfile(memberId, profile);
  }

  Future<void> deleteProfile(String memberId, String profileId) async {
    await _firestoreService.deleteProfile(memberId, profileId);
  }

  Future<void> addDeviceToProfile(String memberId, String profileId, String deviceId) async {
    final profile = await _firestoreService.getProfile(profileId);
    if (!profile.deviceIds.contains(deviceId)) {
      profile.deviceIds.add(deviceId);
      await _firestoreService.updateProfile(memberId, profile);
    }
  }

  Future<void> toggleAllDevicesInProfile(String memberId, String profileId, bool isActive, WidgetRef ref) async {
    try {
      final profile = await _firestoreService.getProfile(profileId);
      final deviceToggleVM = ref.read(deviceToggleVMProvider.notifier);

      List<String> failedDevices = [];

      for (final deviceId in profile.deviceIds) {
        try {
          final deviceAsyncValue = await ref.read(selectedDeviceStreamProvider(deviceId).future);
          await deviceToggleVM.toggleDevice(deviceAsyncValue.copyWith(isSelected: !isActive));
        } catch (e) {
          failedDevices.add(deviceId);
          print('Error toggling device $deviceId: $e');
        }
      }

      final updatedProfile = profile.copyWith(isActive: isActive);
      await _firestoreService.updateProfile(memberId, updatedProfile);

      if (failedDevices.isNotEmpty) {
        throw Exception('Failed to toggle ${failedDevices.length} devices');
      }
    } catch (e) {
      print('Error in toggleAllDevicesInProfile: $e');
      throw Exception('Failed to toggle all devices: $e');
    }
  }
}
