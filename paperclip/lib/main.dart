// ignore_for_file: avoid_print, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
// ignore: unused_import
import 'package:paperclip_app/background_service_handler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';

import 'server_offline_screen.dart';
import 'session_screen.dart';
import 'ota_update_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request necessary permissions for Android
  if (Platform.isAndroid) {
    await _requestPermissions();
  }

  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  // Request notification permissions
  final notificationStatus = await Permission.notification.request();
  if (notificationStatus.isGranted) {
    print("Notification permission granted!");
  } else if (notificationStatus.isDenied) {
    print("Notification permission denied. Foreground service might not work.");
  } else if (notificationStatus.isPermanentlyDenied) {
    print(
        "Notification permission permanently denied. User must enable from settings.");
    openAppSettings();
  }

  // Request other permissions
  await Permission.ignoreBatteryOptimizations.request();

  // For Android 12+ exact alarm permission
  if (Platform.isAndroid) {
    await Permission.scheduleExactAlarm.request();
  }
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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _accessCodeController = TextEditingController();
  late AnimationController _lottieController;
  bool _isLoading = false;
  String? _errorMessage;
  String? _apiBaseUrl;

  final OtaUpdateService _otaUpdateService = OtaUpdateService();

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fetchApiBaseUrl().then((url) {
      if (mounted) {
        setState(() {
          _apiBaseUrl = url;
        });
      }
    });

    _fetchApiBaseUrl().then((url) {
      if (mounted) {
        setState(() {
          _apiBaseUrl = url;
        });
        // After API base URL is fetched, check for updates using the service
        _otaUpdateService.checkForUpdates(context);
      }
    });

    _lottieController.forward();
    _lottieController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _lottieController.reset();
        _lottieController.forward();
      }
    });
  }

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
      print('Error fetching API base URL: $e');
    }
    return null;
  }

  Future<List<String>> _fetchPossibleTables() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://raw.githubusercontent.com/chrispycreeme/paperclip-server-dump/refs/heads/main/allowed_tables'),
      );
      if (response.statusCode == 200) {
        // Split by lines and remove empty lines
        return response.body
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } catch (e) {
      print('Error fetching possible tables: $e');
    }
    // Fallback to an empty list if fetch fails
    return [];
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _accessCodeController.dispose();
    _lottieController.dispose();
    super.dispose();
  }

  Future<void> _loginStudent() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
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

    if (_apiBaseUrl == null) {
      setState(() {
        _errorMessage = "Server configuration not loaded. Please try again.";
        _isLoading = false;
      });
      return;
    }

    // Fetch possible tables from GitHub
    final possibleTables = await _fetchPossibleTables();

    bool found = false;
    for (final teacherTableName in possibleTables) {
      try {
        _lottieController.repeat();

        final response = await http.post(
          Uri.parse('$_apiBaseUrl/student_login.php'),
          body: {
            'lrn': lrn,
            'password': password,
            'teacher_table_name': teacherTableName,
          },
        );

        _lottieController.stop();

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          if (data['success']) {
            found = true;
            final String studentLrn = data['student_lrn'];
            final String fetchedTeacherTableName = data['teacher_table_name'];
            final String studentName = data['student_name'];

            final service = FlutterBackgroundService();

            if (Platform.isAndroid) {
              final status = await Permission.notification.status;
              if (!status.isGranted) {
                print(
                    "Notification permission not granted. Cannot start background service.");
                _errorMessage =
                    "Notification permission required to start monitoring service.";
                setState(() {
                  _isLoading = false;
                });
                return;
              }
            }

            try {
              await service.startService();
              print('Background service started successfully');

              await Future.delayed(const Duration(milliseconds: 500));

              service.invoke('update', {
                'lrn': studentLrn,
                'teacherTable': fetchedTeacherTableName,
                'apiBaseUrl': _apiBaseUrl
              });
              print('Data sent to background service');
            } catch (e) {
              print('Error starting background service: $e');
              _errorMessage =
                  "Failed to start background monitoring. Please ensure notification permissions are granted.";
              setState(() {
                _isLoading = false;
              });
              return;
            }

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OpenWindowScreen(
                  studentLrn: studentLrn,
                  teacherTableName: fetchedTeacherTableName,
                  studentName: studentName,
                ),
              ),
            );
            break;
          }
        }
      } catch (e) {
        print('Login error: $e');
        setState(() {
          _errorMessage = "An unexpected error occurred: $e";
        });
        break;
      }
    }

    if (!found) {
      setState(() {
        _errorMessage = "Login failed. Please check your LRN and password.";
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF7B4EFF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08,
              vertical: size.height * 0.04,
            ),
            child: Column(
              children: [
                SizedBox(height: size.height * 0.02),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: SvgPicture.asset(
                        'assets/images/paperclip_logo.svg',
                        width: 50,
                        height: 50,
                        color: Colors.white,
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
                SizedBox(height: size.height * 0.04),
                SizedBox(
                  height: size.height * 0.25,
                  child: Center(
                    child: Lottie.asset(
                      'assets/animations/education_animation.json',
                      controller: _lottieController,
                      fit: BoxFit.contain,
                      width: size.width * 0.9,
                      height: size.height * 0.9,
                      onLoaded: (composition) {
                        _lottieController.duration = composition.duration;
                      },
                    ),
                  ),
                ),
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
                    hintText: "Access Code",
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
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading || _apiBaseUrl == null
                        ? null
                        : _loginStudent,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: const Color(0xFF7B4EFF),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Color(0xFF7B4EFF))
                        : const Text(
                            'LOG IN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
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
                const SizedBox(height: 16),
                const Text(
                  "If you're a teacher, please visit\nthe web application instead.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: size.width * 0.6,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ServerOfflineScreen()));
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.2),
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
