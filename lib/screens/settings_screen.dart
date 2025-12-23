import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import '../main.dart';
import '../services/translation_service.dart';
import '../services/purchase_service.dart';
import '../services/ad_service.dart';
import '../services/tts_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _adsRemoved = false;
  bool _isRestoring = false;
  double _speechRate = 0.5;
  double _volume = 1.0;
  bool _isMaleVoice = false; // 여자 음성만 사용

  @override
  void initState() {
    super.initState();
    _checkAdsStatus();
    _loadTtsSettings();
  }

  Future<void> _loadTtsSettings() async {
    await TtsService.instance.init();
    setState(() {
      _speechRate = TtsService.instance.speechRate;
      _volume = TtsService.instance.volume;
      _isMaleVoice = TtsService.instance.isMaleVoice;
    });
  }

  Future<void> _checkAdsStatus() async {
    setState(() {
      _adsRemoved = AdService.instance.adsRemoved;
    });
  }

  Future<void> _restorePurchase() async {
    setState(() => _isRestoring = true);

    final purchaseService = PurchaseService.instance;
    await purchaseService.restorePurchases();

    // Wait for restore to complete
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isRestoring = false;
      _adsRemoved = AdService.instance.adsRemoved;
    });

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _adsRemoved ? l10n.restoreComplete : l10n.noPurchaseFound,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          // TTS Settings Section
          _buildSectionHeader(l10n.voiceSettings),
          ListTile(
            leading: const Icon(Icons.speed),
            title: Text(l10n.speechSpeed),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${(_speechRate * 100).toInt()}%'),
                Slider(
                  value: _speechRate,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: '${(_speechRate * 100).toInt()}%',
                  onChanged: (value) async {
                    setState(() => _speechRate = value);
                    await TtsService.instance.setSpeechRate(value);
                  },
                ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.volume_up),
            title: Text(l10n.volume),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${(_volume * 100).toInt()}%'),
                Slider(
                  value: _volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: '${(_volume * 100).toInt()}%',
                  onChanged: (value) async {
                    setState(() => _volume = value);
                    await TtsService.instance.setVolume(value);
                  },
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: Text(l10n.testVoice),
            subtitle: Text(l10n.testVoiceDesc),
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.volume_up, size: 16),
              label: Text(l10n.playButton),
              onPressed: () async {
                await TtsService.instance.speak('你好');
              },
            ),
          ),

          const Divider(),
          // Language Section
          _buildSectionHeader(l10n.language),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.displayLanguage),
            subtitle: Text(
              TranslationService.instance.currentLanguageInfo.nativeName,
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageDialog(),
          ),

          const Divider(),

          // Ads Section (웹에서는 숨김)
          if (!kIsWeb) ...[
            _buildSectionHeader(l10n.removeAds),
            if (_adsRemoved)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(l10n.adsRemoved),
                subtitle: Text(l10n.thankYou),
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.block),
                title: Text(l10n.removeAds),
                subtitle: const Text('\$1.99'),
                trailing: ElevatedButton(
                  onPressed: () => _purchaseAdRemoval(),
                  child: Text(l10n.buy),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: Text(l10n.restorePurchase),
                subtitle: Text(l10n.restorePurchaseDesc),
                trailing:
                    _isRestoring
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : null,
                onTap: _isRestoring ? null : _restorePurchase,
              ),
            ],
            const Divider(),
          ],

          // Info Section
          _buildSectionHeader(l10n.info),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.version),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacyPolicy),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showPrivacyPolicy(),
          ),
          ListTile(
            leading: const Icon(Icons.warning_outlined),
            title: Text(l10n.disclaimer),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showDisclaimer(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context)!;
    final currentLang = TranslationService.instance.currentLanguage;

    // 중국어 간체 제거 - 영어, 한국어, 베트남어, 스페인어만 지원
    final supportedLangs =
        TranslationService.supportedLanguages
            .where((lang) => lang.code != 'zh')
            .toList();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.selectLanguage),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  supportedLangs.map((lang) {
                    return RadioListTile<String>(
                      title: Text(lang.nativeName),
                      subtitle: Text(lang.name),
                      value: lang.code,
                      groupValue: currentLang,
                      onChanged: (value) async {
                        if (value != null) {
                          await TranslationService.instance.setLanguage(value);
                          MyApp.setLocale(context, Locale(value));
                          Navigator.pop(context);
                          setState(() {});
                        }
                      },
                    );
                  }).toList(),
            ),
          ),
    );
  }

  Future<void> _purchaseAdRemoval() async {
    final purchaseService = PurchaseService.instance;
    final success = await purchaseService.buyRemoveAds();
    if (success) {
      _checkAdsStatus();
    }
  }

  void _showPrivacyPolicy() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.privacyPolicy),
            content: SingleChildScrollView(
              child: Text(l10n.privacyPolicyContent),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showDisclaimer() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.disclaimer),
            content: SingleChildScrollView(child: Text(l10n.disclaimerText)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
