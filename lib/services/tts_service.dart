import 'package:flutter_tts/flutter_tts.dart';

/// TTS 서비스 (중국어 음성 지원)
class TtsService {
  static final TtsService instance = TtsService._internal();
  
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  /// TTS 초기화
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 중국어 간체 설정
      await _flutterTts.setLanguage("zh-CN");
      
      // 음성 톤 (1.0이 기본)
      await _flutterTts.setPitch(1.0);
      
      // 말하기 속도 (0.5 = 느리게, 1.0 = 보통)
      await _flutterTts.setSpeechRate(0.5);
      
      // 볼륨 (0.0 ~ 1.0)
      await _flutterTts.setVolume(1.0);

      // iOS 설정
      await _flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );

      _isInitialized = true;
    } catch (e) {
      print('TTS initialization error: $e');
    }
  }

  /// 중국어 텍스트 읽기
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('TTS speak error: $e');
    }
  }

  /// 읽기 중지
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('TTS stop error: $e');
    }
  }

  /// 읽기 일시정지
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      print('TTS pause error: $e');
    }
  }

  /// 말하기 속도 설정 (0.0 ~ 1.0)
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      print('TTS set speech rate error: $e');
    }
  }

  /// 음성 톤 설정 (0.5 ~ 2.0)
  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch);
    } catch (e) {
      print('TTS set pitch error: $e');
    }
  }

  /// 사용 가능한 언어 목록 가져오기
  Future<List<dynamic>> getLanguages() async {
    try {
      return await _flutterTts.getLanguages;
    } catch (e) {
      print('TTS get languages error: $e');
      return [];
    }
  }

  /// 사용 가능한 음성 목록 가져오기
  Future<List<dynamic>> getVoices() async {
    try {
      return await _flutterTts.getVoices;
    } catch (e) {
      print('TTS get voices error: $e');
      return [];
    }
  }

  /// TTS가 현재 말하고 있는지 확인
  Future<bool> isSpeaking() async {
    try {
      final result = await _flutterTts.awaitSpeakCompletion(true);
      return result == 1;
    } catch (e) {
      return false;
    }
  }

  /// 리소스 정리
  void dispose() {
    _flutterTts.stop();
  }
}
