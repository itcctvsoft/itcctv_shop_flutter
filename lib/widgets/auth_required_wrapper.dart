import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoplite/providers/auth_service_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoplite/constants/pref_data.dart';

/// Một widget bọc chức năng cần xác thực
/// Nếu người dùng đã đăng nhập, hiển thị nội dung bình thường
/// Nếu chưa đăng nhập, hiển thị nút đăng nhập hoặc nội dung thay thế
class AuthRequiredWrapper extends ConsumerWidget {
  /// Widget con sẽ hiển thị nếu người dùng đã đăng nhập
  final Widget child;

  /// Mô tả chức năng cần đăng nhập, sẽ hiển thị trong dialog
  final String featureDescription;

  /// Widget thay thế hiển thị khi chưa đăng nhập
  /// Nếu null, sẽ hiển thị widget mặc định với nút đăng nhập
  final Widget? alternativeContent;

  /// Có hiển thị dialog đăng nhập khi người dùng nhấp vào nút không
  final bool showLoginPrompt;

  const AuthRequiredWrapper({
    Key? key,
    required this.child,
    required this.featureDescription,
    this.alternativeContent,
    this.showLoginPrompt = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Nếu người dùng đã đăng nhập, hiển thị nội dung bình thường
    if (authState.isAuthenticated) {
      return child;
    }

    // Người dùng chưa đăng nhập, hiển thị nội dung thay thế
    return alternativeContent ?? _buildDefaultAlternative(context, ref);
  }

  /// Xây dựng widget thay thế mặc định khi chưa đăng nhập
  Widget _buildDefaultAlternative(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock_outline,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Đăng nhập để $featureDescription',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authStateProvider.notifier).handleProtectedFeature(
                    context,
                    featureDescription: featureDescription,
                    showLoginPrompt: showLoginPrompt,
                  );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }
}

/// Widget đơn giản để bọc một IconButton cần xác thực
/// Sẽ hiển thị IconButton như bình thường, nhưng khi nhấp vào sẽ kiểm tra xác thực
class AuthRequiredIconButton extends ConsumerWidget {
  final IconData icon;
  final String featureDescription;
  final VoidCallback onAuthenticated;
  final Color? color;
  final double size;

  const AuthRequiredIconButton({
    Key? key,
    required this.icon,
    required this.featureDescription,
    required this.onAuthenticated,
    this.color,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(icon, color: color, size: size),
      onPressed: () async {
        final canProceed =
            await ref.read(authStateProvider.notifier).handleProtectedFeature(
                  context,
                  featureDescription: featureDescription,
                  featureIcon: icon,
                );

        if (canProceed) {
          onAuthenticated();
        }
      },
    );
  }
}

/// Widget đơn giản để bọc một ElevatedButton cần xác thực
class AuthRequiredButton extends ConsumerWidget {
  final Widget child;
  final String featureDescription;
  final VoidCallback onAuthenticated;
  final ButtonStyle? style;
  final IconData featureIcon;

  const AuthRequiredButton({
    Key? key,
    required this.child,
    required this.featureDescription,
    required this.onAuthenticated,
    this.style,
    this.featureIcon = Icons.lock_outline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      style: style,
      onPressed: () async {
        // Trực tiếp kiểm tra xác thực và token
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
        bool fullKey = prefs.getBool('com.example.shoppingisLoggedIn') ?? false;
        bool standardKey = prefs.getBool(PrefData.isLoggedIn) ?? false;
        bool sessionKey = prefs.getBool('currentSessionLoggedIn') ?? false;
        String token = prefs.getString(PrefData.token) ?? '';

        // Log trạng thái xác thực để debug
        print('AUTH BUTTON PRESS - Auth status check:');
        print('- Simple key: $isLoggedIn');
        print('- Full key: $fullKey');
        print('- Standard key: $standardKey');
        print('- Session key: $sessionKey');
        print('- Token exists: ${token.isNotEmpty}');

        // Kiểm tra xác thực
        bool isAuth = (isLoggedIn || fullKey || standardKey || sessionKey) &&
            token.isNotEmpty;

        if (isAuth) {
          // Đã xác thực, thực hiện hành động
          print('User is authenticated, proceeding with action');
          onAuthenticated();
        } else {
          print('User is NOT authenticated, showing login prompt');
          // Đảm bảo refresh state provider trước
          await ref.read(authStateProvider.notifier).refreshAuthState();

          // Kiểm tra lại sau khi refresh
          if (ref.read(authStateProvider).isAuthenticated) {
            print('Authentication confirmed after refresh, proceeding');
            onAuthenticated();
          } else {
            // Hiển thị giao diện đăng nhập
            final canProceed = await ref
                .read(authStateProvider.notifier)
                .handleProtectedFeature(
                  context,
                  featureDescription: featureDescription,
                  featureIcon: featureIcon,
                );

            if (canProceed) {
              onAuthenticated();
            }
          }
        }
      },
      child: child,
    );
  }
}

/// Widget bọc một widget con và thêm xử lý xác thực khi nhấn vào
class AuthRequiredActionWrapper extends ConsumerWidget {
  final Widget child;
  final String featureDescription;
  final VoidCallback onAuthenticated;
  final IconData featureIcon;

  const AuthRequiredActionWrapper({
    Key? key,
    required this.child,
    required this.featureDescription,
    required this.onAuthenticated,
    this.featureIcon = Icons.lock_outline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return GestureDetector(
      onTap: () async {
        if (authState.isAuthenticated) {
          // Đã xác thực, thực hiện hành động
          onAuthenticated();
        } else {
          // Chưa xác thực, hiển thị thông báo đăng nhập
          final canProceed =
              await ref.read(authStateProvider.notifier).handleProtectedFeature(
                    context,
                    featureDescription: featureDescription,
                    featureIcon: featureIcon,
                  );

          if (canProceed) {
            onAuthenticated();
          }
        }
      },
      child: child,
    );
  }
}
