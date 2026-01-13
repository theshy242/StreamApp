import 'package:firebase_database/firebase_database.dart';
import 'notification_model.dart';

class NotificationService {
  static final _db = FirebaseDatabase.instance.ref();

  /// Gửi thông báo khi streamer bắt đầu LIVE
  static Future<void> sendLiveStartNotification({
    required String streamerId,
    required String streamerName,
    required String streamerAvatar,
    required String streamTitle,
    required List<String> followerIds,
  }) async {
    for (final followerId in followerIds) {
      final notiRef = _db
          .child('notifications')
          .child(followerId)
          .push();

      await notiRef.set({
        'receiverId': followerId,
        'senderId': streamerId,
        'senderName': streamerName,
        'senderAvatar': streamerAvatar,
        'type': 'live_start',
        'title': '🔴 $streamerName đang LIVE',
        'message': streamTitle,
        'timestamp': ServerValue.timestamp,
        'isRead': false,
        'streamId': streamerId,
      });
    }
  }

  /// Lắng nghe notification của user
  static Stream<List<AppNotification>> getUserNotifications(String userId) {
    final ref = _db.child('notifications').child(userId);

    return ref.onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return [];

      final Map map = data as Map;
      return map.entries.map((e) {
        return AppNotification.fromJson(e.key, e.value);
      }).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  static Future<void> markAsRead(String userId, String notiId) async {
    await _db
        .child('notifications')
        .child(userId)
        .child(notiId)
        .update({'isRead': true});
  }
}
