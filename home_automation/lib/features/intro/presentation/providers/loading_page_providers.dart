
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/intro/presentation/viewmodel/loading_notification.viewmodel.dart';
import 'package:home_automation/helpers/enums.dart';

final loadingMessageProvider = StateProvider<String>((ref)=>'');

final loadingNotificationVMProvider = StateNotifierProvider<LoadingNotificationViewModel,
AppLoadingStates>((ref) {
  return LoadingNotificationViewModel(AppLoadingStates.none,ref);
});