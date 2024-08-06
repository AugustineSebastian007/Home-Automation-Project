import 'package:flutter/material.dart';
import 'package:home_automation/features/rooms/data/models/room.model.dart';
import 'package:home_automation/features/outlets/presentation/pages/add_outlet_page.dart';

class RoomTile extends StatelessWidget {
  final RoomModel room;

  const RoomTile({Key? key, required this.room}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(room.name),
      trailing: IconButton(
        icon: Icon(Icons.add),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddOutletPage(roomId: room.id)),
        ),
      ),
    );
  }
}
