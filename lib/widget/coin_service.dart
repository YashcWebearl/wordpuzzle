import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'base_url.dart'; // for LURL

class CoinProvider extends ChangeNotifier {
  int _coins = 0;
  bool _isInitialized = false;
  bool _isUpdating = false;
  String? _errorMessage;

  bool get isInitialized => _isInitialized;
  int get coins => _coins;
  String? get errorMessage => _errorMessage;

  Future<String> _getCoinKey() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id') ?? prefs.getString('email') ?? '';
    if (uid.isNotEmpty) return 'user_coins_${uid.trim().toLowerCase()}';
    final token = prefs.getString('auth_token') ?? '';
    if (token.isNotEmpty) {
      return 'user_coins_${token.length > 20 ? token.substring(token.length - 20) : token}';
    }
    return 'user_coins';
  }

  /// 1. Initialize immediately from local storage (Zero network delay)
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getCoinKey();

    // Immediately load local saved coins so UI is instant and never flickers
    _coins = prefs.getInt(key) ?? prefs.getInt('user_coins') ?? 0;
    _isInitialized = true;
    notifyListeners();

    // 🛡️ If local balance is missing/zero, automatically fetch authentic balance in background
    if (_coins == 0) {
      fetchCoinsFromBackend();
    }
  }

  /// 2. Fetch coins from backend with 3-attempt retry & connection resilience
  /// (Used during Login, fresh install, or auto-recovery when local is zero)
  Future<int?> fetchCoinsFromBackend() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final coinKey = await _getCoinKey();

    if (token.isEmpty) {
      debugPrint('⚠️ [CoinProvider] No auth_token available for fetchCoinsFromBackend');
      return null;
    }

    final authHeader = token.startsWith('Bearer ') ? token : 'Bearer $token';
    final rawToken = token.replaceFirst('Bearer ', '');

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await http.get(
          Uri.parse('$LURL/api/coin/display?gameName=Wordix'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Connection': 'close',
            'ngrok-skip-browser-warning': 'true',
            'Authorization': authHeader,
            'token': rawToken,
          },
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is Map<String, dynamic> && data['success'] == true) {
            final int serverCoins = (data['coins'] as num?)?.toInt() ?? 0;
            _coins = serverCoins;
            await prefs.setInt(coinKey, _coins);
            await prefs.setInt('user_coins', _coins);
            _isInitialized = true;
            notifyListeners();
            print('🪙 [CoinProvider] Successfully fetched coins from backend: $serverCoins (attempt $attempt)');
            return serverCoins;
          }
        } else {
          print('⚠️ [CoinProvider] fetchCoins status: ${response.statusCode} | body: ${response.body}');
        }
      } catch (e) {
        debugPrint('⚠️ [CoinProvider] Attempt $attempt failed fetching coins: $e');
        if (attempt < 3) {
          await Future.delayed(const Duration(milliseconds: 600));
        }
      }
    }
    return null;
  }

  /// 3. Sync coins & levels to backend using Replace API
  /// (Called ONLY on Splash Screen and Logout)
  Future<bool> syncCoinsToBackend({Map<String, int>? levels}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    if (token.isEmpty) return false;

    final coinKey = await _getCoinKey();
    final currentCoins =
        prefs.getInt(coinKey) ?? prefs.getInt('user_coins') ?? _coins;
    _coins = currentCoins;

    final url = Uri.parse('$LURL/api/gameLevel/wordix/replace');
    final Map<String, dynamic> body = {
      'coins': currentCoins,
    };
    if (levels != null && levels.isNotEmpty) {
      body['levels'] = levels;
    }

    try {
      print('🚀 [CoinProvider] Syncing coins ($currentCoins) and levels ($levels) to backend...');
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Connection': 'close',
              'ngrok-skip-browser-warning': 'true',
              'Authorization':
                  token.startsWith('Bearer ') ? token : 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      print(
          '📡 [CoinProvider] Replace API response: ${response.statusCode} | ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error syncing coins/levels to backend: $e');
      return false;
    }
  }

  /// Backward compatible alias
  Future<void> syncWithServer() async {
    await initialize();
  }

  /// Called on screen load (e.g. GameSelectionScreen):
  /// If coins are 0 or local storage is empty, auto-fetches from backend!
  Future<void> getCoin() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getCoinKey();
    final localCoins = prefs.getInt(key) ?? prefs.getInt('user_coins');

    if (localCoins == null || localCoins == 0 || _coins == 0) {
      await fetchCoinsFromBackend();
    } else {
      _coins = localCoins;
      notifyListeners();
    }
  }

  /// Sets balance directly in local storage
  Future<void> setCoins(int newBalance) async {
    _coins = newBalance;
    final prefs = await SharedPreferences.getInstance();
    final coinKey = await _getCoinKey();
    await prefs.setInt(coinKey, _coins);
    await prefs.setInt('user_coins', _coins);
    notifyListeners();
  }

  /// Locally increments (or decrements) coins without calling server
  Future<void> creditCoinsLocally(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final coinKey = await _getCoinKey();
    final newBalance = (_coins + amount).clamp(0, double.infinity).toInt();
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_coins');
    notifyListeners();
  }

  /// 100% Local Add Coins (Zero API calls during gameplay)
  Future<void> addCoins(
    int amount, {
    bool isWinner = false,
    bool instant = false,
    bool syncServer = false,
  }) async {
    final currentCoins = _coins;
    final newCoins = currentCoins + amount;

    final prefs = await SharedPreferences.getInstance();
    final coinKey = await _getCoinKey();

    // 🛡️ Always save to SharedPreferences FIRST so nothing is lost if user exits during animation
    await prefs.setInt(coinKey, newCoins);
    await prefs.setInt('user_coins', newCoins);

    if (isWinner && !instant) {
      for (int i = 1; i <= amount; i++) {
        _coins = currentCoins + i;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 25));
      }
    } else {
      _coins = newCoins;
      notifyListeners();
    }
  }

  /// 100% Local Deduct/Undo Coins (Zero API calls during gameplay)
  Future<void> undoCoins(int amount, {bool instant = true}) async {
    final currentCoins = _coins;
    final newCoins = (currentCoins - amount).clamp(0, double.infinity).toInt();

    final prefs = await SharedPreferences.getInstance();
    final coinKey = await _getCoinKey();

    // Save immediately to local storage
    await prefs.setInt(coinKey, newCoins);
    await prefs.setInt('user_coins', newCoins);

    _coins = newCoins;
    notifyListeners();
  }
}
