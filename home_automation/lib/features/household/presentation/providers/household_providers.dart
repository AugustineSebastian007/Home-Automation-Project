import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/household/data/repositories/household_member.repository.dart';
import 'package:home_automation/features/shared/providers/shared_providers.dart';

final householdMemberRepositoryProvider = Provider((ref) => 
  HouseholdMemberRepository(ref.read(firestoreServiceProvider))
);

final householdMembersProvider = StreamProvider((ref) =>
  ref.read(householdMemberRepositoryProvider).streamHouseholdMembers()
);
