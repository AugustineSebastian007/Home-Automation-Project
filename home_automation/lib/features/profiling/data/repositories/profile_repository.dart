import 'package:home_automation/features/profiling/data/models/profile.model.dart';
import 'package:home_automation/features/shared/services/firestore.service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/presentation/providers/device_providers.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:home_automation/features/devices/data/models/device.model.dart';
import 'package:home_automation/features/devices/data/models/rtdb_device.model.dart';
import 'package:home_automation/features/devices/data/repositories/rtdb_device_repository.dart';
import 'package:home_automation/features/devices/presentation/providers/rtdb_device_providers.dart';

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
      final rtdbDeviceToggle = ref.read(rtdbDeviceToggleProvider.notifier);
      final rtdbRepository = ref.read(rtdbDeviceRepositoryProvider);

      List<String> failedDevices = [];

      // First refresh RTDB devices to get latest state
      await rtdbRepository.refreshDevices();

      // Track all toggle operations
      List<Future<void>> toggleOperations = [];

      // Process all devices
      for (final deviceId in profile.deviceIds) {
        try {
          // Check if this is an RTDB device (prefixed with rtdb_)
          if (deviceId.startsWith('rtdb_')) {
            // Handle RTDB device toggle
            final rtdbDeviceId = deviceId.substring(5); // Remove 'rtdb_' prefix
            final rtdbDevice = await rtdbRepository.getDeviceById(rtdbDeviceId);
            
            if (rtdbDevice != null) {
              // Add to operations list but don't await yet
              toggleOperations.add(rtdbDeviceToggle.setDeviceState(rtdbDevice, isActive)
                .then((_) => print('Toggled RTDB device $rtdbDeviceId to $isActive')));
            }
          } else {
            // Handle Firestore device toggle
            final deviceAsyncValue = await ref.read(selectedDeviceStreamProvider(deviceId).future);
            
            // Only update if current state is different from target state
            if (deviceAsyncValue.isSelected != isActive) {
              print('Toggling Firestore device $deviceId from ${deviceAsyncValue.isSelected} to $isActive');
              
              // The toggleDevice method always flips the current state
              // So we must pass a device with the OPPOSITE of our desired final state
              final deviceToToggle = deviceAsyncValue.copyWith(
                isSelected: !isActive // Use the opposite of desired final state
              );
              
              // Add to operations list but don't await yet
              toggleOperations.add(deviceToggleVM.toggleDevice(deviceToToggle)
                .then((_) => _updateDeviceInRealtimeDB(deviceAsyncValue, isActive)));
            }
          }
        } catch (e) {
          failedDevices.add(deviceId);
          print('Error toggling device $deviceId: $e');
        }
      }
      
      // Now await all toggle operations to complete in parallel
      if (toggleOperations.isNotEmpty) {
        await Future.wait(toggleOperations);
      }

      // Wait a moment for all toggles to complete
      await Future.delayed(Duration(milliseconds: 500));
      
      // Do a final refresh of RTDB devices to ensure UI is updated
      await rtdbRepository.refreshDevices();

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
  
  // Helper to update device in Firebase Realtime Database
  Future<void> _updateDeviceInRealtimeDB(DeviceModel device, bool value) async {
    try {
      // For light and fan devices, update in Firebase Realtime DB
      if (device.label.toLowerCase().contains('light') || 
          device.label.toLowerCase().contains('fan')) {
        
        // Initialize Firebase app for this specific update
        final uniqueAppName = 'updateDeviceApp${DateTime.now().millisecondsSinceEpoch}';
        final app = await Firebase.initializeApp(
          name: uniqueAppName,
          options: const FirebaseOptions(
            databaseURL: 'https://home-automation-78d43-default-rtdb.asia-southeast1.firebasedatabase.app',
            apiKey: 'AIzaSyALytw5DzSOWXSKdMJgRqTthL4IeowTDxc',
            projectId: 'home-automation-78d43',
            messagingSenderId: '872253796110',
            appId: '1:872253796110:web:bc95c78cf47ad1e10ff15f',
            storageBucket: 'home-automation-78d43.appspot.com',
          ),
        );
        
        // Get database instance
        final database = FirebaseDatabase.instanceFor(app: app);
        
        // Update based on device type
        if (device.label.toLowerCase().contains('light')) {
          // Extract light number
          final match = RegExp(r'Light (\d+)').firstMatch(device.label);
          if (match != null) {
            final relayNumber = match.group(1);
            // Update relay state
            await database.ref('outlets/living_room/devices/relay$relayNumber').set(value);
            print('Updated light $relayNumber to $value in Realtime DB');
          }
        } 
        else if (device.label.toLowerCase().contains('fan')) {
          // For fan, update speed (0 if turning off, or some value like 3 if turning on)
          final speed = value ? 3 : 0;
          await database.ref('outlets/living_room/devices/fan/speed').set(speed);
          print('Updated fan speed to $speed in Realtime DB');
        }
        
        // Clean up 
        await app.delete();
      }
    } catch (e) {
      print('Error updating device in Realtime DB: $e');
      // Don't throw here - we want to continue even if Realtime DB update fails
    }
  }
}
