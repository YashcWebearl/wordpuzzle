
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'base_url.dart'; // for LURL

class CoinProvider extends ChangeNotifier {
  int _coins = 0;
  int get coins => _coins;
  String? _errorMessage;

  // Future<void> initialize() async {
  //   await getCoin(); // Wait for API fetch to complete
  //   notifyListeners();
  // }
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _coins = prefs.getInt('user_coins') ?? 0;
    notifyListeners(); // Notify after setting initial value

    await getCoin(); // Fetch updated coins from server
  }
  Future<void> getCoin() async {
    print('Fetching coin balance...');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    print('Token is: $token');

    try {
      final response = await http.get(
        // Uri.parse('$LURL/api/coin/display'),
        Uri.parse('$LURL/api/coin/display?gameName=Wordix'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token ?? '',
        },
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _coins = data['coins'] ?? 0; // Update coins from response
          await prefs.setInt('user_coins', _coins); // Save to SharedPreferences
          print('Fetched coins: $_coins');
          print('Fetched coins sharedpref: ${prefs.getInt('user_coins')}');
        } else {
          _errorMessage = 'Failed to fetch coins: ${data['message'] ?? 'Unknown error'}';
          _coins = prefs.getInt('user_coins') ?? 0; // Fallback to SharedPreferences
        }
      } else {
        _errorMessage = 'Failed to fetch coins: ${response.body}';
        _coins = prefs.getInt('user_coins') ?? 0; // Fallback to SharedPreferences
      }
    } catch (e) {
      _errorMessage = 'Error fetching coins: $e';
      _coins = prefs.getInt('user_coins') ?? 0; // Fallback to SharedPreferences
    } finally {
      notifyListeners();
    }
  }

  Future<void> addCoins(int amount, {bool isWinner = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print('token is:- $token');
      if (token == null) throw Exception('No auth token');

      final currentCoins = _coins;
      final newCoins = currentCoins + amount;
      print('current:-');

      if (isWinner) {
        print('current111111:-');
        // Animate coin count increment
        for (int i = 1; i <= amount; i++) {
          _coins = currentCoins + i;
          notifyListeners();
          await Future.delayed(const Duration(milliseconds: 50)); // Animation speed
        }
      } else {
        print('current22222222:-');
        // Instantly add coins
        _coins = newCoins;
        notifyListeners();
      }
      print('current333333333333333333:-');
      await prefs.setInt('user_coins', newCoins);

      // Sync with server
      print('current444444444:-');
      final url = Uri.parse('$LURL/api/coin/add');
      final response = await http.post(
        url,
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'coin': amount,"gameName": "Wordix",}),
      );

      if (response.statusCode != 200) {
        // Rollback if sync fails
        _coins = currentCoins;
        await prefs.setInt('user_coins', currentCoins);
        notifyListeners();
        print('Failed to sync coins: ${response.body}');
      }
    } catch (e) {
      print('Error adding coins: $e');
    }
  }

  Future<void> undoCoins(int amount) async {
    try {
      print('done undo');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print('done undo token is:- $token');
      if (token == null) throw Exception('No auth token');

      final url = Uri.parse('$LURL/api/coin/undo');
      print('done undo333333333:- $url}');
      final response = await http.post(
        url,
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'coin': amount,"gameName": "Wordix",}),
      );
      print('done undo 4444 response is:- ${response.statusCode}');
      print('done undo 5555555 response body is:- ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newCoins = data['coins'];

        // Animate down
        final currentCoins = _coins;
        if (currentCoins > newCoins) {
          for (int i = currentCoins - 1; i >= newCoins; i--) {
            _coins = i;
            notifyListeners();
            await Future.delayed(const Duration(milliseconds: 50));
          }
        }

        _coins = newCoins;
        await prefs.setInt('user_coins', _coins);
        notifyListeners();
      } else {
        throw Exception('Failed to undo coins: ${response.body}');
      }
    } catch (e) {
      print('Error undoing coins: $e');
    }
  }
}
