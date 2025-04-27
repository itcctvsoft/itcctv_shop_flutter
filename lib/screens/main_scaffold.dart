import 'package:flutter/material.dart';
import 'package:shoplite/widgets/chat_badge.dart';

/// A utility class for adding the chat badge to scaffolds in the app
class ChatBadgeHelper {
  /// Adds a chat badge to the bottom right corner of any scaffold
  static Widget addChatBadge(BuildContext context, Widget child) {
    return Stack(
      children: [
        child,
        Positioned(
          right: 16,
          bottom: 80, // Adjust this value based on your layout
          child: const ChatBadge(),
        ),
      ],
    );
  }

  /// Creates a custom FloatingActionButton that shows the chat badge when pressed
  static Widget chatFab(BuildContext context,
      {VoidCallback? onPressed, Widget? regularFab}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (regularFab != null) regularFab,
        Positioned(
          right: regularFab != null ? -60 : 0,
          bottom: 0,
          child: const ChatBadge(),
        ),
      ],
    );
  }
}
