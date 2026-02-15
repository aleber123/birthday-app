import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/birthday.dart';
import '../utils/app_theme.dart';

class BirthdayAvatar extends StatelessWidget {
  final Birthday birthday;
  final double size;
  final bool showEmoji;

  const BirthdayAvatar({
    super.key,
    required this.birthday,
    this.size = 52,
    this.showEmoji = false,
  });

  bool get _hasImage {
    if (kIsWeb) return false;
    final path = birthday.imagePath;
    if (path == null || path.isEmpty) return false;
    return File(path).existsSync();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getAvatarColor(birthday.avatarColor, birthday.name);
    final initials = _getInitials(birthday.name);

    if (_hasImage) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          image: DecorationImage(
            image: FileImage(File(birthday.imagePath!)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: showEmoji && birthday.isBirthdayToday
            ? Text('🎂', style: TextStyle(fontSize: size * 0.4))
            : Text(
                initials,
                style: TextStyle(
                  color: color,
                  fontSize: size * 0.32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
