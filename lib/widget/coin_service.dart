import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'base_url.dart'; // for LURL

class CoinProvider extends ChangeNotifier {
  int _coins = 0;
  int get coins => _coins;
  String? _errorMessage;

  Future<String> _getCoinKey() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id') ?? prefs.getString('email') ?? '';
    if (uid.isNotEmpty) return 'user_coins_${uid.trim().toLowerCase()}';
    return 'user_coins';
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getCoinKey();
    _coins = prefs.getInt(key) ?? prefs.getInt('user_coins') ?? 0;
    notifyListeners(); // Notify after setting initial value

    await getCoin(); // Fetch updated coins from server
  }

  Future<void> getCoin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final coinKey = await _getCoinKey();

    try {
      final response = await http.get(
        Uri.parse('$LURL/api/coin/display?gameName=Wordix'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          if (token.isNotEmpty)
            'Authorization':
                token.startsWith('Bearer ') ? token : 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _coins = data['coins'] ?? 0; // Update coins from response
          await prefs.setInt(coinKey, _coins); // Save to user-scoped SharedPreferences
          await prefs.setInt('user_coins', _coins);
        } else {
          _errorMessage =
              'Failed to fetch coins: ${data['message'] ?? 'Unknown error'}';
          _coins = prefs.getInt(coinKey) ?? prefs.getInt('user_coins') ?? 0;
        }
      } else {
        _errorMessage = 'Failed to fetch coins: ${response.body}';
        _coins = prefs.getInt(coinKey) ?? prefs.getInt('user_coins') ?? 0;
      }
    } catch (e) {
      _errorMessage = 'Error fetching coins: $e';
      _coins = prefs.getInt(coinKey) ?? prefs.getInt('user_coins') ?? 0;
    } finally {
      notifyListeners();
    }
  }

  /// Directly set coins balance (e.g. from backend response newWalletBalance)
  /// without triggering a duplicate /api/coin/add request!
  Future<void> setCoins(int newCoins) async {
    _coins = newCoins;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    final coinKey = await _getCoinKey();
    await prefs.setInt(coinKey, _coins);
    await prefs.setInt('user_coins', _coins);
  }

  Future<void> addCoins(
    int amount, {
    bool isWinner = false,
    bool instant = false,
    bool syncServer = true,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coinKey = await _getCoinKey();
      final currentCoins = _coins;
      final newCoins = currentCoins + amount;

      if (isWinner && !instant) {
        // Animate coin count increment
        for (int i = 1; i <= amount; i++) {
          _coins = currentCoins + i;
          notifyListeners();
          await Future.delayed(const Duration(milliseconds: 25)); // Smooth & faster
        }
      } else {
        // Instantly add coins
        _coins = newCoins;
        notifyListeners();
      }
      await prefs.setInt(coinKey, newCoins);
      await prefs.setInt('user_coins', newCoins);

      if (!syncServer) {
        // Backend endpoint already credited this amount; do NOT call /api/coin/add again!
        return;
      }

      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No auth token');

      // Sync with server
      final url = Uri.parse('$LURL/api/coin/add');
      final response = await http.post(
        url,
        headers: {
          'Authorization':
              token.startsWith('Bearer ') ? token : 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'coin': amount, "gameName": "Wordix"}),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        // Rollback if sync fails
        _coins = currentCoins;
        await prefs.setInt(coinKey, currentCoins);
        await prefs.setInt('user_coins', currentCoins);
        notifyListeners();
      }
    } catch (e) {
      print('Error adding coins: $e');
    }
  }

  Future<void> undoCoins(int amount, {bool instant = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final coinKey = await _getCoinKey();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No auth token');

      final currentCoins = _coins;
      final newCoins =
          (currentCoins - amount).clamp(0, double.infinity).toInt();

      if (instant) {
        // Optimistically deduct immediately for instant responsive UI
        _coins = newCoins;
        await prefs.setInt(coinKey, _coins);
        await prefs.setInt('user_coins', _coins);
        notifyListeners();
      }

      final url = Uri.parse('$LURL/api/coin/undo');
      final response = await http.post(
        url,
        headers: {
          'Authorization':
              token.startsWith('Bearer ') ? token : 'Bearer $token',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({'coin': amount, "gameName": "Wordix"}),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final serverCoins = data['coins'] as int? ?? newCoins;

        if (!instant && currentCoins > serverCoins) {
          for (int i = currentCoins - 1; i >= serverCoins; i--) {
            _coins = i;
            notifyListeners();
            await Future.delayed(const Duration(milliseconds: 20));
          }
        }

        _coins = serverCoins;
        await prefs.setInt(coinKey, _coins);
        await prefs.setInt('user_coins', _coins);
        notifyListeners();
      } else {
        // Rollback if failed
        if (instant) {
          _coins = currentCoins;
          await prefs.setInt(coinKey, currentCoins);
          await prefs.setInt('user_coins', currentCoins);
          notifyListeners();
        }
        throw Exception('Failed to undo coins: ${response.body}');
      }
    } catch (e) {
      print('Error undoing coins: $e');
    }
  }
}
