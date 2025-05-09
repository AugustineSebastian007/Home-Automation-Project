import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// A simple MJPEG image widget that displays frames from an MJPEG stream.
class SimpleMjpegImage extends StatefulWidget {
  /// The URL of the MJPEG stream.
  final String streamUrl;

  /// How the image should be fitted to the widget's dimensions.
  final BoxFit fit;

  /// How often the widget should attempt to refresh the image.
  /// Note: The actual refresh rate may be lower depending on network latency.
  final Duration refreshInterval;

  /// Widget to display when the stream is loading.
  final Widget loadingWidget;

  /// Widget to display when there's an error loading the stream.
  final Widget errorWidget;

  /// Callback that is called when an error occurs or is resolved.
  final Function(bool)? onError;

  /// Creates a new [SimpleMjpegImage] widget.
  const SimpleMjpegImage({
    Key? key,
    required this.streamUrl,
    this.fit = BoxFit.contain,
    this.refreshInterval = const Duration(milliseconds: 100),
    this.loadingWidget = const Center(child: CircularProgressIndicator()),
    this.errorWidget = const Icon(Icons.error, color: Colors.red, size: 48),
    this.onError,
  }) : super(key: key);

  @override
  State<SimpleMjpegImage> createState() => _SimpleMjpegImageState();
}

class _SimpleMjpegImageState extends State<SimpleMjpegImage> {
  Uint8List? _imageData;
  bool _hasError = false;
  HttpClient? _httpClient;
  int _connectionAttempts = 0;
  final int _maxConnectionAttempts = 3;
  bool _isDisposed = false;
  StreamSubscription? _streamSubscription;
  Timer? _reconnectTimer;
  
  // Buffer for incoming data
  final List<int> _buffer = [];
  
  // Multipart boundary
  String? _boundary;
  bool _isBoundaryDetected = false;
  
  // Flag to indicate if we're in the process of handling an image
  bool _isProcessing = false;
  
  // For monitoring stream health
  DateTime? _lastFrameTime;
  Timer? _healthCheckTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeStream();
    
    // Set up a health check timer to monitor for freezes
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkStreamHealth();
    });
  }
  
  @override
  void didUpdateWidget(SimpleMjpegImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl) {
      _resetStream();
      _initializeStream();
    }
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _cleanupStream();
    _healthCheckTimer?.cancel();
    super.dispose();
  }
  
  void _cleanupStream() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _httpClient?.close(force: true);
    _httpClient = null;
    _buffer.clear();
    _boundary = null;
    _isBoundaryDetected = false;
  }
  
  void _resetStream() {
    _cleanupStream();
    if (mounted) {
      setState(() {
        _imageData = null;
        _hasError = false;
      });
    }
  }
  
  Future<void> _initializeStream() async {
    if (_isDisposed) return;
    
    if (_connectionAttempts >= _maxConnectionAttempts) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
        widget.onError?.call(true);
      }
      return;
    }
    
    _connectionAttempts++;
    
    try {
      // Format URL - make sure it includes http:// or https://
      String url = widget.streamUrl;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'http://$url';
      }
      
      print('Connecting to MJPEG stream at $url (attempt $_connectionAttempts)');
      
      _httpClient = HttpClient();
      _httpClient!.connectionTimeout = const Duration(seconds: 5);
      
      // Start the request
      final request = await _httpClient!.getUrl(Uri.parse(url));
      request.headers.add('Accept', 'multipart/x-mixed-replace;boundary=*');
      request.headers.add('Connection', 'keep-alive');
      
      // Get the response
      final response = await request.close();
      
      if (response.statusCode != 200) {
        throw Exception('Failed to connect to stream: ${response.statusCode}');
      }
      
      // Look for content-type header to extract boundary
      var contentType = response.headers.value('content-type');
      if (contentType != null && contentType.contains('boundary=')) {
        _boundary = contentType.split('boundary=')[1].trim();
        _isBoundaryDetected = true;
        print('Detected boundary: $_boundary');
      } else {
        print('No boundary detected in content-type header, will attempt to detect from stream');
      }
      
      // Clear any previous data
      _buffer.clear();
      
      // Listen to the stream
      _streamSubscription = response.listen(
        (data) {
          if (_isDisposed) return;
          
          // Add data to buffer
          _buffer.addAll(data);
          
          // Process buffer to extract frames
          if (!_isProcessing) {
            _isProcessing = true;
            _processBuffer();
          }
        },
        onError: (error) {
          print('Error in MJPEG stream: $error');
          _handleConnectionError();
        },
        onDone: () {
          print('MJPEG stream closed');
          _handleConnectionError();
        },
        cancelOnError: true,
      );
      
      // Reset connection attempts on successful connection
      _connectionAttempts = 0;
      
    } catch (e) {
      print('Error initializing MJPEG stream: $e');
      _handleConnectionError();
    }
  }
  
  void _handleConnectionError() {
    if (_isDisposed) return;
    
    _cleanupStream();
    
    if (mounted) {
      // Only show error if we've reached max attempts
      if (_connectionAttempts >= _maxConnectionAttempts) {
        setState(() {
          _hasError = true;
        });
        widget.onError?.call(true);
      } else {
        // Otherwise attempt to reconnect after a delay with exponential backoff
        final delay = Duration(seconds: 2 * _connectionAttempts);
        print('Will attempt to reconnect in ${delay.inSeconds} seconds (attempt $_connectionAttempts)');
        
        _reconnectTimer = Timer(delay, () {
          if (!_isDisposed && mounted) {
            _initializeStream();
          }
        });
      }
    }
  }
  
  void _checkStreamHealth() {
    if (_isDisposed || !mounted) return;
    
    // Check if we've received a frame recently
    if (_lastFrameTime != null) {
      final now = DateTime.now();
      final difference = now.difference(_lastFrameTime!);
      
      // If it's been more than 10 seconds since last frame, reconnect
      if (difference.inSeconds > 10) {
        print('No frames received for ${difference.inSeconds} seconds, reconnecting...');
        _resetStream();
        _initializeStream();
      }
    }
  }
  
  void _processBuffer() {
    if (_buffer.isEmpty || _isDisposed) {
      _isProcessing = false;
      return;
    }
    
    try {
      // If boundary isn't detected yet, try to find it in the buffer
      if (!_isBoundaryDetected) {
        _detectBoundary();
      }
      
      // Look for JPEG start/end markers
      int? jpegStartPos = _findJpegStart();
      int? jpegEndPos = jpegStartPos != null ? _findJpegEnd(jpegStartPos) : null;
      
      // If we found a complete JPEG image
      if (jpegStartPos != null && jpegEndPos != null && jpegEndPos > jpegStartPos) {
        // Extract the JPEG data
        final jpegBytes = Uint8List.fromList(
          _buffer.sublist(jpegStartPos, jpegEndPos + 2) // Include the end marker
        );
        
        // Update the image if it's valid
        if (jpegBytes.length > 10) { // Sanity check for valid JPEG data
          if (mounted) {
            setState(() {
              _imageData = jpegBytes;
              _hasError = false;
              _lastFrameTime = DateTime.now();
            });
            // If we were in error state before, notify that the error is resolved
            if (_hasError) {
              widget.onError?.call(false);
            }
          }
        }
        
        // Remove processed data from buffer
        _buffer.removeRange(0, jpegEndPos + 2);
      } 
      // If we found a start but no end marker yet
      else if (jpegStartPos != null) {
        // Wait for more data, but remove any data before the start marker
        if (jpegStartPos > 0) {
          _buffer.removeRange(0, jpegStartPos);
        }
      } 
      // If we didn't find a start marker, check if buffer is too large
      else if (_buffer.length > 100000) {
        // Buffer might be corrupted, clear it
        print('Buffer too large with no JPEG markers, clearing');
        _buffer.clear();
      }
      
      // Schedule next buffer processing after a short delay
      // This prevents excessive CPU usage while still processing frames quickly
      Future.delayed(const Duration(milliseconds: 5), () {
        if (!_isDisposed && mounted) {
          _processBuffer();
        } else {
          _isProcessing = false;
        }
      });
      
    } catch (e) {
      print('Error processing MJPEG buffer: $e');
      _isProcessing = false;
    }
  }
  
  void _detectBoundary() {
    if (_buffer.length < 10) return;
    
    // Convert the start of the buffer to a string
    final headerEnd = _buffer.length > 1000 ? 1000 : _buffer.length;
    final headerString = utf8.decode(_buffer.sublist(0, headerEnd), allowMalformed: true);
    
    // Look for boundary pattern
    final boundaryMatch = RegExp(r'--[-\w]+').firstMatch(headerString);
    if (boundaryMatch != null) {
      _boundary = boundaryMatch.group(0);
      _isBoundaryDetected = true;
      print('Detected boundary from stream: $_boundary');
    }
  }
  
  // Find the start of a JPEG image (FF D8 marker)
  int? _findJpegStart() {
    for (int i = 0; i < _buffer.length - 1; i++) {
      if (_buffer[i] == 0xFF && _buffer[i + 1] == 0xD8) {
        return i;
      }
    }
    return null;
  }
  
  // Find the end of a JPEG image (FF D9 marker)
  int? _findJpegEnd(int startPos) {
    for (int i = startPos + 2; i < _buffer.length - 1; i++) {
      if (_buffer[i] == 0xFF && _buffer[i + 1] == 0xD9) {
        return i;
      }
    }
    return null;
  }
  
  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.errorWidget,
            const SizedBox(height: 16),
            Text(
              'Unable to connect to video stream',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _connectionAttempts = 0;
                });
                widget.onError?.call(false);
                _resetStream();
                _initializeStream();
              },
              child: const Text('Retry Connection'),
            ),
          ],
        ),
      );
    }
    
    if (_imageData == null) {
      return widget.loadingWidget;
    }
    
    return Image.memory(
      _imageData!,
      fit: widget.fit,
      gaplessPlayback: true, // Prevents flickering between frames
    );
  }
} 