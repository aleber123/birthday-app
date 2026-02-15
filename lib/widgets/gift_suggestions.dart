import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/birthday.dart';
import '../services/gift_service.dart';
import '../l10n/app_localizations.dart';

class GiftSuggestions extends StatelessWidget {
  final Birthday birthday;

  const GiftSuggestions({super.key, required this.birthday});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final age = birthday.turningAge;
    final categories = GiftService.getCategorySuggestions(age, birthday.relationType);
    final ageGroup = GiftService.getAgeGroupLabel(age, lang);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Text('\ud83c\udf81', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.giftIdeas,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '$ageGroup \u2022 ${AppLocalizations.of(context).get(birthday.relationTypeLabelKey)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Category grid – 2 columns
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return _CategoryCard(
              category: cat,
              lang: lang,
              isDark: isDark,
            );
          },
        ),
        const SizedBox(height: 8),

        // "Search more" link
        Center(
          child: TextButton.icon(
            onPressed: () async {
              final url = GiftService.getSearchUrl(
                'present ${ageGroup.toLowerCase()}',
                lang,
              );
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: Icon(Icons.search_rounded, size: 18, color: Colors.grey.shade500),
            label: Text(
              'S\u00f6k fler presenter p\u00e5 Amazon',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final GiftCategory category;
  final String lang;
  final bool isDark;

  const _CategoryCard({
    required this.category,
    required this.lang,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openAmazonSearch(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        category.color.withValues(alpha: 0.14),
                        category.color.withValues(alpha: 0.04),
                      ]
                    : [
                        category.color.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.75),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: category.color.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(category.emoji, style: const TextStyle(fontSize: 24)),
                    const Spacer(),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 14,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  category.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAmazonSearch(BuildContext context) async {
    final url = GiftService.getSearchUrl(category.searchQuery, lang);
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Silently fail
    }
  }
}
