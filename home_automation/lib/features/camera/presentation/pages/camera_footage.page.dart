import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_automation/features/shared/widgets/main_page_header.dart';
import 'package:home_automation/features/shared/widgets/flicky_animated_icons.dart';
import 'package:home_automation/helpers/enums.dart';
import 'package:home_automation/styles/styles.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:home_automation/services/background_service.dart';
import 'package:home_automation/features/camera/presentation/widgets/mjpeg_viewer.dart';
import 'package:home_automation/features/camera/presentation/widgets/mjpeg_image.dart';
import 'package:home_automation/features/camera/presentation/widgets/simple_mjpeg_image.dart';

// Add this enum to switch between WebView and direct image loading
enum CameraLoadingMethod {
  webView,
  directImage,
  mjpegViewer,
  mjpegImage,
  simpleMjpegImage
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
  
  // Set the loading method - use simpleMjpegImage for best performance and reliability
  final CameraLoadingMethod _loadingMethod = CameraLoadingMethod.simpleMjpegImage;
  
  // WebView controllers for each camera
  WebViewController? _faceRecognitionController;
  WebViewController? _targetDetectionController;
  bool _isFaceRecognitionLoading = true;
  bool _isTargetDetectionLoading = true;

  // URLs for the camera feeds
  final String _faceRecognitionUrl = 'http://192.168.57.113:5004/video_feed';
  final String _targetDetectionUrl = 'http://192.168.1.38:5000/video_feed';

  @override
  void initState() {
    super.initState();
    
    // Use a post-frame callback to initialize Firebase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFirebase();
    });
    
    if (_loadingMethod == CameraLoadingMethod.webView) {
      // Use a post-frame callback to initialize WebView controllers
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeWebViewControllers();
      });
    } else {
      // For direct image loading, we don't need to initialize controllers
      // Just set loading to false after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isFaceRecognitionLoading = false;
            _isTargetDetectionLoading = false;
          });
        }
      });
    }
  }
  
  void _initializeWebViewControllers() {
    if (!mounted) return;
    
    // Initialize face recognition camera
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
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(_faceRecognitionUrl));
      
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
        });
      }
    }
    
    // Initialize target detection camera
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
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(_targetDetectionUrl));
      
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

  Widget _buildCameraFeed(WebViewController? controller, bool isLoading, String url) {
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
    
    // If using SimpleMjpegImage (recommended for best performance and reliability)
    if (_loadingMethod == CameraLoadingMethod.simpleMjpegImage) {
      return SimpleMjpegImage(
        streamUrl: url,
        fit: BoxFit.cover,
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
        streamUrl: url,
        fit: BoxFit.cover,
        refreshInterval: const Duration(milliseconds: 100),
        onLoading: (isLoading) {
          if (mounted) {
            setState(() {
              if (url == _faceRecognitionUrl) {
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
        streamUrl: url,
        fit: BoxFit.cover,
        onLoading: (isLoading) {
          if (mounted) {
            setState(() {
              if (url == _faceRecognitionUrl) {
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
                        if (url == _faceRecognitionUrl) {
                          _isFaceRecognitionLoading = true;
                        } else {
                          _isTargetDetectionLoading = true;
                        }
                      });
                      
                      // Force refresh by setting state after a short delay
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted) {
                          setState(() {
                            if (url == _faceRecognitionUrl) {
                              _isFaceRecognitionLoading = false;
                            } else {
                              _isTargetDetectionLoading = false;
                            }
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
        key: ValueKey('${url}_${DateTime.now().millisecondsSinceEpoch}'),
        gaplessPlayback: true,
      );
    }
    
    // Otherwise use WebView
    return WebViewWidget(controller: controller!);
  }

  Widget _buildCameraFeedContainer(String label, WebViewController? controller, bool isLoading, String url) {
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      HomeAutomationStyles.smallHGap,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () {
                    String baseUrl = label == 'Face Recognition Camera' 
                      ? 'http://192.168.57.113:5004/'
                      : 'http://192.168.1.38:5000/';
                    
                    // Add the video_feed endpoint for the single camera view
                    String videoUrl = baseUrl + 'video_feed';
                      
                    GoRouter.of(context).push(
                      '/single-camera',
                      extra: {
                        'label': label,
                        'url': videoUrl,
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(HomeAutomationStyles.smallRadius),
              child: _buildCameraFeed(controller, isLoading, url),
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
                            _faceRecognitionUrl
                          ),
                          HomeAutomationStyles.smallVGap,
                          _buildCameraFeedContainer(
                            'Target Detection Camera',
                            _targetDetectionController,
                            _isTargetDetectionLoading,
                            _targetDetectionUrl
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