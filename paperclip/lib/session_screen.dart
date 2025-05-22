import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    with WidgetsBindingObserver { // Mixin for observing app lifecycle changes
  // MethodChannel for platform-specific communication (e.g., screenshot detection)
  static const platform = MethodChannel('com.example.paperclip/screenshots');
  // Flag to ensure the screenshot handler is set only once globally
  static bool _screenshotHandlerSet = false;

  late final WebViewController controller; // WebView controller
  bool _isLoading = true; // State for WebView loading indicator
  final TextEditingController _exitCodeController = TextEditingController(); // Controller for exit code input

  // Analytics counters, these will be synchronized with the PHP backend
  int _timesExited = 0;
  int _screenshotsTaken = 0;
  int _keyboardOpened = 0;
  bool _isKeyboardVisible = false; // Tracks keyboard visibility state

  // Base URL for your PHP API endpoints.
  // IMPORTANT: Replace this with your actual server IP or domain name.
  // Examples:
  // - For Android Emulator: "http://10.0.2.2/your_backend_folder/"
  // - For iOS Simulator/Device: "http://localhost/your_backend_folder/" (if running PHP locally)
  // - For physical Android device: "http://YOUR_MACHINE_IP_ADDRESS/your_backend_folder/"
  // - For deployed server: "https://yourdomain.com/your_backend_folder/" (ALWAYS use HTTPS in production)
  final String _apiBaseUrl = "http://192.168.18.11/"; // Adjust path as needed

  @override
  void initState() {
    super.initState();
    // Add this widget as an observer for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Fetch initial analytics data from the backend when the screen loads
    _fetchAnalytics();

    // Set up the MethodChannel handler for screenshot detection only once
    if (!_screenshotHandlerSet) {
      platform.setMethodCallHandler((call) async {
        if (call.method == "screenshotTaken") {
          if (mounted) { // Check if the widget is still mounted before calling setState
            // Increment the local screenshot count for immediate UI update
            setState(() {
              _screenshotsTaken++;
            });
            // Send the increment (delta of 1) to the backend
            _sendAnalyticsUpdate(screenshotsTakenDelta: 1);
          }
          print('Screenshot taken. Local count: $_screenshotsTaken');
        }
      });
      // Invoke the native method to start listening for screenshot events
      platform.invokeMethod('startScreenshotListener');
      _screenshotHandlerSet = true; // Set the flag to prevent re-initialization
    }

    // Initialize the WebViewController for ZipGrade
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Enable JavaScript
      ..setBackgroundColor(Colors.white) // Set background color
      ..setNavigationDelegate( // Set navigation delegate to track page loading
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
          // You can add onWebResourceError, onNavigationRequest here if needed
        ),
      )
      ..loadRequest(Uri.parse('https://www.zipgrade.com/student/')); // Load the ZipGrade URL

    // Adjust system UI overlay style after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF7B4EFF), // Custom status bar color
          statusBarIconBrightness: Brightness.light, // Light icons for dark status bar
        ),
      );
    });
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
    if (state == AppLifecycleState.paused) {
      // Increment local exit count
      setState(() {
        _timesExited++;
      });
      // Send the increment to the backend
      _sendAnalyticsUpdate(timesExitedDelta: 1);
      print('App exited. Local count: $_timesExited');
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
      // Keyboard has disappeared
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
    try {
      final response = await http.get(Uri.parse(
          '$_apiBaseUrl/student_api.php?action=get_analytics&student_id=${widget.studentLrn}&teacher_table_name=${widget.teacherTableName}'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            // Update local state with data from the backend
            _screenshotsTaken = int.parse(data['data']['screenshots_taken'].toString());
            _timesExited = int.parse(data['data']['times_exited'].toString());
            // Note: Database column is 'keyboard_used', Flutter variable is 'keyboardOpened'
            _keyboardOpened = int.parse(data['data']['keyboard_used'].toString());
          });
          print('Analytics fetched: Screenshots: $_screenshotsTaken, Exits: $_timesExited, Keyboard: $_keyboardOpened');
        } else {
          print('Failed to fetch analytics: ${data['message']}');
          // If student data is not found or an error occurs, reset local counts to 0
          setState(() {
            _screenshotsTaken = 0;
            _timesExited = 0;
            _keyboardOpened = 0;
          });
          // In a real scenario, if a student record doesn't exist, you might
          // want to create it on the server with initial zero counts.
          // For this setup, we assume student records are pre-created by the teacher.
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
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/student_api.php'),
        body: {
          'action': 'update_analytics', // Action to perform on the API
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
          // No need to call _fetchAnalytics() here as local state is already updated,
          // and it will be fetched again when the info modal is opened.
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
    try {
      final response = await http.get(Uri.parse(
          '$_apiBaseUrl/student_api.php?action=get_exit_code&student_id=${widget.studentLrn}&teacher_table_name=${widget.teacherTableName}'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success'] && data['data'] != null && data['data']['exit_code'] != null) {
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

  // Shows the analytics information bottom sheet.
  void _showInfoBottomSheet(BuildContext context) {
    // Fetch the latest analytics data before showing the modal to ensure accuracy.
    _fetchAnalytics().then((_) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true, // Allows the sheet to take up more height
        backgroundColor: const Color.fromRGBO(125, 89, 255, 0.73), // Semi-transparent background
        builder: (BuildContext context) {
          return DraggableScrollableSheet(
            initialChildSize: 0.5, // Initial height of the sheet
            minChildSize: 0.3, // Minimum height when dragged down
            maxChildSize: 0.7, // Maximum height when dragged up
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
                    // Drag handle at the top of the sheet
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Close button at the top right
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    // Main content of the info sheet, scrollable
                    Expanded(
                      child: ListView(
                        controller: scrollController, // Link to DraggableScrollableSheet's controller
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          // Basic Information section title
                          const Text(
                            'Basic Information',
                            style: TextStyle(
                              color: Color(0xFF7B4EFF),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const Divider(height: 24), // Separator

                          // User LRN display
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
                                widget.studentLrn, // Display the actual student LRN passed to the widget
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Student Name display
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
                                widget.studentName, // Display the actual student name passed to the widget
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // Analytics section title
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

                          // Analytics cards displaying the fetched counts
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Times exited card
                              _buildAnalyticsCard(
                                'Times exited:',
                                '$_timesExited',
                              ),

                              // Screenshot taken card
                              _buildAnalyticsCard(
                                'Screenshot taken:',
                                '$_screenshotsTaken',
                              ),

                              // Keyboard opened card
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
    }); // End of .then((_) { ... });
  }

  // Shows the exit confirmation bottom sheet.
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
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Close button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Illustration
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

                        // Exit message
                        const Text(
                          'Before exiting, please enter your exit code given by your class adviser.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500),
                        ),

                        const SizedBox(height: 24),

                        // Exit code input field
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

                        // Exit button
                        ElevatedButton(
                          onPressed: () async {
                            // Get the entered exit code
                            String enteredCode = _exitCodeController.text;
                            // Fetch the correct exit code from the backend
                            String? correctCode = await _getExitCode();

                            // Validate the entered code against the fetched code
                            if (correctCode != null && enteredCode == correctCode) {
                              Navigator.pop(context); // Close the bottom sheet
                              // Navigate back to the login screen (or wherever MyApp leads)
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyApp(),
                                ),
                              );
                            } else {
                              // Show a SnackBar if the code is invalid
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Invalid Exit Code.')),
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

  // Helper method to build a standardized analytics card widget.
  Widget _buildAnalyticsCard(String title, String value) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.27, // Responsive width
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
