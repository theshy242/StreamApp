import 'package:firebase_database/firebase_database.dart';
import 'ChatMessage.dart';

class ChatService {
  static final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Gửi tin nhắn mới
  static Future<void> sendMessage({
    required String streamId,
    required String userId,
    required String userName,
    required String userAvatar,
    required String message,
    bool isStreamer = false,
    bool isModerator = false,
    MessageType type = MessageType.text,
  }) async {
    try {
      final messageId = _dbRef.child('streams/$streamId/chatMessages').push().key!;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final chatMessage = ChatMessage(
        messageId: messageId,
        streamId: streamId,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        message: message,
        timestamp: timestamp,
        type: type,
        isModerator: isModerator,
        isStreamer: isStreamer,
      );

      // Lưu tin nhắn vào stream
      await _dbRef.child('streams/$streamId/chatMessages/$messageId').set(
        chatMessage.toJson(),
      );

      // Lưu vào lịch sử chat của user
      await _dbRef.child('users/$userId/chatHistory/$streamId/$messageId').set({
        'timestamp': timestamp,
        'message': message,
      });

      print("✅ Chat message sent: $message");

    } catch (e) {
      print("❌ Error sending message: $e");
      rethrow;
    }
  }

  // Lấy danh sách tin nhắn của stream
  static Stream<List<ChatMessage>> getStreamMessages(String streamId) {
    return _dbRef.child('streams/$streamId/chatMessages').onValue.map((event) {
      final List<ChatMessage> messages = [];

      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          try {
            final messageData = Map<String, dynamic>.from(value);
            messages.add(ChatMessage.fromJson(messageData));
          } catch (e) {
            print("❌ Error parsing message $key: $e");
          }
        });

        // Sắp xếp theo thời gian (cũ nhất đến mới nhất)
        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }

      return messages;
    });
  }

  // Gửi tin nhắn hệ thống (thông báo)
  static Future<void> sendSystemMessage({
    required String streamId,
    required String message,
  }) async {
    await sendMessage(
      streamId: streamId,
      userId: 'system',
      userName: 'Hệ thống',
      userAvatar: '',
      message: message,
      type: MessageType.system,
    );
  }

  // Gửi tin nhắn donate
  static Future<void> sendDonationMessage({
    required String streamId,
    required String userId,
    required String userName,
    required String userAvatar,
    required String message,
    required double amount,
  }) async {
    final donationMessage = "💰 $userName đã donate \$$amount: $message";

    await sendMessage(
      streamId: streamId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      message: donationMessage,
      type: MessageType.donation,
    );
  }

  // Xoá tin nhắn (cho moderator/streamer)
  static Future<void> deleteMessage({
    required String streamId,
    required String messageId,
  }) async {
    try {
      await _dbRef.child('streams/$streamId/chatMessages/$messageId').remove();
      print("✅ Message deleted: $messageId");
    } catch (e) {
      print("❌ Error deleting message: $e");
      rethrow;
    }
  }

  // Lấy số lượng viewer hiện tại
  static Future<int> getViewerCount(String streamId) async {
    final snapshot = await _dbRef.child('streams/$streamId/activeViewers').get();
    return snapshot.exists ? (snapshot.value as int? ?? 0) : 0;
  }

  // Update viewer count
  static Future<void> updateViewerCount(String streamId, int count) async {
    await _dbRef.child('streams/$streamId/activeViewers').set(count);
  }
}