import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shoplite/services/chat_service.dart';
import 'package:shoplite/screens/chat_screen.dart';

class ChatBadge extends StatefulWidget {
  final Color badgeColor;
  final Color iconColor;

  const ChatBadge({
    Key? key,
    this.badgeColor = Colors.red,
    this.iconColor = Colors.blue,
  }) : super(key: key);

  @override
  _ChatBadgeState createState() => _ChatBadgeState();
}

class _ChatBadgeState extends State<ChatBadge> {
  final ChatService _chatService = ChatService();
  int _unreadCount = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();

    // Set up a timer to refresh unread count every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadUnreadCount();
    });
  }

  Future<void> _loadUnreadCount() async {
    final result = await _chatService.getUnreadCount();

    if (result['success'] && mounted) {
      setState(() {
        _unreadCount = result['unreadCount'];
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton(
          mini: true,
          heroTag: 'chatBadge',
          backgroundColor: Colors.white,
          elevation: 4,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            ).then((_) {
              // Refresh unread count when coming back from chat screen
              _loadUnreadCount();
            });
          },
          child: Icon(
            Icons.chat_bubble_outline,
            color: widget.iconColor,
          ),
        ),
        if (_unreadCount > 0)
          Positioned(
            right: -5,
            top: -5,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: widget.badgeColor,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
