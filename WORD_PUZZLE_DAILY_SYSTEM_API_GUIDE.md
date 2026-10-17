# 🎮 Word Puzzle Hub (Wordix & Crossword) - Backend API Guide
## 📱 Daily Streak Rewards, Combined Daily Tasks & Lucky Spin Wheel System

> **Applicable For**: `word_puzzle` (Wordix Word Search + Crossword Nature Connect)  
> **Base URL (Local)**: `http://localhost:5000/api`  
> **Base URL (Production)**: `https://game-api-0tgi.onrender.com/api`  
> **Auth Header**: `Authorization: Bearer <JWT_TOKEN>` (or `<AUTH_TOKEN>`)  
> **Content-Type**: `application/json`

---

## 🏗️ 1. Architecture & Core Rules

1. **Unified Coin Wallet**:
   - There is a single coin wallet per user shared across **Wordix**, **Crossword**, **Daily Streak Rewards**, **Daily Tasks**, and the **Lucky Spin Wheel**.
   - Any coin rewards won or spent anywhere immediately synchronize the user's main wallet balance across `User` and `Coin` records.
2. **7-Day Streak Calendar**:
   - Users can claim their Daily Streak **once per calendar day (IST standard - midnight to midnight)**.
   - **Consecutive Claim**: If claimed on consecutive days, progress moves `Day 1 -> Day 2 -> ... -> Day 7`.
   - **Cycle Loop**: Completing Day 7 rolls over to **Day 1 of Cycle 2** without losing total streak count.
   - **Skip Penalty**: Missing an entire calendar day resets the current streak back to **Day 1**.
3. **Daily Tasks (Combined Across Both Word Games)**:
   - Tasks generate automatically every midnight at `00:00:00 IST`.
   - Actions across **Wordix** and **Crossword** increment the matching task progress.
   - Once `progress >= total`, the user can claim the reward coins.
4. **Lucky Spin Wheel (Spin & Win)**:
   - **1 Free Spin every calendar day** (resets at midnight IST).
   - **Extra Spins**: Users can unlock extra spins by either **watching a rewarded ad** (max 3 per day) or spending **100 coins**.
   - **Fair Server-Side RNG**: The winning slice is calculated securely on the backend using weighted probabilities to prevent client tampering.
   - Automatically increments the `spin_wheel_task` daily task progress.

---

## 🗄️ 2. Database Schema (MongoDB / Mongoose Reference)

### 2.1. User Daily Streak Schema (`DailyStreak` / `UserDailyStreak`)
```javascript
const userDailyStreakSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  gameName: { type: String, default: 'WordPuzzle' }, // Shared key 'WordPuzzle'
  currentStreak: { type: Number, default: 1, min: 1, max: 7 },
  cycle: { type: Number, default: 1 },
  lastClaimDate: { type: String, default: null }, // 'YYYY-MM-DD' in IST
  totalDaysClaimed: { type: Number, default: 0 },
  maxStreak: { type: Number, default: 0 }
}, { timestamps: true });
```

### 2.2. User Daily Tasks Schema (`DailyTask` / `UserDailyTasks`)
```javascript
const dailyTaskItemSchema = new mongoose.Schema({
  taskKey: { type: String, required: true },
  title: { type: String, required: true },
  description: { type: String, required: true },
  progress: { type: Number, default: 0 },
  total: { type: Number, required: true },
  coins: { type: Number, required: true },
  gameScope: { type: String, default: 'all' }, // 'wordix' | 'crossword' | 'all'
  isCompleted: { type: Boolean, default: false },
  isClaimed: { type: Boolean, default: false }
});

const userDailyTasksSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  gameName: { type: String, default: 'WordPuzzle' },
  date: { type: String, required: true }, // Format: "YYYY-MM-DD" in IST
  tasks: [dailyTaskItemSchema]
}, { timestamps: true });

userDailyTasksSchema.index({ user: 1, gameName: 1, date: 1 }, { unique: true });
```

### 2.3. User Daily Spin Schema (`UserDailySpin`)
```javascript
const userDailySpinSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  dateString: { type: String, required: true }, // Format: "YYYY-MM-DD" in IST
  freeSpinsUsed: { type: Number, default: 0 },
  freeSpinsMax: { type: Number, default: 1 },
  adSpinsUsed: { type: Number, default: 0 },
  adSpinsMax: { type: Number, default: 3 }, // Max 3 ad spins per day
  coinSpinsUsed: { type: Number, default: 0 },
  lastSpinTime: { type: Date, default: null },
  totalSpinsCount: { type: Number, default: 0 }
}, { timestamps: true });

userDailySpinSchema.index({ userId: 1, dateString: 1 }, { unique: true });
```

---

## 🎁 3. 7-Day Rewards Calendar Config

| Day | Milestone | Coins | Reward Name | Description |
| :---: | :---: | :---: | :--- | :--- |
| **Day 1** | — | `100` | Word Explorer | Welcome back starter coin stash |
| **Day 2** | — | `150` | Lexicon Novice | Early streak word enthusiast boost |
| **Day 3** | — | `200` | Vocabulary Cadet | Mid-week puzzle booster |
| **Day 4** | — | `300` | Letter Artisan | Silver coin reserve |
| **Day 5** | — | `450` | Word Master Vault | Gold tier lexicon treasure |
| **Day 6** | — | `600` | Grid Sage Jackpot | Platinum tier high-streak stash |
| **Day 7** | 🏆 **MEGA CHEST** | `1,200` | Grand Lexicon Champion Chest | Maximum 7-Day streak achievement |

---

## 📋 4. Daily Tasks Catalog (Tailored for Wordix & Crossword)

Tasks automatically generated for each user every midnight in IST:

| `taskKey` | Title | Description | Target | Reward Coins | Game Scope |
| :--- | :--- | :--- | :---: | :---: | :--- |
| `play_wordix` | **Word Finder** | Play 3 levels in Wordix Word Search | `3` | `100` | `wordix` |
| `win_wordix` | **Grid Conqueror** | Complete 2 Wordix Word Search levels | `2` | `150` | `wordix` |
| `play_crossword` | **Wheel Weaver** | Play 3 Crossword Word Connect levels | `3` | `100` | `crossword` |
| `win_crossword` | **Crossword Maestro**| Solve 2 Crossword levels | `2` | `150` | `crossword` |
| `word_master_duo`| **Dual Scholar** | Play both Wordix & Crossword today | `2` | `200` | Across App |
| `use_hint` | **Clue Seeker** | Use 2 hints or shuffles in any game | `2` | `80` | Across App |
| `spin_wheel_task`| **Fortune Seeker** | Spin the Lucky Wheel 1 time | `1` | `50` | Across App |
| `watch_ad` | **Bonus Hunter** | Watch 2 rewarded ads | `2` | `80` | Across App |

---

## 🎡 5. Lucky Spin Wheel Config & Probabilities

The wheel contains **8 slices** with server-side weighted probabilities:

| Slice ID | Label / Value | Type | Weight / Chance | Description |
| :---: | :---: | :---: | :---: | :--- |
| `0` | `50 Coins` | `coins` | `30%` (300) | Common Starter Bag |
| `1` | `100 Coins` | `coins` | `25%` (250) | Standard Pocket Cache |
| `2` | `150 Coins` | `coins` | `18%` (180) | Solid Reward Stash |
| `3` | `250 Coins` | `coins` | `12%` (120) | Silver Vault Bonus |
| `4` | `400 Coins` | `coins` | `8%` (80) | Gold Tier Windfall |
| `5` | `600 Coins` | `coins` | `4.5%` (45) | Diamond Stash |
| `6` | `2x Hint Free` | `free_hint` | `2%` (20) | 2 Free Hints in Crossword / Wordix (+100c fallback) |
| `7` | `1,200 Coins` | `jackpot` | `0.5%` (5) | 🏆 GRAND ARCADE JACKPOT |

---

## 🌐 6. Backend API Endpoints Reference

---

### 6.1. Get Daily Status (Streak + Tasks + Spin + Wallet)
Fetches today's streak status, daily tasks with progress, spin wheel eligibility, and current wallet balance in a single call.

* **URL**: `/api/daily/status`
* **Method**: `GET`
* **Query Params**: `gameName=Wordix` (or `crossword` / `word_puzzle`)
* **Headers**:
  ```http
  Authorization: Bearer <USER_AUTH_TOKEN>
  Content-Type: application/json
  ```

#### Example Response (`200 OK`):
```json
{
  "success": true,
  "date": "2026-10-17",
  "gameName": "Wordix",
  "appSharedStreak": true,
  "streak": {
    "currentDay": 1,
    "currentStreak": 1,
    "isTodayClaimed": false,
    "canClaim": true,
    "cycle": 1,
    "totalDaysClaimed": 0,
    "maxStreak": 0,
    "lastClaimDate": null,
    "isResetDueToSkip": false,
    "todayReward": {
      "day": 1,
      "title": "Word Explorer",
      "coins": 100,
      "diamonds": 0
    }
  },
  "rewardsCatalog": [
    { "day": 1, "title": "Day 1", "coins": 100, "status": "available", "isCurrentDay": true },
    { "day": 2, "title": "Day 2", "coins": 150, "status": "locked", "isCurrentDay": false },
    { "day": 3, "title": "Day 3", "coins": 200, "status": "locked", "isCurrentDay": false },
    { "day": 4, "title": "Day 4", "coins": 300, "status": "locked", "isCurrentDay": false },
    { "day": 5, "title": "Day 5", "coins": 450, "status": "locked", "isCurrentDay": false },
    { "day": 6, "title": "Day 6", "coins": 600, "status": "locked", "isCurrentDay": false },
    { "day": 7, "title": "Day 7 (MEGA CHEST)", "coins": 1200, "status": "locked", "isCurrentDay": false }
  ],
  "dailyTasks": [
    {
      "taskKey": "play_wordix",
      "title": "Word Finder",
      "description": "Play 3 levels in Wordix Word Search",
      "progress": 0,
      "total": 3,
      "coins": 100,
      "diamonds": 0,
      "gameScope": "wordix",
      "isCompleted": false,
      "isClaimed": false
    },
    {
      "taskKey": "win_crossword",
      "title": "Crossword Maestro",
      "description": "Solve 2 Crossword levels",
      "progress": 0,
      "total": 2,
      "coins": 150,
      "diamonds": 0,
      "gameScope": "crossword",
      "isCompleted": false,
      "isClaimed": false
    }
  ],
  "spin": {
    "hasFreeSpin": true,
    "freeSpinsRemaining": 1,
    "adSpinsRemaining": 3,
    "coinSpinCost": 100
  },
  "wallet": {
    "coins": 500,
    "diamonds": 0
  }
}
```

---

### 6.2. Claim Today's Daily Streak Reward
Claims the current day's streak coins into the user wallet and advances streak day for tomorrow.

* **URL**: `/api/daily/claim-streak`
* **Method**: `POST`
* **Headers**: `Authorization: Bearer <TOKEN>`
* **Body**:
```json
{
  "gameName": "Wordix"
}
```

#### Success Response (`200 OK`):
```json
{
  "success": true,
  "message": "🎉 Day 1 Reward Claimed Successfully!",
  "data": {
    "claimedDay": 1,
    "coinsAwarded": 100,
    "newWalletBalance": 600,
    "nextDay": 2,
    "nextDayCoins": 150,
    "cycle": 1,
    "totalDaysClaimed": 1
  }
}
```

#### Error Response (Already Claimed) (`400 Bad Request`):
```json
{
  "success": false,
  "message": "You have already claimed today's daily streak reward. Please come back tomorrow!"
}
```

---

### 6.3. Update Daily Task Progress
Called whenever the player plays or wins a level, triggers hints, or watches ads.

* **URL**: `/api/daily/task-progress`
* **Method**: `POST`
* **Headers**: `Authorization: Bearer <TOKEN>`
* **Body**:
```json
{
  "taskKey": "play_wordix",
  "increment": 1
}
```

#### Success Response (`200 OK`):
```json
{
  "success": true,
  "message": "Task progress updated",
  "data": {
    "taskKey": "play_wordix",
    "progress": 2,
    "total": 3,
    "coins": 100,
    "gameScope": "wordix",
    "isCompleted": false,
    "isClaimed": false
  }
}
```

---

### 6.4. Claim Completed Daily Task Reward
Credits coins from a completed task into the user's wallet.

* **URL**: `/api/daily/claim-task`
* **Method**: `POST`
* **Headers**: `Authorization: Bearer <TOKEN>`
* **Body**:
```json
{
  "taskKey": "win_crossword"
}
```

#### Success Response (`200 OK`):
```json
{
  "success": true,
  "message": "🎉 Task reward claimed!",
  "data": {
    "taskKey": "win_crossword",
    "coinsAwarded": 150,
    "newWalletBalance": 750,
    "isClaimed": true
  }
}
```

---

### 6.5. Get Spin Wheel Status
* **URL**: `/api/daily/spin-status`
* **Method**: `GET`
* **Headers**: `Authorization: Bearer <TOKEN>`

#### Success Response (`200 OK`):
```json
{
  "success": true,
  "data": {
    "hasFreeSpin": true,
    "freeSpinsUsed": 0,
    "freeSpinsMax": 1,
    "adSpinsUsed": 0,
    "adSpinsMax": 3,
    "coinSpinCost": 100,
    "userCoins": 750,
    "canSpinWithCoins": true
  }
}
```

---

### 6.6. Execute Lucky Spin Wheel
Calculates the winning slice on the backend with server RNG, updates spin counters, credits coins, and auto-progresses `spin_wheel_task`.

* **URL**: `/api/daily/spin-wheel`
* **Method**: `POST`
* **Headers**: `Authorization: Bearer <TOKEN>`
* **Body**:
```json
{
  "spinType": "free",
  "gameName": "Wordix"
}
```
> `spinType` must be `"free"`, `"ad"`, or `"coins"`.

#### Success Response (`200 OK`):
```json
{
  "success": true,
  "message": "🎉 Lucky Spin Successful!",
  "data": {
    "sliceIndex": 3,
    "reward": {
      "type": "coins",
      "amount": 250,
      "label": "250 Coins"
    },
    "coinsAwarded": 250,
    "newWalletBalance": 1000,
    "freeSpinsRemaining": 0,
    "adSpinsRemaining": 3
  }
}
```

---

## 🎯 7. Flutter Client Integration Examples for `word_puzzle`

### 7.1. Helper in `daily_service.dart`:
```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String BASE_URL = 'https://game-api-0tgi.onrender.com/api';

class DailyService {
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': token.startsWith('Bearer ') ? token : 'Bearer $token',
    };
  }

  // 1. Fetch Daily Status (Streak + Tasks + Spin + Wallet)
  static Future<Map<String, dynamic>?> getDailyStatus({String gameName = 'Wordix'}) async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(
        Uri.parse('$BASE_URL/daily/status?gameName=$gameName'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint("Error fetching daily status: $e");
    }
    return null;
  }

  // 2. Claim Streak Reward
  static Future<Map<String, dynamic>?> claimStreak({String gameName = 'Wordix'}) async {
    try {
      final headers = await _getHeaders();
      final res = await http.post(
        Uri.parse('$BASE_URL/daily/claim-streak'),
        headers: headers,
        body: jsonEncode({'gameName': gameName}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint("Error claiming streak: $e");
    }
    return null;
  }

  // 3. Update Daily Task Progress
  static Future<void> reportTaskProgress(String taskKey, {int increment = 1, String gameName = 'Wordix'}) async {
    try {
      final headers = await _getHeaders();
      await http.post(
        Uri.parse('$BASE_URL/daily/task-progress'),
        headers: headers,
        body: jsonEncode({
          'taskKey': taskKey,
          'increment': increment,
          'gameName': gameName,
        }),
      );
    } catch (e) {
      debugPrint("Failed to update daily task progress: $e");
    }
  }

  // 4. Claim Daily Task Reward
  static Future<Map<String, dynamic>?> claimTask(String taskKey) async {
    try {
      final headers = await _getHeaders();
      final res = await http.post(
        Uri.parse('$BASE_URL/daily/claim-task'),
        headers: headers,
        body: jsonEncode({'taskKey': taskKey}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint("Error claiming task: $e");
    }
    return null;
  }

  // 5. Get Lucky Spin Status
  static Future<Map<String, dynamic>?> getSpinStatus() async {
    try {
      final headers = await _getHeaders();
      final res = await http.get(Uri.parse('$BASE_URL/daily/spin-status'), headers: headers);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint("Error fetching spin status: $e");
    }
    return null;
  }

  // 6. Execute Lucky Spin Wheel
  static Future<Map<String, dynamic>?> spinWheel({required String spinType, String gameName = 'Wordix'}) async {
    try {
      final headers = await _getHeaders();
      final res = await http.post(
        Uri.parse('$BASE_URL/daily/spin-wheel'),
        headers: headers,
        body: jsonEncode({'spinType': spinType, 'gameName': gameName}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      debugPrint("Error executing spin: $e");
    }
    return null;
  }
}
```

### 7.2. Where to Hook in Game Code:
1. **Wordix Level Win** (`lib/wordix/word_search.dart`):
   ```dart
   DailyService.reportTaskProgress('play_wordix');
   DailyService.reportTaskProgress('win_wordix');
   ```
2. **Crossword Level Solved** (`lib/crossword/crossword_game.dart`):
   ```dart
   DailyService.reportTaskProgress('play_crossword');
   DailyService.reportTaskProgress('win_crossword');
   ```
3. **Using Hint or Shuffle**:
   ```dart
   DailyService.reportTaskProgress('use_hint');
   ```
4. **Watching an Ad** (`lib/view/ad_show.dart`):
   ```dart
   DailyService.reportTaskProgress('watch_ad');
   ```
5. **Spinning the Lucky Wheel**:
   ```dart
   final result = await DailyService.spinWheel(spinType: 'free'); // or 'ad' or 'coins'
   ```
