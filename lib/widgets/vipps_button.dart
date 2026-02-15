import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/birthday.dart';
import 'vipps_logo.dart';

/// Vipps button widget that opens the Vipps app for payments.
///
/// Vipps is Norway's equivalent of Sweden's Swish – a mobile payment app
/// used by ~4.4 million Norwegians. The deep link scheme is `vipps://`
/// per the official Vipps MobilePay developer docs.
///
/// Like the Swish integration, this is a consumer app without a merchant
/// backend, so we open the Vipps app directly and let the user complete
/// the payment manually with pre-copied details.
///
/// This widget is ONLY shown for Norwegian users (locale check) on mobile
/// platforms (iOS/Android) where the Vipps app can be installed.
class VippsButton extends StatelessWidget {
  final Birthday birthday;

  // Vipps brand colors
  static const _vippsOrange = Color(0xFFFF5B24);
  static const _vippsOrangeDark = Color(0xFFE04A15);

  const VippsButton({super.key, required this.birthday});

  /// Check if the current user is Norwegian based on device locale.
  static bool _isNorwegianLocale() {
    try {
      final locale = PlatformDispatcher.instance.locale;
      return locale.languageCode == 'nb' ||
          locale.languageCode == 'nn' ||
          locale.languageCode == 'no' ||
          locale.countryCode == 'NO';
    } catch (_) {
      return false;
    }
  }

  /// Check if we're running on a mobile platform where Vipps can be installed.
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
    // Only show for Norwegian users on mobile with a phone number
    if (!_isNorwegianLocale() || !_isMobilePlatform()) {
      return const SizedBox.shrink();
    }
    if (birthday.phone == null || birthday.phone!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showVippsDialog(context),
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
                        _vippsOrange.withValues(alpha: 0.15),
                        _vippsOrange.withValues(alpha: 0.05),
                      ]
                    : [
                        _vippsOrange.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.7),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _vippsOrange.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Vipps logo
                const VippsLogo(size: 48, borderRadius: 14),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Send med Vipps',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Send penger til ${birthday.name}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _vippsOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Vipps',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Format phone number for display: Norwegian format
  String _formatPhoneNumber(String phone) {
    String clean = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (clean.startsWith('+47')) {
      clean = clean.substring(3);
    } else if (clean.startsWith('47') && clean.length > 8) {
      clean = clean.substring(2);
    }
    // Format as XX XX XX XX (Norwegian standard)
    if (clean.length == 8) {
      return '${clean.substring(0, 2)} ${clean.substring(2, 4)} ${clean.substring(4, 6)} ${clean.substring(6, 8)}';
    }
    return clean;
  }

  /// Raw phone number without formatting
  String _rawPhoneNumber(String phone) {
    String clean = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (clean.startsWith('+47')) {
      clean = clean.substring(3);
    } else if (clean.startsWith('47') && clean.length > 8) {
      clean = clean.substring(2);
    }
    return clean;
  }

  void _showVippsDialog(BuildContext context) {
    final amountController = TextEditingController(text: '200');
    final messageController = TextEditingController(
      text: 'Gratulerer med ${birthday.turningAge}-\u00e5rsdagen!',
    );
    final formattedPhone = _formatPhoneNumber(birthday.phone!);
    final rawPhone = _rawPhoneNumber(birthday.phone!);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Vipps logo
            const VippsLogo(size: 60, borderRadius: 18),
            const SizedBox(height: 16),

            Text(
              'Vipps til ${birthday.name}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),

            // Tappable phone number row with copy
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: rawPhone));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Telefonnummer kopiert: $formattedPhone'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedPhone,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.copy_rounded,
                      size: 14, color: Colors.grey.shade400),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Amount field
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Bel\u00f8p (kr)',
                labelStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
                suffixText: 'kr',
                suffixStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _vippsOrange,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Quick amount buttons
            Row(
              children: [100, 200, 500].map((amount) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: OutlinedButton(
                      onPressed: () => amountController.text = '$amount',
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _vippsOrange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        '$amount kr',
                        style: const TextStyle(
                          color: _vippsOrange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Message field
            TextField(
              controller: messageController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Melding',
                labelStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _vippsOrange,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Open Vipps button
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_vippsOrange, _vippsOrangeDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _vippsOrange.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  onPressed: () {
                    // Copy details to clipboard for easy pasting in Vipps
                    final details = 'Nummer: $rawPhone\n'
                        'Bel\u00f8p: ${amountController.text} kr\n'
                        'Melding: ${messageController.text}';
                    Clipboard.setData(ClipboardData(text: details));

                    Navigator.pop(ctx);
                    _openVippsApp(context, rawPhone);
                  },
                  icon:
                      const Text('\ud83d\udcb8', style: TextStyle(fontSize: 18)),
                  label: const Text(
                    '\u00c5pne Vipps',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Betalingsdetaljene kopieres til utklippstavlen',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// Opens the Vipps app using the official vipps:// URL scheme.
  ///
  /// Per Vipps MobilePay developer docs, the deep link scheme is `vipps://`.
  /// Since this is a consumer app without a merchant backend, we open the
  /// Vipps app directly. The user's payment details are copied to clipboard
  /// so they can easily enter them in the Vipps app.
  Future<void> _openVippsApp(
    BuildContext context,
    String phoneNumber,
  ) async {
    final vippsUri = Uri.parse('vipps://');

    try {
      final launched = await launchUrl(
        vippsUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        if (!context.mounted) return;
        _showVippsNotInstalledDialog(context);
      }
    } catch (e) {
      if (!context.mounted) return;
      _showVippsNotInstalledDialog(context);
    }
  }

  /// Shows a dialog when Vipps is not installed, with links to app stores.
  void _showVippsNotInstalledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: _vippsOrange),
            SizedBox(width: 10),
            Text('Vipps mangler'),
          ],
        ),
        content: const Text(
          'Vipps-appen ser ikke ut til \u00e5 v\u00e6re installert p\u00e5 enheten din. '
          'Last ned Vipps fra App Store eller Google Play for \u00e5 '
          'kunne sende betalinger.',
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
            style: FilledButton.styleFrom(backgroundColor: _vippsOrange),
            child: const Text('Last ned Vipps'),
          ),
        ],
      ),
    );
  }

  /// Opens the appropriate app store for downloading Vipps.
  Future<void> _openAppStore() async {
    Uri storeUrl;
    if (Platform.isIOS) {
      storeUrl =
          Uri.parse('https://apps.apple.com/us/app/vipps/id984380185');
    } else {
      storeUrl = Uri.parse(
          'https://play.google.com/store/apps/details?id=no.dnb.vipps');
    }
    await launchUrl(storeUrl, mode: LaunchMode.externalApplication);
  }
}
