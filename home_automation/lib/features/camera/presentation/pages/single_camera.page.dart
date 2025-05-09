import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:home_automation/features/camera/presentation/providers/camera_providers.dart';
import 'package:home_automation/features/shared/providers/shared_providers.dart';
import 'package:home_automation/features/camera/presentation/widgets/mjpeg_viewer.dart';
import 'package:home_automation/features/camera/presentation/widgets/mjpeg_image.dart';
import 'package:home_automation/features/camera/presentation/widgets/simple_mjpeg_image.dart';
import 'package:home_automation/features/camera/presentation/widgets/video_stream_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

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
  simpleMjpegImage,
  videoPlayer
}

class _SingleCameraPageState extends ConsumerState<SingleCameraPage> {
  late WebViewController _controller;
  bool _isSettingBoundary = false;
  bool _isLoading = true;
  
  // Set the loading method - use simpleMjpegImage for MJPEG streams
  final CameraLoadingMethod _loadingMethod = CameraLoadingMethod.simpleMjpegImage;
  
  // Store the video URL
  late String _videoUrl;
  
  // Camera online status
  bool _isCameraOnline = true;
  
  // Firebase user ID
  final String _userId = '1R05PQZRwPdB7mYnqiCOefAv5Jb2';
  
  // Camera type (determined from URL)
  String _cameraType = '';
  
  // Camera status stream
  StreamSubscription? _cameraStatusSubscription;
  
  // Key for widget refresh
  Key _cameraKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    
    // Determine camera type from URL or label
    if (widget.url.contains('5004')) {
      _cameraType = 'face_recognition';
    } else if (widget.url.contains('5000')) {
      _cameraType = 'target_detection';
    } else if (widget.label.toLowerCase().contains('face')) {
      _cameraType = 'face_recognition';
    } else if (widget.label.toLowerCase().contains('target')) {
      _cameraType = 'target_detection';
    }
    
    // Make sure the URL ends with '/video_feed'
    _videoUrl = widget.url;
    if (!_videoUrl.endsWith('/video_feed')) {
      _videoUrl = _videoUrl + '/video_feed';
    }
    
    // Set up camera status listener
    _setupCameraStatusListener();
    
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
  
  @override
  void dispose() {
    _cameraStatusSubscription?.cancel();
    super.dispose();
  }
  
  void _setupCameraStatusListener() {
    if (_cameraType.isEmpty) return;
    
    final firestore = FirebaseFirestore.instance;
    
    _cameraStatusSubscription = firestore
        .collection('users')
        .doc(_userId)
        .collection('camera_status')
        .doc(_cameraType)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        final bool isOnline = data?['isOnline'] ?? false;
        final String? url = data?['url'];
        
        // Only update if changed
        if (_isCameraOnline != isOnline || (url != null && url != _videoUrl)) {
          setState(() {
            _isCameraOnline = isOnline;
            _isLoading = true;
            _cameraKey = UniqueKey();
            
            // If URL changed and camera is online, update
            if (isOnline && url != null && url != _videoUrl) {
              _videoUrl = url;
            }
          });
          
          if (_loadingMethod == CameraLoadingMethod.webView) {
            _initializeController();
          } else {
            // For non-WebView methods, just mark as loaded after a delay
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            });
          }
        }
      } else {
        if (_isCameraOnline) {
          setState(() {
            _isCameraOnline = false;
            _cameraKey = UniqueKey();
          });
        }
      }
    }, onError: (error) {
      print('Error in camera status stream: $error');
      if (mounted && _isCameraOnline) {
        setState(() {
          _isCameraOnline = false;
        });
      }
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
                  if (error.errorCode == -2) { // Failed to connect
                    _isCameraOnline = false;
                  }
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
                          _cameraKey = UniqueKey();
                        });
                        _checkCameraConnection();
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
                  _cameraKey = UniqueKey();
                });
                _checkCameraConnection();
              },
            ),
          ),
        );
      }
    }
  }
  
  // Check if camera is actually reachable
  Future<void> _checkCameraConnection() async {
    if (_videoUrl.isEmpty) return;
    
    try {
      // Format URL
      String checkUrl = _videoUrl;
      if (!checkUrl.startsWith('http://') && !checkUrl.startsWith('https://')) {
        checkUrl = 'http://$checkUrl';
      }
      
      print('Checking camera connection: $checkUrl');
      
      // Try to connect with timeout
      final client = http.Client();
      final response = await client.get(Uri.parse(checkUrl))
          .timeout(const Duration(seconds: 5));
      
      bool isOnline = response.statusCode == 200;
      
      // Update Firestore if needed
      if (_cameraType.isNotEmpty) {
        await _updateCameraStatus(isOnline);
      }
      
      // Update local state
      if (mounted) {
        setState(() {
          _isCameraOnline = isOnline;
          _isLoading = false;
        });
      }
      
      client.close();
      
    } catch (e) {
      print('Camera connection check failed: $e');
      if (_cameraType.isNotEmpty) {
        await _updateCameraStatus(false);
      }
      
      if (mounted) {
        setState(() {
          _isCameraOnline = false;
          _isLoading = false;
        });
      }
    }
  }
  
  // Update camera status in Firestore
  Future<void> _updateCameraStatus(bool isOnline) async {
    try {
      if (_cameraType.isEmpty) return;
      
      // Update status in Firestore
      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('users')
          .doc(_userId)
          .collection('camera_status')
          .doc(_cameraType)
          .update({
        'isOnline': isOnline,
      });
      
    } catch (e) {
      print('Error updating camera status: $e');
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (!_isSettingBoundary) return;

    final boundaryPointsNotifier = ref.read(boundaryPointsProvider(widget.url).notifier);
    boundaryPointsNotifier.addPoint(details.localPosition);
  }
  
  Widget _buildCameraFeed() {
    if (!_isCameraOnline) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, color: Colors.red, size: 48),
            const SizedBox(height: 10),
            Text(
              'Camera is offline',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _cameraKey = UniqueKey();
                });
                _checkCameraConnection();
              },
              child: Text('Check Connection'),
            ),
          ],
        ),
      );
    }
    
    if (_videoUrl.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 10),
            Text(
              'Waiting for camera URL...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }
    
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
    
    // If using VideoPlayer for true video streaming
    if (_loadingMethod == CameraLoadingMethod.videoPlayer) {
      return VideoStreamPlayer(
        key: _cameraKey,
        streamUrl: _videoUrl,
        fit: BoxFit.contain, // Use contain for full screen view
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
    
    // If using SimpleMjpegImage (recommended for best performance and reliability)
    if (_loadingMethod == CameraLoadingMethod.simpleMjpegImage) {
      return SimpleMjpegImage(
        key: _cameraKey,
        streamUrl: _videoUrl,
        fit: BoxFit.contain,
        refreshInterval: const Duration(milliseconds: 100),
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
        errorWidget: const Icon(Icons.error, color: Colors.red, size: 48),
        onError: (bool hasError) {
          if (hasError && mounted) {
            _updateCameraStatus(false);
            setState(() {
              _isCameraOnline = false;
            });
          }
        },
      );
    }
    
    // If using MjpegViewer
    if (_loadingMethod == CameraLoadingMethod.mjpegViewer) {
      return MjpegViewer(
        key: _cameraKey,
        streamUrl: _videoUrl,
        fit: BoxFit.contain,
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
      );
    }
    
    // If using WebView
    if (_loadingMethod == CameraLoadingMethod.webView) {
      return WebViewWidget(controller: _controller);
    }
    
    // Fallback to direct image
    return Image.network(
      _videoUrl,
      key: _cameraKey,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Update camera status to offline
        _updateCameraStatus(false);
        setState(() {
          _isCameraOnline = false;
        });
        
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Unable to connect to camera',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _cameraKey = UniqueKey();
                  });
                  _checkCameraConnection();
                },
                child: Text('Retry Connection'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.label),
        actions: [
          // Add refresh button
          if (_isCameraOnline)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _cameraKey = UniqueKey();
                });
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                });
              },
              tooltip: 'Refresh Camera',
            ),
          IconButton(
            icon: Icon(_isSettingBoundary ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                _isSettingBoundary = !_isSettingBoundary;
              });
              
              if (!_isSettingBoundary) {
                // Save boundary points when exiting boundary setting mode
                final boundaryPointsNotifier = ref.read(boundaryPointsProvider(widget.url).notifier);
                boundaryPointsNotifier.saveBoundary();
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isSettingBoundary 
                    ? 'Tap to set boundary points. Tap check when done.' 
                    : 'Boundary points saved.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          if (_isSettingBoundary)
            IconButton(
              icon: Icon(Icons.undo),
              onPressed: () {
                final boundaryPointsNotifier = ref.read(boundaryPointsProvider(widget.url).notifier);
                boundaryPointsNotifier.removeLastPoint();
              },
            ),
          if (_isSettingBoundary)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                final boundaryPointsNotifier = ref.read(boundaryPointsProvider(widget.url).notifier);
                boundaryPointsNotifier.clearPoints();
              },
            ),
        ],
      ),
      body: GestureDetector(
        onTapDown: _isSettingBoundary ? _onTapDown : null,
        child: Stack(
          children: [
            // Camera feed
            Positioned.fill(
              child: _buildCameraFeed(),
            ),
            
            // Boundary points
            if (_isSettingBoundary)
              Positioned.fill(
                child: Consumer(
                  builder: (context, ref, child) {
                    final boundaryPoints = ref.watch(boundaryPointsProvider(widget.url));
                    return CustomPaint(
                      painter: BoundaryPainter(boundaryPoints),
                    );
                  },
                ),
              ),
            
            // Status indicator
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isCameraOnline ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isCameraOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
}

class BoundaryPainter extends CustomPainter {
  final List<Offset> points;
  
  BoundaryPainter(this.points);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < points.length; i++) {
      // Draw points
      canvas.drawCircle(
        points[i],
        8.0,
        Paint()..color = Colors.red.withOpacity(0.7),
      );
      
      // Draw numbers
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(color: Colors.white, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas, 
        points[i].translate(-textPainter.width / 2, -textPainter.height / 2),
      );
      
      // Draw lines
      if (points.length > 1 && i < points.length - 1) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
    
    // Close the polygon
    if (points.length > 2) {
      canvas.drawLine(points.last, points.first, paint);
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
