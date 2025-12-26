import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatService {
  static final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  static final String url =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey";

  final DatabaseReference _streamRef = FirebaseDatabase.instance.ref("streamItems");

  // 🔹 LẤY FIREBASE → TEXT
  Future<String> _getStreamItemsText() async {
    final snapshot = await _streamRef.get();

    if (!snapshot.exists) {
      return "Hiện không có livestream nào.";
    }
    final data = snapshot.value as Map<dynamic, dynamic>;
    final buffer = StringBuffer();
    buffer.writeln("Danh sách livestream hiện có:");
    int i = 1;
    data.forEach((key, value) {
      final stream = Map<String, dynamic>.from(value);
      buffer.writeln("");
      buffer.writeln("Livestream $i:");
      if (stream['name'] != null) {
        buffer.writeln("Streamer: ${stream['name']}");
      }
      if (stream['streamTitle'] != null) {
        buffer.writeln("Tiêu đề: ${stream['streamTitle']}");
      }
      if (stream['category'] != null) {
        buffer.writeln("Danh mục: ${stream['category']}");
      }
      if (stream['description'] != null) {
        buffer.writeln("Mô tả: ${stream['description']}");
      }
      if (stream['viewer'] != null) {
        buffer.writeln("Người xem: ${stream['viewer']}");
      }
      if (stream['isLiveNow'] != null) {
        buffer.writeln(
          "Trạng thái: ${stream['isLiveNow'] == true ? "Đang LIVE" : "Offline"}",
        );
      }
      i++;
    });

    return buffer.toString();
  }


  Future<String> sendMessage(String message) async {
    final streamItemsText = await _getStreamItemsText();
    final prompt = """
      Bạn là trợ lý AI của ứng dụng xem livestream.
      
      Nhiệm vụ của bạn:
      - Trò chuyện thân thiện với người dùng.
      - Hỗ trợ thông tin về các livestream đang diễn ra.
      
      Quy tắc bắt buộc:
      1. Chỉ trả lời bằng TEXT THUẦN.
      2. Không dùng markdown, không dùng ký tự *, -, #, **.
      3. Trả lời ngắn gọn, rõ ràng, thân thiện, bằng tiếng Việt.
      
      Cách trả lời:
      - Nếu người dùng chào hỏi (ví dụ: xin chào, hello, hi) hoặc hỏi bạn là ai → trả lời lịch sự, giới thiệu bạn là trợ lý AI của ứng dụng livestream.
      - Nếu câu hỏi liên quan đến livestream, người livestream, thể loại, số người xem, tiêu đề stream → trả lời dựa trên dữ liệu bên dưới.
      - Nếu câu hỏi không liên quan đến livestream hoặc ứng dụng → trả lời:
        Xin lỗi, mình chỉ có thể hỗ trợ các câu hỏi liên quan đến livestream đang diễn ra.
      
      Dữ liệu livestream hiện có:$streamItemsText      
      Câu hỏi của người dùng:$message
      Hãy trả lời:
""";
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "contents": [
            {
              "role": "user",
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode != 200) {
        return "❌ Lỗi API (${response.statusCode})";
      }

      final data = jsonDecode(response.body);

      if (data["candidates"] == null ||
          data["candidates"].isEmpty ||
          data["candidates"][0]["content"] == null) {
        return "❌ AI không trả lời";
      }

      return data["candidates"][0]["content"]["parts"][0]["text"];
    } catch (e) {
      return "❌ Lỗi kết nối AI";
    }
  }
}
