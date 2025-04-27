import 'package:flutter/material.dart';
import 'package:shoplite/screens/chat_screen.dart';
import 'package:shoplite/screens/main_scaffold.dart';
import 'package:shoplite/widgets/chat_badge.dart';

class ChatDemoPage extends StatelessWidget {
  const ChatDemoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChatBadgeHelper.addChatBadge(
      context,
      Scaffold(
        appBar: AppBar(
          title: const Text('Tính năng nhắn tin hỗ trợ'),
          actions: [
            // Có thể thêm badge vào trong AppBar
            IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.chat_bubble_outline),
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 15,
                        minHeight: 15,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatScreen()),
                );
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Tính năng nhắn tin hỗ trợ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Chức năng nhắn tin giúp khách hàng liên hệ trực tiếp với đội ngũ hỗ trợ.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text('Nhắn tin với bộ phận hỗ trợ'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Hoặc bấm vào biểu tượng tin nhắn ở góc phải màn hình',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Gửi và nhận tin nhắn văn bản',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Gửi hình ảnh, âm thanh và tập tin đính kèm',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Thông báo tin nhắn mới từ bộ phận hỗ trợ',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
