import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../db/database_helper.dart';
import '../models/word.dart';
import '../services/translation_service.dart';
import '../services/tts_service.dart';

class WordDetailScreen extends StatefulWidget {
  final Word word;

  const WordDetailScreen({super.key, required this.word});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  late Word _word;
  String? _translatedDefinition;
  String? _translatedExample;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _word = widget.word;
    _loadTranslations();
  }

  Future<void> _loadTranslations() async {
    final translationService = TranslationService.instance;
    await translationService.init();

    if (translationService.needsTranslation) {
      final langCode = translationService.currentLanguage;
      final embeddedDef = _word.getEmbeddedTranslation(langCode, 'definition');
      final embeddedEx = _word.getEmbeddedTranslation(langCode, 'example');

      if (mounted) {
        setState(() {
          _translatedDefinition = embeddedDef;
          _translatedExample = embeddedEx;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    await DatabaseHelper.instance.toggleFavorite(_word.id, !_word.isFavorite);
    setState(() {
      _word = _word.copyWith(isFavorite: !_word.isFavorite);
    });

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _word.isFavorite ? l10n.addedToFavorites : l10n.removedFromFavorites,
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _speakWord() async {
    if (_isSpeaking) {
      await TtsService.instance.stop();
      setState(() {
        _isSpeaking = false;
      });
    } else {
      setState(() {
        _isSpeaking = true;
      });
      await TtsService.instance.speak(_word.word);
      // 말하기가 끝나면 상태 업데이트
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }

  Future<void> _speakExample() async {
    if (_word.exampleZh != null && _word.exampleZh!.isNotEmpty) {
      await TtsService.instance.speak(_word.exampleZh!);
    }
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.wordDetail),
        actions: [
          IconButton(
            icon: Icon(
              _word.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _word.isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word Card
            Card(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _word.word,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(
                            _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                            color: theme.colorScheme.onPrimary,
                            size: 32,
                          ),
                          onPressed: _speakWord,
                        ),
                      ],
                    ),
                    if (_word.pinyin.isNotEmpty)
                      Text(
                        _word.pinyin,
                        style: TextStyle(
                          fontSize: 24,
                          color: theme.colorScheme.onPrimary.withOpacity(0.9),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _word.level,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Definition
            Text(
              l10n.definition,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _word.definition,
                      style: const TextStyle(fontSize: 18),
                    ),
                    if (_translatedDefinition != null &&
                        _translatedDefinition!.isNotEmpty) ...[
                      const Divider(height: 24),
                      Text(
                        _translatedDefinition!,
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Chinese Example
            if (_word.exampleZh != null && _word.exampleZh!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    l10n.example,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.volume_up_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    onPressed: _speakExample,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _word.exampleZh!,
                        style: const TextStyle(fontSize: 18),
                      ),
                      if (_word.examplePinyin != null &&
                          _word.examplePinyin!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _word.examplePinyin!,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                      if (_word.example.isNotEmpty) ...[
                        const Divider(height: 24),
                        Text(
                          _word.example,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                      if (_translatedExample != null &&
                          _translatedExample!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _translatedExample!,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
