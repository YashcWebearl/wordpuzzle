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

    _button = await _soLoud.loadAsset('assets/music/button.mp3');
    _dragWord = await _soLoud.loadAsset('assets/music/drag_word.mp3');
    _found = await _soLoud.loadAsset('assets/music/found.mp3');
    _notFound = await _soLoud.loadAsset('assets/music/not_found.mp3');
    _screenOpen = await _soLoud.loadAsset('assets/music/screen_open.mp3');
    _winner = await _soLoud.loadAsset('assets/music/winner.mp3');
    _money = await _soLoud.loadAsset('assets/music/Money.mp3');
    _timeOut = await _soLoud.loadAsset('assets/music/time_out.mp3');
    _last5sec = await _soLoud.loadAsset('assets/music/last5sec.mp3');
    _hint = await _soLoud.loadAsset('assets/music/hint.mp3');

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

  Future<void> playButtonSound() async {
    if (_isSoundOn && _button != null) {
      await _soLoud.play(_button!);
    }
  }
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
      _soLoud.fadeVolume(_backgroundHandle!, 0.0, const Duration(milliseconds: 500));
    }
  }

  void dispose() {
    _soLoud.deinit();
  }
}
