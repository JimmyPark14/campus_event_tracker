import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';

class UpdateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Checks Firestore for the latest version.
  /// Returns a Map with 'updateAvailable', 'latestVersion', and 'apkUrl'.
  Future<Map<String, dynamic>> checkForUpdates() async {
    try {
      // 1. Get current app version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // 2. Fetch latest version from Firestore
      DocumentSnapshot snapshot = await _firestore.collection('config').doc('app_settings').get();
      
      if (!snapshot.exists) {
        return {'updateAvailable': false};
      }

      var data = snapshot.data() as Map<String, dynamic>;
      String latestVersion = data['latest_version'] ?? currentVersion;
      String apkUrl = data['apk_url'] ?? '';

      // Simple version check (assumes semantic versioning like 1.0.0)
      bool isUpdateAvailable = _isVersionGreaterThan(latestVersion, currentVersion);

      return {
        'updateAvailable': isUpdateAvailable,
        'latestVersion': latestVersion,
        'apkUrl': apkUrl,
      };
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      return {'updateAvailable': false};
    }
  }

  /// Downloads the APK and triggers installation
  Future<void> downloadAndInstallUpdate(String url, Function(double) onProgress) async {
    try {
      // Request storage permission if needed (especially for older Androids)
      if (Platform.isAndroid) {
        await Permission.storage.request();
        // Storage permissions might be denied or restricted in Android 13+,
        // so we don't strictly fail if it's denied unless we can't write to temp dir.
      }

      // Get temporary directory
      Directory tempDir = await getTemporaryDirectory();
      String savePath = '${tempDir.path}/app-update.apk';

      // Download file using Dio
      Dio dio = Dio();
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = received / total;
            onProgress(progress);
          }
        },
      );

      // Open file to trigger install
      final result = await OpenFile.open(savePath);
      debugPrint('OpenFile result: ${result.message}');
    } catch (e) {
      debugPrint('Error downloading or installing update: $e');
      rethrow;
    }
  }

  /// Helper to compare semantic version strings (e.g., '1.0.1' > '1.0.0')
  bool _isVersionGreaterThan(String latest, String current) {
    List<String> latestParts = latest.split('.');
    List<String> currentParts = current.split('.');

    for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
      int l = int.tryParse(latestParts[i]) ?? 0;
      int c = int.tryParse(currentParts[i]) ?? 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    
    // If we reach here, it might be 1.0 vs 1.0.1
    return latestParts.length > currentParts.length;
  }
}
