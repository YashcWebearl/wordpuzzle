import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widget/base_url.dart';

class GameProvider extends ChangeNotifier {
  int _currentLevel = 1;
  int _gridSize = 6;

  int get currentLevel => _currentLevel;
  int get gridSize => _gridSize;

  GameProvider() {
    _loadFromPrefs();
    _fetchGameLevel();
  }

  // Load saved level from SharedPreferences immediately
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLevel = prefs.getInt('maxLevel_$_gridSize');
    if (savedLevel != null) {
      _currentLevel = savedLevel;
      notifyListeners();
    }
  }

  // Fetch latest level from API (called once at startup)
  Future<void> _fetchGameLevel() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await http.get(
        Uri.parse('$LURL/api/gameLevel/data?gameName=Word Puzzle'),
        headers: {'Authorization': '$token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        final int newLevel = data['gameLevel'];
        final int newGridSize = int.tryParse(data['gridSize'] ?? '6') ?? 6;

        _currentLevel = newLevel;
        _gridSize = newGridSize;
        await prefs.setInt('maxLevel_$newGridSize', newLevel);
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching game level: $e');
    }
  }

  // Update level on server and locally (called after winning a level)
  Future<void> updateGameLevel(int level, int gridSize) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('$LURL/api/gameLevel/update'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': '$token',
        },
        body: jsonEncode({
          "gameName": "Word Puzzle",
          "gameLevel": level,
          "gridSize": "$gridSize",
        }),
      );

      if (response.statusCode == 200) {
        _currentLevel = level;
        _gridSize = gridSize;
        await prefs.setInt('maxLevel_$gridSize', level);
        notifyListeners();
      } else {
        print('Failed to update game level: ${response.body}');
      }
    } catch (e) {
      print('Error updating game level: $e');
    }
  }
}