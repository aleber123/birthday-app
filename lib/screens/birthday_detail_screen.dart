import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/birthday.dart';
import '../providers/birthday_provider.dart';
import '../services/premium_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_theme.dart';
import '../widgets/gift_suggestions.dart';
import '../widgets/planning_checklist.dart';
import '../widgets/relation_map.dart';
import '../widgets/send_message_button.dart';
import '../widgets/swish_button.dart';
import '../widgets/vipps_button.dart';
import '../widgets/wishlist_widget.dart';
import 'add_birthday_screen.dart';
import 'paywall_screen.dart';
import '../services/facebook_analytics_service.dart';

class BirthdayDetailScreen extends StatefulWidget {
  final String birthdayId;

  const BirthdayDetailScreen({super.key, required this.birthdayId});

  @override
  State<BirthdayDetailScreen> createState() => _BirthdayDetailScreenState();
}

class _BirthdayDetailScreenState extends State<BirthdayDetailScreen> {
  @override
  void initState() {
    super.initState();
    FacebookAnalyticsService.instance.logViewContent(
      contentType: 'birthday_detail',
      contentId: widget.birthdayId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BirthdayProvider>(
      builder: (context, provider, _) {
        final birthday = provider.allBirthdays
            .where((b) => b.id == widget.birthdayId)
            .firstOrNull;

        if (birthday == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(AppLocalizations.of(context).get('no_birthdays_this_day'))),
          );
        }

        final color = AppTheme.getAvatarColor(birthday.avatarColor, birthday.name);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildHeader(context, birthday, color),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildCountdownCard(context, birthday, color),
                      if (birthday.isMilestone) ...[
                        const SizedBox(height: 12),
                        _buildMilestoneBanner(context, birthday),
                      ],
                      const SizedBox(height: 16),
                      _buildInfoCard(context, birthday),
                      if (birthday.address != null && birthday.address!.isNotEmpty) ...[                        const SizedBox(height: 16),
                        _buildAddressCard(context, birthday),
                      ],
                      if (birthday.notes != null && birthday.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildNotesCard(context, birthday),
                      ],
                      const SizedBox(height: 16),
                      _ExpandableSection(
                        title: AppLocalizations.of(context).planning,
                        icon: Icons.checklist_rounded,
                        badge: '${birthday.planningItems.where((i) => i.isCompleted).length}/${birthday.planningItems.length}',
                        child: PlanningChecklist(birthday: birthday),
                      ),
                      const SizedBox(height: 16),
                      _ExpandableSection(
                        title: AppLocalizations.of(context).wishlist,
                        icon: Icons.card_giftcard_rounded,
                        badge: birthday.wishlistItems.isNotEmpty
                            ? '${birthday.wishlistItems.length}'
                            : null,
                        child: WishlistWidget(birthday: birthday),
                      ),
                      const SizedBox(height: 16),
                      _ExpandableSection(
                        title: AppLocalizations.of(context).relationMap,
                        icon: Icons.hub_outlined,
                        child: RelationMapWidget(
                          birthday: birthday,
                          onPersonTap: (id) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BirthdayDetailScreen(birthdayId: id),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildBigBirthdayCountdown(context, birthday),
                      const SizedBox(height: 16),
                      _ExpandableSection(
                        title: AppLocalizations.of(context).reminders,
                        icon: Icons.notifications_outlined,
                        badge: '${birthday.reminderDaysBefore.length} ${AppLocalizations.of(context).active}',
                        child: _buildRemindersCard(context, birthday),
                      ),
                      const SizedBox(height: 16),
                      SendMessageButton(birthday: birthday),
                      const SizedBox(height: 12),
                      SwishButton(birthday: birthday),
                      VippsButton(birthday: birthday),
                      const SizedBox(height: 24),
                      GiftSuggestions(birthday: birthday),
                      const SizedBox(height: 32),
                      _buildActions(context, provider, birthday),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Birthday birthday, Color color) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _buildHeaderAvatar(birthday),
                const SizedBox(height: 12),
                Text(
                  birthday.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.ios_share, color: Colors.white),
          onPressed: () {
            final premium = context.read<PremiumService>();
            if (!premium.isPremium) {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, a1, a2) => const PaywallScreen(),
                  transitionsBuilder: (_, animation, a3, child) {
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 1),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
              return;
            }
            _shareBirthday(context, birthday);
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddBirthdayScreen(editBirthday: birthday),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeaderAvatar(Birthday birthday) {
    final hasImage = !kIsWeb &&
        birthday.imagePath != null &&
        birthday.imagePath!.isNotEmpty &&
        File(birthday.imagePath!).existsSync();

    if (hasImage) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
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
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          birthday.name.isNotEmpty ? birthday.name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownCard(BuildContext context, Birthday birthday, Color color) {
    if (!birthday.hasBirthday) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.warning_amber_rounded, size: 40, color: Colors.orange.shade400),
              const SizedBox(height: 12),
              Text(
                'Födelsedag saknas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
              ),
              const SizedBox(height: 8),
              Text(
                'Tryck på redigera för att lägga till ett datum.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddBirthdayScreen(editBirthday: birthday)),
                ),
                icon: const Icon(Icons.edit_calendar_outlined),
                label: const Text('Lägg till födelsedag'),
                style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade400),
              ),
            ],
          ),
        ),
      );
    }

    final days = birthday.daysUntilBirthday;
    final isToday = birthday.isBirthdayToday;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (isToday) ...[
              const Text('🎂', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).happyBirthday,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).get('turns_years_today').replaceAll('{age}', '${birthday.turningAge}'),
                style: const TextStyle(fontSize: 16),
              ),
            ] else ...[
              Text(
                '$days',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: days <= 7 ? AppTheme.secondaryColor : AppTheme.primaryColor,
                ),
              ),
              Text(
                days == 1 ? AppLocalizations.of(context).get('days_left') : AppLocalizations.of(context).get('days_left'),
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).get('turning_age_on_weekday').replaceAll('{age}', '${birthday.turningAge}').replaceAll('{weekday}', AppLocalizations.of(context).get(birthday.weekdayKey)),
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Birthday birthday) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).information,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (birthday.hasBirthday) ...[  
              _infoRow(Icons.cake_outlined, AppLocalizations.of(context).birthdate,
                  DateFormat.yMMMMd(AppLocalizations.of(context).locale.languageCode).format(birthday.date)),
              _infoRow(Icons.elderly, AppLocalizations.of(context).age, '${birthday.age} ${AppLocalizations.of(context).yearsOld}'),
              _infoRow(Icons.calendar_today_outlined, AppLocalizations.of(context).nextBirthday,
                  AppLocalizations.of(context).get(birthday.weekdayKey)),
              _infoRow(Icons.auto_awesome, AppLocalizations.of(context).zodiacSign, AppLocalizations.of(context).get(birthday.zodiacKey)),
            ] else
              _infoRow(Icons.cake_outlined, AppLocalizations.of(context).birthdate, 'Saknas'),
            _infoRow(Icons.favorite_outlined, 'Relation', '${birthday.relationTypeEmoji} ${AppLocalizations.of(context).get(birthday.relationTypeLabelKey)}'),
            if (birthday.phone != null)
              _infoRow(Icons.phone_outlined, AppLocalizations.of(context).phone, birthday.phone!),
            if (birthday.email != null)
              _infoRow(Icons.email_outlined, AppLocalizations.of(context).email, birthday.email!),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, Birthday birthday) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accentSky.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.location_on_outlined, color: AppTheme.accentSky),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).get('address'),
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  Text(
                    birthday.address!,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context, Birthday birthday) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).notes,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(birthday.notes!, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersCard(BuildContext context, Birthday birthday) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: birthday.reminderDaysBefore.map((days) {
          String label;
          final l = AppLocalizations.of(context);
          if (days == 0) {
            label = l.sameDay;
          } else if (days == 1) {
            label = l.dayBefore;
          } else if (days == 7) {
            label = l.weekBefore;
          } else if (days == 14) {
            label = l.weeksBefore2;
          } else if (days == 30) {
            label = l.monthBefore;
          } else {
            label = l.get('days_before_3').replaceAll('3', '$days');
          }
          return Chip(
            label: Text(label, style: const TextStyle(fontSize: 13)),
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActions(BuildContext context, BirthdayProvider provider, Birthday birthday) {
    return Column(
      children: [
        // CSV share button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _shareAsCsv(context, birthday),
            icon: const Icon(Icons.download_outlined),
            label: const Text('Dela som CSV'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddBirthdayScreen(editBirthday: birthday),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: Text(AppLocalizations.of(context).edit),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _confirmDelete(context, provider, birthday),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: Text(AppLocalizations.of(context).delete, style: const TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _shareAsCsv(BuildContext context, Birthday birthday) async {
    final l = AppLocalizations.of(context);
    String csvEscape(String? s) {
      if (s == null || s.isEmpty) return '';
      if (s.contains(',') || s.contains('"') || s.contains('\n')) {
        return '"${s.replaceAll('"', '""')}"';
      }
      return s;
    }

    final csvBuffer = StringBuffer();
    csvBuffer.writeln('Namn,F\u00f6delsedatum,\u00c5lder,Telefon,E-post,Adress,Relation,Anteckningar');
    final date = DateFormat('yyyy-MM-dd').format(birthday.date);
    csvBuffer.writeln(
      '${csvEscape(birthday.name)},$date,${birthday.age},'
      '${csvEscape(birthday.phone)},${csvEscape(birthday.email)},'
      '${csvEscape(birthday.address)},${csvEscape(l.get(birthday.relationTypeLabelKey))},'
      '${csvEscape(birthday.notes)}',
    );

    final size = MediaQuery.of(context).size;
    try {
      final dir = await getTemporaryDirectory();
      final safeName = birthday.name.replaceAll(RegExp(r'[^\w\u00e5\u00e4\u00f6\u00c5\u00c4\u00d6]'), '_');
      final file = File('${dir.path}/$safeName.csv');
      await file.writeAsString(csvBuffer.toString());
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv')],
        subject: '${birthday.name} \u2013 F\u00f6delsedag',
        sharePositionOrigin: Rect.fromLTWH(
          size.width / 2 - 50,
          size.height / 2 - 50,
          100,
          100,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunde inte dela: $e')),
      );
    }
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigBirthdayCountdown(BuildContext context, Birthday birthday) {
    final premium = context.read<PremiumService>();
    final countdowns = birthday.bigBirthdayCountdowns;
    if (countdowns.isEmpty) return const SizedBox.shrink();

    final nextBig = countdowns.first;

    final l = AppLocalizations.of(context);
    if (!premium.isPremium) {
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PaywallScreen()),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.06),
                AppTheme.secondaryColor.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('\u2728', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.premiumUnlockAll,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _premiumFeatureRow('\ud83c\udf82', l.bigBirthdaysFeature),
              _premiumFeatureRow('\ud83d\udcdd', l.planningFeature),
              _premiumFeatureRow('\ud83c\udf81', l.wishlistFeature),
              _premiumFeatureRow('\ud83c\udf33', l.relationTreeFeature),
              _premiumFeatureRow('\u2728', l.adFreeFeature),
            ],
          ),
        ),
      );
    }

    bool expanded = false;
    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => setLocalState(() => expanded = !expanded),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      const Text('\ud83c\udf82', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Stora f\u00f6delsedagar',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'N\u00e4sta: ${nextBig.age} \u00e5r',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.expand_more, size: 22, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: countdowns.take(5).map((c) {
                        final years = (c.days / 365.25).floor();
                        final months = ((c.days % 365.25) / 30.44).floor();
                        final days = c.days - (years * 365.25).round() - (months * 30.44).round();
                        final timeStr = years > 0
                            ? '$years \u00e5r, $months m\u00e5n'
                            : months > 0
                                ? '$months m\u00e5nader, ${days.abs()} dagar'
                                : '${c.days} dagar';
                        final dateStr = DateFormat('d MMM yyyy', 'sv').format(c.date);
                        final isNext = c == nextBig;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: isNext
                                ? LinearGradient(colors: [
                                    AppTheme.primaryColor.withValues(alpha: 0.08),
                                    AppTheme.secondaryColor.withValues(alpha: 0.05),
                                  ])
                                : null,
                            color: isNext ? null : Colors.grey.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: isNext
                                ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2))
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: isNext ? AppTheme.primaryGradient : null,
                                  color: isNext ? null : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    '${c.age}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isNext ? Colors.white : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fyller ${c.age} \u00e5r',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      dateStr,
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isNext ? AppTheme.primaryColor : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMilestoneBanner(BuildContext context, Birthday birthday) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('\u{1F389}', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Milstolpe!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  birthday.milestoneKey != null ? AppLocalizations.of(context).get(birthday.milestoneKey!) : '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const Text('\u{1F38A}', style: TextStyle(fontSize: 28)),
        ],
      ),
    );
  }

  Future<void> _shareBirthday(BuildContext context, Birthday birthday) async {
    final date = birthday.date;
    final bday = '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';

    final vcf = StringBuffer();
    vcf.writeln('BEGIN:VCARD');
    vcf.writeln('VERSION:3.0');
    vcf.writeln('FN:${birthday.name}');
    vcf.writeln('BDAY:$bday');
    if (birthday.phone != null && birthday.phone!.isNotEmpty) {
      vcf.writeln('TEL:${birthday.phone}');
    }
    if (birthday.email != null && birthday.email!.isNotEmpty) {
      vcf.writeln('EMAIL:${birthday.email}');
    }
    if (birthday.address != null && birthday.address!.isNotEmpty) {
      vcf.writeln('ADR:;;${birthday.address};;;;');
    }
    if (birthday.notes != null && birthday.notes!.isNotEmpty) {
      vcf.writeln('NOTE:${birthday.notes}');
    }
    vcf.writeln('END:VCARD');

    final size = MediaQuery.of(context).size;
    try {
      final dir = await getTemporaryDirectory();
      final safeName = birthday.name.replaceAll(RegExp(r'[^a-zA-Z0-9\u00e5\u00e4\u00f6\u00c5\u00c4\u00d6]'), '_');
      final file = File('${dir.path}/$safeName.vcf');
      await file.writeAsString(vcf.toString());
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/vcard')],
        subject: '${birthday.name} \u2013 F\u00f6delsedag',
        sharePositionOrigin: Rect.fromLTWH(
          size.width / 2 - 50,
          size.height / 2 - 50,
          100,
          100,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunde inte dela: $e')),
      );
    }
  }

  void _confirmDelete(BuildContext context, BirthdayProvider provider, Birthday birthday) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).delete),
        content: Text(AppLocalizations.of(context).get('delete_confirm_name').replaceAll('{name}', birthday.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () {
              provider.deleteBirthday(birthday.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );
  }

  Widget _premiumFeatureRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool initiallyExpanded;
  final String? badge;

  const _ExpandableSection({
    required this.title,
    required this.icon,
    required this.child,
    this.initiallyExpanded = false,
    this.badge,
  });

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(widget.icon, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (widget.badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.badge!,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, size: 22, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: widget.child,
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
