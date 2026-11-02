import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'base_url.dart'; // for LURL

class CoinProvider extends ChangeNotifier {
  int _coins = 0;
  bool _isInitialized = false;
  bool _isUpdating = false; // Flag to track pending updates
  String? _errorMessage;

  bool get isInitialized => _isInitialized;
  int get coins => _coins;
  String? get errorMessage => _errorMessage;

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
    notifyListeners();

    await getCoin();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> getCoin() async {
    if (_isUpdating) {
      print('Skipping getCoin due to pending update');
      return;
    }
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
          _coins = data['coins'] ?? 0;
          await prefs.setInt(coinKey, _coins);
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

  /// Sets balance directly without calling /api/coin/add (used when backend API already credited coins e.g. streak/task claims)
  Future<void> setCoins(int newBalance) async {
    _coins = newBalance;
    final prefs = await SharedPreferences.getInstance();
    final coinKey = await _getCoinKey();
    await prefs.setInt(coinKey, _coins);
    await prefs.setInt('user_coins', _coins);
    notifyListeners();
  }

  /// Locally increments coins without calling /api/coin/add
  Future<void> creditCoinsLocally(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final coinKey = await _getCoinKey();
    final newBalance = _coins + amount;
    _coins = newBalance;
    await prefs.setInt(coinKey, newBalance);
    await prefs.setInt('user_coins', newBalance);
    notifyListeners();
  }

  /// Resets coins in memory and state on logout
  Future<void> reset() async {
    _coins = 0;
    _isInitialized = false;
    _isUpdating = false;
    notifyListeners();
  }

  Future<void> addCoins(
    int amount, {
    bool isWinner = false,
    bool instant = false,
    bool syncServer = true,
  }) async {
    if (_isUpdating) {
      print('Skipping addCoins due to pending update');
      return;
    }
    _isUpdating = true;
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
          await Future.delayed(const Duration(milliseconds: 25));
        }
      } else {
        _coins = newCoins;
        notifyListeners();
      }

      await prefs.setInt(coinKey, newCoins);
      await prefs.setInt('user_coins', newCoins);

      if (!syncServer) {
        return;
      }

      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) throw Exception('No auth token');

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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final bool isSuccess = data['success'] == true ||
            data.containsKey('coins') ||
            (data.containsKey('message') &&
                (data['message'] == 'Coins added' ||
                    data['message'] == 'Coin data updated'));

        if (isSuccess) {
          _coins = data['coins'] ?? newCoins;
          await prefs.setInt(coinKey, _coins);
          await prefs.setInt('user_coins', _coins);
        } else {
          _coins = currentCoins;
          await prefs.setInt(coinKey, currentCoins);
          await prefs.setInt('user_coins', currentCoins);
        }
      } else {
        // Rollback if sync fails
        _coins = currentCoins;
        await prefs.setInt(coinKey, currentCoins);
        await prefs.setInt('user_coins', currentCoins);
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final coinKey = await _getCoinKey();
      print('Error adding coins: $e');
      _coins = prefs.getInt(coinKey) ?? prefs.getInt('user_coins') ?? _coins;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> undoCoins(int amount, {bool instant = true}) async {
    int attempts = 0;
    while (_isUpdating && attempts < 25) {
      await Future.delayed(const Duration(milliseconds: 80));
      attempts++;
    }
    _isUpdating = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final coinKey = await _getCoinKey();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) throw Exception('No auth token');

      final currentCoins = _coins;
      final newCoins =
          (currentCoins - amount).clamp(0, double.infinity).toInt();

      if (instant) {
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
        final serverCoins =
            data['coins'] ?? (_coins - amount).clamp(0, double.infinity).toInt();
        _coins = serverCoins;
        await prefs.setInt(coinKey, _coins);
        await prefs.setInt('user_coins', _coins);
      } else {
        // Rollback if sync failed on server
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
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }
}
