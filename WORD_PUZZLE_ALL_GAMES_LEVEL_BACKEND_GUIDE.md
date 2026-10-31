# 🎮 Word Puzzle - 4 Games Level Progression Backend API Guide
> **Version:** 2.0  
> **Author:** Antigravity Engineering  
> **Base URL:** `https://shrank-race-pastrami.ngrok-free.dev` (or production API host)  
> **Target Games:** Wordix, Crossword, Word Scramble, Balloon Rescue

---

## 📌 1. Overview & Architecture

All 4 word puzzle games within the application use a **unified game level architecture** under the parent `gameName: "Wordix"`. Each game mode is distinguished by its `subGame` parameter:

| # | Game Title | `gameName` | `subGame` | Description |
|---|------------|------------|-----------|-------------|
| 1 | **Wordix Search & Voyage** | `"Wordix"` | `""` *(or omit)* | Classic word search grid puzzle |
| 2 | **Crossword / Word Connect** | `"Wordix"` | `"crossword"` | Circular letter wheel connect crossword |
| 3 | **Word Scramble** | `"Wordix"` | `"scramble"` | Letter column rearrangement / anagrams |
| 4 | **Balloon Rescue** | `"Wordix"` | `"balloon"` | Balloon pin letter popping word rescue |

---

## 🗄️ 2. Database Schema (MongoDB / Mongoose Reference)

Each user has **one document per game mode**. The unique compound index ensures no duplicate records:

```javascript
const completedLevelSchema = new mongoose.Schema({
  level: { type: Number, required: true },
  stars: { type: Number, default: 3, min: 0, max: 3 },
  score: { type: Number, default: 0 },
  moves: { type: Number, default: 0 },
  isCompleted: { type: Boolean, default: true },
  completedAt: { type: Date, default: Date.now }
}, { _id: false });

const gameLevelSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  gameName: { type: String, required: true, default: 'Wordix' },
  subGame: { type: String, default: '' }, // '', 'crossword', 'scramble', 'balloon'
  gameLevel: { type: Number, default: 1 }, // Currently active level
  highestLevelUnlocked: { type: Number, default: 1 }, // Highest unlocked level
  totalStars: { type: Number, default: 0 },
  highScore: { type: Number, default: 0 },
  totalScore: { type: Number, default: 0 },
  gridSize: { type: String, default: '6' },
  completedLevels: [completedLevelSchema]
}, { timestamps: true });

// Compound Index: One level progression document per user per subGame!
gameLevelSchema.index({ user: 1, gameName: 1, subGame: 1 }, { unique: true });
```

---

## 📡 3. API Endpoints Specification

### 🔹 3.1. Fetch User Game Level (`GET /api/gameLevel/data`)
Fetches the current level progression and completed level history for the specified game.

- **Method:** `GET`
- **URL:** `/api/gameLevel/data`
- **Headers:**
  ```http
  Authorization: Bearer <JWT_USER_TOKEN>
  Content-Type: application/json
  ```
- **Query Parameters:**
  - `gameName`: (Required) `"Wordix"`
  - `subGame`: (Optional / Required for mode) `""`, `"crossword"`, `"scramble"`, or `"balloon"`

#### Examples:
- **Wordix:** `GET /api/gameLevel/data?gameName=Wordix`
- **Crossword:** `GET /api/gameLevel/data?gameName=Wordix&subGame=crossword`
- **Word Scramble:** `GET /api/gameLevel/data?gameName=Wordix&subGame=scramble`
- **Balloon Rescue:** `GET /api/gameLevel/data?gameName=Wordix&subGame=balloon`

#### Success Response (`200 OK`):
```json
{
  "success": true,
  "data": {
    "_id": "6ae2d9c0006e6d5bb706b3f5",
    "user": "69afb519c43429af7d70cb68",
    "gameName": "Wordix",
    "subGame": "scramble",
    "gameLevel": 4,
    "highestLevelUnlocked": 4,
    "totalStars": 9,
    "highScore": 450,
    "totalScore": 1250,
    "completedLevels": [
      {
        "level": 1,
        "stars": 3,
        "score": 400,
        "moves": 5,
        "isCompleted": true,
        "completedAt": "2026-10-31T05:20:00.000Z"
      },
      {
        "level": 2,
        "stars": 3,
        "score": 420,
        "moves": 6,
        "isCompleted": true,
        "completedAt": "2026-10-31T05:25:00.000Z"
      },
      {
        "level": 3,
        "stars": 3,
        "score": 430,
        "moves": 4,
        "isCompleted": true,
        "completedAt": "2026-10-31T05:30:00.000Z"
      }
    ],
    "createdAt": "2026-10-31T05:00:00.000Z",
    "updatedAt": "2026-10-31T05:30:00.000Z"
  }
}
```

> **Note on New Users:** If the user has never played this subGame before, the API must automatically create and return a default record with `gameLevel: 1`, `highestLevelUnlocked: 1`, and `completedLevels: []`.

---

### 🔹 3.2. Complete Level & Unlock Next (`POST /api/gameLevel/completeLevel`)
Called when the user successfully wins/completes a level in any of the 4 games.

- **Method:** `POST`
- **URL:** `/api/gameLevel/completeLevel`
- **Headers:**
  ```http
  Authorization: Bearer <JWT_USER_TOKEN>
  Content-Type: application/json
  ```
- **Request Body:**
```json
{
  "gameName": "Wordix",
  "subGame": "scramble",
  "level": 3,
  "stars": 3,
  "score": 450,
  "moves": 4
}
```

#### Backend Processing Rules:
1. Find or create the `GameLevel` document for `(user, gameName, subGame)`.
2. Check `completedLevels` for this `level`:
   - If not present: add it to `completedLevels`, increase `totalScore += score`, and `totalStars += stars`.
   - If already present: update `stars = max(existing.stars, new.stars)` and `score = max(existing.score, new.score)`.
3. Advance `highestLevelUnlocked`:
   - If `level >= highestLevelUnlocked`, set `highestLevelUnlocked = level + 1`.
   - Set `gameLevel = max(gameLevel, level + 1)`.
4. Update `highScore = max(highScore, score)`.
5. Save and return updated document.

#### Success Response (`200 OK`):
```json
{
  "success": true,
  "message": "Level completed successfully",
  "data": {
    "gameName": "Wordix",
    "subGame": "scramble",
    "highestLevelUnlocked": 4,
    "nextUnlockedLevel": 4,
    "gameLevel": 4,
    "totalStars": 12,
    "totalScore": 1700
  }
}
```

---

### 🔹 3.3. Direct Level Update (`POST /api/gameLevel/update`)
Compatibility endpoint used for quick level advancement or grid size synchronization.

- **Method:** `POST`
- **URL:** `/api/gameLevel/update`
- **Headers:**
  ```http
  Authorization: Bearer <JWT_USER_TOKEN>
  Content-Type: application/json
  ```
- **Request Body:**
```json
{
  "gameName": "Wordix",
  "subGame": "balloon",
  "gameLevel": 5,
  "gridSize": "6"
}
```

#### Success Response (`200 OK`):
```json
{
  "success": true,
  "message": "Level updated successfully",
  "data": {
    "gameName": "Wordix",
    "subGame": "balloon",
    "gameLevel": 5,
    "highestLevelUnlocked": 5
  }
}
```

---

### 🔹 3.4. Reset Level (`POST /api/gameLevel/reset`) *(Testing / Admin)*
Resets the specified game mode back to Level 1.

- **Method:** `POST`
- **URL:** `/api/gameLevel/reset`
- **Headers:**
  ```http
  Authorization: Bearer <JWT_USER_TOKEN>
  Content-Type: application/json
  ```
- **Request Body:**
```json
{
  "gameName": "Wordix",
  "subGame": "scramble"
}
```

#### Success Response (`200 OK`):
```json
{
  "success": true,
  "message": "Game level reset to 1",
  "data": {
    "gameName": "Wordix",
    "subGame": "scramble",
    "gameLevel": 1,
    "highestLevelUnlocked": 1,
    "completedLevels": []
  }
}
```

---

## ⚡ 4. Flutter Frontend Integration Summary

All 4 services in Flutter now follow this exact specification:

| Game | Flutter Service File | Calling URL |
|---|---|---|
| **Wordix** | `lib/widget/get_level.dart` | `.../api/gameLevel/data?gameName=Wordix` |
| **Crossword** | `lib/crossword/crossword_level_service.dart` | `.../api/gameLevel/data?gameName=Wordix&subGame=crossword` |
| **Word Scramble** | `lib/scramble/scramble_level_service.dart` | `.../api/gameLevel/data?gameName=Wordix&subGame=scramble` |
| **Balloon Rescue** | `lib/balloon_rescue/balloon_level_service.dart` | `.../api/gameLevel/data?gameName=Wordix&subGame=balloon` |

### Offline Guarantee:
Every service saves locally to `SharedPreferences` first so the user never experiences lag or gets blocked if offline. When the network is available, progress is seamlessly synced with the backend endpoints specified above.

