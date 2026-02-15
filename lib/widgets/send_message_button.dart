import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../models/birthday.dart';
import '../utils/app_theme.dart';

/// A button that opens the device's SMS/Messages app with the birthday
/// person's phone number pre-filled and an optional greeting message.
///
/// Only shown if the birthday person has a phone number.
class SendMessageButton extends StatelessWidget {
  final Birthday birthday;

  static const _messageBlue = Color(0xFF34C759);

  const SendMessageButton({super.key, required this.birthday});

  @override
  Widget build(BuildContext context) {
    if (birthday.phone == null || birthday.phone!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showMessagePicker(context),
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
                        _messageBlue.withValues(alpha: 0.15),
                        _messageBlue.withValues(alpha: 0.05),
                      ]
                    : [
                        _messageBlue.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.7),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _messageBlue.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _messageBlue,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _messageBlue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.message_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).sendGreeting,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context).openMessages,
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

  void _showMessagePicker(BuildContext context) {
    final name = birthday.name.split(' ').first;
    final age = birthday.turningAge;
    final messages = _getMessages(name, age, birthday.relationType);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).chooseGreeting,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).tapToSendSms,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 16),
              ...messages.map((msg) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _sendSms(context, msg);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      msg,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getMessages(String name, int age, RelationType relation) {
    switch (relation) {
      case RelationType.closeFamily:
        return [
          'Grattis på födelsedagen $name! ❤️🎂🎉',
          'Hurra för dig $name! $age år – så stolt över dig! 🎉👏',
          'Grattis älskade $name! Hoppas dagen blir lika underbar som du! 🎂❤️',
          'Stort grattis på $age-årsdagen $name! 🎂 Kram!',
          '$name!! GRATTIS! 🎂🎉❤️',
        ];
      case RelationType.friend:
        return [
          'Grattis på födelsedagen $name! 🎂🎉 Hoppas du får en grym dag!',
          'Hurra, grattis $name! $age år – det måste firas! 🎉🎂',
          'Grattis $name! 🎂 Vi måste fira snart!',
          'HBD $name! 🎉 $age ser bra ut på dig!',
          'Grattis kompisen! 🎂🎁 Hoppas du får en magisk dag!',
        ];
      case RelationType.colleague:
        return [
          'Grattis på födelsedagen $name! 🎂 Hoppas du får en fin dag!',
          'Stort grattis $name! 🎉 Önskar dig en trevlig födelsedag!',
          'Grattis på dagen $name! 🎂',
          'Hej $name, grattis på födelsedagen! Hoppas den blir bra! 🎂',
        ];
    }
  }

  Future<void> _sendSms(BuildContext context, String message) async {
    final phone = birthday.phone!.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final encoded = Uri.encodeComponent(message);
    final smsUri = Uri.parse('sms:$phone?body=$encoded');

    try {
      await launchUrl(smsUri);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).couldNotOpenMessages),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
