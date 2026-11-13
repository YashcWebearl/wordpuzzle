import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioHelper with WidgetsBindingObserver {
  static final AudioHelper _instance = AudioHelper._internal();
  factory AudioHelper() => _instance;
  AudioHelper._internal();

  late SoLoud _soLoud;
  bool _isSoundOn = true;
  bool _isObserverRegistered = false;

  AudioSource? _button;
  AudioSource? _dragWord;
  AudioSource? _found;
  AudioSource? _notFound;
  AudioSource? _screenOpen;
  AudioSource? _money;
  AudioSource? _winner;
  AudioSource? _last5sec;
  AudioSource? _timeOut;
  AudioSource? _hint;

  // Word Scramble bespoke sound sources
  final List<AudioSource> _scramblePopNotes = [];
  AudioSource? _scramblePopDefault;
  AudioSource? _scrambleCollapse;
  AudioSource? _scrambleSolve;
  AudioSource? _scrambleKitty;
  AudioSource? _scrambleShuffle;
  AudioSource? _scramblePraise;

  // Balloon Rescue bespoke sound sources
  final List<AudioSource> _balloonPops = [];
  AudioSource? _balloonPopDefault;
  AudioSource? _balloonBurst;
  AudioSource? _balloonFly;
  AudioSource? _balloonPraise;
  AudioSource? _balloonTakeoff;
  AudioSource? _balloonFall;
  AudioSource? _balloonInflate;
  AudioSource? _balloonDanger;
  AudioSource? _balloonWrong;
  AudioSource? _balloonScared;
  AudioSource? _balloonGiggle;
  AudioSource? _balloonLetterHappy;

  SoundHandle? _characterVocalHandle;
  SoundHandle? _winnerHandle;
  SoundHandle? _notFoundHandle;
  SoundHandle? _backgroundHandle;
  SoundHandle? _last5secHandle;
  SoundHandle? _hintHandle;

  static bool _isRecovering = false;
  static final List<Future<void> Function()> onAudioEngineReset = [];

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When returning from background or full-screen video Ad, verify and recover audio
    if (state == AppLifecycleState.resumed) {
      debugPrint('🔄 [AudioHelper] App resumed. Verifying audio engine...');
      ensureAudioReady();
    }
  }

  /// Ensure SoLoud engine is alive and assets are properly loaded
  Future<void> ensureAudioReady({bool forceReload = false}) async {
    if (_isRecovering) return;
    _isRecovering = true;
    try {
      _soLoud = SoLoud.instance;
      final bool needsInit = !_soLoud.isInitialized || forceReload;
      if (needsInit) {
        debugPrint('🔄 [AudioHelper] (Re)initializing SoLoud audio engine...');
        if (_soLoud.isInitialized) {
          try {
            _soLoud.deinit();
          } catch (_) {}
        }
        await _soLoud.init();
        await _loadAllSoundAssets();
        for (final cb in onAudioEngineReset) {
          try {
            await cb();
          } catch (e) {
            debugPrint('⚠️ Error in audio reset callback: $e');
          }
        }
        debugPrint('✅ [AudioHelper] SoLoud audio engine ready and sound assets loaded.');
      } else if (_button == null) {
        await _loadAllSoundAssets();
      }
    } catch (e) {
      debugPrint('❌ [AudioHelper] ensureAudioReady failed: $e');
    } finally {
      _isRecovering = false;
    }
  }

  Future<void> initialize() async {
    await _loadSoundSetting();
    _soLoud = SoLoud.instance;

    if (!_isObserverRegistered) {
      WidgetsBinding.instance.addObserver(this);
      _isObserverRegistered = true;
    }

    await ensureAudioReady(forceReload: false);
    await _loadSoundSetting();
  }

  Future<void> _loadAllSoundAssets() async {
    _button = await _safeLoad('assets/music/button.mp3');
    _dragWord = await _safeLoad('assets/music/drag_word.mp3');
    _found = await _safeLoad('assets/music/found.mp3');
    _notFound = await _safeLoad('assets/music/not_found.mp3');
    _screenOpen = await _safeLoad('assets/music/screen_open.mp3');
    _winner = await _safeLoad('assets/music/winner.mp3');
    _money = await _safeLoad('assets/music/Money.mp3');
    _timeOut = await _safeLoad('assets/music/time_out.mp3');
    _last5sec = await _safeLoad('assets/music/last5sec.mp3');
    _hint = await _safeLoad('assets/music/hint.mp3');

    // Load Word Scramble sounds safely
    _scramblePopNotes.clear();
    for (int i = 1; i <= 8; i++) {
      try {
        final src = await _safeLoad('assets/music/scramble/scramble_pop_$i.wav');
        if (src != null) _scramblePopNotes.add(src);
      } catch (_) {}
    }
    _scramblePopDefault = await _safeLoad('assets/music/scramble/scramble_pop.wav');
    _scrambleCollapse = await _safeLoad('assets/music/scramble/scramble_collapse.wav');
    _scrambleSolve = await _safeLoad('assets/music/scramble/scramble_solve.wav');
    _scrambleKitty = await _safeLoad('assets/music/scramble/scramble_kitty.wav');
    _scrambleShuffle = await _safeLoad('assets/music/scramble/scramble_shuffle.wav');
    _scramblePraise = await _safeLoad('assets/music/scramble/scramble_praise.wav');

    // Load Balloon Rescue sounds safely
    _balloonPops.clear();
    for (int i = 1; i <= 8; i++) {
      try {
        final src = await _safeLoad('assets/music/balloon/balloon_pop_$i.wav');
        if (src != null) _balloonPops.add(src);
      } catch (_) {}
    }
    _balloonPopDefault = await _safeLoad('assets/music/balloon/balloon_pop.wav');
    _balloonBurst = await _safeLoad('assets/music/balloon/balloon_burst.wav');
    _balloonFly = await _safeLoad('assets/music/balloon/balloon_fly.wav');
    _balloonPraise = await _safeLoad('assets/music/balloon/balloon_praise.wav');
    _balloonTakeoff = await _safeLoad('assets/music/balloon/balloon_takeoff.wav');
    _balloonFall = await _safeLoad('assets/music/balloon/balloon_fall.wav');
    _balloonInflate = await _safeLoad('assets/music/balloon/balloon_inflate.wav');
    _balloonDanger = await _safeLoad('assets/music/balloon/balloon_danger.wav');
    _balloonWrong = await _safeLoad('assets/music/balloon/balloon_wrong.wav');
    _balloonScared = await _safeLoad('assets/music/balloon/balloon_scared.wav');
    _balloonGiggle = await _safeLoad('assets/music/balloon/balloon_giggle.wav');
    _balloonLetterHappy = await _safeLoad('assets/music/balloon/balloon_letter_happy.wav');
  }

  /// Centralized robust sound playback with auto-recovery if audio focus was lost
  Future<SoundHandle?> _safePlay(
    AudioSource? source, {
    double volume = 1.0,
    bool protectVoice = false,
  }) async {
    if (!_isSoundOn) return null;
    if (source == null) {
      await ensureAudioReady();
      if (source == null) return null;
    }

    try {
      if (!_soLoud.isInitialized) {
        await ensureAudioReady();
      }
      final handle = await _soLoud.play(source, volume: volume);
      if (protectVoice) {
        _soLoud.setProtectVoice(handle, true);
      }
      return handle;
    } catch (e) {
      debugPrint('⚠️ [AudioHelper] Play error ($e). Auto-recovering audio engine...');
      try {
        await ensureAudioReady(forceReload: true);
        if (_soLoud.isInitialized && source != null) {
          final handle = await _soLoud.play(source, volume: volume);
          if (protectVoice) {
            _soLoud.setProtectVoice(handle, true);
          }
          return handle;
        }
      } catch (retryError) {
        debugPrint('❌ [AudioHelper] Recovery play retry failed: $retryError');
      }
      return null;
    }
  }

  Future<void> _loadSoundSetting() async {
    final prefs = await SharedPreferences.getInstance();
    _isSoundOn = prefs.getBool('sound_on') ?? true;
  }

  Future<void> setSound(bool value) async {
    _isSoundOn = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_on', _isSoundOn);
    if (!_isSoundOn) {
      await stopAllSounds();
    }
  }

  Future<void> stopAllSounds() async {
    try {
      if (_last5secHandle != null) {
        await _soLoud.stop(_last5secHandle!);
        _last5secHandle = null;
      }
      if (_hintHandle != null) {
        await _soLoud.stop(_hintHandle!);
        _hintHandle = null;
      }
      if (_backgroundHandle != null) {
        await _soLoud.stop(_backgroundHandle!);
        _backgroundHandle = null;
      }
      if (_winnerHandle != null) {
        await _soLoud.stop(_winnerHandle!);
        _winnerHandle = null;
      }
      if (_notFoundHandle != null) {
        await _soLoud.stop(_notFoundHandle!);
        _notFoundHandle = null;
      }
      if (_characterVocalHandle != null) {
        await _soLoud.stop(_characterVocalHandle!);
        _characterVocalHandle = null;
      }
    } catch (_) {}
  }

  Future<void> toggleSound() async {
    await setSound(!_isSoundOn);
  }

  bool get isSoundOn => _isSoundOn;

  static int _lastButtonSoundTime = 0;

  Future<void> playButtonSound() async {
    if (!_isSoundOn) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastButtonSoundTime < 100) return;
    _lastButtonSoundTime = now;

    await _safePlay(_button);
  }

  Future<void> playTapSound() => playButtonSound();

  Future<void> playMoneySound() async {
    await _safePlay(_money);
  }

  Future<void> playLastSecond() async {
    _last5secHandle = await _safePlay(_last5sec);
  }

  Future<void> stopLastSecond() async {
    if (_last5secHandle != null) {
      try {
        await _soLoud.stop(_last5secHandle!);
      } catch (_) {}
      _last5secHandle = null;
    }
  }

  Future<void> playHintSound() async {
    _hintHandle = await _safePlay(_hint);
  }

  Future<void> stopHintSound() async {
    if (_hintHandle != null) {
      try {
        await _soLoud.stop(_hintHandle!);
      } catch (_) {}
      _hintHandle = null;
    }
  }

  Future<void> playDragWordSound() async {
    _backgroundHandle = await _safePlay(_dragWord, protectVoice: true);
  }

  Future<void> playFoundSound() async {
    await _safePlay(_found);
  }

  Future<void> playTimeOutSound() async {
    await _safePlay(_timeOut);
  }

  Future<void> playNotFoundSound() async {
    _notFoundHandle = await _safePlay(_notFound);
  }

  Future<void> playScreenOpenSound() async {
    await _safePlay(_screenOpen);
  }

  Future<void> playWinnerSound() async {
    _winnerHandle = await _safePlay(_winner);
  }

  Future<void> stopWinnerOrNotFoundSound() async {
    if (_winnerHandle != null) {
      try {
        _soLoud.stop(_winnerHandle!);
      } catch (_) {}
      _winnerHandle = null;
    }
    if (_notFoundHandle != null) {
      try {
        _soLoud.stop(_notFoundHandle!);
      } catch (_) {}
      _notFoundHandle = null;
    }
  }

  Future<void> stopBackgroundSound() async {
    if (_backgroundHandle != null) {
      try {
        _soLoud.fadeVolume(
            _backgroundHandle!, 0.0, const Duration(milliseconds: 500));
      } catch (_) {}
    }
  }

  void dispose() {
    if (_isObserverRegistered) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserverRegistered = false;
    }
    try {
      _soLoud.deinit();
    } catch (_) {}
  }

  Future<AudioSource?> _safeLoad(String path) async {
    try {
      return await _soLoud.loadAsset(path);
    } catch (_) {
      return null;
    }
  }

  // --- Word Scramble In-Game Audio Methods ---
  Future<void> playScramblePop([int noteIndex = 0]) async {
    if (!_isSoundOn) return;
    if (_scramblePopNotes.isNotEmpty) {
      final idx = noteIndex.clamp(0, _scramblePopNotes.length - 1);
      await _safePlay(_scramblePopNotes[idx]);
    } else if (_scramblePopDefault != null) {
      await _safePlay(_scramblePopDefault);
    } else {
      await playButtonSound();
    }
  }

  Future<void> playScrambleCollapse() async {
    await _safePlay(_scrambleCollapse);
  }

  Future<void> playScrambleSolve() async {
    if (_scrambleSolve != null) {
      await _safePlay(_scrambleSolve);
    } else {
      await playFoundSound();
    }
  }

  Future<void> playScrambleKitty() async {
    await _safePlay(_scrambleKitty);
  }

  Future<void> playScrambleShuffle() async {
    await _safePlay(_scrambleShuffle);
  }

  Future<void> playScramblePraise() async {
    await _safePlay(_scramblePraise);
  }

  // --- Balloon Rescue In-Game Audio Methods ---
  Future<void> playBalloonPop([int noteIndex = 0]) async {
    if (!_isSoundOn) return;
    if (_balloonPops.isNotEmpty) {
      final idx = noteIndex.clamp(0, _balloonPops.length - 1);
      await _safePlay(_balloonPops[idx]);
    } else if (_balloonPopDefault != null) {
      await _safePlay(_balloonPopDefault);
    } else {
      await playButtonSound();
    }
  }

  Future<void> playBalloonBurst() async {
    if (_balloonBurst != null) {
      await _safePlay(_balloonBurst);
    } else {
      await playNotFoundSound();
    }
  }

  Future<void> playBalloonFly() async {
    await _safePlay(_balloonFly);
  }

  Future<void> playBalloonPraise() async {
    if (_balloonPraise != null) {
      await _safePlay(_balloonPraise);
    } else {
      await playButtonSound();
    }
  }

  Future<void> playBalloonTakeoff() async {
    if (_balloonTakeoff != null) {
      await _safePlay(_balloonTakeoff);
    } else {
      await playWinnerSound();
    }
  }

  Future<void> playBalloonFall() async {
    if (_balloonFall != null) {
      await _safePlay(_balloonFall);
    } else {
      await playTimeOutSound();
    }
  }

  Future<void> playBalloonInflate() async {
    if (_balloonInflate != null) {
      await _safePlay(_balloonInflate);
    } else {
      await playMoneySound();
    }
  }

  Future<void> playBalloonDanger() async {
    await _safePlay(_balloonDanger);
  }

  Future<void> playBalloonWrong() async {
    await _safePlay(_balloonWrong);
  }

  /// Stop any active character vocalization immediately to prevent sound overlay
  Future<void> stopCharacterVoice() async {
    if (_characterVocalHandle != null) {
      try {
        await _soLoud.stop(_characterVocalHandle!);
      } catch (_) {}
      _characterVocalHandle = null;
    }
  }

  /// Cute playful cartoon squeak/chirp on touch (0.22s, pleasant, NOT engine loop)
  Future<void> playBalloonScared() async {
    if (!_isSoundOn) return;
    await stopCharacterVoice();
    _characterVocalHandle = await _safePlay(_balloonScared, volume: 0.75);
  }

  Future<void> startBalloonHoldScared() => playBalloonScared();
  Future<void> stopBalloonHoldScared() => stopCharacterVoice();

  /// When finger is released without panic: cute short baby relief giggle
  Future<void> playBalloonRelief() async {
    if (!_isSoundOn) return;
    await stopCharacterVoice();
    _characterVocalHandle = await _safePlay(_balloonGiggle, volume: 0.85);
  }

  /// When 1 letter is correct in Balloon Rescue: short, sweet baby happy "Yay!"
  Future<void> playBalloonLetterHappy() async {
    if (!_isSoundOn) return;
    await stopCharacterVoice();
    if (_balloonLetterHappy != null) {
      _characterVocalHandle =
          await _safePlay(_balloonLetterHappy, volume: 0.85);
    } else {
      _characterVocalHandle =
          await _safePlay(_balloonGiggle, volume: 0.85);
    }
  }

  /// Celebratory "Yoo-hoooo!" joyful victory cheer on takeoff
  Future<void> playBalloonWoohoo() async {
    if (!_isSoundOn) return;
    await stopCharacterVoice();
    _characterVocalHandle = await _safePlay(_balloonTakeoff, volume: 0.95);
  }

  Future<void> playBalloonGiggle() => playBalloonRelief();
}
