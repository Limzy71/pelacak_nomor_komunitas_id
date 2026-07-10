import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/phone_record.dart';

class ApiService extends ChangeNotifier {
  late String _baseUrl;

  ApiService() {
    if (!kIsWeb && Platform.isAndroid) {
      // Default menggunakan http://127.0.0.1:3000 via ADB Reverse Tunnel (paling stabil & anti firewall).
      // Bisa diganti via menu Pengaturan ke IP Wi-Fi PC saat ini: http://192.168.1.159:3000
      _baseUrl = 'http://127.0.0.1:3000';
    } else {
      _baseUrl = 'http://localhost:3000';
    }
  }

  String get baseUrl => _baseUrl;

  void setBaseUrl(String newUrl) {
    if (newUrl.trim().isNotEmpty) {
      _baseUrl = newUrl.trim();
      if (_baseUrl.endsWith('/')) {
        _baseUrl = _baseUrl.substring(0, _baseUrl.length - 1);
      }
      notifyListeners();
    }
  }

  Future<LookupResponse> lookupPhoneNumber(String rawNumber) async {
    try {
      final url = Uri.parse('$_baseUrl/phone-lookup/${Uri.encodeComponent(rawNumber)}');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return LookupResponse.fromJson(decoded);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal menghubungi server: $e');
    }
  }

  Future<SyncContactResult> syncContacts(
    List<Map<String, String>> contacts, {
    String? userId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/phone-lookup/sync');
      final payload = {
        'userId': userId ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
        'contacts': contacts,
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return SyncContactResult.fromJson(decoded);
      } else {
        throw Exception('Server error (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal menyinkronkan kontak: $e');
    }
  }

  Future<TagItem?> addTag(
    String phoneNumberId,
    String labelName, {
    String? userId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/phone-lookup/tag');
      final payload = {
        'phoneNumberId': phoneNumberId,
        'labelName': labelName,
        'userId': userId ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded['success'] == true && decoded['data'] != null) {
          return TagItem.fromJson(decoded['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Gagal menambah tag: $e');
    }
  }

  Future<bool> voteTag(
    String tagId,
    String voteType, {
    String? userId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/phone-lookup/vote');
      final payload = {
        'tagId': tagId,
        'userId': userId ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
        'voteType': voteType, // 'UPVOTE' or 'DOWNVOTE'
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded['success'] == true;
      }
      return false;
    } catch (e) {
      throw Exception('Gagal melakukan voting: $e');
    }
  }

  Future<AnalyticsResponse> getAnalytics() async {
    try {
      final url = Uri.parse('$_baseUrl/phone-lookup/analytics');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return AnalyticsResponse.fromJson(decoded);
      } else {
        throw Exception('Server error (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Gagal memuat analitik: $e');
    }
  }
}
