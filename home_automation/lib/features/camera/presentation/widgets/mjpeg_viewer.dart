import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MjpegViewer extends StatefulWidget {
  final String streamUrl;
  final BoxFit fit;
  final Function(bool)? onLoading;
  final Widget loadingWidget;
  final Widget errorWidget;

  const MjpegViewer({
    Key? key,
    required this.streamUrl,
    this.fit = BoxFit.contain,
    this.onLoading,
    this.loadingWidget = const Center(child: CircularProgressIndicator()),
    this.errorWidget = const Center(child: Icon(Icons.error, color: Colors.red, size: 48)),
  }) : super(key: key);

  @override
  State<MjpegViewer> createState() => _MjpegViewerState();
}

class _MjpegViewerState extends State<MjpegViewer> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  StreamSubscription? _streamSubscription;
  http.Client? _client;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  bool _isFirstLoad = true;
  
  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to start the streaming process
    // This ensures we don't call setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startStreaming();
    });
  }

  @override
  void dispose() {
    _stopStreaming();
    super.dispose();
  }

  @override
  void didUpdateWidget(MjpegViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl) {
      _stopStreaming();
      // Use a post-frame callback to restart the streaming process
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startStreaming();
      });
    }
  }

  void _stopStreaming() {
    print('Stopping MJPEG stream');
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _client?.close();
    _client = null;
  }

  void _startStreaming() async {
    if (!mounted) return;
    
    // Reset state
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    
    if (widget.onLoading != null) {
      widget.onLoading!(true);
    }
    
    // Close any existing client
    _client?.close();
    _client = http.Client();

    try {
      if (_isFirstLoad) {
        print('Starting MJPEG stream from: ${widget.streamUrl}');
        _isFirstLoad = false;
      }
      
      // Create a request
      final request = http.Request('GET', Uri.parse(widget.streamUrl));
      request.headers['Connection'] = 'keep-alive';
      request.headers['Cache-Control'] = 'no-cache';
      request.headers['Pragma'] = 'no-cache';
      
      // Send the request with timeout
      final response = await _client!.send(request).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP error ${response.statusCode}');
      }
      
      print('MJPEG stream connected successfully');
      
      // Process the stream
      final stream = response.stream;
      List<int> buffer = [];
      
      _streamSubscription = stream.listen(
        (List<int> chunk) {
          // Add new data to buffer
          buffer.addAll(chunk);
          
          // Find JPEG start and end markers
          int startMarkerIndex = -1;
          int endMarkerIndex = -1;
          
          for (int i = 0; i < buffer.length - 1; i++) {
            // Look for JPEG start marker (0xFF 0xD8)
            if (buffer[i] == 0xFF && buffer[i + 1] == 0xD8) {
              startMarkerIndex = i;
            }
            
            // Look for JPEG end marker (0xFF 0xD9)
            if (i > startMarkerIndex && startMarkerIndex != -1 && 
                buffer[i] == 0xFF && buffer[i + 1] == 0xD9) {
              endMarkerIndex = i + 1;
              break;
            }
          }
          
          // If we found a complete JPEG frame
          if (startMarkerIndex != -1 && endMarkerIndex != -1) {
            // Extract the JPEG frame
            final frameBytes = Uint8List.fromList(
              buffer.sublist(startMarkerIndex, endMarkerIndex + 1)
            );
            
            // Update the UI with the new frame
            if (mounted) {
              setState(() {
                _imageBytes = frameBytes;
                _isLoading = false;
                _hasError = false;
              });
              
              if (widget.onLoading != null && _isLoading) {
                widget.onLoading!(false);
              }
            }
            
            // Remove processed data from buffer
            buffer = buffer.sublist(endMarkerIndex + 1);
          }
          
          // Prevent buffer from growing too large
          if (buffer.length > 100000) {
            print('Buffer too large (${buffer.length} bytes), truncating');
            buffer = buffer.sublist(buffer.length - 50000);
          }
        },
        onError: (error) {
          print('MJPEG stream error: $error');
          if (mounted) {
            setState(() {
              _hasError = true;
              _isLoading = false;
              _errorMessage = error.toString();
            });
            
            if (widget.onLoading != null) {
              widget.onLoading!(false);
            }
            
            _retryStreamingIfNeeded();
          }
        },
        onDone: () {
          print('MJPEG stream done');
          if (mounted) {
            // Only show error if we haven't received any frames
            if (_imageBytes == null) {
              setState(() {
                _hasError = true;
                _isLoading = false;
                _errorMessage = 'Stream ended unexpectedly';
              });
              
              _retryStreamingIfNeeded();
            }
            
            if (widget.onLoading != null && _isLoading) {
              widget.onLoading!(false);
            }
          }
        },
      );
      
      // Add a timeout to handle slow loading
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _isLoading) {
          print('MJPEG stream timeout after 10 seconds');
          setState(() {
            _isLoading = false;
            if (_imageBytes == null) {
              _hasError = true;
              _errorMessage = 'Loading timeout';
              _retryStreamingIfNeeded();
            }
          });
          
          if (widget.onLoading != null) {
            widget.onLoading!(false);
          }
        }
      });
      
    } catch (e) {
      print('Error starting MJPEG stream: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = e.toString();
        });
        
        if (widget.onLoading != null) {
          widget.onLoading!(false);
        }
        
        _retryStreamingIfNeeded();
      }
    }
  }
  
  void _retryStreamingIfNeeded() {
    if (!mounted) return;
    
    if (_retryCount < _maxRetries) {
      _retryCount++;
      print('Retrying MJPEG stream (attempt $_retryCount of $_maxRetries)');
      Future.delayed(Duration(seconds: 2 * _retryCount), () {
        if (mounted) {
          _startStreaming();
        }
      });
    } else {
      print('Max retry attempts reached');
      _retryCount = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingWidget;
    }
    
    if (_hasError || _imageBytes == null) {
      return GestureDetector(
        onTap: () {
          _retryCount = 0;
          // Use a post-frame callback to restart the streaming process
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startStreaming();
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
                // Use a post-frame callback to restart the streaming process
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _startStreaming();
                });
              },
              child: const Text('Retry Connection'),
            ),
          ],
        ),
      );
    }
    
    return Image.memory(
      _imageBytes!,
      fit: widget.fit,
      gaplessPlayback: true,
    );
  }
} 