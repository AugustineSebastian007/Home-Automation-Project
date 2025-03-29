import 'package:flutter/material.dart';
import 'package:home_automation/features/outlets/data/models/outlet.model.dart';

class OutletTile extends StatelessWidget {
  final OutletModel outlet;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const OutletTile({
    Key? key,
    required this.outlet,
    required this.onTap,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(outlet.label),
      subtitle: Text('IP: ${outlet.ip}'),
      onTap: onTap,
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: onRemove,
      ),
    );
  }
}