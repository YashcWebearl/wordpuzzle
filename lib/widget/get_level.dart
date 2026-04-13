import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/base_url.dart';

class GameLevelProvider with ChangeNotifier {
  int? _currentLevel; // level for the current grid size
  int? _currentGridSize; // currently active grid size
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  int get currentLevel => _currentLevel ?? 1;
  int get currentGridSize => _currentGridSize ?? 6;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  GameLevelProvider() {
    _loadFromPrefs();
    _fetchGameLevel(); // optional background refresh
  }

  // Load cached data from SharedPreferences (for the default or last used grid size)
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // First, try to load the last used grid size
    _currentGridSize = prefs.getInt('lastGridSize') ?? 6;
    // Then load the level for that grid size
    _currentLevel = prefs.getInt('maxLevel_$_currentGridSize') ?? 1;
    notifyListeners();
  }

  // Save the level for the current grid size
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentGridSize != null && _currentLevel != null) {
      await prefs.setInt('maxLevel_$_currentGridSize', _currentLevel!);
      await prefs.setInt('lastGridSize', _currentGridSize!);
    }
  }

  // Fetch latest game level from API (updates both level and grid size)
  Future<void> _fetchGameLevel() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await http.get(
        Uri.parse('$LURL/api/gameLevel/data?gameName=Wordix'),
        headers: {'Authorization': token ?? ''},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        final int newLevel = data['gameLevel'] ?? 1;
        final int newGridSize = int.tryParse(data['gridSize'] ?? '') ?? 6;

        // Update state
        _currentLevel = newLevel;
        _currentGridSize = newGridSize;
        await _saveToPrefs();
      } else {
        _errorMessage = 'Failed to fetch: ${response.body}';
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Public method to update game level after winning
  Future<void> updateGameLevel(int newLevel, int gridSize) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Call the API
      final response = await http.post(
        Uri.parse('$LURL/api/gameLevel/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token ?? '',
        },
        body: jsonEncode({
          "gameName": "Wordix",
          "gameLevel": newLevel,
          "gridSize": "$gridSize",
        }),
      );

      if (response.statusCode == 200) {
        // Update local state
        _currentLevel = newLevel;
        _currentGridSize = gridSize;
        await _saveToPrefs();
        notifyListeners();
      } else {
        print('Update failed: ${response.body}');
        // Optionally show an error to the user
      }
    } catch (e) {
      print('Update error: $e');
    }
  }

  // Optional: manually refresh from API
  Future<void> refresh() => _fetchGameLevel();
}
































































// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../widget/base_url.dart';
//
// class GameLevelProvider with ChangeNotifier {
//   int? _gameLevel;
//   int? _gridSize;
//   bool _isLoading = false;
//   String? _authToken;
//   String? _errorMessage;
//
//   int? get gameLevel => _gameLevel ?? 1; // Default to 1 if null
//   int? get gridSize => _gridSize ?? 6; //
//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;
//
//   GameLevelProvider() {
//     _loadFromPrefs();
//   }
//
//   // Load cached data from SharedPreferences
//   Future<void> _loadFromPrefs() async {
//     final prefs = await SharedPreferences.getInstance();
//     _gameLevel = prefs.getInt('gameLevel') ?? 1; // Default to 1
//     _gridSize = prefs.getInt('gridSize') ?? 6; // D
//     _authToken = prefs.getString('auth_token');
//     // final prefs = await SharedPreferences.getInstance();
//
//     notifyListeners();
//   }
//
//   // Save data to SharedPreferences
//   Future<void> _saveToPrefs() async {
//     final prefs = await SharedPreferences.getInstance();
//     if (_gameLevel != null) {
//       await prefs.setInt('gameLevel', _gameLevel!);
//     }
//     if (_gridSize != null) {
//       await prefs.setInt('gridSize', _gridSize!);
//     }
//   }
//
//   // Fetch game level from API
//   Future<void> fetchGameLevel({bool forceRefresh = false}) async {
//     print('Fetching game level...');
//     // If data is already cached and not forcing a refresh, skip API call
//     if (_gameLevel != null && _gridSize != null && !forceRefresh) {
//       return;
//     }
//     print('Fetching game level1111111111111...');
//     final prefs = await SharedPreferences.getInstance();
//     _isLoading = true;
//     _errorMessage = null;
//     final token = prefs.getString('auth_token');
//     print('Token is get 11111111111111: $token');
//     notifyListeners();
//     print('Fetching game level222222222222...');
//     try {
//       print('Fetching game token:- $_authToken');
//       final response = await http.get(
//         Uri.parse('$LURL/api/gameLevel/data?gameName=Wordix'),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': token ?? '',
//         },
//       );
//       print('Fetching game level333333333333333...');
//       print('Response status: ${response.statusCode}');
//       print('Response body: ${response.body}');
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body)['data'];
//         print('Fetching game level44444444444...');
//         _gameLevel = data['gameLevel'] ?? 1; // Default to 1 if null
//         _gridSize = int.tryParse(data['gridSize'] ?? '') ?? 6; // Defa
//         print('fetched grid size:-$_gridSize');
//         await _saveToPrefs(); // Cache the data
//       } else {
//         _errorMessage = 'Failed to fetch game level: ${response.body}';
//       }
//     } catch (e) {
//       _errorMessage = 'Error fetching game level: $e';
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
//
//   // Retry mechanism
//   Future<void> retryFetchGameLevel() async {
//     await fetchGameLevel(forceRefresh: true);
//   }
//
//   // Set token
//   void setAuthToken(String token) {
//     _authToken = token;
//     notifyListeners();
//   }
// }