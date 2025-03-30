import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/outlets/presentation/providers/outlet_providers.dart';
import 'package:home_automation/features/navigation/presentation/widgets/main_appbar.dart';
import 'package:home_automation/styles/styles.dart';

class RemoveOutletPage extends ConsumerWidget {
  static const String route = '/remove-outlet/:roomId';
  final String roomId;

  const RemoveOutletPage({Key? key, required this.roomId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outletsAsyncValue = ref.watch(outletListStreamProvider(roomId));

    return Scaffold(
      appBar: HomeAutomationAppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/room-details/$roomId'),
        ),
        title: 'Remove Outlet',
      ),
      body: Padding(
        padding: HomeAutomationStyles.mediumPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select an outlet to remove:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            Expanded(
              child: outletsAsyncValue.when(
                data: (outlets) => ListView.builder(
                  itemCount: outlets.length,
                  itemBuilder: (context, index) {
                    final outlet = outlets[index];
                    return Card(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Color(0xFF2A2A2A) // Dark gray for dark mode
                          : null, // Default color for light mode
                      child: ListTile(
                        leading: Icon(Icons.power, color: Theme.of(context).colorScheme.primary),
                        title: Text(outlet.label),
                        subtitle: Text(outlet.ip),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showRemoveConfirmationDialog(context, ref, outlet.id),
                        ),
                      ),
                    );
                  },
                ),
                loading: () => Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error loading outlets: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveConfirmationDialog(BuildContext context, WidgetRef ref, String outletId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Removal'),
          content: Text('Are you sure you want to remove this outlet?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Remove'),
              onPressed: () {
                Navigator.of(context).pop();
                _removeOutlet(context, ref, outletId);
              },
            ),
          ],
        );
      },
    );
  }

  void _removeOutlet(BuildContext context, WidgetRef ref, String outletId) {
    ref.read(outletRepositoryProvider).removeOutlet(roomId, outletId).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Outlet removed successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing outlet: $error')),
      );
    });
  }
}