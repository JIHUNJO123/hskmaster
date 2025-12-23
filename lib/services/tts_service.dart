import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TTS 서비스 (중국어 음성 지원)
class TtsService {
  static final TtsService instance = TtsService._internal();

  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  // 기본 설정
  double _speechRate = 0.5; // 0.0 ~ 1.0 (느림 ~ 빠름), 실제 적용은 0.0 ~ 0.5
  double _volume = 1.0; // 0.0 ~ 1.0 (소리 크기)
  bool _isMaleVoice = false; // 여자 음성만 사용

  // Getters
  double get speechRate => _speechRate;
  double get volume => _volume;
  bool get isMaleVoice => _isMaleVoice;

  /// TTS 초기화
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 저장된 설정 로드
      await _loadSettings();

      // 중국어 간체 설정
      await _flutterTts.setLanguage("zh-CN");

      // 저장된 설정 적용 (속도는 0.5배로 적용하여 너무 빠르지 않게)
      await _flutterTts.setSpeechRate(_speechRate * 0.5);
      await _flutterTts.setVolume(_volume);

      // 음성 성별 적용
      await _applyVoiceGender();

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

  /// 저장된 설정 로드
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _speechRate = prefs.getDouble('tts_speech_rate') ?? 0.5;
      _volume = prefs.getDouble('tts_volume') ?? 1.0;
      _isMaleVoice = prefs.getBool('tts_is_male_voice') ?? true;
    } catch (e) {
      print('TTS load settings error: $e');
    }
  }

  /// 설정 저장
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('tts_speech_rate', _speechRate);
      await prefs.setDouble('tts_volume', _volume);
      await prefs.setBool('tts_is_male_voice', _isMaleVoice);
    } catch (e) {
      print('TTS save settings error: $e');
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

  /// 말하기 속도 설정 (0.0 ~ 1.0, 실제 적용은 0.0 ~ 0.5)
  Future<void> setSpeechRate(double rate) async {
    try {
      _speechRate = rate.clamp(0.0, 1.0);
      await _flutterTts.setSpeechRate(_speechRate * 0.5); // 0.5배로 적용
      await _saveSettings();
    } catch (e) {
      print('TTS set speech rate error: $e');
    }
  }

  /// 음성 성별 설정 (true: 남자, false: 여자)
  Future<void> setVoiceGender(bool isMale) async {
    try {
      _isMaleVoice = isMale;
      await _applyVoiceGender();
      await _saveSettings();
    } catch (e) {
      print('TTS set voice gender error: $e');
    }
  }

  /// 음성 성별 적용 (중국어 음성 선택)
  Future<void> _applyVoiceGender() async {
    try {
      // 먼저 pitch로 성별 차이 적용 (가장 확실한 방법)
      // 남자: 낮은 pitch (0.8), 여자: 높은 pitch (1.2)
      final pitch = _isMaleVoice ? 0.8 : 1.2;
      await _flutterTts.setPitch(pitch);
      print('Applied pitch: $pitch for ${_isMaleVoice ? "male" : "female"} voice');

      // 추가로 음성 선택 시도
      final voices = await _flutterTts.getVoices;
      if (voices == null) {
        print('No voices available');
        return;
      }

      // 디버그: 모든 음성 출력
      print('Available voices:');
      for (var voice in (voices as List)) {
        print('  - ${voice['name']} (${voice['locale']}) gender: ${voice['gender']}');
      }

      // 중국어 음성 필터링
      final chineseVoices = (voices as List).where((voice) {
        final locale = voice['locale']?.toString().toLowerCase() ?? '';
        final name = voice['name']?.toString().toLowerCase() ?? '';
        return locale.contains('zh') || 
               locale.contains('cmn') || 
               name.contains('chinese') ||
               name.contains('mandarin');
      }).toList();

      print('Chinese voices found: ${chineseVoices.length}');
      for (var voice in chineseVoices) {
        print('  - ${voice['name']} (${voice['locale']}) gender: ${voice['gender']}');
      }

      if (chineseVoices.isEmpty) {
        print('No Chinese voices found, using pitch only');
        return;
      }

      // 남자/여자 음성 찾기
      Map<String, dynamic>? selectedVoice;
      
      for (var voice in chineseVoices) {
        final name = voice['name']?.toString().toLowerCase() ?? '';
        final gender = voice['gender']?.toString().toLowerCase() ?? '';
        
        // 성별로 필터링
        if (_isMaleVoice) {
          if (gender == 'male' || name.contains('male') || 
              name.contains('yunxi') || name.contains('yunyang') ||
              name.contains('kangkang') || name.contains('yunjian')) {
            selectedVoice = voice;
            print('Found male voice: ${voice['name']}');
            break;
          }
        } else {
          if (gender == 'female' || name.contains('female') || 
              name.contains('xiaoxiao') || name.contains('xiaoyi') ||
              name.contains('yaoyao') || name.contains('huihui')) {
            selectedVoice = voice;
            print('Found female voice: ${voice['name']}');
            break;
          }
        }
      }

      // 성별에 맞는 음성이 없으면 첫 번째 중국어 음성 사용
      if (selectedVoice == null && chineseVoices.isNotEmpty) {
        selectedVoice = chineseVoices.first;
        print('Using first Chinese voice: ${selectedVoice?['name']}');
      }

      if (selectedVoice != null) {
        await _flutterTts.setVoice({
          "name": selectedVoice['name'],
          "locale": selectedVoice['locale'],
        });
        
        print('Selected voice: ${selectedVoice['name']}');
      }
    } catch (e) {
      print('TTS apply voice gender error: $e');
    }
  }

  /// 볼륨 설정 (0.0 ~ 1.0)
  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _flutterTts.setVolume(_volume);
      await _saveSettings();
    } catch (e) {
      print('TTS set volume error: $e');
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
