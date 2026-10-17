# 🎮 Word Puzzle Hub (Wordix & Crossword) - Backend API Guide
## 📱 Daily Streak Rewards, Combined Daily Tasks & Lucky Spin Wheel System

> **Applicable For**: `word_puzzle` (Wordix Word Search + Crossword Nature Connect)  
> **Base URL (Production)**: `https://game-api-0tgi.onrender.com/api`  
> **Auth Header**: `Authorization: Bearer <JWT_TOKEN>` (or `<AUTH_TOKEN>`)  
> **Content-Type**: `application/json`

---

## 🏗️ 1. Architecture & Core Rules

1. **Unified Coin Wallet**:
   - There is a single coin wallet per user shared across **Wordix**, **Crossword**, **Daily Streak Rewards**, **Daily Tasks**, and the **Lucky Spin Wheel**.
   - Any coin rewards won or spent anywhere immediately update the user's main wallet balance.
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
   - **Extra Spins**: Users can unlock extra spins by either **watching a rewarded ad** or spending **100 coins**.
   - **Fair Server-Side RNG**: The winning slice is calculated securely on the backend using weighted probabilities to prevent client tampering.

---

## 🗄️ 2. Database Schema (MongoDB / Mongoose Reference)

### 2.1. User Daily Streak Schema (`UserDailyStreak`)
```javascript
const userDailyStreakSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  currentDay: { type: Number, default: 1, min: 1, max: 7 },
  cycle: { type: Number, default: 1 },
  lastClaimDate: { type: Date, default: null }, // Exact timestamp of last claim
  totalDaysClaimed: { type: Number, default: 0 },
  maxStreak: { type: Number, default: 0 }
}, { timestamps: true });
```

### 2.2. User Daily Tasks Schema (`UserDailyTasks`)
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
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  dateString: { type: String, required: true }, // Format: "YYYY-MM-DD" in IST
  tasks: [dailyTaskItemSchema]
}, { timestamps: true });

userDailyTasksSchema.index({ userId: 1, dateString: 1 }, { unique: true });
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

Tasks automatically generated for each user every midnight:

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
| `0` | `50 Coins` | `coins` | `30%` | Common Starter Bag |
| `1` | `100 Coins` | `coins` | `25%` | Standard Pocket Cache |
| `2` | `150 Coins` | `coins` | `18%` | Solid Reward Stash |
| `3` | `250 Coins` | `coins` | `12%` | Silver Vault Bonus |
| `4` | `400 Coins` | `coins` | `8%` | Gold Tier Windfall |
| `5` | `600 Coins` | `coins` | `4.5%` | Diamond Stash |
| `6` | `2x Hint Free` | `free_hint` | `2%` | 2 Free Hints in Crossword / Wordix |
| `7` | `1,200 Coins` | `jackpot` | `0.5%` | 🏆 GRAND ARCADE JACKPOT |

---

## 🌐 6. Backend API Endpoints Reference

---

### 6.1. Get Daily Status (Streak + Tasks + Spin + Wallet)
Fetches today's streak status, daily tasks with progress, spin wheel eligibility, and current wallet balance in a single fast call.

* **URL**: `/api/daily/status`
* **Method**: `GET`
* **Query Params**: `gameName=Wordix` (optional)
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
  "streak": {
    "currentDay": 2,
    "isTodayClaimed": false,
    "canClaim": true,
    "cycle": 1,
    "totalDaysClaimed": 1,
    "maxStreak": 1,
    "lastClaimDate": "2026-10-16T10:30:00.000Z",
    "todayReward": {
      "day": 2,
      "title": "Lexicon Novice",
      "coins": 150
    }
  },
  "rewardsCatalog": [
    { "day": 1, "title": "Day 1", "coins": 100, "status": "claimed", "isCurrentDay": false },
    { "day": 2, "title": "Day 2", "coins": 150, "status": "available", "isCurrentDay": true },
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
      "progress": 1,
      "total": 3,
      "coins": 100,
      "gameScope": "wordix",
      "isCompleted": false,
      "isClaimed": false
    },
    {
      "taskKey": "win_crossword",
      "title": "Crossword Maestro",
      "description": "Solve 2 Crossword levels",
      "progress": 2,
      "total": 2,
      "coins": 150,
      "gameScope": "crossword",
      "isCompleted": true,
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
    "coins": 520
  }
}
```

---

### 6.2. Claim Today's Daily Streak Reward
Claims the current day's streak coins into the user wallet.

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
  "message": "🎉 Day 2 Reward Claimed Successfully!",
  "data": {
    "claimedDay": 2,
    "coinsAwarded": 150,
    "newWalletBalance": 670,
    "nextDay": 3,
    "nextDayCoins": 200
  }
}
```

#### Error Response (Already Claimed) (`400 Bad Request`):
```json
{
  "success": false,
  "message": "You have already claimed today's daily streak reward."
}
```

---

### 6.3. Update Daily Task Progress
Called from Flutter whenever the player finishes a match, completes a level, or triggers an action.

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
    "newWalletBalance": 820,
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
    "userCoins": 820,
    "canSpinWithCoins": true
  }
}
```

---

### 6.6. Execute Lucky Spin Wheel
Calculates the winning slice on the server, updates spin counters, credits coins, and returns the slice index and reward details.

* **URL**: `/api/daily/spin-wheel`
* **Method**: `POST`
* **Headers**: `Authorization: Bearer <TOKEN>`
* **Body**:
```json
{
  "spinType": "free" 
}
```
> `spinType` can be `"free"`, `"ad"`, or `"coins"`.

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
    "newWalletBalance": 1070,
    "freeSpinsRemaining": 0,
    "adSpinsRemaining": 3
  }
}
```

---

## ⚙️ 7. Backend Controller Logic (Node.js/Express Complete Reference)

Here is the exact production-ready controller code for the backend team:

```javascript
// controllers/dailyWordPuzzleController.js
const mongoose = require('mongoose');
const User = require('../models/User'); // Adjust path to User model
const { UserDailyStreak, UserDailyTasks, UserDailySpin } = require('../models/DailyModels');

const STREAK_REWARDS = [100, 150, 200, 300, 450, 600, 1200];

// Spin Wheel Configuration with Weighted Chances
const WHEEL_SLICES = [
  { index: 0, type: 'coins', amount: 50, label: '50 Coins', weight: 300 },
  { index: 1, type: 'coins', amount: 100, label: '100 Coins', weight: 250 },
  { index: 2, type: 'coins', amount: 150, label: '150 Coins', weight: 180 },
  { index: 3, type: 'coins', amount: 250, label: '250 Coins', weight: 120 },
  { index: 4, type: 'coins', amount: 400, label: '400 Coins', weight: 80 },
  { index: 5, type: 'coins', amount: 600, label: '600 Coins', weight: 45 },
  { index: 6, type: 'free_hint', amount: 2, label: '2x Hints', weight: 20 },
  { index: 7, type: 'jackpot', amount: 1200, label: '1,200 JACKPOT', weight: 5 }
];

// Helper: Get IST Date string 'YYYY-MM-DD'
function getISTDateString(d = new Date()) {
  const istOffset = 5.5 * 60 * 60 * 1000;
  const istTime = new Date(d.getTime() + istOffset);
  return istTime.toISOString().split('T')[0];
}

// Helper: Pick a random slice according to weights
function pickRandomSlice() {
  const totalWeight = WHEEL_SLICES.reduce((sum, item) => sum + item.weight, 0);
  let randomVal = Math.random() * totalWeight;
  for (const slice of WHEEL_SLICES) {
    if (randomVal < slice.weight) {
      return slice;
    }
    randomVal -= slice.weight;
  }
  return WHEEL_SLICES[0];
}

// 1. GET /api/daily/status
exports.getDailyStatus = async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const todayStr = getISTDateString();

    // 1. Streak doc
    let streak = await UserDailyStreak.findOne({ userId });
    if (!streak) {
      streak = await UserDailyStreak.create({ userId, currentDay: 1 });
    }

    let isTodayClaimed = false;
    let canClaim = true;

    if (streak.lastClaimDate) {
      const lastClaimStr = getISTDateString(streak.lastClaimDate);
      const diffDays = Math.floor((new Date(todayStr) - new Date(lastClaimStr)) / (1000 * 60 * 60 * 24));

      if (diffDays === 0) {
        isTodayClaimed = true;
        canClaim = false;
      } else if (diffDays > 1) {
        // Skipped 1 or more calendar days -> reset to Day 1
        streak.currentDay = 1;
        await streak.save();
      }
    }

    // 2. Daily Tasks doc
    let dailyTaskDoc = await UserDailyTasks.findOne({ userId, dateString: todayStr });
    if (!dailyTaskDoc) {
      dailyTaskDoc = await UserDailyTasks.create({
        userId,
        dateString: todayStr,
        tasks: [
          { taskKey: 'play_wordix', title: 'Word Finder', description: 'Play 3 levels in Wordix Word Search', total: 3, coins: 100, gameScope: 'wordix' },
          { taskKey: 'win_wordix', title: 'Grid Conqueror', description: 'Complete 2 Wordix Word Search levels', total: 2, coins: 150, gameScope: 'wordix' },
          { taskKey: 'play_crossword', title: 'Wheel Weaver', description: 'Play 3 Crossword Word Connect levels', total: 3, coins: 100, gameScope: 'crossword' },
          { taskKey: 'win_crossword', title: 'Crossword Maestro', description: 'Solve 2 Crossword levels', total: 2, coins: 150, gameScope: 'crossword' },
          { taskKey: 'word_master_duo', title: 'Dual Scholar', description: 'Play both Wordix & Crossword today', total: 2, coins: 200, gameScope: 'all' },
          { taskKey: 'use_hint', title: 'Clue Seeker', description: 'Use 2 hints or shuffles in any game', total: 2, coins: 80, gameScope: 'all' },
          { taskKey: 'spin_wheel_task', title: 'Fortune Seeker', description: 'Spin the Lucky Wheel 1 time', total: 1, coins: 50, gameScope: 'all' },
          { taskKey: 'watch_ad', title: 'Bonus Hunter', description: 'Watch 2 rewarded ads', total: 2, coins: 80, gameScope: 'all' }
        ]
      });
    }

    // 3. Daily Spin doc
    let spinDoc = await UserDailySpin.findOne({ userId, dateString: todayStr });
    if (!spinDoc) {
      spinDoc = await UserDailySpin.create({ userId, dateString: todayStr });
    }

    // 4. User Wallet
    const user = await User.findById(userId);

    // 5. 7-Day Rewards Catalog
    const rewardsCatalog = STREAK_REWARDS.map((coins, idx) => {
      const day = idx + 1;
      let status = 'locked';
      if (day < streak.currentDay || (day === streak.currentDay && isTodayClaimed)) {
        status = 'claimed';
      } else if (day === streak.currentDay && canClaim) {
        status = 'available';
      }
      return {
        day,
        title: day === 7 ? 'Day 7 (MEGA CHEST)' : `Day ${day}`,
        coins,
        status,
        isCurrentDay: day === streak.currentDay
      };
    });

    return res.status(200).json({
      success: true,
      date: todayStr,
      streak: {
        currentDay: streak.currentDay,
        isTodayClaimed,
        canClaim,
        cycle: streak.cycle,
        totalDaysClaimed: streak.totalDaysClaimed,
        todayReward: {
          day: streak.currentDay,
          coins: STREAK_REWARDS[streak.currentDay - 1]
        }
      },
      rewardsCatalog,
      dailyTasks: dailyTaskDoc.tasks,
      spin: {
        hasFreeSpin: spinDoc.freeSpinsUsed < spinDoc.freeSpinsMax,
        freeSpinsRemaining: Math.max(0, spinDoc.freeSpinsMax - spinDoc.freeSpinsUsed),
        adSpinsRemaining: Math.max(0, spinDoc.adSpinsMax - spinDoc.adSpinsUsed),
        coinSpinCost: 100
      },
      wallet: { coins: user ? user.coins : 0 }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// 2. POST /api/daily/claim-streak
exports.claimStreak = async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const todayStr = getISTDateString();

    const streak = await UserDailyStreak.findOne({ userId });
    if (!streak) return res.status(404).json({ success: false, message: "Streak record not found." });

    if (streak.lastClaimDate && getISTDateString(streak.lastClaimDate) === todayStr) {
      return res.status(400).json({ success: false, message: "Already claimed today's streak reward." });
    }

    const currentDay = streak.currentDay;
    const coinsAwarded = STREAK_REWARDS[currentDay - 1];

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { $inc: { coins: coinsAwarded } },
      { new: true }
    );

    streak.lastClaimDate = new Date();
    streak.totalDaysClaimed += 1;
    if (streak.currentDay >= 7) {
      streak.currentDay = 1;
      streak.cycle += 1;
    } else {
      streak.currentDay += 1;
    }
    await streak.save();

    return res.status(200).json({
      success: true,
      message: `🎉 Day ${currentDay} Reward Claimed Successfully!`,
      data: {
        claimedDay: currentDay,
        coinsAwarded,
        newWalletBalance: updatedUser.coins,
        nextDay: streak.currentDay,
        nextDayCoins: STREAK_REWARDS[streak.currentDay - 1]
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// 3. POST /api/daily/task-progress
exports.updateTaskProgress = async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const { taskKey, increment = 1 } = req.body;
    const todayStr = getISTDateString();

    let taskDoc = await UserDailyTasks.findOne({ userId, dateString: todayStr });
    if (!taskDoc) return res.status(404).json({ success: false, message: "Today's tasks not found." });

    const task = taskDoc.tasks.find(t => t.taskKey === taskKey);
    if (!task) return res.status(404).json({ success: false, message: `Task key '${taskKey}' not found.` });

    task.progress = Math.min(task.total, task.progress + increment);
    if (task.progress >= task.total) {
      task.isCompleted = true;
    }

    await taskDoc.save();

    return res.status(200).json({
      success: true,
      message: "Task progress updated",
      data: task
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// 4. POST /api/daily/claim-task
exports.claimTask = async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const { taskKey } = req.body;
    const todayStr = getISTDateString();

    const taskDoc = await UserDailyTasks.findOne({ userId, dateString: todayStr });
    if (!taskDoc) return res.status(404).json({ success: false, message: "Tasks not found." });

    const task = taskDoc.tasks.find(t => t.taskKey === taskKey);
    if (!task) return res.status(404).json({ success: false, message: "Task not found." });

    if (task.progress < task.total) {
      return res.status(400).json({ success: false, message: "Task is not completed yet." });
    }
    if (task.isClaimed) {
      return res.status(400).json({ success: false, message: "Task reward already claimed." });
    }

    task.isClaimed = true;
    await taskDoc.save();

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { $inc: { coins: task.coins } },
      { new: true }
    );

    return res.status(200).json({
      success: true,
      message: "🎉 Task reward claimed!",
      data: {
        taskKey,
        coinsAwarded: task.coins,
        newWalletBalance: updatedUser.coins,
        isClaimed: true
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// 5. GET /api/daily/spin-status
exports.getSpinStatus = async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const todayStr = getISTDateString();

    let spinDoc = await UserDailySpin.findOne({ userId, dateString: todayStr });
    if (!spinDoc) {
      spinDoc = await UserDailySpin.create({ userId, dateString: todayStr });
    }

    const user = await User.findById(userId);
    const userCoins = user ? user.coins : 0;

    return res.status(200).json({
      success: true,
      data: {
        hasFreeSpin: spinDoc.freeSpinsUsed < spinDoc.freeSpinsMax,
        freeSpinsUsed: spinDoc.freeSpinsUsed,
        freeSpinsMax: spinDoc.freeSpinsMax,
        adSpinsUsed: spinDoc.adSpinsUsed,
        adSpinsMax: spinDoc.adSpinsMax,
        coinSpinCost: 100,
        userCoins,
        canSpinWithCoins: userCoins >= 100
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// 6. POST /api/daily/spin-wheel
exports.spinWheel = async (req, res) => {
  try {
    const userId = req.user.id || req.user._id;
    const { spinType = 'free' } = req.body; // 'free' | 'ad' | 'coins'
    const todayStr = getISTDateString();

    let spinDoc = await UserDailySpin.findOne({ userId, dateString: todayStr });
    if (!spinDoc) {
      spinDoc = await UserDailySpin.create({ userId, dateString: todayStr });
    }

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ success: false, message: "User not found" });

    // Validate Spin eligibility
    if (spinType === 'free') {
      if (spinDoc.freeSpinsUsed >= spinDoc.freeSpinsMax) {
        return res.status(400).json({ success: false, message: "Today's free spin has already been used." });
      }
      spinDoc.freeSpinsUsed += 1;
    } else if (spinType === 'ad') {
      if (spinDoc.adSpinsUsed >= spinDoc.adSpinsMax) {
        return res.status(400).json({ success: false, message: "Maximum daily ad spins reached." });
      }
      spinDoc.adSpinsUsed += 1;
    } else if (spinType === 'coins') {
      const COST = 100;
      if (user.coins < COST) {
        return res.status(400).json({ success: false, message: "Insufficient coins for spin." });
      }
      user.coins -= COST;
      spinDoc.coinSpinsUsed += 1;
    } else {
      return res.status(400).json({ success: false, message: "Invalid spinType. Use 'free', 'ad', or 'coins'." });
    }

    // Pick winning slice
    const winningSlice = pickRandomSlice();
    let coinsAwarded = 0;

    if (winningSlice.type === 'coins' || winningSlice.type === 'jackpot') {
      coinsAwarded = winningSlice.amount;
      user.coins += coinsAwarded;
    } else if (winningSlice.type === 'free_hint') {
      // Award 2 free hints or coin equivalent if hints aren't a separate DB field
      coinsAwarded = 100; // Bonus coin fallback
      user.coins += coinsAwarded;
    }

    await user.save();

    spinDoc.lastSpinTime = new Date();
    spinDoc.totalSpinsCount += 1;
    await spinDoc.save();

    // Automatically increment daily task for spin if present
    const taskDoc = await UserDailyTasks.findOne({ userId, dateString: todayStr });
    if (taskDoc) {
      const spinTask = taskDoc.tasks.find(t => t.taskKey === 'spin_wheel_task');
      if (spinTask && !spinTask.isCompleted) {
        spinTask.progress = Math.min(spinTask.total, spinTask.progress + 1);
        if (spinTask.progress >= spinTask.total) spinTask.isCompleted = true;
        await taskDoc.save();
      }
    }

    return res.status(200).json({
      success: true,
      message: "🎉 Lucky Spin Successful!",
      data: {
        sliceIndex: winningSlice.index,
        reward: {
          type: winningSlice.type,
          amount: winningSlice.amount,
          label: winningSlice.label
        },
        coinsAwarded,
        newWalletBalance: user.coins,
        freeSpinsRemaining: Math.max(0, spinDoc.freeSpinsMax - spinDoc.freeSpinsUsed),
        adSpinsRemaining: Math.max(0, spinDoc.adSpinsMax - spinDoc.adSpinsUsed)
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
```

---

## 🎯 8. Flutter Client Integration Examples for `wordpuzzle`

### 8.1. Triggering Task Progress from Games

Whenever a player completes or plays a level, call this quick helper:

```dart
// Helper in daily_service.dart
Future<void> reportTaskProgress(String taskKey, {int increment = 1}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) return;

    await http.post(
      Uri.parse('$LURL/api/daily/task-progress'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token.startsWith('Bearer ') ? token : 'Bearer $token',
      },
      body: jsonEncode({
        'taskKey': taskKey,
        'increment': increment,
      }),
    );
  } catch (e) {
    debugPrint("Failed to update daily task progress: $e");
  }
}
```

#### Where to hook in `wordpuzzle`:
1. **Wordix Level Win** (`lib/wordix/word_search.dart`):
   ```dart
   reportTaskProgress('play_wordix');
   reportTaskProgress('win_wordix');
   ```
2. **Crossword Level Solved** (`lib/crossword/crossword_game.dart`):
   ```dart
   reportTaskProgress('play_crossword');
   reportTaskProgress('win_crossword');
   ```
3. **Using Hint or Shuffle**:
   ```dart
   reportTaskProgress('use_hint');
   ```
4. **Watching an Ad** (`lib/view/ad_show.dart`):
   ```dart
   reportTaskProgress('watch_ad');
   ```
