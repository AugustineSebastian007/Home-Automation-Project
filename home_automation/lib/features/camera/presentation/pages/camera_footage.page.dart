import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'package:home_automation/features/camera/presentation/pages/single_camera.page.dart';
import 'package:go_router/go_router.dart';
import 'package:home_automation/services/background_service.dart';

class CameraFootagePage extends ConsumerStatefulWidget {
  static const String route = '/camera-footage';

  const CameraFootagePage({super.key});

  @override
  ConsumerState<CameraFootagePage> createState() => _CameraFootagePageState();
}

class _CameraFootagePageState extends ConsumerState<CameraFootagePage> {
  bool isAlertMode = false;
  FirebaseDatabase? database;
  bool _isInitialized = false;
  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, bool> _isPlaying = {};

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
    _loadVideosSequentially();
  }

  Future<void> _initializeFirebase() async {
    database = FirebaseDatabase.instance;
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _loadVideosSequentially() async {
    final Map<String, String> testVideos = {
      'camera/feed1': 'assets/test_videos/thief_video.mp4',
      'camera/feed2': 'assets/test_videos/thief_video2.mp4',
      'camera/feed3': 'assets/test_videos/thief_video3.mp4',
    };

    try {
      for (var entry in testVideos.entries) {
        await _initializeSingleVideo(entry.key, entry.value);
      }
    } catch (e) {
      print("Error loading videos: $e");
    }
  }

  Future<void> _initializeSingleVideo(String key, String path) async {
    try {
      final controller = VideoPlayerController.asset(
        path,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      _controllers[key] = controller;
      _isPlaying[key] = false;

      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(0.0);
      controller.play();

      if (mounted) {
        setState(() {
          _isPlaying[key] = true;
        });
      }
    } catch (e) {
      print("Error initializing video $key: $e");
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MainPageHeader(
              icon: FlickyAnimatedIcons(
                icon: FlickyAnimatedIconOptions.bardevices,
                size: FlickyAnimatedIconSizes.large,
                isSelected: true,
              ),
              title: 'Camera Footage',
            ),
            Expanded(
              child: Padding(
                padding: HomeAutomationStyles.mediumPadding,
                child: Column(
                  children: [
                    // Camera Feeds List
                    Expanded(
                      flex: 3,
                      child: ListView(
                        children: [
                          _buildCameraFeedContainer('Living Room Camera', 'camera/feed1'),
                          HomeAutomationStyles.smallVGap,
                          _buildCameraFeedContainer('Front Door Camera', 'camera/feed2'),
                          HomeAutomationStyles.smallVGap,
                          _buildCameraFeedContainer('Backyard Camera', 'camera/feed3'),
                        ],
                      ),
                    ),
                    HomeAutomationStyles.mediumVGap,
                    // Alert Mode Switch
                    Container(
                      padding: HomeAutomationStyles.mediumPadding,
                      decoration: BoxDecoration(
                        color: isAlertMode 
                          ? colorScheme.error.withOpacity(0.15)
                          : colorScheme.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: isAlertMode ? colorScheme.error : colorScheme.secondary,
                          ),
                          HomeAutomationStyles.smallHGap,
                          Expanded(
                            child: Text(
                              'Alert Mode',
                              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                                color: isAlertMode ? colorScheme.error : colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Switch(
                            value: isAlertMode,
                            onChanged: (value) {
                              setState(() {
                                isAlertMode = value;
                              });
                              if (value) {
                                _showAlertModeDialog(context);
                              }
                              _updateAlertMode(value);
                            },
                            activeColor: colorScheme.error,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraFeedContainer(String label, String feedPath) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(HomeAutomationStyles.mediumRadius),
      ),
      child: Column(
        children: [
          Padding(
            padding: HomeAutomationStyles.smallPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () {
                    GoRouter.of(context).push(
                      '/single-camera',
                      extra: {
                        'label': label,
                        'feedPath': feedPath,
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildCameraFeed(feedPath),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraFeed(String feedPath) {
    // First check if the controller exists
    final controller = _controllers[feedPath];
    if (controller == null) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      );
    }

    // Then check if it's initialized
    if (!controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      );
    }

    // Now we can safely use the controller
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),
      ),
    );
  }

  void _updateAlertMode(bool value) async {
    if (_isInitialized && database != null) {
      await database!.ref('camera/alert_mode').set(value);
      if (value) {
        await BackgroundService.showAlertNotification();
      }
    }
  }

  void _showAlertModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alert Mode Activated'),
          content: Text('The system will now monitor for any suspicious activity and notify you immediately.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}