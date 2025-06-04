import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

/// A service class to handle Over-The-Air (OTA) updates for the application.
class OtaUpdateService {
  // GitHub raw URL for the version file.
  // IMPORTANT: Replace with your actual GitHub raw content URL for version.json
  static const String _githubVersionUrl =
      'https://raw.githubusercontent.com/chrispycreeme/paperclip-server-dump/main/app_version.json';

  /// Checks for app updates from GitHub and prompts the user if a new version is available.
  ///
  /// Requires a [BuildContext] to display dialogs.
  Future<void> checkForUpdates(BuildContext context) async {
    // Ensure the context is still valid before proceeding with any UI operations
    if (!context.mounted) {
      print('Context not mounted in checkForUpdates. Aborting update check.');
      return;
    }

    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      print('Current app version: $currentVersion');

      // Fetch latest version info from GitHub
      final response = await http.get(Uri.parse(_githubVersionUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final String latestVersion = data['latest_version'];
        final String downloadUrl = data['download_url'];
        print('Latest available version: $latestVersion');
        print('Download URL: $downloadUrl');

        // Compare versions
        if (_isNewVersionAvailable(currentVersion, latestVersion)) {
          _showUpdateDialog(context, latestVersion, downloadUrl);
        } else {
          print('App is up to date.');
        }
      } else {
        print('Failed to fetch latest version info: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking for updates: $e');
      // Optionally show an error dialog if update check fails
      // _showErrorDialog(context, 'Failed to check for updates. Please try again later.');
    }
  }

  /// Helper function to compare versions (e.g., "1.0.0" vs "1.0.1").
  /// Returns true if [latest] is a newer version than [current].
  bool _isNewVersionAvailable(String current, String latest) {
    final currentParts = current.split('.').map(int.parse).toList();
    final latestParts = latest.split('.').map(int.parse).toList();

    // Pad shorter version with zeros if necessary
    final maxLength =
        currentParts.length > latestParts.length ? currentParts.length : latestParts.length;
    while (currentParts.length < maxLength) currentParts.add(0);
    while (latestParts.length < maxLength) latestParts.add(0);

    for (int i = 0; i < maxLength; i++) {
      if (latestParts[i] > currentParts[i]) {
        return true;
      }
      if (latestParts[i] < currentParts[i]) {
        return false;
      }
    }
    return false; // Versions are the same
  }

  /// Shows an alert dialog prompting the user to update the app.
  void _showUpdateDialog(
      BuildContext context, String latestVersion, String downloadUrl) {
    // Ensure the context is still valid before showing the dialog
    if (!context.mounted) {
      print('Context not mounted in _showUpdateDialog. Aborting dialog display.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false, // User must choose an option
      builder: (BuildContext dialogContext) { // Use dialogContext to avoid conflicts
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('New Update Available!', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            'A new version ($latestVersion) of the app is available. Please update to get the latest features and bug fixes.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Later', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
                SystemNavigator.pop(); // Exit app
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B4EFF), // Use your app's primary color
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Update Now', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Dismiss dialog
                if (await canLaunchUrl(Uri.parse(downloadUrl))) {
                  await launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
                } else {
                  // Fallback if URL cannot be launched
                  _showErrorDialog(context, 'Could not launch update URL. Please try again later.');
                }
                SystemNavigator.pop(); // Exit app
              },
            ),
          ],
        );
      },
    );
  }

  /// Shows a generic error dialog with a given [message].
  void _showErrorDialog(BuildContext context, String message) {
    // Ensure the context is still valid before showing the dialog
    if (!context.mounted) {
      print('Context not mounted in _showErrorDialog. Aborting dialog display.');
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Use dialogContext
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Error', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
