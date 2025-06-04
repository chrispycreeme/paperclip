// In a new file, e.g., `lib/background_service_handler.dart`
// This is the entry point for the background service that runs in a separate isolate.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:ui'; // For DartPluginRegistrant
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:http/http.dart' as http;
// ignore: unused_import
import 'dart:convert';

// This is the entry point for the background service.
// It must be a top-level function or a static method.
@pragma('vm:entry-point')
Future<bool> onStart(ServiceInstance service) async {
  // Ensure Flutter plugins are initialized for background isolates.
  DartPluginRegistrant.ensureInitialized();

  String? studentLrn;
  String? teacherTableName;
  String? apiBaseUrl;

  // Configure Android foreground service notification immediately
  if (service is AndroidServiceInstance) {
    await service.setForegroundNotificationInfo(
      title: "Paperclip Monitoring",
      content: "Session active. Monitoring for integrity.",
    );
    
    // Set as foreground service immediately
    await service.setAsForegroundService();
  }

  // Listen for 'update' events from the main Flutter app to receive data
  service.on('update').listen((event) {
    if (event != null) {
      studentLrn = event['lrn'];
      teacherTableName = event['teacherTable'];
      apiBaseUrl = event['apiBaseUrl'];
      print('Background service received update: LRN=$studentLrn, Table=$teacherTableName, API=$apiBaseUrl');
    }
  });

  // Listen for 'stopService' events from the main Flutter app.
  service.on('stopService').listen((event) {
    service.stopSelf(); // Stops the background service
    print('Background service received stop command.');
  });

  // Listen for 'setAsForeground' command from the main app.
  service.on('setAsForeground').listen((event) async {
    if (service is AndroidServiceInstance) {
      await service.setAsForegroundService();
      await service.setForegroundNotificationInfo(
        title: "Paperclip",
        content: "Running in foreground",
      );
      print('Background service set as foreground.');
    }
  });

  service.on('setAsBackground').listen((event) async {
    if (service is AndroidServiceInstance) {
      await service.setAsBackgroundService();
      print('Background service set as background.');
    }
  });

  // Periodic heartbeat timer
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (apiBaseUrl != null && studentLrn != null && teacherTableName != null) {
      try {
        final response = await http.post(
          Uri.parse('$apiBaseUrl/student_api.php'),
          body: {
            'action': 'background_heartbeat',
            'student_id': studentLrn!,
            'teacher_table_name': teacherTableName!,
            'status': 'alive',
          },
        );

        if (response.statusCode == 200) {
          print('Background heartbeat sent for $studentLrn: ${response.body}');
        } else {
          print('Background heartbeat failed: ${response.statusCode}');
        }
      } catch (e) {
        print('Background heartbeat error: $e');
      }
    }
  });

  return true;
}