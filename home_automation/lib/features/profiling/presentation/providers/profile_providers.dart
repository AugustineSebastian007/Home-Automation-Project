import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/profiling/data/models/profile.model.dart';
import 'package:home_automation/features/profiling/data/repositories/profile_repository.dart';
import 'package:home_automation/features/shared/providers/shared_providers.dart' show firestoreServiceProvider;
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart' hide firestoreServiceProvider;
import 'package:rxdart/rxdart.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository(ref.read(firestoreServiceProvider)));

final profileListProvider = StreamProvider<List<ProfileModel>>((ref) {
  final repository = ref.read(profileRepositoryProvider);
  return repository.streamProfiles();
});

final profileProvider = StreamProvider.family<ProfileModel, String>((ref, profileId) {
  final repository = ref.read(profileRepositoryProvider);
  return repository.streamProfile(profileId);
});

final allDevicesProvider = StreamProvider<List<DeviceModel>>((ref) {
  final repository = ref.read(deviceRepositoryProvider);
  return repository.streamAllDevices();
});

final profileWithDevicesProvider = StreamProvider.family<(ProfileModel, List<DeviceModel>), String>((ref, profileId) {
  final profileStream = ref.watch(profileProvider(profileId).stream);
  final allDevicesStream = ref.watch(allDevicesProvider.stream);

  return Rx.combineLatest2(profileStream, allDevicesStream, (profile, devices) {
    final profileDevices = devices.where((device) => profile.deviceIds.contains(device.id)).toList();
    return (profile, profileDevices);
  });
});