import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../l10n/generated/app_localizations.dart';
import '../db/database_helper.dart';
import '../models/word.dart';
import '../services/translation_service.dart';
import '../services/ad_service.dart';
import 'word_list_screen.dart';
import 'word_detail_screen.dart';
import 'favorites_screen.dart';
import 'quiz_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Word? _todayWord;
  String? _translatedDefinition;
  bool _isLoading = true;
  bool _isBannerAdLoaded = false;
  String? _lastLanguage;
  List<Level> _levels = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadBannerAd();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLanguage = TranslationService.instance.currentLanguage;
    if (_lastLanguage != null && _lastLanguage != currentLanguage) {
      _loadData();
    }
    _lastLanguage = currentLanguage;
  }

  Future<void> _loadBannerAd() async {
    final adService = AdService.instance;
    await adService.initialize();

    if (!adService.adsRemoved) {
      await adService.loadBannerAd(
        onLoaded: () {
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = true;
            });
          }
        },
      );
    }
  }

  Future<void> _loadData() async {
    try {
      // Load today's word
      final word = await DatabaseHelper.instance.getTodayWord();

      // Load levels
      final levels = await DatabaseHelper.instance.loadLevels();

      if (word != null) {
        final translationService = TranslationService.instance;
        await translationService.init();

        if (translationService.needsTranslation) {
          final embeddedTranslation = word.getEmbeddedTranslation(
            translationService.currentLanguage,
            'definition',
          );

          if (mounted) {
            setState(() {
              _todayWord = word;
              _translatedDefinition = embeddedTranslation;
              _levels = levels;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _todayWord = word;
              _translatedDefinition = null;
              _levels = levels;
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _todayWord = null;
            _levels = levels;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _todayWord = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    AdService.instance.disposeBannerAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.appTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) => _loadData());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Today's Word Card
                  _buildTodayWordCard(),
                  const SizedBox(height: 24),

                  // Quick Actions
                  Text(
                    l10n.learning,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMenuGrid(),

                  const SizedBox(height: 24),

                  // HSK Levels
                  const Text(
                    'HSK Levels',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildLevelCards(),
                ],
              ),
            ),
          ),
          _buildBannerAd(),
        ],
      ),
    );
  }

  Widget _buildBannerAd() {
    final adService = AdService.instance;

    if (adService.adsRemoved ||
        !_isBannerAdLoaded ||
        adService.bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: adService.bannerAd!.size.width.toDouble(),
      height: adService.bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: adService.bannerAd!),
    );
  }

  Widget _buildTodayWordCard() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isLoading) {
      return Card(
        child: Container(
          height: 150,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    if (_todayWord == null) {
      return Card(
        child: Container(
          height: 150,
          alignment: Alignment.center,
          child: Text(l10n.cannotLoadWords),
        ),
      );
    }

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WordDetailScreen(word: _todayWord!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.todayWord,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onPrimary.withOpacity(0.8),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _todayWord!.word,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              if (_todayWord!.pinyin.isNotEmpty)
                Text(
                  _todayWord!.pinyin,
                  style: TextStyle(
                    fontSize: 18,
                    color: theme.colorScheme.onPrimary.withOpacity(0.9),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                _translatedDefinition ?? _todayWord!.definition,
                style: TextStyle(
                  fontSize: 16,
                  color: theme.colorScheme.onPrimary.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuGrid() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final menuItems = [
      {
        'icon': Icons.list_alt,
        'title': l10n.allWords,
        'subtitle': l10n.viewAllWords,
        'color': Colors.blue,
        'onTap':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WordListScreen()),
            ),
      },
      {
        'icon': Icons.favorite,
        'title': l10n.favorites,
        'subtitle': l10n.savedWords,
        'color': Colors.red,
        'onTap':
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoritesScreen()),
            ),
      },
      {
        'icon': Icons.style,
        'title': l10n.flashcard,
        'subtitle': l10n.cardLearning,
        'color': Colors.orange,
        'onTap': () => _showLevelSelectionDialog(isFlashcard: true),
      },
      {
        'icon': Icons.quiz,
        'title': l10n.quiz,
        'subtitle': l10n.testYourself,
        'color': Colors.green,
        'onTap': () => _showLevelSelectionDialog(isFlashcard: false),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return Card(
          child: InkWell(
            onTap: item['onTap'] as VoidCallback,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      item['title'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      item['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelCards() {
    final langCode = TranslationService.instance.currentLanguage;

    if (_levels.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _levels.length,
      itemBuilder: (context, index) {
        final level = _levels[index];
        final hskLevel = HskLevel.fromString(level.id);
        final levelColor = Color(
          int.parse(level.color.replaceFirst('#', '0xFF')),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: levelColor,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '${hskLevel.number}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            title: Text(
              level.getName(langCode),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(level.getDescription(langCode) ?? ''),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => WordListScreen(
                        level: level.id,
                        levelName: level.getName(langCode),
                      ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showLevelSelectionDialog({required bool isFlashcard}) {
    final l10n = AppLocalizations.of(context)!;
    final langCode = TranslationService.instance.currentLanguage;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(isFlashcard ? l10n.flashcard : l10n.quiz),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  // 전체 단어 옵션
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.all_inclusive,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(l10n.allWords),
                    onTap: () {
                      Navigator.pop(context);
                      if (isFlashcard) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const WordListScreen(isFlashcardMode: true),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QuizScreen(),
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(),
                  // HSK 레벨별 옵션
                  ..._levels.map((level) {
                    final hskLevel = HskLevel.fromString(level.id);
                    final levelColor = Color(
                      int.parse(level.color.replaceFirst('#', '0xFF')),
                    );

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: levelColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${hskLevel.number}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      title: Text(level.getName(langCode)),
                      subtitle: Text(
                        level.getDescription(langCode) ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        if (isFlashcard) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => WordListScreen(
                                    level: level.id,
                                    levelName: level.getName(langCode),
                                    isFlashcardMode: true,
                                  ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => QuizScreen(category: level.id),
                            ),
                          );
                        }
                      },
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
            ],
          ),
    );
  }
}
