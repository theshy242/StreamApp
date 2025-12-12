import 'package:firebase_database/firebase_database.dart';

class StreamKeyService {
  static final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// Tạo stream key tự động: user05, user06, user07...
  static Future<String> generateStreamKey() async {
    try {
      print("🔄 Generating new stream key...");

      // Lấy counter hiện tại
      final counterRef = _dbRef.child('counters/user_counter');
      final counterSnap = await counterRef.get();

      int currentCounter;
      if (counterSnap.exists && counterSnap.value != null) {
        // Đã có counter, tăng lên 1
        currentCounter = (counterSnap.value as int) + 1;
        print("📊 Current counter: ${counterSnap.value} -> $currentCounter");
      } else {
        // Chưa có counter, bắt đầu từ 5
        currentCounter = 5;
        print("📊 Initializing counter: $currentCounter");
      }

      // Cập nhật counter mới lên database
      await counterRef.set(currentCounter);

      // Format: user05, user06,... user10, user11...
      final streamKey = 'user${currentCounter.toString().padLeft(2, '0')}';
      print("✅ Generated stream key: $streamKey");

      return streamKey;
    } catch (e) {
      print("❌ StreamKeyService Error: $e");

      // Fallback cứng: dùng timestamp
      final fallbackKey = 'user_${DateTime.now().millisecondsSinceEpoch}';
      print("⚠️ Using fallback key: $fallbackKey");

      return fallbackKey;
    }
  }

  /// Reset counter về giá trị ban đầu
  static Future<void> resetCounter({int startFrom = 5}) async {
    try {
      await _dbRef.child('counters/user_counter').set(startFrom);
      print("✅ Counter reset to: $startFrom");
    } catch (e) {
      print("❌ Reset counter error: $e");
      rethrow;
    }
  }

  /// Lấy counter hiện tại
  static Future<int> getCurrentCounter() async {
    try {
      final snapshot = await _dbRef.child('counters/user_counter').get();
      return snapshot.exists ? (snapshot.value as int? ?? 4) : 4;
    } catch (e) {
      print("❌ Get counter error: $e");
      return 4; // Default fallback
    }
  }

  /// Format số thành chuỗi userXX
  static String formatStreamKey(int number) {
    return 'user${number.toString().padLeft(2, '0')}';
  }
}