import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http; // Import for HTTP requests
import 'dart:convert'; // Import for JSON encoding/decoding

import 'server_offline_screen.dart';
import 'session_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paperclip Anti-Cheating App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Poppins',
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _referenceController = TextEditingController(); // For LRN
  final TextEditingController _accessCodeController = TextEditingController(); // For Password
  late AnimationController _lottieController;
  bool _isLoading = false; // To show loading state during login
  String? _errorMessage; // To display login error messages

  // Base URL for your PHP API endpoints.
  // IMPORTANT: Replace this with your actual server IP or domain name.
  // This should be the same base URL as in session_screen.dart.
  final String _apiBaseUrl = "http://192.168.18.11/"; // Adjust path as needed

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Auto-play the animation when the screen loads
    _lottieController.forward();

    // Optional: Loop the animation
    _lottieController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _lottieController.reset();
        _lottieController.forward();
      }
    });
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _accessCodeController.dispose();
    _lottieController.dispose();
    super.dispose();
  }

  // Helper function to derive teacher_table_name from LRN
  // This logic must match how your students are assigned to teacher tables.
  // Example: If LRNs starting with 'S1' belong to teacher1, 'S2' to teacher2, etc.
  String? _deriveTeacherTableName(String lrn) {
    if (lrn.startsWith('S1')) { // Example: S1001 for students_teacher1
      return 'students_teacher1';
    } else if (lrn.startsWith('S2')) { // Example: S2001 for students_teacher2
      return 'students_teacher2';
    }
    // Add more conditions for other teachers if you have more student tables
    return null; // Return null if no matching table name is found for the given LRN
  }

  // Method to handle student login
  Future<void> _loginStudent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null; // Clear previous errors
    });

    final lrn = _referenceController.text.trim();
    final password = _accessCodeController.text.trim();

    if (lrn.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Please enter both LRN and password.";
        _isLoading = false;
      });
      return;
    }

    // Derive the teacher table name from the LRN before sending the request
    final teacherTableName = _deriveTeacherTableName(lrn);
    if (teacherTableName == null) {
      setState(() {
        _errorMessage = "Invalid LRN format or no associated teacher found.";
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/student_login.php'),
        body: {
          'lrn': lrn,
          'password': password,
          'teacher_table_name': teacherTableName, // Pass the derived table name to PHP
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          // Login successful, navigate to OpenWindowScreen
          final String studentLrn = data['student_lrn'];
          final String fetchedTeacherTableName = data['teacher_table_name']; // Use fetched table name from PHP response
          final String studentName = data['student_name']; // Get student name from response

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OpenWindowScreen(
                studentLrn: studentLrn,
                teacherTableName: fetchedTeacherTableName,
                studentName: studentName, // Pass student name to session screen
              ),
            ),
          );
        } else {
          // Login failed, show error message from backend
          setState(() {
            _errorMessage = data['message'] ?? "Login failed. Please try again.";
          });
        }
      } else {
        // Server error (e.g., 500, 404)
        setState(() {
          _errorMessage = "Server error: ${response.statusCode}. Please try again later.";
        });
      }
    } catch (e) {
      // Network error or other exceptions
      setState(() {
        _errorMessage = "Network error: Could not connect to server. Check your internet connection or server URL.";
      });
      print('Login error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final size = MediaQuery.of(context).size;
    // ignore: unused_local_variable
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF7B4EFF), // Purple background color
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08,
              vertical: size.height * 0.04,
            ),
            child: Column(
              children: [
                // Logo and app name
                SizedBox(height: size.height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Replace with your actual logo SVG
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: SvgPicture.asset(
                        width: 50,
                        height: 50,
                        color: Colors.white,
                        'assets/images/paperclip_logo.svg', // Your SVG file
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'paperclip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'anti-cheating app',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Lottie Animation instead of static image
                SizedBox(height: size.height * 0.04),
                SizedBox(
                  height: size.height * 0.25,
                  child: Center(
                    child: Lottie.asset(
                      'assets/animations/education_animation.json', // Your Lottie JSON file
                      controller: _lottieController,
                      fit: BoxFit.contain,
                      width: size.width * 0.9,
                      height: size.height * 0.9,
                      // Optional: Add onLoaded callback if you need to set specific animation behavior
                      onLoaded: (composition) {
                        // You can adjust the controller duration to match the animation
                        _lottieController.duration = composition.duration;
                      },
                    ),
                  ),
                ),

                // Hello text
                SizedBox(height: size.height * 0.03),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello,',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'please log in using your student account.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Form fields
                SizedBox(height: size.height * 0.04),
                TextField(
                  controller: _referenceController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    hintText: "Learner's Reference Number",
                    hintStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _accessCodeController,
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    hintText: "Access Code", // Changed from "Access Code" to "Password" conceptually
                    hintStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),

                // Error message display
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Login button
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginStudent, // Disable button while loading
                    style: ElevatedButton.styleFrom(
                      foregroundColor: const Color(0xFF7B4EFF), backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF7B4EFF)) // Show loading indicator
                        : const Text(
                            'LOG IN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                // OR divider
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.white.withOpacity(0.5),
                        thickness: 1,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.white.withOpacity(0.5),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                // Teacher note
                const SizedBox(height: 16),
                const Text(
                  "If you're a teacher, please visit\nthe web application instead.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),

                // Web application button (This button now correctly navigates to OpenWindowScreen
                // with placeholder values, as it's not a student login path)
                const SizedBox(height: 16),
                SizedBox(
                  width: size.width * 0.6,
                  child: ElevatedButton(
                    onPressed: () {
                      // This button is for teachers to visit the web app.
                      // In a real scenario, this would likely open a browser or
                      // navigate to a teacher-specific login flow.
                      // For now, it navigates to the OpenWindowScreen with dummy data.
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const ServerOfflineScreen()
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.white.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Visit Web Application',
                      style: TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                // Footer
                SizedBox(height: size.height * 0.06),
                Text(
                  'Hosted by Tapinac Senior High School @ STEM',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PaperclipLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final Path path = Path()
      ..moveTo(size.width * 0.3, size.height * 0.2)
      ..lineTo(size.width * 0.3, size.height * 0.7)
      ..arcToPoint(
        Offset(size.width * 0.7, size.height * 0.7),
        radius: Radius.circular(size.width * 0.2),
        clockwise: false,
      )
      ..lineTo(size.width * 0.7, size.height * 0.3)
      ..arcToPoint(
        Offset(size.width * 0.5, size.height * 0.3),
        radius: Radius.circular(size.width * 0.1),
        clockwise: true,
      )
      ..lineTo(size.width * 0.5, size.height * 0.6)
      ..arcToPoint(
        Offset(size.width * 0.5, size.height * 0.6),
        radius: Radius.circular(size.width * 0.1),
        clockwise: false,
      );

    final Path linePath = Path()
      ..moveTo(size.width * 0.2, size.height * 0.2)
      ..lineTo(size.width * 0.8, size.height * 0.8);

    canvas.drawPath(path, paint);
    canvas.drawPath(linePath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
