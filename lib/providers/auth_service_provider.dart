import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/constants/pref_data.dart';
import 'package:shoplite/constants/apilist.dart';
import 'package:flutter/material.dart';
import 'package:shoplite/ui/login/login_screen.dart';
import 'package:shoplite/ui/home/home_screen.dart';
import 'package:shoplite/ui/widgets/auth_action_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides the current authentication state
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});

/// Authentication state model
class AuthState {
  final bool isAuthenticated;
  final String? token;
  final int? userId;

  AuthState({
    required this.isAuthenticated,
    this.token,
    this.userId,
  });

  // Create an unauthenticated state
  AuthState.unauthenticated()
      : isAuthenticated = false,
        token = null,
        userId = null;

  // Create an authenticated state with token and userId
  AuthState.authenticated(this.token, this.userId) : isAuthenticated = true;

  // Create a copy with some values changed
  AuthState copyWith({
    bool? isAuthenticated,
    String? token,
    int? userId,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      token: token ?? this.token,
      userId: userId ?? this.userId,
    );
  }
}

/// Notifier for managing authentication state
class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(AuthState.unauthenticated()) {
    // Initialize by checking the current authentication state
    refreshAuthState();
  }

  /// Refresh the current authentication state
  Future<void> refreshAuthState() async {
    try {
      // Lấy tất cả trạng thái xác thực
      final isAuthenticated = await PrefData.isAuthenticated();
      final token = await PrefData.getToken();

      // Log trạng thái hiện tại
      print('AUTH SERVICE PROVIDER: Refreshing auth state');
      print('- Auth status: $isAuthenticated');
      print('- Token exists: ${token.isNotEmpty}');

      // Nếu có token và đã xác thực, đảm bảo trạng thái xác thực là nhất quán
      if (isAuthenticated && token.isNotEmpty) {
        // Get shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Đảm bảo tất cả các cờ đăng nhập được đặt đúng
        await prefs.setBool(PrefData.isLoggedIn, true);
        await prefs.setBool('isLoggedIn', true);
        await prefs.setBool('com.example.shoppingisLoggedIn', true);
        await prefs.setBool('currentSessionLoggedIn', true);

        // Cập nhật global token
        g_token = token;

        // AGGRESSIVE FIX: Make sure userId is handled properly
        int? userId;
        try {
          // First, check what type is currently stored
          if (prefs.containsKey('userId')) {
            var rawUserId = prefs.get('userId');
            print('- Raw userId: $rawUserId (type: ${rawUserId.runtimeType})');

            // Clean up any existing userId to avoid type conflicts
            if (prefs.containsKey('userId')) {
              await prefs.remove('userId');
            }

            // Convert to int regardless of original type and store back
            if (rawUserId != null) {
              if (rawUserId is int) {
                userId = rawUserId;
              } else {
                // Try parsing if it's not already an int
                userId = int.tryParse(rawUserId.toString());
              }

              // Only store if we got a valid value
              if (userId != null && userId > 0) {
                await prefs.setInt('userId', userId);
                print('- Stored fixed userId as INT: $userId');
              }
            }
          } else {
            print('- No userId found in preferences');
          }
        } catch (e) {
          print('- Error handling userId: $e');
          // Continue with null userId on error
          userId = null;
        }

        // Cập nhật trạng thái
        state = AuthState.authenticated(token, userId);
        print('AUTH SERVICE PROVIDER: Set state to authenticated');
        print('- User ID: $userId');
      } else {
        // Không có token hoặc chưa xác thực
        state = AuthState.unauthenticated();
        print('AUTH SERVICE PROVIDER: Set state to unauthenticated');
      }
    } catch (e) {
      print('Error refreshing auth state: $e');
      state = AuthState.unauthenticated();
    }
  }

  /// Sign out the user
  Future<void> signOut() async {
    try {
      // Use the comprehensive logout method
      await PrefData.logout();

      // Update global token
      g_token = '';

      // Update state to unauthenticated
      state = AuthState.unauthenticated();

      print("AUTH SERVICE PROVIDER: User has been signed out completely");
    } catch (e) {
      print("Error during sign out: $e");
      // Still update state to unauthenticated even if there was an error
      state = AuthState.unauthenticated();
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => state.isAuthenticated;

  /// Get current token
  String? get token => state.token;

  /// Handle access to protected features
  /// Returns true if the user can access the feature
  /// If the user is not authenticated and showLoginPrompt is true, a login dialog will be shown
  Future<bool> handleProtectedFeature(
    BuildContext context, {
    required String featureDescription,
    bool showLoginPrompt = true,
    IconData featureIcon = Icons.lock_outline,
  }) async {
    // First check if already authenticated
    if (isAuthenticated) return true;

    // Not authenticated, handle according to parameters
    if (showLoginPrompt) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AuthActionView(
            featureDescription: featureDescription,
            featureIcon: featureIcon,
            onBackPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
      return false;
    }

    return false;
  }

  /// Handle logout with proper navigation
  Future<void> logoutAndNavigate(BuildContext context) async {
    try {
      // First sign out
      await signOut();

      // Then navigate to LoginScreen with replacement instead of clearing the stack
      // Pass a flag to indicate the user just logged out
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginScreen(fromLogout: true),
        ),
      );

      // No notification here - it will be shown in the LoginScreen
    } catch (e) {
      print("Error during logout navigation: $e");
      // Still attempt to navigate even if there was an error
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginScreen(fromLogout: true),
        ),
      );
    }
  }
}
