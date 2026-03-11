import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoinNotifier {
  static final ValueNotifier<int> coins = ValueNotifier<int>(0);

  // static void initialize() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   coins.value = prefs.getInt('user_coins') ?? 0;
  // }
  static Future<void> initialize() async { // Changed return type to Future<void>
    final prefs = await SharedPreferences.getInstance();
    coins.value = prefs.getInt('user_coins') ?? 0;
  }
}