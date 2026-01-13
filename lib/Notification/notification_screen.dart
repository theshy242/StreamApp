import 'package:flutter/material.dart';
import 'notification_service.dart';
import 'notification_item.dart';
import '../Model/user.dart';

class NotificationScreen extends StatelessWidget {
  final User currentUser;

  const NotificationScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
      ),
      body: StreamBuilder(
        stream: NotificationService.getUserNotifications(currentUser.userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!;
          if (notifications.isEmpty) {
            return const Center(child: Text('Chưa có thông báo'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final noti = notifications[index];
              return NotificationItem(
                notification: noti,
                onTap: () {
                  NotificationService.markAsRead(
                    currentUser.userId,
                    noti.id,
                  );

                  // 👉 Có thể navigate vào stream ở đây
                },
              );
            },
          );
        },
      ),
    );
  }
}
