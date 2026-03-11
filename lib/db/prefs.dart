import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static Future<void> saveMaxLevel(int gridSize, int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maxLevel_$gridSize', level);
  }

  static Future<int> getMaxLevel(int gridSize) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('maxLevel_$gridSize') ?? 1;
  }
  static Future<int> incrementPlayCount() async {
    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt('playCount') ?? 0;
    count++;
    await prefs.setInt('playCount', count);
    return count;
  }
}



// import 'package:shared_preferences/shared_preferences.dart';
//
// class Prefs {
//   static Future<void> saveMaxLevel(int gridSize, int level) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setInt('maxLevel_$gridSize', level);
//   }
//
//   static Future<int> getMaxLevel(int gridSize) async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getInt('maxLevel_$gridSize') ?? 1;
//   }
// }