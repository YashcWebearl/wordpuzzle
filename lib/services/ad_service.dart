import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widget/base_url.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  Map<String, dynamic>? _cachedPoster;
  Future<Map<String, dynamic>?>? _inFlightFuture;

  Future<Map<String, dynamic>?> getGamePoster(
    String gameName, {
    bool forceRefresh = false,
  }) async {
    // 1. Return in-memory cache if available and not forcing refresh
    if (!forceRefresh && _cachedPoster != null) {
      return _cachedPoster;
    }

    // 2. Deduplicate: if a request is already in progress, reuse the same Future
    if (_inFlightFuture != null) {
      return _inFlightFuture!;
    }

    _inFlightFuture = _fetchPoster(gameName);
    try {
      final res = await _inFlightFuture;
      if (res != null) {
        _cachedPoster = res;
      }
      return res;
    } finally {
      _inFlightFuture = null;
    }
  }

  Future<Map<String, dynamic>?> _fetchPoster(String gameName) async {
    final url = '$LURL/api/gamePoster/getByGame/$gameName';
    print('Fetching game poster from: $url');
    try {
      final response = await http.get(Uri.parse(url));

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Map<String, dynamic>? posterData;

        if (data['success'] == true &&
            data['data'] is List &&
            (data['data'] as List).isNotEmpty) {
          posterData = Map<String, dynamic>.from(data['data'][0]);
        } else if (data['success'] == true &&
            data['data'] is Map<String, dynamic>) {
          posterData = Map<String, dynamic>.from(data['data']);
        }

        if (posterData != null) {
          // Handle localhost and http in image URL if needed
          if (posterData['gamePhoto'] != null) {
            String photoUrl = posterData['gamePhoto'].toString();
            if (photoUrl.contains('localhost:8000')) {
              photoUrl = photoUrl.replaceFirst('http://localhost:8000', LURL);
            } else if (photoUrl.startsWith('http://') &&
                !photoUrl.contains('10.0.2.2')) {
              // Force HTTPS for remote URLs to avoid cleartext issues on Android/iOS
              photoUrl = photoUrl.replaceFirst('http://', 'https://');
            }
            posterData['gamePhoto'] = photoUrl;
          }

          print('Ad data fetched successfully: $posterData');
          return posterData;
        } else {
          print('API error or empty data: ${data['message']}');
        }
      } else {
        print('Server error: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('Exception during fetching game poster: $e');
      return null;
    }
  }
}
