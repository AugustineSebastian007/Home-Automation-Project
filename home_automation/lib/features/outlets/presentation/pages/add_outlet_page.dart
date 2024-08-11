import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/outlets/data/models/outlet.model.dart';
import 'package:home_automation/features/outlets/presentation/providers/outlet_providers.dart';
import 'package:home_automation/features/outlets/presentation/pages/outlet_page.dart';
import 'package:home_automation/features/navigation/presentation/widgets/main_appbar.dart';
import 'package:home_automation/styles/styles.dart';

class AddOutletPage extends ConsumerWidget {
  final String roomId;
  final TextEditingController _outletNameController = TextEditingController();
  final TextEditingController _outletIpController = TextEditingController();

  AddOutletPage({Key? key, required this.roomId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: HomeAutomationAppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/room-details/$roomId'),
        ),
        title: 'Add New Outlet',
      ),
      body: Padding(
        padding: HomeAutomationStyles.mediumPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter outlet details:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _outletNameController,
              decoration: InputDecoration(labelText: 'Outlet Name'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _outletIpController,
              decoration: InputDecoration(labelText: 'Outlet IP'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final outletName = _outletNameController.text.trim();
                final outletIp = _outletIpController.text.trim();
                if (outletName.isNotEmpty && outletIp.isNotEmpty) {
                  final newOutlet = OutletModel(
                    id: DateTime.now().toString(),
                    label: outletName,
                    ip: outletIp,
                    roomId: roomId,
                  );
                  ref.read(outletRepositoryProvider).addOutlet(roomId, newOutlet);
                  
                  // Show snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Outlet added successfully')),
                  );
                  
                  // Redirect to RoomDetailsPage
                  context.go('/room-details/$roomId');
                }
              },
              child: Text('Add Outlet'),
            ),
          ],
        ),
      ),
    );
  }
}