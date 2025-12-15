import 'package:firebase_database/firebase_database.dart';
class User {
  final String userId;
  final String name;
  final String email;
  final String avatar;
  final String serverUrl; // URL Nginx / RTMP / HLS của user
  final String description;
  final int followers;

  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.avatar,
    required this.serverUrl,
    required this.description,
    required this.followers,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final id = json['userId'] ?? '';
    return User(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? '',
      serverUrl: json['serverUrl'] ?? "http://192.168.2.249/live/$id.m3u8",
      description: json['description'] ?? '',
      followers: json['followers'] ?? 0,
    );
  }
  // ================== CÁC HÀM SỬA TRƯỜNG GIÁ TRỊ ==================

  // 1. Sửa URL server của tất cả users
  static Future<void> updateAllServerUrls(String newBaseUrl) async {
    try {
      print('🔄 Bắt đầu cập nhật server URLs...');
      final database = FirebaseDatabase.instance;
      final usersRef = database.ref('users');

      final snapshot = await usersRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;
        int updatedCount = 0;

        for (var entry in users.entries) {
          final userId = entry.key.toString();

          // Cập nhật URL mới: http://{newBaseUrl}/live/{userId}.m3u8
          final newServerUrl = "http://$newBaseUrl/live/$userId.m3u8";

          await usersRef.child(userId).update({
            'serverUrl': newServerUrl
          });

          print('✅ Đã cập nhật URL cho $userId: $newServerUrl');
          updatedCount++;

          // Delay nhỏ để tránh rate limit
          await Future.delayed(const Duration(milliseconds: 100));
        }

        print('🎉 Đã cập nhật xong $updatedCount users!');
      }
    } catch (e) {
      print('❌ Lỗi khi cập nhật server URLs: $e');
      rethrow;
    }
  }

  // 2. Sửa followers của tất cả users
  static Future<void> updateAllFollowers(int newFollowerCount) async {
    try {
      print('🔄 Bắt đầu cập nhật followers...');
      final database = FirebaseDatabase.instance;
      final usersRef = database.ref('users');

      final snapshot = await usersRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;
        int updatedCount = 0;

        for (var entry in users.entries) {
          final userId = entry.key.toString();

          await usersRef.child(userId).update({
            'followers': newFollowerCount
          });

          print('✅ Đã cập nhật followers cho $userId: $newFollowerCount');
          updatedCount++;

          await Future.delayed(const Duration(milliseconds: 100));
        }

        print('🎉 Đã cập nhật followers cho $updatedCount users!');
      }
    } catch (e) {
      print('❌ Lỗi khi cập nhật followers: $e');
      rethrow;
    }
  }

  // 3. Sửa description của tất cả users
  static Future<void> updateAllDescriptions(String newDescription) async {
    try {
      print('🔄 Bắt đầu cập nhật descriptions...');
      final database = FirebaseDatabase.instance;
      final usersRef = database.ref('users');

      final snapshot = await usersRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;
        int updatedCount = 0;

        for (var entry in users.entries) {
          final userId = entry.key.toString();

          await usersRef.child(userId).update({
            'description': newDescription
          });

          print('✅ Đã cập nhật description cho $userId');
          updatedCount++;

          await Future.delayed(const Duration(milliseconds: 100));
        }

        print('🎉 Đã cập nhật descriptions cho $updatedCount users!');
      }
    } catch (e) {
      print('❌ Lỗi khi cập nhật descriptions: $e');
      rethrow;
    }
  }

  // 4. Sửa avatar của tất cả users
  static Future<void> updateAllAvatars(String avatarBaseUrl) async {
    try {
      print('🔄 Bắt đầu cập nhật avatars...');
      final database = FirebaseDatabase.instance;
      final usersRef = database.ref('users');

      final snapshot = await usersRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;
        List<String> userIds = users.keys.cast<String>().toList();
        int updatedCount = 0;

        for (int i = 0; i < userIds.length; i++) {
          final userId = userIds[i];
          final newAvatar = '$avatarBaseUrl?img=${(i % 70) + 1}';

          await usersRef.child(userId).update({
            'avatar': newAvatar
          });

          print('✅ Đã cập nhật avatar cho $userId: $newAvatar');
          updatedCount++;

          await Future.delayed(const Duration(milliseconds: 100));
        }

        print('🎉 Đã cập nhật avatars cho $updatedCount users!');
      }
    } catch (e) {
      print('❌ Lỗi khi cập nhật avatars: $e');
      rethrow;
    }
  }

  // 5. Hàm tổng quát: Sửa bất kỳ trường nào của tất cả users
  static Future<void> updateAllUsersField({
    required String fieldName,
    required dynamic newValue,
  }) async {
    try {
      print('🔄 Bắt đầu cập nhật field "$fieldName"...');
      final database = FirebaseDatabase.instance;
      final usersRef = database.ref('users');

      final snapshot = await usersRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;
        int updatedCount = 0;

        for (var entry in users.entries) {
          final userId = entry.key.toString();

          await usersRef.child(userId).update({
            fieldName: newValue
          });

          print('✅ Đã cập nhật $fieldName cho $userId: $newValue');
          updatedCount++;

          await Future.delayed(const Duration(milliseconds: 100));
        }

        print('🎉 Đã cập nhật $fieldName cho $updatedCount users!');
      }
    } catch (e) {
      print('❌ Lỗi khi cập nhật field $fieldName: $e');
      rethrow;
    }
  }

  // 6. Hàm sửa nhiều trường cùng lúc cho tất cả users
  static Future<void> updateMultipleFieldsForAllUsers(
      Map<String, dynamic> fieldsToUpdate,
      ) async {
    try {
      print('🔄 Bắt đầu cập nhật nhiều fields...');
      final database = FirebaseDatabase.instance;
      final usersRef = database.ref('users');

      final snapshot = await usersRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;
        int updatedCount = 0;

        for (var entry in users.entries) {
          final userId = entry.key.toString();

          await usersRef.child(userId).update(fieldsToUpdate);

          print('✅ Đã cập nhật ${fieldsToUpdate.length} fields cho $userId');
          updatedCount++;

          await Future.delayed(const Duration(milliseconds: 100));
        }

        print('🎉 Đã cập nhật xong $updatedCount users!');
      }
    } catch (e) {
      print('❌ Lỗi khi cập nhật multiple fields: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'avatar': avatar,
      'serverUrl': serverUrl,
      'description': description,
      'followers': followers,
    };
  }
}
