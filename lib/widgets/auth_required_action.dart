import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/constants/color_data.dart';
import 'package:shoplite/providers/auth_service_provider.dart';
import 'package:shoplite/ui/login/login_screen.dart';

/// A widget that conditionally renders content based on authentication state.
///
/// It can show different content for authenticated and unauthenticated users,
/// or automatically show a login prompt for unauthenticated users.
class AuthRequiredAction extends ConsumerWidget {
  /// Content to show when user is authenticated
  final Widget authenticatedContent;

  /// Content to show when user is not authenticated (optional)
  final Widget? unauthenticatedContent;

  /// Whether to show a standard login prompt for unauthenticated users
  final bool showLoginPrompt;

  /// The message to show in the login prompt
  final String loginPromptMessage;

  /// The feature name for context in error messages
  final String featureName;

  const AuthRequiredAction({
    Key? key,
    required this.authenticatedContent,
    this.unauthenticatedContent,
    this.showLoginPrompt = true,
    this.loginPromptMessage = 'Vui lòng đăng nhập để sử dụng tính năng này',
    required this.featureName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // If user is authenticated, show the authenticated content
    if (authState.isAuthenticated) {
      return authenticatedContent;
    }

    // If unauthenticated content is provided, show it
    if (unauthenticatedContent != null) {
      return unauthenticatedContent!;
    }

    // Otherwise, if showLoginPrompt is true, show a standard login prompt
    if (showLoginPrompt) {
      return _buildLoginPrompt(context, loginPromptMessage);
    }

    // Default to an empty container if no content should be shown
    return Container();
  }

  /// Builds a standard login prompt UI
  Widget _buildLoginPrompt(BuildContext context, String message) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            color: AppColors.primaryColor,
            size: 36,
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.fontBlack,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonColor,
              foregroundColor: AppColors.fontLight,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Đăng nhập ngay'),
          ),
        ],
      ),
    );
  }
}

/// A version of AuthRequiredAction specifically for buttons
class AuthRequiredButton extends ConsumerWidget {
  /// The text to display on the button
  final String text;

  /// The icon to show on the button (optional)
  final IconData? icon;

  /// The action to perform when authenticated user presses the button
  final VoidCallback onPressed;

  /// The feature name for context in error messages
  final String featureName;

  /// Button style
  final ButtonStyle? style;

  const AuthRequiredButton({
    Key? key,
    required this.text,
    this.icon,
    required this.onPressed,
    required this.featureName,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return ElevatedButton.icon(
      onPressed: () {
        if (authState.isAuthenticated) {
          onPressed();
        } else {
          // Show login dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Đăng nhập yêu cầu'),
              content: Text('Bạn cần đăng nhập để ${featureName}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonColor,
                  ),
                  child: Text('Đăng nhập'),
                ),
              ],
            ),
          );
        }
      },
      icon: Icon(icon ?? Icons.login),
      label: Text(text),
      style: style ??
          ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonColor,
            foregroundColor: AppColors.fontLight,
          ),
    );
  }
}
