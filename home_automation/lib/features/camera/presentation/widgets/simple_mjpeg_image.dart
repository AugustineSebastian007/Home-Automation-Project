import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A simple camera viewer that uses WebView with a more robust approach
/// This handles video decoding errors and provides better stability
class SimpleMjpegImage extends StatefulWidget {
  final String streamUrl;
  final BoxFit fit;
  final Duration refreshInterval; // Kept for backward compatibility
  final Widget loadingWidget;
  final Widget errorWidget;

  const SimpleMjpegImage({
    Key? key,
    required this.streamUrl,
    this.fit = BoxFit.contain,
    this.refreshInterval = const Duration(milliseconds: 3000), // Not used in direct streaming
    this.loadingWidget = const Center(child: CircularProgressIndicator()),
    this.errorWidget = const Center(child: Icon(Icons.error, color: Colors.red, size: 48)),
  }) : super(key: key);

  @override
  State<SimpleMjpegImage> createState() => _SimpleMjpegImageState();
}

class _SimpleMjpegImageState extends State<SimpleMjpegImage> {
  bool _isLoading = true;
  bool _hasError = false;
  late WebViewController _controller;
  bool _isTargetDetection = false;
  Timer? _healthCheckTimer;
  
  @override
  void initState() {
    super.initState();
    // Check if this is the target detection URL
    _isTargetDetection = widget.streamUrl.contains('5000');
    print("Initializing camera feed: ${widget.streamUrl} (Target Detection: $_isTargetDetection)");
    _initializeWebView();
    
    // Set up a health check timer to monitor and recover from potential issues
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isLoading && !_hasError) {
        _checkStreamHealth();
      }
    });
  }
  
  @override
  void dispose() {
    _healthCheckTimer?.cancel();
    super.dispose();
  }
  
  void _checkStreamHealth() {
    // Inject JavaScript to check if the stream is still working
    _controller.runJavaScript('''
      (function() {
        try {
          const status = document.getElementById('status');
          if (status) {
            status.textContent = "Checking connection...";
            status.style.display = 'block';
            status.style.opacity = '1';
          }
          
          // Send a ping to the stream URL to check if it's responsive
          fetch('${widget.streamUrl.split('/video_feed')[0]}/ping', { 
            method: 'GET',
            cache: 'no-cache',
            mode: 'no-cors',
            timeout: 5000
          })
          .then(() => {
            if (status) {
              status.textContent = "Connection OK";
              setTimeout(() => {
                status.style.opacity = '0';
                setTimeout(() => {
                  status.style.display = 'none';
                }, 1000);
              }, 2000);
            }
            console.log("Stream health check passed");
          })
          .catch(err => {
            console.error("Stream health check failed:", err);
            if (status) {
              status.textContent = "Reconnecting...";
            }
            // Reload the page to reestablish connection
            window.location.reload();
          });
        } catch (e) {
          console.error("Error in health check:", e);
        }
      })();
    ''').catchError((error) {
      print("Error running health check script: $error");
    });
  }
  
  void _initializeWebView() {
    if (!mounted) return;
    
    try {
      print("Initializing WebView for camera feed: ${widget.streamUrl}");
      
      // Create a simpler HTML page that uses a more reliable method to display the stream
      final String htmlContent = '''
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body, html {
              margin: 0;
              padding: 0;
              height: 100%;
              overflow: hidden;
              background-color: #000;
              display: flex;
              justify-content: center;
              align-items: center;
            }
            .stream-container {
              width: 100%;
              height: 100%;
              position: relative;
              display: flex;
              justify-content: center;
              align-items: center;
            }
            #status {
              position: absolute;
              bottom: 10px;
              left: 10px;
              color: white;
              background-color: rgba(0,0,0,0.5);
              padding: 5px;
              border-radius: 5px;
              font-family: Arial, sans-serif;
              font-size: 12px;
              z-index: 10;
              transition: opacity 0.5s ease;
            }
            /* Simple image display - more reliable than iframe for MJPEG */
            img.mjpeg {
              max-width: 100%;
              max-height: 100%;
              object-fit: ${widget.fit == BoxFit.contain ? 'contain' : 'cover'};
            }
            /* Error message styling */
            .error-container {
              position: absolute;
              top: 0;
              left: 0;
              right: 0;
              bottom: 0;
              display: none;
              flex-direction: column;
              justify-content: center;
              align-items: center;
              background-color: rgba(0,0,0,0.7);
              color: white;
              z-index: 20;
              text-align: center;
              padding: 20px;
            }
            .error-icon {
              font-size: 48px;
              color: #ff5252;
              margin-bottom: 16px;
            }
            .retry-button {
              margin-top: 16px;
              padding: 8px 16px;
              background-color: #2196F3;
              color: white;
              border: none;
              border-radius: 4px;
              cursor: pointer;
              font-family: Arial, sans-serif;
            }
            .retry-button:hover {
              background-color: #0b7dda;
            }
          </style>
        </head>
        <body>
          <div class="stream-container">
            <!-- Use a simple image tag for the MJPEG stream -->
            <img id="streamImage" class="mjpeg" src="${widget.streamUrl}" alt="Camera Feed">
            
            <div id="status">Connecting...</div>
            
            <!-- Error display container -->
            <div id="errorContainer" class="error-container">
              <div class="error-icon">⚠️</div>
              <div id="errorMessage">Unable to connect to camera</div>
              <div id="errorDetail" style="font-size: 12px; color: #cccccc; margin-top: 8px;">
                ${_isTargetDetection 
                  ? 'Target detection server may be offline or still starting up.'
                  : 'Please check your network connection and try again.'}
              </div>
              <button id="retryButton" class="retry-button">Retry Connection</button>
            </div>
          </div>
          
          <script>
            // Elements
            const statusElement = document.getElementById('status');
            const streamImage = document.getElementById('streamImage');
            const errorContainer = document.getElementById('errorContainer');
            const errorMessage = document.getElementById('errorMessage');
            const retryButton = document.getElementById('retryButton');
            
            // Variables
            let isConnected = false;
            let connectionAttempts = 0;
            let lastLoadTime = 0;
            let errorTimeout = null;
            
            // Function to update the status display
            function updateStatus(message) {
              statusElement.textContent = message;
              statusElement.style.display = 'block';
              statusElement.style.opacity = '1';
              console.log(message);
            }
            
            // Function to hide status after a delay
            function hideStatus(delay = 3000) {
              setTimeout(() => {
                statusElement.style.opacity = '0';
                setTimeout(() => {
                  statusElement.style.display = 'none';
                }, 500);
              }, delay);
            }
            
            // Function to show error
            function showError(message, detail) {
              errorMessage.textContent = message || 'Connection failed';
              if (detail) {
                document.getElementById('errorDetail').textContent = detail;
              }
              errorContainer.style.display = 'flex';
              updateStatus('Error: ' + message);
            }
            
            // Function to hide error
            function hideError() {
              errorContainer.style.display = 'none';
            }
            
            // Function to reload the stream
            function reloadStream() {
              hideError();
              updateStatus('Reconnecting...');
              connectionAttempts++;
              
              // Add timestamp to URL to prevent caching
              streamImage.src = '${widget.streamUrl}?t=' + new Date().getTime();
              
              // Set a timeout to detect if loading takes too long
              if (errorTimeout) {
                clearTimeout(errorTimeout);
              }
              
              errorTimeout = setTimeout(() => {
                if (!isConnected) {
                  showError('Connection timed out', 'The server is not responding.');
                }
              }, 10000);
            }
            
            // Handle image load events
            streamImage.onload = function() {
              isConnected = true;
              lastLoadTime = new Date().getTime();
              hideError();
              
              if (connectionAttempts === 0) {
                updateStatus('Connected');
                hideStatus(2000);
              } else {
                updateStatus('Reconnected successfully');
                hideStatus(2000);
              }
              
              if (errorTimeout) {
                clearTimeout(errorTimeout);
                errorTimeout = null;
              }
            };
            
            // Handle image error events
            streamImage.onerror = function(e) {
              console.error('Stream image error:', e);
              
              if (errorTimeout) {
                clearTimeout(errorTimeout);
                errorTimeout = null;
              }
              
              if (connectionAttempts < 3) {
                // Try a few quick retries
                updateStatus('Connection failed, retrying (' + (connectionAttempts + 1) + '/3)');
                reloadStream();
              } else {
                // After several retries, show the error UI
                isConnected = false;
                showError(
                  'Unable to connect to camera', 
                  ${_isTargetDetection} 
                    ? 'Target detection server may be offline or still starting up.'
                    : 'Please check your network connection and try again.'
                );
              }
            };
            
            // Retry button click handler
            retryButton.addEventListener('click', function() {
              connectionAttempts = 0;
              reloadStream();
            });
            
            // Set up a watchdog timer to detect frozen streams
            setInterval(() => {
              const now = new Date().getTime();
              // If we're connected but haven't received a new frame in 30 seconds
              if (isConnected && (now - lastLoadTime) > 30000) {
                console.log('Stream appears to be frozen, attempting to reconnect');
                updateStatus('Stream frozen, reconnecting...');
                reloadStream();
              }
            }, 10000);
          </script>
        </body>
        </html>
      ''';
      
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..enableZoom(false)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              print('Camera feed page started loading: ${widget.streamUrl}');
            },
            onPageFinished: (String url) {
              print('Camera feed page finished loading: ${widget.streamUrl}');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              print('Camera feed WebView error for ${widget.streamUrl}: ${error.description}, errorType: ${error.errorType}, errorCode: ${error.errorCode}');
              if (mounted && _isLoading) {
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                });
              }
            },
          ),
        )
        ..loadHtmlString(htmlContent);
      
      // Add a timeout to handle slow loading
      Future.delayed(const Duration(seconds: 10), () {
        if (_isLoading && mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
      
    } catch (e) {
      print('Error initializing WebView for camera feed ${widget.streamUrl}: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }
  
  void _retryConnection() {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    
    _initializeWebView();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingWidget;
    }
    
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            widget.errorWidget,
            const SizedBox(height: 16),
            Text(
              'Unable to connect to camera',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _isTargetDetection 
                ? 'Target detection server may be offline or still starting up.'
                : 'Please check your network connection and try again.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _retryConnection,
              child: const Text('Retry Connection'),
            ),
          ],
        ),
      );
    }
    
    return WebViewWidget(controller: _controller);
  }
} 