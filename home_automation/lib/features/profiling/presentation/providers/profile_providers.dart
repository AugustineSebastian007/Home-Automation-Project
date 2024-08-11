import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/profiling/data/models/profile.model.dart';
import 'package:home_automation/features/profiling/data/repositories/profile_repository.dart';
import 'package:home_automation/features/shared/services/firestore.service.dart';
import 'package:home_automation/features/shared/providers/shared_providers.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository(ref.read(firestoreServiceProvider)));

final profileListProvider = FutureProvider<List<ProfileModel>>((ref) async {
  final repository = ref.read(profileRepositoryProvider);
  return await repository.getProfiles();
});

final profileProvider = FutureProvider.family<ProfileModel, String>((ref, profileId) async {
  final repository = ref.read(profileRepositoryProvider);
  final profiles = await repository.getProfiles();
  return profiles.firstWhere((profile) => profile.id == profileId);
});
