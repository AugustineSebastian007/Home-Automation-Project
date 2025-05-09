import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/navigation/presentation/widgets/main_appbar.dart';

class DummyMainHallPage extends ConsumerStatefulWidget {
  @override
  _DummyMainHallPageState createState() => _DummyMainHallPageState();
}

class _DummyMainHallPageState extends ConsumerState<DummyMainHallPage> {
  FirebaseDatabase? database;
  bool _isInitialized = false;
  final String uniqueAppName = "dummyRoomApp";

  @override
  void initState() {
    super.initState();
    _setupFirebase();
  }

  Future<void> _setupFirebase() async {
    try {
      // Check if Firebase is already initialized
      FirebaseApp? app;
      try {
        app = Firebase.app(uniqueAppName);
      } catch (e) {
        app = await Firebase.initializeApp(
          name: uniqueAppName,
          options: const FirebaseOptions(
            databaseURL: 'https://home-automation-78d43-default-rtdb.asia-southeast1.firebasedatabase.app',
            apiKey: 'AIzaSyALytw5DzSOWXSKdMJgRqTthL4IeowTDxc',
            projectId: 'home-automation-78d43',
            messagingSenderId: '872253796110',
            appId: '1:872253796110:web:bc95c78cf47ad1e10ff15f',
            storageBucket: 'home-automation-78d43.appspot.com',
          ),
        );
      }

      database = FirebaseDatabase.instanceFor(app: app);
      
      // Initialize the data structure if it doesn't exist
      final dbRef = database!.ref('outlets/living_room');
      final snapshot = await dbRef.get();
      if (!snapshot.exists) {
        await dbRef.set({
          'devices': {
            'relay1': false,
            'relay2': false,
            'relay3': false,
            'relay4': false,
            'fan': {
              'speed': 0,
              'power': false
            }
          }
        });
      }

      print("Firebase setup complete");
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print("Firebase setup error: $e");
      if (e is FirebaseException) {
        print("Firebase error details - Code: ${e.code}, Message: ${e.message}");
      }
    }
  }

  @override
  void dispose() {
    try {
      Firebase.app(uniqueAppName).delete();
    } catch (e) {
      print("Error cleaning up Firebase: $e");
    }
    super.dispose();
  }

  Future<void> updateFirebase(String device, dynamic value) async {
    if (!_isInitialized || database == null) {
      print("Firebase not initialized");
      return;
    }

    try {
      final outletRef = database!.ref('outlets/living_room/devices/$device');
      await outletRef.set(value);
      print("Successfully updated $device to $value");
    } catch (e) {
      print("Update error: $e");
    }
  }

  Widget _buildDeviceToggle(int deviceNumber) {
    if (!_isInitialized || database == null) {
      return const CircularProgressIndicator();
    }

    return StreamBuilder<DatabaseEvent>(
      stream: database!.ref('outlets/living_room/devices/relay$deviceNumber').onValue,
      builder: (context, snapshot) {
        bool isOn = false;
        if (snapshot.hasData) {
          final event = snapshot.data!;
          isOn = event.snapshot.value as bool? ?? false;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: HomeAutomationStyles.smallSize),
          child: Material(
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
            child: InkWell(
              splashColor: Theme.of(context).colorScheme.secondary.withOpacity(0.25),
              highlightColor: Theme.of(context).colorScheme.secondary.withOpacity(0.25),
              child: Padding(
                padding: HomeAutomationStyles.mediumPadding,
                child: Row(
                  children: [
                    FlickyAnimatedIcons(
                      icon: FlickyAnimatedIconOptions.lightbulb,
                      isSelected: isOn,
                    ),
                    HomeAutomationStyles.smallHGap,
                    Expanded(
                      child: Text(
                        'Light ${deviceNumber}',
                        style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Switch(
                      value: isOn,
                      onChanged: (value) => updateFirebase('relay$deviceNumber', value),
                      activeColor: Theme.of(context).colorScheme.secondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFanControl() {
    if (!_isInitialized || database == null) {
      return const CircularProgressIndicator();
    }

    return StreamBuilder<DatabaseEvent>(
      stream: database!.ref('outlets/living_room/devices/fan/speed').onValue,
      builder: (context, snapshot) {
        int fanSpeed = 0;
        if (snapshot.hasData) {
          fanSpeed = (snapshot.data!.snapshot.value as int?) ?? 0;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: HomeAutomationStyles.smallSize),
          child: Material(
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
            child: InkWell(
              splashColor: Theme.of(context).colorScheme.secondary.withOpacity(0.25),
              highlightColor: Theme.of(context).colorScheme.secondary.withOpacity(0.25),
              child: Padding(
                padding: HomeAutomationStyles.mediumPadding,
                child: Column(
                  children: [
                    Row(
                      children: [
                        FlickyAnimatedIcons(
                          icon: FlickyAnimatedIconOptions.fan,
                          isSelected: fanSpeed > 0,
                        ),
                        HomeAutomationStyles.smallHGap,
                        Expanded(
                          child: Text(
                            'Fan',
                            style: Theme.of(context).textTheme.labelMedium!.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Switch(
                          value: fanSpeed > 0,
                          onChanged: (value) {
                            updateFirebase('fan/speed', value ? 1 : 0);
                            updateFirebase('fan/power', value);
                          },
                          activeColor: Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    ),
                    if (fanSpeed > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Text(
                              'Speed: $fanSpeed',
                              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: fanSpeed.toDouble(),
                                min: 1,
                                max: 4,  // Changed from 5 to 4
                                divisions: 3,  // Changed from 4 to 3
                                onChanged: (value) {
                                  updateFirebase('fan/speed', value.toInt());
                                },
                                activeColor: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAutomationAppBar(
        title: 'Morning',
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MainPageHeader(
              icon: FlickyAnimatedIcons(
                icon: FlickyAnimatedIconOptions.lightbulb,
                size: FlickyAnimatedIconSizes.large,
                isSelected: true,
              ),
              title: 'Room Control',
            ),
            Expanded(
              child: !_isInitialized
                ? Center(child: CircularProgressIndicator())
                : ListView(
                    padding: HomeAutomationStyles.mediumPadding,
                    children: [
                      _buildDeviceToggle(1),
                      _buildDeviceToggle(2),
                      _buildDeviceToggle(3),
                      _buildDeviceToggle(4),
                      _buildFanControl(),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
