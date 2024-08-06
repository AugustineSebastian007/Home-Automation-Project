import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/devices/presentation/providers/add_device_providers.dart';

class OutletList extends ConsumerWidget {
  final String roomId;

  const OutletList({Key? key, required this.roomId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outletListAsyncValue = ref.watch(outletListProvider(roomId));

    return Scaffold(
      appBar: AppBar(title: Text('Outlets')),
      body: outletListAsyncValue.when(
        data: (outlets) {
          return ListView.builder(
            itemCount: outlets.length,
            itemBuilder: (context, index) {
              final outlet = outlets[index];
              return ListTile(
                title: Text(outlet.label),
                // Add more outlet details as needed
              );
            },
          );
        },
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading outlets: $error')),
      ),
    );
  }
}