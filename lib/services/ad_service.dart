import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widget/base_url.dart';

class AdService {
  Future<Map<String, dynamic>?> getGamePoster(String gameName) async {
    final url = '$LURL/api/gamePoster/getByGame/$gameName';
    print('Fetching game poster from: $url');
    try {
      final response = await http.get(Uri.parse(url));

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true &&
            data['data'] is List &&
            (data['data'] as List).isNotEmpty) {
          final posterData = data['data'][0] as Map<String, dynamic>;

          // Handle localhost in image URL if needed
          if (posterData['gamePhoto'] != null &&
              posterData['gamePhoto'].contains('localhost:8000')) {
            posterData['gamePhoto'] = posterData['gamePhoto']
                .replaceFirst('http://localhost:8000', LURL);
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
