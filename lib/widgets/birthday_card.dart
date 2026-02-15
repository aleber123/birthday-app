import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/birthday.dart';
import '../utils/app_theme.dart';
import 'birthday_avatar.dart';
import 'glass_card.dart';

class BirthdayCard extends StatelessWidget {
  final Birthday birthday;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const BirthdayCard({
    super.key,
    required this.birthday,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = birthday.isBirthdayToday;
    final daysUntil = birthday.daysUntilBirthday;
    final color = AppTheme.getAvatarColor(birthday.avatarColor, birthday.name);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      onTap: onTap,
      onLongPress: onLongPress,
      borderColor: isToday ? color.withValues(alpha: 0.4) : null,
      gradient: isToday
          ? LinearGradient(
              colors: isDark
                  ? [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)]
                  : [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          BirthdayAvatar(birthday: birthday, size: 52, showEmoji: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        birthday.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isToday ? color : null,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (birthday.isMilestone) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${birthday.turningAge}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      DateFormat('d MMM', 'sv').format(birthday.date),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      '${birthday.age} år',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      birthday.zodiacEmoji,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildCountdown(context, daysUntil, isToday, color, isDark),
        ],
      ),
    );
  }

  Widget _buildCountdown(BuildContext context, int days, bool isToday, Color color, bool isDark) {
    if (isToday) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.8)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Text(
          '🎉 Idag!',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      );
    }

    final isUrgent = days <= 7;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isUrgent
            ? AppTheme.secondaryColor.withValues(alpha: isDark ? 0.15 : 0.08)
            : AppTheme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$days',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isUrgent ? AppTheme.secondaryColor : AppTheme.primaryColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            days == 1 ? 'dag' : 'dagar',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isUrgent
                  ? AppTheme.secondaryColor.withValues(alpha: 0.7)
                  : AppTheme.primaryColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
