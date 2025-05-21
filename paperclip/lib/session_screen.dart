import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:lottie/lottie.dart';
import 'main.dart';

class OpenWindowScreen extends StatefulWidget {
  const OpenWindowScreen({Key? key}) : super(key: key);

  @override
  State<OpenWindowScreen> createState() => _OpenWindowScreenState();
}

class _OpenWindowScreenState extends State<OpenWindowScreen> {
  late final WebViewController controller;
  bool _isLoading = true;
  final TextEditingController _exitCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.zipgrade.com/student/'));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Color(0xFF7B4EFF),
          statusBarIconBrightness: Brightness.light,
        ),
      );
    });
  }

  @override
  void dispose() {
    _exitCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  // Gallery/Info icon (left)
                  IconButton(
                    icon: const Icon(Icons.analytics, color: Colors.white),
                    onPressed: () {
                      _showInfoBottomSheet(context);
                    },
                  ),

                  // Paperclip logo and text
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

                  // Exit icon (right)
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

            // WebView to display ZipGrade
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: controller),
                  // Loading indicator
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

  // Show the info bottom sheet (left button)
  void _showInfoBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromRGBO(125, 89, 255, 0.73),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.7,
          builder: (_, controller) {
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
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Basic Information section
                        const Text(
                          'Basic Information',
                          style: TextStyle(
                            color: Color(0xFF7B4EFF),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const Divider(height: 24),

                        // User LRN
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'User LRN:',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '107***130146',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Student Name
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Student Name:',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Christofer D. B.',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Analytics section
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

                        // Analytics cards
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Times exited
                            _buildAnalyticsCard(
                              'Times exited:',
                              '99',
                            ),

                            // Screenshot taken
                            _buildAnalyticsCard(
                              'Screenshot taken:',
                              '0',
                            ),

                            // Keyboard opened
                            _buildAnalyticsCard(
                              'Keyboard opened',
                              '0',
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
  }

  // Show the exit bottom sheet (right button)
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
          builder: (_, controller) {
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
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Illustration
                        SizedBox(
                          height: 180,
                          child: Center(
                            // Use the same illustration from login screen
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

                        // Exit code input
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
                          onPressed: () {
                            // Implement exit functionality
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MyApp(),
                              ),
                            );
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

  // Helper method to build analytics cards
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
