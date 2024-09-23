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

  Stream<ProfileModel> streamProfile(String profileId) {
    return _firestoreService.streamProfile(profileId);
  }

  Future<void> addProfile(ProfileModel profile) async {
    await _firestoreService.addProfile(profile);
  }

  Future<void> updateProfile(ProfileModel profile) async {
    await _firestoreService.updateProfile(profile);
  }

  Future<void> deleteProfile(String profileId) async {
    await _firestoreService.deleteProfile(profileId);
  }

  Future<void> addDeviceToProfile(String profileId, String deviceId) async {
    final profile = await _firestoreService.getProfile(profileId);
    if (!profile.deviceIds.contains(deviceId)) {
      profile.deviceIds.add(deviceId);
      await _firestoreService.updateProfile(profile);
    }
  }

  Future<void> toggleAllDevicesInProfile(String profileId, bool isActive, WidgetRef ref) async {
    final profile = await _firestoreService.getProfile(profileId);
    final deviceToggleVM = ref.read(deviceToggleVMProvider.notifier);

    for (final deviceId in profile.deviceIds) {
      final deviceAsyncValue = await ref.read(selectedDeviceStreamProvider(deviceId).future);
      if (deviceAsyncValue.isSelected != isActive) {
        await deviceToggleVM.toggleDevice(deviceAsyncValue);
      }
    }

    final updatedProfile = profile.copyWith(isActive: isActive);
    await _firestoreService.updateProfile(updatedProfile);
  }
}