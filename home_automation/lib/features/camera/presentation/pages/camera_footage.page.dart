import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:home_automation/services/background_service.dart';
import 'package:home_automation/features/camera/presentation/widgets/mjpeg_viewer.dart';
import 'package:home_automation/features/camera/presentation/widgets/mjpeg_image.dart';
import 'package:home_automation/features/camera/presentation/widgets/simple_mjpeg_image.dart';
import 'package:home_automation/features/camera/presentation/widgets/video_stream_player.dart';
import 'package:http/http.dart' as http;

// Add this enum to switch between WebView and direct image loading
enum CameraLoadingMethod {
  webView,
  directImage,
  mjpegViewer,
  mjpegImage,
  simpleMjpegImage,
  videoPlayer
}

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
  
  // Set the loading method - use simpleMjpegImage for MJPEG streams
  final CameraLoadingMethod _loadingMethod = CameraLoadingMethod.simpleMjpegImage;
  
  // WebView controllers for each camera
  WebViewController? _faceRecognitionController;
  WebViewController? _targetDetectionController;
  bool _isFaceRecognitionLoading = true;
  bool _isTargetDetectionLoading = true;

  // Firebase user ID
  final String _userId = '1R05PQZRwPdB7mYnqiCOefAv5Jb2';
  
  // Camera status streams
  StreamSubscription? _faceRecognitionStatusSubscription;
  StreamSubscription? _targetDetectionStatusSubscription;
  
  // Camera URLs (will be populated from Firebase)
  String? _faceRecognitionUrl;
  String? _targetDetectionUrl;
  
  // Camera online status
  bool _isFaceRecognitionOnline = false;
  bool _isTargetDetectionOnline = false;
  
  // Keys to force widget refresh
  Key _faceRecognitionKey = UniqueKey();
  Key _targetDetectionKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    
    // Use a post-frame callback to initialize Firebase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFirebase();
      _setupCameraStatusListeners();
    });
  }
  
  @override
  void dispose() {
    _faceRecognitionStatusSubscription?.cancel();
    _targetDetectionStatusSubscription?.cancel();
    super.dispose();
  }
  
  void _setupCameraStatusListeners() {
    final firestore = FirebaseFirestore.instance;
    
    // Listen for face recognition camera status updates
    _faceRecognitionStatusSubscription = firestore
        .collection('users')
        .doc(_userId)
        .collection('camera_status')
        .doc('face_recognition')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        final bool isOnline = data?['isOnline'] ?? false;
        final String? url = data?['url'];
        
        // If status or URL changed, update state and force widget refresh
        if (_isFaceRecognitionOnline != isOnline || _faceRecognitionUrl != url) {
          setState(() {
            _isFaceRecognitionOnline = isOnline;
            _faceRecognitionUrl = url;
            _isFaceRecognitionLoading = true;
            
            // Generate a new key to force widget rebuild
            _faceRecognitionKey = UniqueKey();
            
            if (_loadingMethod == CameraLoadingMethod.webView && url != null) {
              _initializeFaceRecognitionController();
            } else {
              // For non-WebView methods, just mark as non-loading after a delay
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  setState(() {
                    _isFaceRecognitionLoading = false;
                  });
                }
              });
            }
          });
          
          print('Face recognition camera status updated: online=$isOnline, url=$url');
        }
      } else {
        setState(() {
          _isFaceRecognitionOnline = false;
          _faceRecognitionUrl = null;
          _isFaceRecognitionLoading = false;
          _faceRecognitionKey = UniqueKey();
        });
      }
    }, onError: (error) {
      print('Error in face recognition status stream: $error');
      setState(() {
        _isFaceRecognitionOnline = false;
        _isFaceRecognitionLoading = false;
      });
    });
    
    // Listen for target detection camera status updates
    _targetDetectionStatusSubscription = firestore
        .collection('users')
        .doc(_userId)
        .collection('camera_status')
        .doc('target_detection')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        final bool isOnline = data?['isOnline'] ?? false;
        final String? url = data?['url'];
        
        // If status or URL changed, update state and force widget refresh
        if (_isTargetDetectionOnline != isOnline || _targetDetectionUrl != url) {
          setState(() {
            _isTargetDetectionOnline = isOnline;
            _targetDetectionUrl = url;
            _isTargetDetectionLoading = true;
            
            // Generate a new key to force widget rebuild
            _targetDetectionKey = UniqueKey();
            
            if (_loadingMethod == CameraLoadingMethod.webView && url != null) {
              _initializeTargetDetectionController();
            } else {
              // For non-WebView methods, just mark as non-loading after a delay
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  setState(() {
                    _isTargetDetectionLoading = false;
                  });
                }
              });
            }
          });
          
          print('Target detection camera status updated: online=$isOnline, url=$url');
        }
      } else {
        setState(() {
          _isTargetDetectionOnline = false;
          _targetDetectionUrl = null;
          _isTargetDetectionLoading = false;
          _targetDetectionKey = UniqueKey();
        });
      }
    }, onError: (error) {
      print('Error in target detection status stream: $error');
      setState(() {
        _isTargetDetectionOnline = false;
        _isTargetDetectionLoading = false;
      });
    });
  }
  
  void _initializeFaceRecognitionController() {
    if (!mounted || _faceRecognitionUrl == null) return;
    
    try {
      print("Initializing face recognition camera WebView at: $_faceRecognitionUrl");
      
      _faceRecognitionController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        // Add additional WebView settings for performance
        ..enableZoom(false)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              print('Face recognition camera - Page started loading: $url');
            },
            onPageFinished: (String url) {
              print('Face recognition camera - Page finished loading: $url');
              if (mounted) {
                setState(() {
                  _isFaceRecognitionLoading = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              print('Face recognition camera - WebView error: ${error.description}, errorType: ${error.errorType}, errorCode: ${error.errorCode}');
              if (mounted) {
                setState(() {
                  _isFaceRecognitionLoading = false;
                  if (error.errorCode == -2) { // Failed to connect
                    _isFaceRecognitionOnline = false;
                  }
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(_faceRecognitionUrl!));
      
      // Add a timeout to handle slow loading
      Future.delayed(const Duration(seconds: 10), () {
        if (_isFaceRecognitionLoading && mounted) {
          setState(() {
            _isFaceRecognitionLoading = false;
          });
        }
      });
      
    } catch (e) {
      print('Error initializing face recognition camera WebView: $e');
      if (mounted) {
        setState(() {
          _isFaceRecognitionLoading = false;
          _isFaceRecognitionOnline = false;
        });
      }
    }
  }
  
  void _initializeTargetDetectionController() {
    if (!mounted || _targetDetectionUrl == null) return;
    
    try {
      print("Initializing target detection camera WebView at: $_targetDetectionUrl");
      
      _targetDetectionController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        // Add additional WebView settings for performance
        ..enableZoom(false)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              print('Target detection camera - Page started loading: $url');
            },
            onPageFinished: (String url) {
              print('Target detection camera - Page finished loading: $url');
              if (mounted) {
                setState(() {
                  _isTargetDetectionLoading = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              print('Target detection camera - WebView error: ${error.description}, errorType: ${error.errorType}, errorCode: ${error.errorCode}');
              if (mounted) {
                setState(() {
                  _isTargetDetectionLoading = false;
                  if (error.errorCode == -2) { // Failed to connect
                    _isTargetDetectionOnline = false;
                  }
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(_targetDetectionUrl!));
      
      // Add a timeout to handle slow loading
      Future.delayed(const Duration(seconds: 10), () {
        if (_isTargetDetectionLoading && mounted) {
          setState(() {
            _isTargetDetectionLoading = false;
          });
        }
      });
      
    } catch (e) {
      print('Error initializing target detection camera WebView: $e');
      if (mounted) {
        setState(() {
          _isTargetDetectionLoading = false;
          _isTargetDetectionOnline = false;
        });
      }
    }
  }

  Future<void> _initializeFirebase() async {
    database = FirebaseDatabase.instance;
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Widget _buildCameraFeed(WebViewController? controller, bool isLoading, String url, bool isOnline, Key key) {
    if (!isOnline) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, color: Colors.red, size: 48),
            const SizedBox(height: 10),
            Text(
              'Camera is offline',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Attempt to refresh camera
                if (url.contains('face_recognition') || url.contains('5004')) {
                  setState(() {
                    _isFaceRecognitionLoading = true;
                    _faceRecognitionKey = UniqueKey();
                  });
                  // Try to ping the camera to update status
                  _checkCameraConnection(url, 'face_recognition');
                } else if (url.contains('target_detection') || url.contains('5000')) {
                  setState(() {
                    _isTargetDetectionLoading = true;
                    _targetDetectionKey = UniqueKey();
                  });
                  // Try to ping the camera to update status
                  _checkCameraConnection(url, 'target_detection');
                }
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.primary),
                foregroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.onPrimary),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              child: Text('Check Connection'),
            ),
          ],
        ),
      );
    }
    
    if (url.isEmpty) {
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
    
    if (isLoading) {
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
    
    // If using VideoPlayer (recommended for best performance as true video stream)
    if (_loadingMethod == CameraLoadingMethod.videoPlayer) {
      return VideoStreamPlayer(
        key: key,
        streamUrl: url,
        fit: BoxFit.cover,
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
    
    // If using SimpleMjpegImage (recommended for MJPEG streams)
    if (_loadingMethod == CameraLoadingMethod.simpleMjpegImage) {
      return SimpleMjpegImage(
        key: key,
        streamUrl: url,
        fit: BoxFit.cover,
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
        errorWidget: Icon(Icons.error_outline, color: Colors.red, size: 48),
        onError: (bool hasError) {
          // If there's an error connecting to the camera, mark it as offline
          if (hasError && mounted) {
            _updateCameraStatus(url, false);
          }
        },
      );
    }
    
    // If using MjpegImage
    if (_loadingMethod == CameraLoadingMethod.mjpegImage) {
      return MjpegImage(
        key: key,
        streamUrl: url,
        fit: BoxFit.cover,
        refreshInterval: const Duration(milliseconds: 100),
        onLoading: (isLoading) {
          if (mounted) {
            setState(() {
              if (url.contains('face_recognition') || url.contains('5004')) {
                _isFaceRecognitionLoading = isLoading;
              } else {
                _isTargetDetectionLoading = isLoading;
              }
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
        key: key,
        streamUrl: url,
        fit: BoxFit.cover,
        onLoading: (isLoading) {
          if (mounted) {
            setState(() {
              if (url.contains('face_recognition') || url.contains('5004')) {
                _isFaceRecognitionLoading = isLoading;
              } else {
                _isTargetDetectionLoading = isLoading;
              }
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
    
    // If using direct image loading, return an Image widget
    if (_loadingMethod == CameraLoadingMethod.directImage) {
      return Image.network(
        url,
        key: key,
        fit: BoxFit.cover,
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
          
          // Update camera status to offline
          _updateCameraStatus(url, false);
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text('Unable to connect to camera',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    if (url.contains('face_recognition') || url.contains('5004')) {
                      setState(() {
                        _isFaceRecognitionLoading = true;
                        _faceRecognitionKey = UniqueKey();
                      });
                      _checkCameraConnection(url, 'face_recognition');
                    } else if (url.contains('target_detection') || url.contains('5000')) {
                      setState(() {
                        _isTargetDetectionLoading = true;
                        _targetDetectionKey = UniqueKey();
                      });
                      _checkCameraConnection(url, 'target_detection');
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.primary),
                    foregroundColor: MaterialStateProperty.all(Theme.of(context).colorScheme.onPrimary),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  child: Text('Retry Connection'),
                ),
              ],
            ),
          );
        },
        // Add a key with timestamp to force refresh
        gaplessPlayback: true,
      );
    }
    
    // Otherwise use WebView
    return WebViewWidget(controller: controller!);
  }
  
  // Check if camera is actually reachable
  Future<void> _checkCameraConnection(String url, String cameraType) async {
    if (url.isEmpty) return;
    
    try {
      // Format URL
      String checkUrl = url;
      if (!checkUrl.startsWith('http://') && !checkUrl.startsWith('https://')) {
        checkUrl = 'http://$checkUrl';
      }
      
      print('Checking camera connection: $checkUrl');
      
      // Try to connect with timeout
      final client = http.Client();
      final response = await client.get(Uri.parse(checkUrl))
          .timeout(const Duration(seconds: 5));
      
      bool isOnline = response.statusCode == 200;
      
      // Update status in Firestore
      await _updateCameraStatus(url, isOnline);
      
      client.close();
      
    } catch (e) {
      print('Camera connection check failed: $e');
      await _updateCameraStatus(url, false);
    }
    
    // Reset loading state
    if (mounted) {
      setState(() {
        if (cameraType == 'face_recognition') {
          _isFaceRecognitionLoading = false;
        } else {
          _isTargetDetectionLoading = false;
        }
      });
    }
  }
  
  // Update camera status in Firestore
  Future<void> _updateCameraStatus(String url, bool isOnline) async {
    try {
      String cameraType = '';
      if (url.contains('face_recognition') || url.contains('5004')) {
        cameraType = 'face_recognition';
        setState(() {
          _isFaceRecognitionOnline = isOnline;
        });
      } else if (url.contains('target_detection') || url.contains('5000')) {
        cameraType = 'target_detection';
        setState(() {
          _isTargetDetectionOnline = isOnline;
        });
      } else {
        return; // Unknown camera type
      }
      
      // Update status in Firestore
      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('users')
          .doc(_userId)
          .collection('camera_status')
          .doc(cameraType)
          .update({
        'isOnline': isOnline,
      });
      
    } catch (e) {
      print('Error updating camera status: $e');
    }
  }

  Widget _buildCameraFeedContainer(String label, WebViewController? controller, bool isLoading, String url, bool isOnline, Key key) {
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
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelMedium!.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (isOnline)
                        const SizedBox(width: 8),
                      if (isOnline)
                        Text(
                          'Online',
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Colors.green,
                          ),
                        ),
                      if (!isOnline)
                        const SizedBox(width: 8),
                      if (!isOnline)
                        Text(
                          'Offline',
                          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (isOnline)
                      InkWell(
                        onTap: () {
                          // Force refresh the camera feed
                          if (label.contains('Face Recognition')) {
                            setState(() {
                              _faceRecognitionKey = UniqueKey();
                              _isFaceRecognitionLoading = true;
                            });
                            // Mark as loaded after delay
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (mounted) {
                                setState(() {
                                  _isFaceRecognitionLoading = false;
                                });
                              }
                            });
                          } else {
                            setState(() {
                              _targetDetectionKey = UniqueKey();
                              _isTargetDetectionLoading = true;
                            });
                            // Mark as loaded after delay
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (mounted) {
                                setState(() {
                                  _isTargetDetectionLoading = false;
                                });
                              }
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.refresh,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    InkWell(
                      onTap: () {
                        final cameraType = label == 'Face Recognition Camera' ? 'face_recognition' : 'target_detection';
                        final currentUrl = label == 'Face Recognition Camera' ? _faceRecognitionUrl : _targetDetectionUrl;
                        
                        if (isOnline && currentUrl != null) {
                          context.push(
                            '/single-camera', 
                            extra: {
                              'label': label,
                              'url': currentUrl,
                            },
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Camera is offline'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.fullscreen,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(HomeAutomationStyles.mediumRadius),
              ),
              child: _buildCameraFeed(controller, isLoading, url, isOnline, key),
            ),
          ),
        ],
      ),
    );
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
                    Expanded(
                      flex: 3,
                      child: ListView(
                        children: [
                          _buildCameraFeedContainer(
                            'Face Recognition Camera', 
                            _faceRecognitionController,
                            _isFaceRecognitionLoading, 
                            _faceRecognitionUrl ?? '',
                            _isFaceRecognitionOnline,
                            _faceRecognitionKey
                          ),
                          HomeAutomationStyles.smallVGap,
                          _buildCameraFeedContainer(
                            'Target Detection Camera', 
                            _targetDetectionController,
                            _isTargetDetectionLoading, 
                            _targetDetectionUrl ?? '',
                            _isTargetDetectionOnline,
                            _targetDetectionKey
                          ),
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