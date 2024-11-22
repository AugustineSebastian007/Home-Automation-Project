import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/navigation/presentation/widgets/main_appbar.dart';
import 'package:home_automation/features/outlets/presentation/providers/outlet_providers.dart';
import 'package:home_automation/features/outlets/presentation/widgets/outlet_tile.dart';
import 'package:go_router/go_router.dart';

class OutletsPage extends ConsumerWidget {
  final String roomId;

  const OutletsPage({Key? key, required this.roomId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outletsAsyncValue = ref.watch(outletListStreamProvider(roomId));

    return Scaffold(
      appBar: HomeAutomationAppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/rooms'),
        ),
        title: 'Outlets',
      ),
      body: outletsAsyncValue.when(
        data: (outlets) => ListView.builder(
          itemCount: outlets.length,
          itemBuilder: (context, index) {
            final outlet = outlets[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: OutletTile(
                outlet: outlet,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/devices',
                  arguments: {'roomId': roomId, 'outletId': outlet.id},
                ),
                onRemove: () => _removeOutlet(context, ref, outlet.id),
              ),
            );
          },
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/add-outlet', arguments: roomId),
              icon: Icon(Icons.add),
              label: Text('Add Outlet'),
            ),
            ElevatedButton.icon(
              onPressed: () => _removeAllOutlets(context, ref),
              icon: Icon(Icons.delete),
              label: Text('Remove All Outlets'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeOutlet(BuildContext context, WidgetRef ref, String outletId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove Outlet'),
          content: Text('Are you sure you want to remove this outlet?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Remove'),
              onPressed: () {
                ref.read(outletRepositoryProvider).removeOutlet(roomId, outletId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _removeAllOutlets(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove All Outlets'),
          content: Text('Are you sure you want to remove all outlets in this room?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Remove All'),
              onPressed: () {
                ref.read(outletRepositoryProvider).removeAllOutlets(roomId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}