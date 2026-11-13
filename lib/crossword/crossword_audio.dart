import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widget/sound.dart';

/// Dedicated Audio Helper for Crossword game with bespoke sound effects
class CrosswordAudioHelper {
  static final CrosswordAudioHelper _instance =
      CrosswordAudioHelper._internal();
  factory CrosswordAudioHelper() => _instance;
  CrosswordAudioHelper._internal();

  late SoLoud _soLoud;
  bool _isSoundOn = true;
  bool _isInitialized = false;

  final List<AudioSource> _letterTaps = [];
  AudioSource? _wordMatch;
  AudioSource? _tileLand;
  AudioSource? _notFound;
  AudioSource? _shuffle;
  AudioSource? _hint;
  AudioSource? _winner;
  AudioSource? _coin;
  AudioSource? _button;
  AudioSource? _countdown;
  AudioSource? _gameOver;

  SoundHandle? _countdownHandle;
  Timer? _countdownLoopTimer;

  bool get isSoundOn => AudioHelper().isSoundOn;

  Future<void> initialize() async {
    await _loadSoundSetting();
    if (_isInitialized) return;
    try {
      _soLoud = SoLoud.instance;
      if (!_soLoud.isInitialized) {
        await AudioHelper().ensureAudioReady();
      }

      await _loadSoundSetting();
      await _loadAllSoundAssets();

      if (!AudioHelper.onAudioEngineReset.contains(_loadAllSoundAssets)) {
        AudioHelper.onAudioEngineReset.add(_loadAllSoundAssets);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('CrosswordAudioHelper initialize error: $e');
    }
  }

  Future<void> _loadAllSoundAssets() async {
    _letterTaps.clear();
    for (int i = 1; i <= 8; i++) {
      try {
        final src = await _safeLoad('assets/music/crossword/cw_letter_tap_$i.wav');
        if (src != null) {
          _letterTaps.add(src);
        }
      } catch (e) {
        debugPrint('Error loading cw_letter_tap_$i: $e');
      }
    }

    _wordMatch = await _safeLoad('assets/music/crossword/cw_word_match.wav');
    _tileLand = await _safeLoad('assets/music/crossword/cw_tile_land.wav');
    _notFound = await _safeLoad('assets/music/crossword/cw_not_found.wav');
    _shuffle = await _safeLoad('assets/music/crossword/cw_shuffle.wav');
    _hint = await _safeLoad('assets/music/crossword/cw_hint.wav');
    _winner = await _safeLoad('assets/music/crossword/cw_winner.wav');
    _coin = await _safeLoad('assets/music/crossword/cw_coin.wav');
    _button = await _safeLoad('assets/music/button.mp3');
    _countdown = await _safeLoad('assets/music/crossword/cw_countdown.wav');
    _gameOver = await _safeLoad('assets/music/crossword/cw_game_over.wav');
  }

  Future<AudioSource?> _safeLoad(String path) async {
    try {
      _soLoud = SoLoud.instance;
      return await _soLoud.loadAsset(path);
    } catch (e) {
      debugPrint('Error loading $path: $e');
      return null;
    }
  }

  Future<SoundHandle?> _safePlay(
    AudioSource? source, {
    double volume = 1.0,
  }) async {
    if (!isSoundOn) return null;
    if (source == null) {
      await _loadAllSoundAssets();
      if (source == null) return null;
    }

    try {
      if (!_soLoud.isInitialized) {
        await AudioHelper().ensureAudioReady();
        await _loadAllSoundAssets();
      }
      return await _soLoud.play(source, volume: volume);
    } catch (e) {
      debugPrint('⚠️ [CrosswordAudioHelper] Play error ($e). Auto-recovering audio...');
      try {
        await AudioHelper().ensureAudioReady(forceReload: true);
        await _loadAllSoundAssets();
        if (_soLoud.isInitialized && source != null) {
          return await _soLoud.play(source, volume: volume);
        }
      } catch (retryError) {
        debugPrint('❌ [CrosswordAudioHelper] Recovery play retry failed: $retryError');
      }
      return null;
    }
  }

  Future<void> _loadSoundSetting() async {
    final prefs = await SharedPreferences.getInstance();
    _isSoundOn = prefs.getBool('sound_on') ?? true;
  }

  Future<void> toggleSound() async {
    await AudioHelper().toggleSound();
    _isSoundOn = AudioHelper().isSoundOn;
  }

  /// Play dynamic rising note as letters are connected on the circular wheel
  Future<void> playLetterTap([int noteIndex = 0]) async {
    if (!isSoundOn) return;
    if (_letterTaps.isEmpty) {
      await _loadAllSoundAssets();
    }
    if (_letterTaps.isEmpty) return;
    final safeIndex = noteIndex.clamp(0, _letterTaps.length - 1);
    await _safePlay(_letterTaps[safeIndex]);
  }

  /// Word formed and matches target list (sparkling triumphant chord)
  Future<void> playWordMatch() async {
    await _safePlay(_wordMatch);
  }

  /// Letter tile snaps into crossword grid
  Future<void> playTileLand() async {
    await _safePlay(_tileLand);
  }

  /// Invalid word or incomplete level bounce
  Future<void> playNotFound() async {
    await _safePlay(_notFound);
  }

  /// Shuffle wheel letters swoosh
  Future<void> playShuffle() async {
    await _safePlay(_shuffle);
  }

  /// Hint clue sparkle
  Future<void> playHint() async {
    await _safePlay(_hint);
  }

  /// Level complete victory fanfare
  Future<void> playWinner() async {
    await _safePlay(_winner);
  }

  /// Coin reward or deduction ting
  Future<void> playCoin() async {
    await _safePlay(_coin);
  }

  /// Tactile button click (delegates to AudioHelper for unified button tap sound & debouncing)
  Future<void> playButton() async {
    if (!isSoundOn) return;
    await AudioHelper().playButtonSound();
  }

  /// Game over / out of moves / time out
  Future<void> playGameOver() async {
    await _safePlay(_gameOver);
  }

  /// Last seconds rhythmic countdown tick
  void playCountdown() {
    stopCountdown();
    if (!isSoundOn || _countdown == null) return;
    // Play immediately
    _safePlay(_countdown).then((h) => _countdownHandle = h);
    // Periodic tick every 1 second
    _countdownLoopTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isSoundOn && _countdown != null) {
        _safePlay(_countdown);
      }
    });
  }

  void stopCountdown() {
    _countdownLoopTimer?.cancel();
    _countdownLoopTimer = null;
    if (_countdownHandle != null) {
      _soLoud.stop(_countdownHandle!);
      _countdownHandle = null;
    }
  }
}
