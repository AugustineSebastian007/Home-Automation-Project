import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/camera/presentation/providers/camera_providers.dart';
import 'package:home_automation/features/shared/providers/shared_providers.dart';

class SingleCameraPage extends ConsumerStatefulWidget {
  static const String route = '/single-camera';
  final String label;
  final String feedPath;

  const SingleCameraPage({
    required this.label,
    required this.feedPath,
    super.key,
  });

  @override
  ConsumerState<SingleCameraPage> createState() => _SingleCameraPageState();
}

class _SingleCameraPageState extends ConsumerState<SingleCameraPage> {
  late VideoPlayerController _controller;
  bool _isSettingBoundary = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
    
    // Load existing boundary points from Firestore
    ref.read(firestoreServiceProvider)
      .streamCameraBoundaryPoints(widget.feedPath)
      .listen((points) {
        if (points.isNotEmpty) {
          final boundaryPointsNotifier = ref.read(boundaryPointsProvider(widget.feedPath).notifier);
          boundaryPointsNotifier.loadPointsFromFirestore(
            points.map((p) => Offset(p[0], p[1])).toList()
          );
        }
      }).onError((error) {
        print('Error streaming boundary points: $error');
      });
  }

  Future<void> _initializeController() async {
    try {
      print("Initializing video for path: ${widget.feedPath}");
      // Get the actual video path from the test videos map
      final Map<String, String> testVideos = {
        'camera/feed1': 'assets/test_videos/thief_video.mp4',
        'camera/feed2': 'assets/test_videos/thief_video2.mp4',
        'camera/feed3': 'assets/test_videos/thief_video3.mp4',
      };
      
      final videoPath = testVideos[widget.feedPath];
      if (videoPath == null) {
        throw Exception('Video path not found');
      }

      _controller = VideoPlayerController.asset(videoPath);
      await _controller.initialize();
      _controller.setLooping(true);
      await _controller.play();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Error initializing video controller: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading video: $e')),
        );
      }
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (!_isSettingBoundary) return;

    final boundaryPointsNotifier = ref.read(boundaryPointsProvider(widget.feedPath).notifier);
    boundaryPointsNotifier.addPoint(details.localPosition);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use the provider to get the current boundary points
    final boundaryPoints = ref.watch(boundaryPointsProvider(widget.feedPath));

    if (!_controller.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.label),
        actions: [
          IconButton(
            icon: Icon(
              _isSettingBoundary ? Icons.check : Icons.edit,
              color: _isSettingBoundary ? Colors.green : null,
            ),
            onPressed: () {
              setState(() {
                if (_isSettingBoundary) {
                  _isSettingBoundary = false;
                  ref.read(boundaryPointsProvider(widget.feedPath).notifier).saveBoundary();
                } else {
                  ref.read(boundaryPointsProvider(widget.feedPath).notifier).clearPoints();
                  _isSettingBoundary = true;
                }
              });
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTapDown: _onTapDown,
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
            if (boundaryPoints.isNotEmpty)
              CustomPaint(
                size: Size.infinite,
                painter: BoundaryPainter(
                  points: boundaryPoints,
                  color: Colors.red,
                ),
              ),
            if (_isSettingBoundary)
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: HomeAutomationStyles.smallPadding,
                    color: Colors.black54,
                    child: Text(
                      'Tap to set boundary points (${boundaryPoints.length}/4)',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class BoundaryPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  BoundaryPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    if (points.length >= 4) {
      path.lineTo(points[0].dx, points[0].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
