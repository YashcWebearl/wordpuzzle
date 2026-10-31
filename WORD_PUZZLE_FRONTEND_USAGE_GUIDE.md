# 🎮 Word Puzzle Hub (4-in-1) - Complete Frontend & App Usage Guide
## 📱 Daily Streak, 4-Game Daily Tasks, Unified Wallet & Lucky Spin Wheel

> **Supported Games**:
> 1. `wordix` (Word Search Grid)
> 2. `crossword` (Nature Connect Word Wheel)
> 3. `scramble` (**Word Scramble / Anagram Quest**)
> 4. `balloon` (**Balloon Rescue / Letter Guess**)
>
> **Base URL (Production)**: `https://game-api-0tgi.onrender.com/api`  
> **Auth Header**: `Authorization: Bearer <JWT_TOKEN>`  
> **Content-Type**: `application/json`  
> **Target Audience**: Flutter / Frontend Developers, QA & Backend Integrators

---

## 📌 1. Architecture & How It Works

1. **Unified Coin Wallet**:
   - There is a **single shared coin wallet** across all 4 word games.
   - Any coin rewards won from daily tasks, streak milestones, or the lucky wheel automatically reflect across **Wordix**, **Crossword**, **Word Scramble**, and **Balloon Rescue**.
2. **Shared 7-Day Streak Calendar**:
   - Resets at **`00:00:00 IST` (midnight)** every calendar day.
   - Claiming your streak reward in *any* of the 4 games counts for the entire Word Puzzle app.
   - Completing Day 7 automatically rolls over into Cycle 2 (Day 1) without losing progress.
3. **Combined Daily Tasks Pool (12 Tasks)**:
   - Each game has dedicated start and win quests (`play_scramble`, `win_scramble`, `play_balloon`, `win_balloon`, etc.).
   - Universal actions like using a hint, spinning the wheel, or watching an ad credit universal tasks regardless of which of the 4 games you are currently playing.
4. **Lucky Spin Wheel**:
   - 1 Free spin every calendar day (resets midnight IST).
   - Up to 3 additional spins by watching rewarded ads.
   - Extra spins available for 100 coins each.
   - Free hints won on the wheel are automatically synced to the user's powerup inventory in all 4 games.

---

## 📋 2. Complete Daily Tasks Cheat Sheet

| `taskKey` | Title | Description | Target (`total`) | Reward (`coins`) | Game Scope | When to Call in Flutter |
| :--- | :--- | :--- | :---: | :---: | :--- | :--- |
| `play_wordix` | **Word Finder** | Play 3 levels in Wordix Word Search | `3` | `100` | `wordix` | When Wordix grid loads / level starts |
| `win_wordix` | **Grid Conqueror** | Complete 2 Wordix levels | `2` | `150` | `wordix` | When Wordix victory dialog appears |
| `play_crossword` | **Wheel Weaver** | Play 3 Crossword levels | `3` | `100` | `crossword` | When Crossword wheel level starts |
| `win_crossword` | **Crossword Maestro** | Complete 2 Crossword levels | `2` | `150` | `crossword` | When Crossword level is solved |
| `play_scramble` ⭐ | **Letter Unscrambler** | Play 3 Word Scramble levels | `3` | `100` | `scramble` | When Scramble board/word starts |
| `win_scramble` ⭐ | **Master Speller** | Complete 2 Word Scramble levels | `2` | `150` | `scramble` | When Scramble word is solved |
| `play_balloon` ⭐ | **Balloon Savior** | Play 3 Balloon Rescue levels | `3` | `100` | `balloon` | When Balloon game starts |
| `win_balloon` ⭐ | **Sky Guardian** | Complete 2 Balloon Rescue levels | `2` | `150` | `balloon` | When Buddy is rescued / level won |
| `word_master_duo` | **Dual Scholar** | Play multiple word games today | `2` | `200` | `all` | Auto-incremented when playing any 2 games |
| `use_hint` | **Clue Seeker** | Use 2 hints or shuffles in any game | `2` | `80` | `all` | Hint, reveal letter, or shuffle button clicked |
| `spin_wheel_task` | **Fortune Seeker** | Spin the Lucky Wheel 1 time | `1` | `50` | `all` | Triggered when wheel is spun |
| `watch_ad` | **Bonus Hunter** | Watch 2 rewarded ads | `2` | `80` | `all` | Rewarded ad finishes playback |

---

## 🚀 3. REST API Endpoints Specification

### 3.1. Fetch Daily Status (Streak, Tasks, Spin & Wallet)
Use this on app startup and when opening the `DailyRewardsTasksScreen`.

* **Method**: `GET`
* **Route**: `/api/daily/status?gameName=scramble` *(or `wordix`, `crossword`, `balloon`)*
* **Headers**: `Authorization: Bearer <TOKEN>`

#### Success Response (`200 OK`):
```json
{
  "success": true,
  "date": "2026-10-31",
  "gameName": "scramble",
  "streak": {
    "currentDay": 3,
    "currentStreak": 3,
    "isTodayClaimed": false,
    "canClaim": true,
    "cycle": 1,
    "todayReward": {
      "day": 3,
      "title": "Day 3 Stash",
      "coins": 300,
      "diamonds": 0
    }
  },
  "dailyTasks": [
    {
      "taskKey": "play_scramble",
      "title": "Letter Unscrambler",
      "description": "Play 3 Word Scramble levels",
      "progress": 1,
      "total": 3,
      "target": 3,
      "coins": 100,
      "gameScope": "scramble",
      "icon": "letters",
      "isCompleted": false,
      "isClaimed": false
    },
    {
      "taskKey": "win_scramble",
      "title": "Master Speller",
      "description": "Complete 2 Word Scramble levels",
      "progress": 2,
      "total": 2,
      "target": 2,
      "coins": 150,
      "gameScope": "scramble",
      "icon": "crown",
      "isCompleted": true,
      "isClaimed": false
    },
    {
      "taskKey": "play_balloon",
      "title": "Balloon Savior",
      "description": "Play 3 Balloon Rescue levels",
      "progress": 0,
      "total": 3,
      "target": 3,
      "coins": 100,
      "gameScope": "balloon",
      "icon": "balloon",
      "isCompleted": false,
      "isClaimed": false
    },
    {
      "taskKey": "win_balloon",
      "title": "Sky Guardian",
      "description": "Complete 2 Balloon Rescue levels",
      "progress": 0,
      "total": 2,
      "target": 2,
      "coins": 150,
      "gameScope": "balloon",
      "icon": "shield",
      "isCompleted": false,
      "isClaimed": false
    },
    {
      "taskKey": "use_hint",
      "title": "Clue Seeker",
      "description": "Use 2 hints or shuffles in any game",
      "progress": 2,
      "total": 2,
      "target": 2,
      "coins": 80,
      "gameScope": "all",
      "icon": "wand",
      "isCompleted": true,
      "isClaimed": true
    }
  ],
  "spin": {
    "hasFreeSpin": true,
    "freeSpinsRemaining": 1,
    "adSpinsRemaining": 3,
    "coinSpinCost": 100
  },
  "wallet": {
    "coins": 950,
    "diamonds": 0
  }
}
```

---

### 3.2. Update Task Progress (Gameplay Hook)
Call this in the background when the user performs an action.

* **Method**: `POST`
* **Route**: `/api/daily/task-progress`
* **Headers**: `Authorization: Bearer <TOKEN>`, `Content-Type: application/json`

#### Request Body:
```json
{
  "taskKey": "play_scramble",
  "increment": 1,
  "gameName": "scramble"
}
```

#### Success Response (`200 OK`):
```json
{
  "success": true,
  "message": "Task progress updated",
  "data": {
    "taskKey": "play_scramble",
    "title": "Letter Unscrambler",
    "description": "Play 3 Word Scramble levels",
    "progress": 2,
    "total": 3,
    "target": 3,
    "coins": 100,
    "gameScope": "scramble",
    "isCompleted": false,
    "isClaimed": false
  }
}
```

---

### 3.3. Claim Completed Daily Task
Call this when the user clicks the "CLAIM" button on a completed quest.

* **Method**: `POST`
* **Route**: `/api/daily/claim-task`
* **Headers**: `Authorization: Bearer <TOKEN>`, `Content-Type: application/json`

#### Request Body:
```json
{
  "taskKey": "win_scramble",
  "gameName": "scramble"
}
```

#### Success Response (`200 OK`):
```json
{
  "success": true,
  "message": "🎉 Task reward claimed successfully!",
  "reward": 150,
  "newCoinBalance": 1100,
  "data": {
    "taskKey": "win_scramble",
    "coinsAwarded": 150,
    "diamondsAwarded": 0,
    "newWalletBalance": 1100,
    "isClaimed": true,
    "wallet": {
      "coins": 1100,
      "diamonds": 0
    }
  }
}
```

---

### 3.4. Claim Daily Streak Reward
Call this when the player clicks the current day's streak chest/card.

* **Method**: `POST`
* **Route**: `/api/daily/claim-streak`
* **Headers**: `Authorization: Bearer <TOKEN>`, `Content-Type: application/json`

#### Request Body:
```json
{
  "gameName": "scramble"
}
```

#### Success Response (`200 OK`):
```json
{
  "success": true,
  "message": "Day 3 streak reward claimed!",
  "data": {
    "day": 3,
    "coinsAwarded": 300,
    "diamondsAwarded": 0,
    "newWalletBalance": 1400
  }
}
```

---

### 3.5. Spin Lucky Wheel
Call this when the player spins the wheel.

* **Method**: `POST`
* **Route**: `/api/daily/spin-wheel`
* **Headers**: `Authorization: Bearer <TOKEN>`, `Content-Type: application/json`

#### Request Body:
```json
{
  "spinType": "free",
  "gameName": "scramble"
}
```
*(Valid `spinType` values: `"free"`, `"ad"`, `"coins"`)*

#### Success Response (`200 OK`):
```json
{
  "success": true,
  "data": {
    "sliceIndex": 2,
    "winningSlice": {
      "index": 2,
      "type": "coins",
      "amount": 150,
      "label": "150 Coins"
    },
    "coinsAwarded": 150,
    "newCoinBalance": 1550,
    "spinTypeUsed": "free"
  }
}
```

---

## 📱 4. Production-Ready Flutter / Dart Integration Class

Save this file in your Flutter app under `lib/services/word_puzzle_daily_service.dart`.

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class WordPuzzleDailyService {
  static const String baseUrl = 'https://game-api-0tgi.onrender.com/api';

  // Helper for auth headers
  static Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  // ========================================================
  // 1. GET DAILY STATUS (Streak, Tasks, Spin, Wallet)
  // ========================================================
  static Future<Map<String, dynamic>?> getDailyStatus({
    required String token,
    String gameName = 'scramble', // 'wordix' | 'crossword' | 'scramble' | 'balloon'
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/daily/status?gameName=$gameName');
      final res = await http.get(uri, headers: _headers(token));

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      print('❌ getDailyStatus error: ${res.statusCode} - ${res.body}');
      return null;
    } catch (e) {
      print('❌ Exception in getDailyStatus: $e');
      return null;
    }
  }

  // ========================================================
  // 2. TRACK GAMEPLAY PROGRESS (Start, Win, Hint, Ad, Spin)
  // ========================================================
  static Future<bool> trackTaskProgress({
    required String token,
    required String taskKey,
    String gameName = 'word_puzzle',
    int increment = 1,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/daily/task-progress');
      final res = await http.post(
        uri,
        headers: _headers(token),
        body: jsonEncode({
          'taskKey': taskKey,
          'gameName': gameName,
          'increment': increment,
        }),
      );

      return res.statusCode == 200;
    } catch (e) {
      print('❌ Exception in trackTaskProgress: $e');
      return false;
    }
  }

  // Convenience helper: Level Started
  static Future<void> onLevelStarted({
    required String token,
    required String gameScope, // 'scramble' | 'balloon' | 'wordix' | 'crossword'
  }) async {
    final keyMap = {
      'scramble': 'play_scramble',
      'balloon': 'play_balloon',
      'wordix': 'play_wordix',
      'crossword': 'play_crossword',
    };
    final key = keyMap[gameScope.toLowerCase()] ?? 'play_$gameScope';
    await trackTaskProgress(token: token, taskKey: key, gameName: gameScope);
  }

  // Convenience helper: Level Completed / Won
  static Future<void> onLevelWon({
    required String token,
    required String gameScope,
  }) async {
    final keyMap = {
      'scramble': 'win_scramble',
      'balloon': 'win_balloon',
      'wordix': 'win_wordix',
      'crossword': 'win_crossword',
    };
    final key = keyMap[gameScope.toLowerCase()] ?? 'win_$gameScope';
    await trackTaskProgress(token: token, taskKey: key, gameName: gameScope);
  }

  // Convenience helper: Hint Used
  static Future<void> onHintUsed(String token, {String gameName = 'word_puzzle'}) async {
    await trackTaskProgress(token: token, taskKey: 'use_hint', gameName: gameName);
  }

  // Convenience helper: Rewarded Ad Watched
  static Future<void> onAdWatched(String token, {String gameName = 'word_puzzle'}) async {
    await trackTaskProgress(token: token, taskKey: 'watch_ad', gameName: gameName);
  }

  // ========================================================
  // 3. CLAIM COMPLETED TASK REWARD
  // ========================================================
  static Future<int?> claimDailyTask({
    required String token,
    required String taskKey,
    String gameName = 'word_puzzle',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/daily/claim-task');
      final res = await http.post(
        uri,
        headers: _headers(token),
        body: jsonEncode({
          'taskKey': taskKey,
          'gameName': gameName,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['newCoinBalance'] ?? data['data']?['newWalletBalance'];
      }
      print('❌ claimDailyTask failed: ${res.statusCode} - ${res.body}');
      return null;
    } catch (e) {
      print('❌ Exception in claimDailyTask: $e');
      return null;
    }
  }

  // ========================================================
  // 4. CLAIM 7-DAY STREAK REWARD
  // ========================================================
  static Future<Map<String, dynamic>?> claimDailyStreak({
    required String token,
    String gameName = 'word_puzzle',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/daily/claim-streak');
      final res = await http.post(
        uri,
        headers: _headers(token),
        body: jsonEncode({'gameName': gameName}),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      print('❌ Exception in claimDailyStreak: $e');
      return null;
    }
  }

  // ========================================================
  // 5. SPIN LUCKY WHEEL
  // ========================================================
  static Future<Map<String, dynamic>?> executeSpin({
    required String token,
    String spinType = 'free', // 'free' | 'ad' | 'coins'
    String gameName = 'word_puzzle',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/daily/spin-wheel');
      final res = await http.post(
        uri,
        headers: _headers(token),
        body: jsonEncode({
          'spinType': spinType,
          'gameName': gameName,
        }),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      print('❌ executeSpin failed: ${res.statusCode} - ${res.body}');
      return null;
    } catch (e) {
      print('❌ Exception in executeSpin: $e');
      return null;
    }
  }
}
```

---

## 🎯 5. How & Where to Call in Your Flutter Screens

### 5.1. Word Scramble Screen (`ScrambleGameScreen.dart`)
```dart
// 1. In initState or when loading a new puzzle:
@override
void initState() {
  super.initState();
  WordPuzzleDailyService.onLevelStarted(
    token: userToken,
    gameScope: 'scramble',
  );
}

// 2. When player correctly unscrambles word & clears level:
void onWordCompleted() {
  WordPuzzleDailyService.onLevelWon(
    token: userToken,
    gameScope: 'scramble',
  );
  showVictoryDialog();
}

// 3. When player taps Hint / Reveal Letter:
void onHintTapped() {
  revealOneLetter();
  WordPuzzleDailyService.onHintUsed(userToken, gameName: 'scramble');
}
```

### 5.2. Balloon Rescue Screen (`BalloonGameScreen.dart`)
```dart
// 1. When balloon level starts:
@override
void initState() {
  super.initState();
  WordPuzzleDailyService.onLevelStarted(
    token: userToken,
    gameScope: 'balloon',
  );
}

// 2. When player guesses the word and saves the character:
void onBuddySaved() {
  WordPuzzleDailyService.onLevelWon(
    token: userToken,
    gameScope: 'balloon',
  );
  showSuccessBanner();
}
```

### 5.3. Daily Tasks & Rewards Dialog / Screen
```dart
// In your Task Card widget:
ElevatedButton(
  onPressed: task.isCompleted && !task.isClaimed
      ? () async {
          final newBalance = await WordPuzzleDailyService.claimDailyTask(
            token: userToken,
            taskKey: task.taskKey,
            gameName: 'scramble',
          );
          if (newBalance != null) {
            setState(() {
              task.isClaimed = true;
              userWalletCoins = newBalance;
            });
            showCoinSparkleAnimation();
          }
        }
      : null,
  child: Text(task.isClaimed ? 'CLAIMED' : 'CLAIM'),
)
```

---

## ⚡ 6. Instant cURL Test Commands

Replace `<JWT_TOKEN>` with a valid token:

```bash
# 1. Fetch Daily Status for Word Scramble
curl -X GET "https://game-api-0tgi.onrender.com/api/daily/status?gameName=scramble" \
  -H "Authorization: Bearer <JWT_TOKEN>"

# 2. Track "Play Scramble Level"
curl -X POST "https://game-api-0tgi.onrender.com/api/daily/task-progress" \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"taskKey": "play_scramble", "gameName": "scramble", "increment": 1}'

# 3. Track "Win Scramble Level"
curl -X POST "https://game-api-0tgi.onrender.com/api/daily/task-progress" \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"taskKey": "win_scramble", "gameName": "scramble", "increment": 1}'

# 4. Track "Play Balloon Rescue Level"
curl -X POST "https://game-api-0tgi.onrender.com/api/daily/task-progress" \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"taskKey": "play_balloon", "gameName": "balloon", "increment": 1}'

# 5. Track "Win Balloon Rescue Level"
curl -X POST "https://game-api-0tgi.onrender.com/api/daily/task-progress" \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"taskKey": "win_balloon", "gameName": "balloon", "increment": 1}'

# 6. Claim Completed Task Reward
curl -X POST "https://game-api-0tgi.onrender.com/api/daily/claim-task" \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"taskKey": "win_scramble", "gameName": "scramble"}'

# 7. Claim 7-Day Streak Reward
curl -X POST "https://game-api-0tgi.onrender.com/api/daily/claim-streak" \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"gameName": "scramble"}'

# 8. Spin Lucky Wheel
curl -X POST "https://game-api-0tgi.onrender.com/api/daily/spin-wheel" \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"spinType": "free", "gameName": "scramble"}'
```

