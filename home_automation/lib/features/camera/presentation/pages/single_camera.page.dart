import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/camera/presentation/providers/camera_providers.dart';
import 'package:home_automation/features/shared/providers/shared_providers.dart';
import 'package:home_automation/features/camera/presentation/widgets/mjpeg_viewer.dart';
import 'package:home_automation/features/camera/presentation/widgets/mjpeg_image.dart';
import 'package:home_automation/features/camera/presentation/widgets/simple_mjpeg_image.dart';

class SingleCameraPage extends ConsumerStatefulWidget {
  static const String route = '/single-camera';
  final String label;
  final String url;

  const SingleCameraPage({
    Key? key,
    required this.label,
    required this.url,
  }) : super(key: key);

  @override
  ConsumerState<SingleCameraPage> createState() => _SingleCameraPageState();
}

enum CameraLoadingMethod {
  webView,
  directImage,
  mjpegViewer,
  mjpegImage,
  simpleMjpegImage
}

class _SingleCameraPageState extends ConsumerState<SingleCameraPage> {
  late WebViewController _controller;
  bool _isSettingBoundary = false;
  bool _isLoading = true;
  
  // Set the loading method - use simpleMjpegImage for best performance and reliability
  final CameraLoadingMethod _loadingMethod = CameraLoadingMethod.simpleMjpegImage;
  
  // Store the video URL
  late String _videoUrl;

  @override
  void initState() {
    super.initState();
    
    // Make sure the URL ends with '/video_feed'
    _videoUrl = widget.url;
    if (!_videoUrl.endsWith('/video_feed')) {
      _videoUrl = _videoUrl + '/video_feed';
    }
    
    if (_loadingMethod == CameraLoadingMethod.webView) {
      // Use a post-frame callback to initialize the controller
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeController();
      });
    } else {
      // For direct image or mjpeg loading, we don't need to initialize controllers
      // Just set loading to false after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
    
    // Load existing boundary points from Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(firestoreServiceProvider)
        .streamCameraBoundaryPoints(widget.url)
        .listen((points) {
          if (points.isNotEmpty) {
            final boundaryPointsNotifier = ref.read(boundaryPointsProvider(widget.url).notifier);
            boundaryPointsNotifier.loadPointsFromFirestore(
              points.map((p) => Offset(p[0], p[1])).toList()
            );
          }
        }).onError((error) {
          print('Error streaming boundary points: $error');
        });
    });
  }

  void _initializeController() {
    if (!mounted) return;
    
    try {
      print("Initializing WebView for url: ${widget.url}");
      print("Using video feed URL: $_videoUrl");
      
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        // Add additional WebView settings for performance
        ..enableZoom(false)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              print('Single camera - Page started loading: $url');
            },
            onPageFinished: (String url) {
              print('Single camera - Page finished loading: $url');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              print("Single camera - WebView error: ${error.description}, errorType: ${error.errorType}, errorCode: ${error.errorCode}");
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error loading camera: ${error.description}'),
                    duration: Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'Retry',
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                        });
                        _initializeController();
                      },
                    ),
                  ),
                );
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(_videoUrl));
      
      // Add a timeout to handle slow loading
      Future.delayed(const Duration(seconds: 10), () {
        if (_isLoading && mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
      
    } catch (e) {
      print("Error initializing WebView controller: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading camera: $e'),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _initializeController();
              },
            ),
          ),
        );
      }
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (!_isSettingBoundary) return;

    final boundaryPointsNotifier = ref.read(boundaryPointsProvider(widget.url).notifier);
    boundaryPointsNotifier.addPoint(details.localPosition);
  }
  
  Widget _buildCameraFeed() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 10),
            Text(
              'Loading video feed...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }
    
    // If using SimpleMjpegImage (recommended for best performance and reliability)
    if (_loadingMethod == CameraLoadingMethod.simpleMjpegImage) {
      return SimpleMjpegImage(
        streamUrl: _videoUrl,
        fit: BoxFit.contain,
        refreshInterval: const Duration(milliseconds: 1000),
        loadingWidget: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              Text(
                'Loading video feed...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        errorWidget: Icon(Icons.error_outline, color: Colors.red, size: 48),
      );
    }
    
    // If using MjpegImage
    if (_loadingMethod == CameraLoadingMethod.mjpegImage) {
      return MjpegImage(
        streamUrl: _videoUrl,
        fit: BoxFit.contain,
        refreshInterval: const Duration(milliseconds: 100),
        onLoading: (isLoading) {
          if (mounted && _isLoading != isLoading) {
            setState(() {
              _isLoading = isLoading;
            });
          }
        },
        loadingWidget: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              Text(
                'Loading video feed...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        errorWidget: Icon(Icons.error_outline, color: Colors.red, size: 48),
      );
    }
    
    // If using MJPEG viewer
    if (_loadingMethod == CameraLoadingMethod.mjpegViewer) {
      return MjpegViewer(
        streamUrl: _videoUrl,
        fit: BoxFit.contain,
        onLoading: (isLoading) {
          if (mounted && _isLoading != isLoading) {
            setState(() {
              _isLoading = isLoading;
            });
          }
        },
        loadingWidget: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              Text(
                'Loading video feed...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        errorWidget: Icon(Icons.error_outline, color: Colors.red, size: 48),
      );
    }
    
    // If using direct image loading
    if (_loadingMethod == CameraLoadingMethod.directImage) {
      return Image.network(
        _videoUrl,
        fit: BoxFit.contain,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  Text(
                    'Loading video feed...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }
          return child;
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text('Unable to connect to camera',
                    style: Theme.of(context).textTheme.bodyMedium),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _isLoading = true;
                      });
                      
                      // Force refresh by setting state after a short delay
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      });
                    });
                  },
                  child: Text('Retry Connection'),
                ),
              ],
            ),
          );
        },
        // Add a key with timestamp to force refresh
        key: ValueKey('${_videoUrl}_${DateTime.now().millisecondsSinceEpoch}'),
        gaplessPlayback: true,
      );
    }
    
    // Otherwise use WebView
    return WebViewWidget(controller: _controller);
  }

  @override
  Widget build(BuildContext context) {
    // Use the provider to get the current boundary points
    final boundaryPoints = ref.watch(boundaryPointsProvider(widget.url));

    if (_isLoading && _loadingMethod == CameraLoadingMethod.webView) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.label),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              Text(
                'Loading video feed...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
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
                  ref.read(boundaryPointsProvider(widget.url).notifier).saveBoundary();
                } else {
                  ref.read(boundaryPointsProvider(widget.url).notifier).clearPoints();
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
            _buildCameraFeed(),
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
