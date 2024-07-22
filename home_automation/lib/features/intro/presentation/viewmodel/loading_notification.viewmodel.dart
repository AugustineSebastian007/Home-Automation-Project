import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/intro/presentation/providers/loading_page_providers.dart';
import 'package:home_automation/helpers/enums.dart';

class LoadingNotificationViewModel extends StateNotifier<AppLoadingStates>{

  final Ref ref;
  LoadingNotificationViewModel(super.state, this.ref);

  Future<void> triggerLoading() async{

    state = AppLoadingStates.loading;

    ref.read(loadingMessageProvider.notifier).state = "Initializing App....";

    await Future.delayed(const Duration(seconds: 1));

    ref.read(loadingMessageProvider.notifier).state = "Loading Device List....";

    await Future.delayed(const Duration(seconds: 1));

    ref.read(loadingMessageProvider.notifier).state = "Loading Outlet Config....";

    await Future.delayed(const Duration(seconds: 1));

    ref.read(loadingMessageProvider.notifier).state = "Done!";

    state = AppLoadingStates.success;


  }
}