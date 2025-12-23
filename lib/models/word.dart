import 'dart:convert';

/// 단어 모델 (HSK 중국어)
class Word {
  final int id;
  final String word; // 중국어 간체자
  final String pinyin; // 병음
  final String definition; // 영어 정의
  final String level; // HSK 레벨 (HSK1-HSK6)
  final String example; // 영어 예문
  final String? exampleZh; // 중국어 예문
  final String? examplePinyin; // 예문 병음
  bool isFavorite;

  // 내장 번역 데이터 (words.json에서 로드)
  final Map<String, Map<String, String>>? translations;

  // 번역된 텍스트 (런타임에 설정됨)
  String? translatedDefinition;
  String? translatedExample;

  Word({
    required this.id,
    required this.word,
    required this.pinyin,
    required this.level,
    required this.definition,
    this.example = '',
    this.exampleZh,
    this.examplePinyin,
    this.isFavorite = false,
    this.translations,
    this.translatedDefinition,
    this.translatedExample,
  });

  /// 내장 번역 가져오기
  String? getEmbeddedTranslation(String langCode, String fieldType) {
    if (translations == null) return null;
    final langData = translations![langCode];
    if (langData == null) return null;
    return langData[fieldType];
  }

  /// JSON에서 생성
  factory Word.fromJson(Map<String, dynamic> json) {
    // translations 파싱
    Map<String, Map<String, String>>? translations = {};

    // 다국어 번역 필드 처리
    final langCodes = ['ko', 'ja', 'es', 'vi'];
    for (final lang in langCodes) {
      String? def;
      String? ex;

      // 직접 필드 (korean, japanese 등)
      if (lang == 'ko' && json['korean'] != null) {
        def = json['korean']?.toString();
      } else if (lang == 'ja' && json['japanese'] != null) {
        def = json['japanese']?.toString();
      } else if (lang == 'es' && json['spanish'] != null) {
        def = json['spanish']?.toString();
      } else if (lang == 'vi' && json['vietnamese'] != null) {
        def = json['vietnamese']?.toString();
      }

      // 예문 번역 - example_ko, example_ja, example_es, example_vi
      final exKey = 'example_$lang';
      if (json[exKey] != null && json[exKey].toString().isNotEmpty) {
        ex = json[exKey].toString();
      }

      // 번역 데이터가 있으면 저장
      if ((def != null && def.isNotEmpty) || (ex != null && ex.isNotEmpty)) {
        translations[lang] = {'definition': def ?? '', 'example': ex ?? ''};
      }
    }

    return Word(
      id: json['id'] ?? 0,
      word: json['word'] ?? '',
      pinyin: json['pinyin'] ?? '',
      level: json['level'] ?? 'HSK1',
      definition: json['definition'] ?? '',
      example: json['example_en'] ?? json['example'] ?? '',
      exampleZh: json['example_zh'],
      examplePinyin: json['example_pinyin'],
      isFavorite: json['is_favorite'] == 1 || json['isFavorite'] == true,
      translations: translations.isNotEmpty ? translations : null,
    );
  }

  /// DB에서 생성
  factory Word.fromDb(Map<String, dynamic> json) {
    Map<String, Map<String, String>>? translations;
    if (json['translations'] != null && json['translations'] is String) {
      try {
        final decoded = jsonDecode(json['translations'] as String);
        if (decoded is Map<String, dynamic>) {
          translations = {};
          decoded.forEach((langCode, data) {
            if (data is Map<String, dynamic>) {
              translations![langCode] = {
                'definition': data['definition']?.toString() ?? '',
                'example': data['example']?.toString() ?? '',
              };
            }
          });
        }
      } catch (e) {
        print('Error parsing translations JSON: $e');
      }
    }

    return Word(
      id: json['id'] as int,
      word: json['word'] as String,
      pinyin: json['pinyin'] as String? ?? '',
      level: json['level'] as String? ?? 'HSK1',
      definition: json['definition'] as String,
      example: json['example'] as String? ?? '',
      exampleZh: json['example_zh'] as String?,
      examplePinyin: json['example_pinyin'] as String?,
      isFavorite: (json['isFavorite'] as int?) == 1,
      translations: translations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'pinyin': pinyin,
      'level': level,
      'definition': definition,
      'example': example,
      'example_zh': exampleZh,
      'example_pinyin': examplePinyin,
      'isFavorite': isFavorite ? 1 : 0,
      'translations': translations,
    };
  }

  /// 번역된 정의 가져오기
  String getDefinition(bool useTranslation) {
    if (useTranslation &&
        translatedDefinition != null &&
        translatedDefinition!.isNotEmpty) {
      return translatedDefinition!;
    }
    return definition;
  }

  /// 번역된 예문 가져오기
  String getExample(bool useTranslation) {
    if (useTranslation &&
        translatedExample != null &&
        translatedExample!.isNotEmpty) {
      return translatedExample!;
    }
    return example;
  }

  /// 단어 표시 (중국어 + 병음)
  String getDisplayWord({String displayMode = 'parentheses'}) {
    if (pinyin.isNotEmpty) {
      if (displayMode == 'bracket') {
        return '$word [$pinyin]';
      } else {
        return '$word ($pinyin)';
      }
    }
    return word;
  }

  Word copyWith({
    int? id,
    String? word,
    String? pinyin,
    String? level,
    String? definition,
    String? example,
    String? exampleZh,
    String? examplePinyin,
    bool? isFavorite,
    Map<String, Map<String, String>>? translations,
    String? translatedDefinition,
    String? translatedExample,
  }) {
    return Word(
      id: id ?? this.id,
      word: word ?? this.word,
      pinyin: pinyin ?? this.pinyin,
      level: level ?? this.level,
      definition: definition ?? this.definition,
      example: example ?? this.example,
      exampleZh: exampleZh ?? this.exampleZh,
      examplePinyin: examplePinyin ?? this.examplePinyin,
      isFavorite: isFavorite ?? this.isFavorite,
      translations: translations ?? this.translations,
      translatedDefinition: translatedDefinition ?? this.translatedDefinition,
      translatedExample: translatedExample ?? this.translatedExample,
    );
  }
}

/// HSK 레벨 정보
class HskLevel {
  final String id; // HSK1, HSK2, etc.
  final String name;
  final int number; // 1, 2, 3, 4, 5, 6
  final String color;

  const HskLevel({
    required this.id,
    required this.name,
    required this.number,
    required this.color,
  });

  static const List<HskLevel> all = [
    HskLevel(id: 'HSK1', name: 'HSK 1', number: 1, color: '#4CAF50'),
    HskLevel(id: 'HSK2', name: 'HSK 2', number: 2, color: '#2196F3'),
    HskLevel(id: 'HSK3', name: 'HSK 3', number: 3, color: '#FF9800'),
    HskLevel(id: 'HSK4', name: 'HSK 4', number: 4, color: '#F44336'),
    HskLevel(id: 'HSK5', name: 'HSK 5', number: 5, color: '#9C27B0'),
    HskLevel(id: 'HSK6', name: 'HSK 6', number: 6, color: '#795548'),
  ];

  static HskLevel fromString(String levelStr) {
    return all.firstWhere(
      (level) => level.id == levelStr,
      orElse: () => all[0],
    );
  }
}

/// HSK 레벨 카테고리 (JSON 파일에서 로드)
class Level {
  final String id;
  final String nameEn;
  final String nameKo;
  final String nameZh;
  final String nameVi;
  final String? descriptionEn;
  final String? descriptionKo;
  final String? descriptionZh;
  final String? descriptionVi;
  final String color;
  final int? wordCount;

  Level({
    required this.id,
    required this.nameEn,
    required this.nameKo,
    required this.nameZh,
    required this.nameVi,
    this.descriptionEn,
    this.descriptionKo,
    this.descriptionZh,
    this.descriptionVi,
    required this.color,
    this.wordCount,
  });

  factory Level.fromJson(Map<String, dynamic> json) {
    return Level(
      id: json['id'] as String,
      nameEn: json['name_en'] as String,
      nameKo: json['name_ko'] as String,
      nameZh: json['name_zh'] as String,
      nameVi: json['name_vi'] as String,
      descriptionEn: json['description_en'] as String?,
      descriptionKo: json['description_ko'] as String?,
      descriptionZh: json['description_zh'] as String?,
      descriptionVi: json['description_vi'] as String?,
      color: json['color'] as String,
      wordCount: json['word_count'] as int?,
    );
  }

  String getName(String languageCode) {
    switch (languageCode) {
      case 'ko':
        return nameKo;
      case 'zh':
        return nameZh;
      case 'vi':
        return nameVi;
      default:
        return nameEn;
    }
  }

  String? getDescription(String languageCode) {
    switch (languageCode) {
      case 'ko':
        return descriptionKo;
      case 'zh':
        return descriptionZh;
      case 'vi':
        return descriptionVi;
      default:
        return descriptionEn;
    }
  }
}
