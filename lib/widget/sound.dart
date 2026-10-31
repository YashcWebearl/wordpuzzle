import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioHelper {
  static final AudioHelper _instance = AudioHelper._internal();
  factory AudioHelper() => _instance;
  AudioHelper._internal();

  late SoLoud _soLoud;
  bool _isSoundOn = true;

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

  Future<void> initialize() async {
    // _soLoud = SoLoud.instance;
    //
    // if (_soLoud.isInitialized) return;
    print('sound fetch00000000000000');
    _soLoud = SoLoud.instance;
    print('sound fetch44444444444444');
    if (_soLoud.isInitialized) return;
    print('sound fetch11111111111');
    await _soLoud.init();

    _button = await _safeLoad('assets/music/button.mp3');
    _dragWord = await _soLoud.loadAsset('assets/music/drag_word.mp3');
    _found = await _soLoud.loadAsset('assets/music/found.mp3');
    _notFound = await _soLoud.loadAsset('assets/music/not_found.mp3');
    _screenOpen = await _soLoud.loadAsset('assets/music/screen_open.mp3');
    _winner = await _soLoud.loadAsset('assets/music/winner.mp3');
    _money = await _soLoud.loadAsset('assets/music/Money.mp3');
    _timeOut = await _soLoud.loadAsset('assets/music/time_out.mp3');
    _last5sec = await _soLoud.loadAsset('assets/music/last5sec.mp3');
    _hint = await _soLoud.loadAsset('assets/music/hint.mp3');

    // Load Word Scramble sounds safely
    _scramblePopNotes.clear();
    for (int i = 1; i <= 8; i++) {
      try {
        final src = await _soLoud.loadAsset(
          'assets/music/scramble/scramble_pop_$i.wav',
        );
        _scramblePopNotes.add(src);
      } catch (_) {}
    }
    _scramblePopDefault =
        await _safeLoad('assets/music/scramble/scramble_pop.wav');
    _scrambleCollapse =
        await _safeLoad('assets/music/scramble/scramble_collapse.wav');
    _scrambleSolve =
        await _safeLoad('assets/music/scramble/scramble_solve.wav');
    _scrambleKitty =
        await _safeLoad('assets/music/scramble/scramble_kitty.wav');
    _scrambleShuffle =
        await _safeLoad('assets/music/scramble/scramble_shuffle.wav');
    _scramblePraise =
        await _safeLoad('assets/music/scramble/scramble_praise.wav');

    // Load Balloon Rescue sounds safely
    _balloonPops.clear();
    for (int i = 1; i <= 8; i++) {
      try {
        final src = await _soLoud.loadAsset(
          'assets/music/balloon/balloon_pop_$i.wav',
        );
        _balloonPops.add(src);
      } catch (_) {}
    }
    _balloonPopDefault =
        await _safeLoad('assets/music/balloon/balloon_pop.wav');
    _balloonBurst = await _safeLoad('assets/music/balloon/balloon_burst.wav');
    _balloonFly = await _safeLoad('assets/music/balloon/balloon_fly.wav');
    _balloonPraise = await _safeLoad('assets/music/balloon/balloon_praise.wav');
    _balloonTakeoff =
        await _safeLoad('assets/music/balloon/balloon_takeoff.wav');
    _balloonFall = await _safeLoad('assets/music/balloon/balloon_fall.wav');
    _balloonInflate =
        await _safeLoad('assets/music/balloon/balloon_inflate.wav');
    _balloonDanger = await _safeLoad('assets/music/balloon/balloon_danger.wav');
    _balloonWrong = await _safeLoad('assets/music/balloon/balloon_wrong.wav');
    _balloonScared = await _safeLoad('assets/music/balloon/balloon_scared.wav');
    _balloonGiggle = await _safeLoad('assets/music/balloon/balloon_giggle.wav');
    _balloonLetterHappy =
        await _safeLoad('assets/music/balloon/balloon_letter_happy.wav');

    await _loadSoundSetting();
  }

  Future<void> _loadSoundSetting() async {
    final prefs = await SharedPreferences.getInstance();
    print('sound fetch222222222222');
    _isSoundOn = prefs.getBool('sound_on') ?? true;
  }

  Future<void> toggleSound() async {
    _isSoundOn = !_isSoundOn;
    print('sound fetch33333333333');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_on', _isSoundOn);
  }

  bool get isSoundOn => _isSoundOn;

  static int _lastButtonSoundTime = 0;

  Future<void> playButtonSound() async {
    if (!_isSoundOn || _button == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastButtonSoundTime < 100) return;
    _lastButtonSoundTime = now;

    try {
      _soLoud.play(_button!);
    } catch (_) {}
  }

  Future<void> playTapSound() => playButtonSound();
  Future<void> playMoneySound() async {
    if (_isSoundOn && _money != null) {
      await _soLoud.play(_money!);
    }
  }

  Future<void> playLastSecond() async {
    if (_isSoundOn && _last5sec != null) {
      _last5secHandle = await _soLoud.play(_last5sec!);
    }
  }

  Future<void> stopLastSecond() async {
    if (_last5secHandle != null) {
      await _soLoud.stop(_last5secHandle!);
      _last5secHandle = null;
    }
  }

  Future<void> playHintSound() async {
    if (_isSoundOn && _hint != null) {
      _hintHandle = await _soLoud.play(_hint!);
    }
  }

  Future<void> stopHintSound() async {
    if (_hintHandle != null) {
      await _soLoud.stop(_hintHandle!);
      _hintHandle = null;
    }
  }

  // Future<void> playHintSound() async {
  //   if (_isSoundOn && _hint != null) {
  //     await _soLoud.play(_hint!);
  //   }
  // }
  // Future<void> playLastSecond() async {
  //   if (_isSoundOn && _last5sec != null) {
  //     await _soLoud.play(_last5sec!);
  //   }
  // }
  // Future<void> stopLastSecond() async {
  //   if (_last5secHandle != null) {
  //     await _soLoud.stop(_last5secHandle!);
  //     _last5secHandle = null;
  //   }
  // }
  Future<void> playDragWordSound() async {
    if (_isSoundOn && _dragWord != null) {
      _backgroundHandle = await _soLoud.play(_dragWord!);
      _soLoud.setProtectVoice(_backgroundHandle!, true); // prevents auto-stop
    }
  }

  Future<void> playFoundSound() async {
    if (_isSoundOn && _found != null) {
      await _soLoud.play(_found!);
    }
  }

  Future<void> playTimeOutSound() async {
    if (_isSoundOn && _timeOut != null) {
      await _soLoud.play(_timeOut!);
    }
  }

  Future<void> playNotFoundSound() async {
    if (_isSoundOn && _notFound != null) {
      _notFoundHandle = await _soLoud.play(_notFound!);
    }
  }

  Future<void> playScreenOpenSound() async {
    if (_isSoundOn && _screenOpen != null) {
      await _soLoud.play(_screenOpen!);
    }
  }

  Future<void> playWinnerSound() async {
    if (_isSoundOn && _winner != null) {
      _winnerHandle = await _soLoud.play(_winner!);
    }
  }

  Future<void> stopWinnerOrNotFoundSound() async {
    if (_winnerHandle != null) {
      _soLoud.stop(_winnerHandle!);
      _winnerHandle = null;
    }
    if (_notFoundHandle != null) {
      _soLoud.stop(_notFoundHandle!);
      _notFoundHandle = null;
    }
  }

  Future<void> stopBackgroundSound() async {
    if (_backgroundHandle != null) {
      _soLoud.fadeVolume(
          _backgroundHandle!, 0.0, const Duration(milliseconds: 500));
    }
  }

  void dispose() {
    _soLoud.deinit();
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
    try {
      if (_scramblePopNotes.isNotEmpty) {
        final idx = noteIndex.clamp(0, _scramblePopNotes.length - 1);
        await _soLoud.play(_scramblePopNotes[idx]);
      } else if (_scramblePopDefault != null) {
        await _soLoud.play(_scramblePopDefault!);
      } else {
        await playButtonSound();
      }
    } catch (_) {}
  }

  Future<void> playScrambleCollapse() async {
    if (!_isSoundOn) return;
    try {
      if (_scrambleCollapse != null) {
        await _soLoud.play(_scrambleCollapse!);
      }
    } catch (_) {}
  }

  Future<void> playScrambleSolve() async {
    if (!_isSoundOn) return;
    try {
      if (_scrambleSolve != null) {
        await _soLoud.play(_scrambleSolve!);
      } else {
        await playFoundSound();
      }
    } catch (_) {}
  }

  Future<void> playScrambleKitty() async {
    if (!_isSoundOn) return;
    try {
      if (_scrambleKitty != null) {
        await _soLoud.play(_scrambleKitty!);
      }
    } catch (_) {}
  }

  Future<void> playScrambleShuffle() async {
    if (!_isSoundOn) return;
    try {
      if (_scrambleShuffle != null) {
        await _soLoud.play(_scrambleShuffle!);
      }
    } catch (_) {}
  }

  Future<void> playScramblePraise() async {
    if (!_isSoundOn) return;
    try {
      if (_scramblePraise != null) {
        await _soLoud.play(_scramblePraise!);
      }
    } catch (_) {}
  }

  // --- Balloon Rescue In-Game Audio Methods ---
  Future<void> playBalloonPop([int noteIndex = 0]) async {
    if (!_isSoundOn) return;
    try {
      if (_balloonPops.isNotEmpty) {
        final idx = noteIndex.clamp(0, _balloonPops.length - 1);
        await _soLoud.play(_balloonPops[idx]);
      } else if (_balloonPopDefault != null) {
        await _soLoud.play(_balloonPopDefault!);
      } else {
        await playButtonSound();
      }
    } catch (_) {}
  }

  Future<void> playBalloonBurst() async {
    if (!_isSoundOn) return;
    try {
      if (_balloonBurst != null) {
        await _soLoud.play(_balloonBurst!);
      } else {
        await playNotFoundSound();
      }
    } catch (_) {}
  }

  Future<void> playBalloonFly() async {
    if (!_isSoundOn) return;
    try {
      if (_balloonFly != null) {
        await _soLoud.play(_balloonFly!);
      }
    } catch (_) {}
  }

  Future<void> playBalloonPraise() async {
    if (!_isSoundOn) return;
    try {
      if (_balloonPraise != null) {
        await _soLoud.play(_balloonPraise!);
      } else {
        await playButtonSound();
      }
    } catch (_) {}
  }

  Future<void> playBalloonTakeoff() async {
    if (!_isSoundOn) return;
    try {
      if (_balloonTakeoff != null) {
        await _soLoud.play(_balloonTakeoff!);
      } else {
        await playWinnerSound();
      }
    } catch (_) {}
  }

  Future<void> playBalloonFall() async {
    if (!_isSoundOn) return;
    try {
      if (_balloonFall != null) {
        await _soLoud.play(_balloonFall!);
      } else {
        await playTimeOutSound();
      }
    } catch (_) {}
  }

  Future<void> playBalloonInflate() async {
    if (!_isSoundOn) return;
    try {
      if (_balloonInflate != null) {
        await _soLoud.play(_balloonInflate!);
      } else {
        await playMoneySound();
      }
    } catch (_) {}
  }

  Future<void> playBalloonDanger() async {
    if (!_isSoundOn) return;
    try {
      if (_balloonDanger != null) {
        await _soLoud.play(_balloonDanger!);
      }
    } catch (_) {}
  }

  Future<void> playBalloonWrong() async {
    if (!_isSoundOn) return;
    try {
      if (_balloonWrong != null) {
        await _soLoud.play(_balloonWrong!);
      }
    } catch (_) {}
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
    if (!_isSoundOn || _balloonScared == null) return;
    await stopCharacterVoice();
    try {
      _characterVocalHandle = await _soLoud.play(_balloonScared!, volume: 0.75);
    } catch (_) {}
  }

  Future<void> startBalloonHoldScared() => playBalloonScared();
  Future<void> stopBalloonHoldScared() => stopCharacterVoice();

  /// When finger is released without panic: cute short baby relief giggle
  Future<void> playBalloonRelief() async {
    if (!_isSoundOn || _balloonGiggle == null) return;
    await stopCharacterVoice();
    try {
      _characterVocalHandle = await _soLoud.play(_balloonGiggle!, volume: 0.85);
    } catch (_) {}
  }

  /// When 1 letter is correct in Balloon Rescue: short, sweet baby happy "Yay!"
  Future<void> playBalloonLetterHappy() async {
    if (!_isSoundOn) return;
    await stopCharacterVoice();
    try {
      if (_balloonLetterHappy != null) {
        _characterVocalHandle =
            await _soLoud.play(_balloonLetterHappy!, volume: 0.85);
      } else if (_balloonGiggle != null) {
        _characterVocalHandle =
            await _soLoud.play(_balloonGiggle!, volume: 0.85);
      }
    } catch (_) {}
  }

  /// Celebratory "Yoo-hoooo!" joyful victory cheer on takeoff
  Future<void> playBalloonWoohoo() async {
    if (!_isSoundOn) return;
    await stopCharacterVoice();
    try {
      if (_balloonTakeoff != null) {
        _characterVocalHandle =
            await _soLoud.play(_balloonTakeoff!, volume: 0.95);
      }
    } catch (_) {}
  }

  // Future<void> playBalloonScared() => startBalloonHoldScared();
  Future<void> playBalloonGiggle() => playBalloonRelief();
}
