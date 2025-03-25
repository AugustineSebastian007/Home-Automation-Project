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

final profileProvider = StreamProvider.family<ProfileModel, (String memberId, String profileId)>((ref, params) {
  final repository = ref.read(profileRepositoryProvider);
  return repository.streamProfile(params.$1, params.$2);
});

final allDevicesProvider = StreamProvider<List<DeviceModel>>((ref) {
  final repository = ref.read(deviceRepositoryProvider);
  return repository.streamAllDevices();
});

final profileWithDevicesProvider = StreamProvider.family.autoDispose<(ProfileModel, List<DeviceModel>), (String memberId, String profileId)>((ref, params) {
  // Create a single subscription that combines both streams
  final combinedStream = Rx.combineLatest2(
    ref.watch(profileProvider(params).stream),
    ref.watch(allDevicesProvider.stream),
    (ProfileModel profile, List<DeviceModel> devices) {
      final profileDevices = profile.deviceIds.isEmpty 
          ? <DeviceModel>[] 
          : devices.where((device) => profile.deviceIds.contains(device.id)).toList();
      
      return (profile, profileDevices);
    },
  ).distinct((previous, next) => 
    previous.$1.id == next.$1.id && 
    previous.$2.length == next.$2.length
  );

  // Handle cleanup when switching profiles
  ref.onDispose(() {
    ref.invalidate(profileProvider(params));
    ref.invalidate(allDevicesProvider);
  });

  return combinedStream;
});

// Add a new provider to handle the currently selected profile
final selectedProfileIdProvider = StateProvider.autoDispose<String?>((ref) => null);