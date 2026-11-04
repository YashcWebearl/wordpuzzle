import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

/// Helper service for Google Play Store In-App Updates (Play Core API)
class InAppUpdateService {
  static final InAppUpdateService _instance = InAppUpdateService._internal();
  factory InAppUpdateService() => _instance;
  InAppUpdateService._internal();

  bool _isChecking = false;

  /// Check Google Play Store for available app updates.
  /// If a newer version is live on Google Play, Play Store prompts the user automatically.
  Future<void> checkForUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (_isChecking) return;

    _isChecking = true;
    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        debugPrint('InAppUpdateService: Newer version found on Google Play Store!');

        // 1. Try Immediate / Force update first (official Google Play popup)
        if (updateInfo.immediateUpdateAllowed) {
          debugPrint('InAppUpdateService: Triggering Immediate Update dialog...');
          await InAppUpdate.performImmediateUpdate();
        } else if (updateInfo.flexibleUpdateAllowed) {
          // 2. Fallback to Flexible update if immediate is not allowed
          debugPrint('InAppUpdateService: Triggering Flexible Update...');
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      } else {
        debugPrint('InAppUpdateService: App is already at the latest Play Store version.');
      }
    } catch (e) {
      // Note: During local debug testing or side-loaded APKs, Play Core returns error -10
      // because the app was not downloaded from Google Play. This catch prevents any crash.
      debugPrint('InAppUpdateService: Update check notice (Normal during debug): $e');
    } finally {
      _isChecking = false;
    }
  }
}

