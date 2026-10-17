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

  bool get isSoundOn => _isSoundOn;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _soLoud = SoLoud.instance;
      if (!_soLoud.isInitialized) {
        await _soLoud.init();
      }

      await _loadSoundSetting();

      // Load ascending pentatonic letter tap notes
      _letterTaps.clear();
      for (int i = 1; i <= 8; i++) {
        try {
          final src = await _soLoud.loadAsset(
            'assets/music/crossword/cw_letter_tap_$i.wav',
          );
          _letterTaps.add(src);
        } catch (e) {
          debugPrint('Error loading cw_letter_tap_$i: $e');
        }
      }

      // Load primary game sounds
      _wordMatch = await _safeLoad('assets/music/crossword/cw_word_match.wav');
      _tileLand = await _safeLoad('assets/music/crossword/cw_tile_land.wav');
      _notFound = await _safeLoad('assets/music/crossword/cw_not_found.wav');
      _shuffle = await _safeLoad('assets/music/crossword/cw_shuffle.wav');
      _hint = await _safeLoad('assets/music/crossword/cw_hint.wav');
      _winner = await _safeLoad('assets/music/crossword/cw_winner.wav');
      _coin = await _safeLoad('assets/music/crossword/cw_coin.wav');
      // _button = await _safeLoad('assets/music/crossword/cw_button.wav');
      _button = await _safeLoad('assets/music/button.mp3');
      _countdown = await _safeLoad('assets/music/crossword/cw_countdown.wav');
      _gameOver = await _safeLoad('assets/music/crossword/cw_game_over.wav');

      _isInitialized = true;
    } catch (e) {
      debugPrint('CrosswordAudioHelper initialize error: $e');
    }
  }

  Future<AudioSource?> _safeLoad(String path) async {
    try {
      return await _soLoud.loadAsset(path);
    } catch (e) {
      debugPrint('Error loading $path: $e');
      return null;
    }
  }

  Future<void> _loadSoundSetting() async {
    final prefs = await SharedPreferences.getInstance();
    _isSoundOn = prefs.getBool('sound_on') ?? true;
  }

  Future<void> toggleSound() async {
    _isSoundOn = !_isSoundOn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_on', _isSoundOn);
  }

  /// Play dynamic rising note as letters are connected on the circular wheel
  Future<void> playLetterTap([int noteIndex = 0]) async {
    if (!_isSoundOn || _letterTaps.isEmpty) return;
    try {
      final safeIndex = noteIndex.clamp(0, _letterTaps.length - 1);
      await _soLoud.play(_letterTaps[safeIndex]);
    } catch (e) {
      debugPrint('playLetterTap error: $e');
    }
  }

  /// Word formed and matches target list (sparkling triumphant chord)
  Future<void> playWordMatch() async {
    if (!_isSoundOn || _wordMatch == null) return;
    try {
      await _soLoud.play(_wordMatch!);
    } catch (e) {
      debugPrint('playWordMatch error: $e');
    }
  }

  /// Letter tile snaps into crossword grid
  Future<void> playTileLand() async {
    if (!_isSoundOn || _tileLand == null) return;
    try {
      await _soLoud.play(_tileLand!);
    } catch (e) {
      debugPrint('playTileLand error: $e');
    }
  }

  /// Invalid word or incomplete level bounce
  Future<void> playNotFound() async {
    if (!_isSoundOn || _notFound == null) return;
    try {
      await _soLoud.play(_notFound!);
    } catch (e) {
      debugPrint('playNotFound error: $e');
    }
  }

  /// Shuffle wheel letters swoosh
  Future<void> playShuffle() async {
    if (!_isSoundOn || _shuffle == null) return;
    try {
      await _soLoud.play(_shuffle!);
    } catch (e) {
      debugPrint('playShuffle error: $e');
    }
  }

  /// Hint clue sparkle
  Future<void> playHint() async {
    if (!_isSoundOn || _hint == null) return;
    try {
      await _soLoud.play(_hint!);
    } catch (e) {
      debugPrint('playHint error: $e');
    }
  }

  /// Level complete victory fanfare
  Future<void> playWinner() async {
    if (!_isSoundOn || _winner == null) return;
    try {
      await _soLoud.play(_winner!);
    } catch (e) {
      debugPrint('playWinner error: $e');
    }
  }

  /// Coin reward or deduction ting
  Future<void> playCoin() async {
    if (!_isSoundOn || _coin == null) return;
    try {
      await _soLoud.play(_coin!);
    } catch (e) {
      debugPrint('playCoin error: $e');
    }
  }

  /// Tactile button click (delegates to AudioHelper for unified button tap sound & debouncing)
  Future<void> playButton() async {
    if (!_isSoundOn) return;
    await AudioHelper().playButtonSound();
  }

  /// Game over / out of moves / time out
  Future<void> playGameOver() async {
    if (!_isSoundOn || _gameOver == null) return;
    try {
      await _soLoud.play(_gameOver!);
    } catch (e) {
      debugPrint('playGameOver error: $e');
    }
  }

  /// Last seconds rhythmic countdown tick
  void playCountdown() {
    stopCountdown();
    if (!_isSoundOn || _countdown == null) return;
    // Play immediately
    _soLoud.play(_countdown!);
    // Periodic tick every 1 second
    _countdownLoopTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isSoundOn && _countdown != null) {
        _soLoud.play(_countdown!);
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
