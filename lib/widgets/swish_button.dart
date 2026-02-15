import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/birthday.dart';
import 'swish_logo.dart';

/// Swish button that simply opens the Swish app on tap.
/// Only shown for Swedish users on mobile platforms.
class SwishButton extends StatelessWidget {
  final Birthday birthday;

  static const _swishGreen = Color(0xFF67B444);

  const SwishButton({super.key, required this.birthday});

  static bool _isSwedishLocale() {
    try {
      final locale = PlatformDispatcher.instance.locale;
      return locale.languageCode == 'sv' || locale.countryCode == 'SE';
    } catch (_) {
      return false;
    }
  }

  static bool _isMobilePlatform() {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS || Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSwedishLocale() || !_isMobilePlatform()) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _openSwishApp(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        _swishGreen.withValues(alpha: 0.15),
                        _swishGreen.withValues(alpha: 0.05),
                      ]
                    : [
                        _swishGreen.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.7),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _swishGreen.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const SwishLogo(size: 48, borderRadius: 14),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Swisha en present',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\u00d6ppna Swish',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSwishApp(BuildContext context) async {
    final swishUri = Uri.parse('swish://');

    try {
      final launched = await launchUrl(
        swishUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        if (!context.mounted) return;
        _showSwishNotInstalledDialog(context);
      }
    } catch (e) {
      if (!context.mounted) return;
      _showSwishNotInstalledDialog(context);
    }
  }

  void _showSwishNotInstalledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: _swishGreen),
            SizedBox(width: 10),
            Text('Swish saknas'),
          ],
        ),
        content: const Text(
          'Swish-appen verkar inte vara installerad p\u00e5 din enhet. '
          'Ladda ner Swish fr\u00e5n App Store eller Google Play f\u00f6r att '
          'kunna skicka betalningar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openAppStore();
            },
            style: FilledButton.styleFrom(backgroundColor: _swishGreen),
            child: const Text('Ladda ner Swish'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAppStore() async {
    Uri storeUrl;
    if (Platform.isIOS) {
      storeUrl = Uri.parse('https://apps.apple.com/se/app/swish/id563204724');
    } else {
      storeUrl = Uri.parse('https://play.google.com/store/apps/details?id=se.bankgirot.swish');
    }
    await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
  }
}
