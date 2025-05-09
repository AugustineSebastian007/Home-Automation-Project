import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// A simpler alternative to MjpegViewer that periodically refreshes the image
/// This can be more reliable on some devices and with some MJPEG streams
class MjpegImage extends StatefulWidget {
  final String streamUrl;
  final BoxFit fit;
  final Duration refreshInterval;
  final Function(bool)? onLoading;
  final Widget loadingWidget;
  final Widget errorWidget;

  const MjpegImage({
    Key? key,
    required this.streamUrl,
    this.fit = BoxFit.contain,
    this.refreshInterval = const Duration(milliseconds: 100),
    this.onLoading,
    this.loadingWidget = const Center(child: CircularProgressIndicator()),
    this.errorWidget = const Center(child: Icon(Icons.error, color: Colors.red, size: 48)),
  }) : super(key: key);

  @override
  State<MjpegImage> createState() => _MjpegImageState();
}

class _MjpegImageState extends State<MjpegImage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Timer? _refreshTimer;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  DateTime _lastRefreshTime = DateTime.now();
  bool _isFirstLoad = true;
  
  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to start the refresh process
    // This ensures we don't call setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRefreshing();
    });
  }

  @override
  void dispose() {
    _stopRefreshing();
    super.dispose();
  }

  @override
  void didUpdateWidget(MjpegImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl || 
        oldWidget.refreshInterval != widget.refreshInterval) {
      _stopRefreshing();
      // Use a post-frame callback to restart the refresh process
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startRefreshing();
      });
    }
  }

  void _stopRefreshing() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _startRefreshing() {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    
    if (widget.onLoading != null) {
      widget.onLoading!(true);
    }
    
    // Fetch the first image
    _fetchImage();
    
    // Set up periodic refresh
    _refreshTimer = Timer.periodic(widget.refreshInterval, (timer) {
      // Only fetch a new image if the previous one completed
      if (!_isLoading && mounted) {
        _fetchImage();
      }
    });
  }
  
  Future<void> _fetchImage() async {
    // Don't start a new fetch if we're still loading
    if (_isLoading && _imageBytes != null) return;
    
    // Set loading state
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      // Calculate time since last refresh for logging
      final now = DateTime.now();
      final timeSinceLastRefresh = now.difference(_lastRefreshTime);
      _lastRefreshTime = now;
      
      // Log less frequently to avoid flooding the console
      if (_isFirstLoad || _retryCount > 0 || timeSinceLastRefresh.inSeconds > 5) {
        print('Fetching MJPEG image from: ${widget.streamUrl} (${timeSinceLastRefresh.inMilliseconds}ms since last refresh)');
        _isFirstLoad = false;
      }
      
      // Fetch the image with a timeout
      final response = await http.get(
        Uri.parse(widget.streamUrl),
        headers: {
          'Connection': 'keep-alive',
          'Cache-Control': 'no-cache, no-store',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode != 200) {
        throw Exception('HTTP error ${response.statusCode}');
      }
      
      if (response.bodyBytes.isEmpty) {
        throw Exception('Empty response');
      }
      
      // Check if the response is a valid JPEG
      if (response.bodyBytes.length >= 2 && 
          response.bodyBytes[0] == 0xFF && 
          response.bodyBytes[1] == 0xD8) {
        
        if (mounted) {
          setState(() {
            _imageBytes = response.bodyBytes;
            _isLoading = false;
            _hasError = false;
            _errorMessage = '';
            _retryCount = 0; // Reset retry count on success
          });
          
          if (widget.onLoading != null) {
            widget.onLoading!(false);
          }
        }
      } else {
        throw Exception('Invalid image format');
      }
      
    } catch (e) {
      print('Error fetching MJPEG image: $e');
      
      if (mounted) {
        // Only show error if we haven't received any frames yet
        if (_imageBytes == null) {
          setState(() {
            _hasError = true;
            _isLoading = false;
            _errorMessage = e.toString();
          });
          
          if (widget.onLoading != null) {
            widget.onLoading!(false);
          }
          
          _retryFetchIfNeeded();
        } else {
          // If we already have an image, just mark as not loading
          // and we'll try again on the next refresh
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  void _retryFetchIfNeeded() {
    if (!mounted) return;
    
    if (_retryCount < _maxRetries) {
      _retryCount++;
      print('Retrying MJPEG image fetch (attempt $_retryCount of $_maxRetries)');
      
      Future.delayed(Duration(seconds: 2 * _retryCount), () {
        if (mounted) {
          _fetchImage();
        }
      });
    } else {
      print('Max retry attempts reached');
      _stopRefreshing();
      
      // Restart after a longer delay
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          _retryCount = 0;
          _startRefreshing();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _imageBytes == null) {
      return widget.loadingWidget;
    }
    
    if (_hasError && _imageBytes == null) {
      return GestureDetector(
        onTap: () {
          _retryCount = 0;
          // Use a post-frame callback to restart the refresh process
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startRefreshing();
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.errorWidget,
            const SizedBox(height: 16),
            Text(
              'Unable to connect to camera',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Error: $_errorMessage',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                _retryCount = 0;
                // Use a post-frame callback to restart the refresh process
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _startRefreshing();
                });
              },
              child: const Text('Retry Connection'),
            ),
          ],
        ),
      );
    }
    
    // Show the image if we have it
    if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        fit: widget.fit,
        gaplessPlayback: true,
      );
    }
    
    // Fallback
    return widget.loadingWidget;
  }
} 