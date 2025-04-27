import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoplite/constants/pref_data.dart';
import 'package:shoplite/constants/apilist.dart';
import 'package:shoplite/ui/widgets/notification_dialog.dart';
import 'package:shoplite/ui/login/login_screen.dart';
import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

/// Authentication helper utility functions
class AuthHelpers {
  /// Check if user is logged in and return a boolean
  static Future<bool> isLoggedIn() async {
    // Don't log every check to reduce console spam
    // developer.log('Checking if user is logged in', name: 'AuthHelpers');

    // Get authentication status from PrefData
    bool isAuth = await PrefData.isAuthenticated();

    // Only log successful logins, not every check
    if (isAuth) {
      developer.log('User is logged in', name: 'AuthHelpers');
    }
    return isAuth;
  }

  /// Get valid token if available
  static Future<String?> getValidToken() async {
    final token = await PrefData.getToken();
    if (token.isEmpty) {
      return null;
    }
    return token;
  }

  /// Handle restricted feature access with appropriate dialogs
  ///
  /// Shows a login dialog if user is not authenticated
  /// Returns true if action can proceed (user is authenticated)
  /// Returns false if action should be blocked (user not authenticated)
  static Future<bool> handleAuthRequiredFeature({
    required BuildContext context,
    required String featureName,
    bool showDialog = true,
  }) async {
    final isAuthenticated = await isLoggedIn();

    if (!isAuthenticated && showDialog) {
      NotificationDialog.showInfo(
        context: context,
        title: 'Đăng nhập yêu cầu',
        message: 'Bạn cần đăng nhập để ${featureName}',
        primaryButtonText: 'Đăng nhập',
        secondaryButtonText: 'Hủy',
        primaryAction: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
        secondaryAction: () {
          // Just dismiss dialog
        },
      );
    }

    return isAuthenticated;
  }

  /// Handle authenticated action with a standard pattern:
  /// 1. Check authentication
  /// 2. Show login dialog if not authenticated
  /// 3. Execute action callback if authenticated
  static Future<void> executeAuthenticatedAction({
    required BuildContext context,
    required String featureName,
    required Future<void> Function(String token) action,
  }) async {
    final isAuth = await handleAuthRequiredFeature(
      context: context,
      featureName: featureName,
    );

    if (isAuth) {
      final token = await getValidToken();
      if (token != null) {
        await action(token);
      }
    }
  }

  static Future<void> logout() async {
    // Log the action
    developer.log('Logging out user', name: 'AuthHelpers');

    try {
      // Use the comprehensive logout method
      await PrefData.logout();

      developer.log('User logged out successfully', name: 'AuthHelpers');
    } catch (e) {
      developer.log('Error during logout: $e', name: 'AuthHelpers');
    }
  }

  // Method to set login state for current session only
  static Future<void> setCurrentSessionLogin() async {
    developer.log('Setting current session login flag', name: 'AuthHelpers');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('currentSessionLoggedIn', true);
  }

  // Method to clear current session login
  static Future<void> clearCurrentSessionLogin() async {
    developer.log('Clearing current session login flag', name: 'AuthHelpers');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('currentSessionLoggedIn', false);
  }
}
