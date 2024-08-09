import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/outlets/data/models/outlet.model.dart';
import 'package:home_automation/features/outlets/presentation/providers/outlet_providers.dart';

class AddOutletPage extends ConsumerWidget {
  final String roomId;
  final TextEditingController _outletNameController = TextEditingController();
  final TextEditingController _outletIpController = TextEditingController();

  AddOutletPage({Key? key, required this.roomId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Outlet')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
                  ref.read(outletRepositoryProvider).addOutlet(newOutlet);
                  Navigator.of(context).pop();
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
