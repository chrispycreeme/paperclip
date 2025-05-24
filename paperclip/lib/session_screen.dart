// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http; // Import for HTTP requests
import 'dart:convert'; // Import for JSON encoding/decoding

import 'main.dart'; // Ensure this points to your main app file

// The OpenWindowScreen now accepts studentLrn, teacherTableName, and studentName
class OpenWindowScreen extends StatefulWidget {
  final String studentLrn;
  final String teacherTableName; // e.g., 'students_teacher1'
  final String studentName; // New: Student's name passed from login

  const OpenWindowScreen({
    Key? key,
    required this.studentLrn,
    required this.teacherTableName,
    required this.studentName, // Required parameter
  }) : super(key: key);

  @override
  State<OpenWindowScreen> createState() => _OpenWindowScreenState();
}

class _OpenWindowScreenState extends State<OpenWindowScreen>
    with WidgetsBindingObserver {
  // Mixin for observing app lifecycle changes
  // MethodChannel for platform-specific communication (e.g., screenshot detection)
  static const platform = MethodChannel('com.example.paperclip/screenshots');
  // Flag to ensure the screenshot handler is set only once globally
  static bool _screenshotHandlerSet = false;

  late final WebViewController controller; // WebView controller
  bool _isLoading = true; // State for WebView loading indicator
  final TextEditingController _exitCodeController =
      TextEditingController(); // Controller for exit code input

  int _timesExited = 0;
  int _screenshotsTaken = 0;
  int _keyboardOpened = 0;
  bool _isKeyboardVisible = false;

  // Base URL for your PHP API endpoints.
  String? _apiBaseUrl; // Now nullable, fetched asynchronously

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // Fetch API base URL first, then proceed with analytics fetch and screenshot listener setup
    _fetchApiBaseUrl().then((url) {
      if (mounted) {
        // Ensure widget is still mounted before setState
        setState(() {
          _apiBaseUrl = url;
        });
        _fetchAnalytics(); // Fetch analytics once API base URL is available

        // Set up screenshot handler only after API base URL is available and once
        if (!_screenshotHandlerSet) {
          platform.setMethodCallHandler((call) async {
            if (call.method == "screenshotTaken") {
              if (mounted) {
                setState(() {
                  _screenshotsTaken++;
                });
                _sendAnalyticsUpdate(screenshotsTakenDelta: 1);
              }
              print('Screenshot taken. Local count: $_screenshotsTaken');
            }
          });
          // Await the invokeMethod call
          platform.invokeMethod('startScreenshotListener');
          _screenshotHandlerSet = true;
        }
      }
    });

    // Initialize the WebViewController for ZipGrade
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Enable JavaScript
      ..setBackgroundColor(Colors.white) // Set background color
      ..setNavigationDelegate(
        // Set navigation delegate to track page loading
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true; // Show loading indicator when page starts
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false; // Hide loading indicator when page finishes
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(
          'https://www.zipgrade.com/student/')); // Load the ZipGrade URL

    // Adjust system UI overlay style after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF7B4EFF), // Custom status bar color
          statusBarIconBrightness:
              Brightness.light, // Light icons for dark status bar
        ),
      );
    });
  }

  // Method to fetch API base URL from a remote source
  Future<String?> _fetchApiBaseUrl() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://raw.githubusercontent.com/chrispycreeme/paperclip-server-dump/refs/heads/main/server'),
      );
      if (response.statusCode == 200) {
        return response.body.trim();
      }
    } catch (e) {
      print('Error fetching API base URL in session_screen: $e');
    }
    return null;
  }

  @override
  void dispose() {
    // Remove the app lifecycle observer to prevent memory leaks
    WidgetsBinding.instance.removeObserver(this);
    // Dispose the text editing controller
    _exitCodeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Detect when the app goes into the background (user exits or switches apps)
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Increment local exit count
      setState(() {
        _timesExited++;
      });
      // Send the increment to the backend
      _sendAnalyticsUpdate(timesExitedDelta: 1);
      print('App exited. Local count: $_timesExited');

      // Attempt to bring the app back to foreground if it's paused or detached
      // This is a proactive measure to keep the app in focus if the user tries to exit without the code.
      final service = FlutterBackgroundService();
      // Ensure the service is running before trying to bring to foreground
      service.startService().then((_) {
        // Only attempt to set as foreground if the service started successfully
        service.invoke('setAsForeground');
      }).catchError((e) {
        print('Error starting service to bring to foreground: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detect keyboard visibility by checking the bottom view insets
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    if (keyboardHeight > 0 && !_isKeyboardVisible) {
      // Keyboard has appeared
      setState(() {
        _keyboardOpened++;
        _isKeyboardVisible = true;
      });
      // Send the increment to the backend
      _sendAnalyticsUpdate(keyboardOpenedDelta: 1);
      print('Keyboard opened. Local count: $_keyboardOpened');
    } else if (keyboardHeight == 0 && _isKeyboardVisible) {
      setState(() {
        _isKeyboardVisible = false;
      });
      print('Keyboard closed.');
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom app bar with purple background
            Container(
              color: const Color(0xFF7B4EFF),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Analytics/Info icon (left) to show the bottom sheet
                  IconButton(
                    icon: const Icon(Icons.analytics, color: Colors.white),
                    onPressed: () {
                      _showInfoBottomSheet(context);
                    },
                  ),

                  // Paperclip logo and text in the center
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/images/paperclip_logo.svg',
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'paperclip',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // Exit icon (right) to show the exit bottom sheet
                  IconButton(
                    icon:
                        const Icon(Icons.logout_outlined, color: Colors.white),
                    onPressed: () {
                      _showExitBottomSheet(context);
                    },
                  ),
                ],
              ),
            ),

            // Expanded WebView to display ZipGrade content
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: controller),
                  // Loading indicator shown while WebView is loading
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF7B4EFF)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HTTP Methods for Backend Communication ---

  // Fetches the current analytics counts for the student from the PHP backend.
  Future<void> _fetchAnalytics() async {
    if (_apiBaseUrl == null) {
      print('API Base URL is null, cannot fetch analytics.');
      return;
    }
    try {
      final response = await http.get(Uri.parse(
          '$_apiBaseUrl/student_api.php?action=get_analytics&student_id=${widget.studentLrn}&teacher_table_name=${widget.teacherTableName}'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _screenshotsTaken =
                int.parse(data['data']['screenshots_taken'].toString());
            _timesExited = int.parse(data['data']['times_exited'].toString());
            _keyboardOpened =
                int.parse(data['data']['keyboard_used'].toString());
          });
          print(
              'Analytics fetched: Screenshots: $_screenshotsTaken, Exits: $_timesExited, Keyboard: $_keyboardOpened');
        } else {
          print('Failed to fetch analytics: ${data['message']}');
          setState(() {
            _screenshotsTaken = 0;
            _timesExited = 0;
            _keyboardOpened = 0;
          });
        }
      } else {
        print('Server error fetching analytics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching analytics: $e');
    }
  }

  // Sends incremental updates to the analytics counts to the PHP backend.
  Future<void> _sendAnalyticsUpdate({
    int screenshotsTakenDelta = 0,
    int timesExitedDelta = 0,
    int keyboardOpenedDelta = 0,
  }) async {
    if (_apiBaseUrl == null) {
      print('API Base URL is null, cannot send analytics update.');
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/student_api.php'),
        body: {
          'action': 'update_analytics',
          'student_id': widget.studentLrn,
          'teacher_table_name': widget.teacherTableName,
          'screenshots_taken_delta': screenshotsTakenDelta.toString(),
          'times_exited_delta': timesExitedDelta.toString(),
          'keyboard_opened_delta': keyboardOpenedDelta.toString(),
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          print('Analytics update successful: ${data['message']}');
        } else {
          print('Analytics update failed: ${data['message']}');
        }
      } else {
        print('Server error updating analytics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending analytics update: $e');
    }
  }

  // Fetches the exit code for the current student from the PHP backend for validation.
  Future<String?> _getExitCode() async {
    if (_apiBaseUrl == null) {
      print('API Base URL is null, cannot get exit code.');
      return null;
    }
    try {
      final response = await http.get(Uri.parse(
          '$_apiBaseUrl/student_api.php?action=get_exit_code&student_id=${widget.studentLrn}&teacher_table_name=${widget.teacherTableName}'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] &&
            data['data'] != null &&
            data['data']['exit_code'] != null) {
          return data['data']['exit_code'].toString();
        } else {
          print('Failed to get exit code: ${data['message']}');
          return null;
        }
      } else {
        print('Server error getting exit code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting exit code: $e');
      return null;
    }
  }

  // --- UI Methods for Bottom Sheets ---

  void _showInfoBottomSheet(BuildContext context) {
    _fetchAnalytics().then((_) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: const Color.fromRGBO(125, 89, 255, 0.73),
        builder: (BuildContext context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.7,
            builder: (_, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          const Text(
                            'Basic Information',
                            style: TextStyle(
                              color: Color(0xFF7B4EFF),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'User LRN:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                widget.studentLrn,
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Student Name:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                widget.studentName,
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Row(
                            children: [
                              Icon(
                                Icons.analytics_outlined,
                                color: Color(0xFF7B4EFF),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Analytics',
                                style: TextStyle(
                                  color: Color(0xFF7B4EFF),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildAnalyticsCard(
                                'Times exited:',
                                '$_timesExited',
                              ),
                              _buildAnalyticsCard(
                                'Screenshot taken:',
                                '$_screenshotsTaken',
                              ),
                              _buildAnalyticsCard(
                                'Keyboard opened',
                                '$_keyboardOpened',
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    });
  }

  void _showExitBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromRGBO(125, 89, 255, 0.73),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.6,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        SizedBox(
                          height: 180,
                          child: Center(
                            child: Lottie.asset(
                              'assets/animations/education_animation.json',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Before exiting, please enter your exit code given by your class adviser.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _exitCodeController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[200],
                            hintText: 'Six-String Exit Code',
                            hintStyle:
                                const TextStyle(color: Color(0xFF9E9E9E)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () async {
                            String enteredCode = _exitCodeController.text;
                            String? correctCode = await _getExitCode();

                            if (correctCode != null &&
                                enteredCode == correctCode) {
                              // Stop the background service before navigating away
                              final service = FlutterBackgroundService();
                              try {
                                service.invoke('stopService');
                              } catch (e) {
                                print('Error invoking stopService: $e');
                                // Log the error but don't block navigation
                              }

                              Navigator.pop(context);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyApp(),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Invalid Exit Code.')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFF7B4EFF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Exit Session',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnalyticsCard(String title, String value) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.27,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
