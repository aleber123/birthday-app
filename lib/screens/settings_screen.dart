import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/birthday.dart';
import '../providers/birthday_provider.dart';
import '../services/notification_service.dart';
import '../services/premium_service.dart';
import '../services/theme_service.dart';
import '../utils/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'paywall_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _saveNotificationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);

    if (!value) {
      await NotificationService().cancelAllNotifications();
    } else {
      if (!mounted) return;
      final provider = context.read<BirthdayProvider>();
      await NotificationService().rescheduleAllReminders(provider.allBirthdays);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final premium = context.watch<PremiumService>();

    return Consumer<BirthdayProvider>(
      builder: (context, provider, _) {
        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: Text(l10n.settings),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCard(provider, premium, l10n),
                    const SizedBox(height: 24),
                    _buildSectionTitle(l10n.notifications),
                    const SizedBox(height: 8),
                    _buildSettingCard(
                      icon: Icons.notifications_outlined,
                      title: l10n.notifications,
                      subtitle: _notificationsEnabled ? l10n.enabled : l10n.disabled,
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: _saveNotificationSetting,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Tema'),
                    const SizedBox(height: 8),
                    _buildThemePicker(premium),
                    const SizedBox(height: 24),
                    _buildSectionTitle(l10n.premium),
                    const SizedBox(height: 8),
                    _buildPremiumCard(premium, l10n),
                    const SizedBox(height: 24),
                    _buildSectionTitle(l10n.data),
                    const SizedBox(height: 8),
                    _buildSettingCard(
                      icon: Icons.file_download_outlined,
                      title: l10n.exportCsv,
                      subtitle: premium.canExport ? l10n.exportData : l10n.requiresPremium,
                      onTap: premium.canExport ? _exportData : () => _openPaywall(),
                    ),
                    const SizedBox(height: 8),
                    _buildSettingCard(
                      icon: Icons.file_upload_outlined,
                      title: l10n.importCsv,
                      subtitle: l10n.importData,
                      onTap: _importCsv,
                    ),
                    const SizedBox(height: 8),
                    _buildSettingCard(
                      icon: Icons.delete_sweep_outlined,
                      title: l10n.deleteAllData,
                      subtitle: l10n.deleteAllConfirm.split('.').first,
                      titleColor: Colors.red,
                      onTap: () => _confirmDeleteAll(provider, l10n),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsCard(BirthdayProvider provider, PremiumService premium, AppLocalizations l10n) {
    final total = provider.allBirthdays.length;
    final thisMonth = provider.allBirthdays
        .where((b) => b.date.month == DateTime.now().month)
        .length;
    final upcoming7 = provider.allBirthdays
        .where((b) => b.daysUntilBirthday <= 7 && b.daysUntilBirthday > 0)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.statistics,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _statItem(l10n.total, '$total', Icons.people_outline),
                _statItem(l10n.thisMonth, '$thisMonth', Icons.calendar_today_outlined),
                _statItem(l10n.within7Days, '$upcoming7', Icons.schedule),
              ],
            ),
            if (!premium.isPremium) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: total / PremiumService.maxFreeBirthdays,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                  total >= PremiumService.maxFreeBirthdays
                      ? Colors.red
                      : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$total / ${PremiumService.maxFreeBirthdays} (${l10n.free})',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildThemePicker(PremiumService premium) {
    final themeService = context.watch<ThemeService>();
    final canUse = premium.canUseThemes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette_outlined, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'F\u00e4rgtema',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (!canUse)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Premium',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppColorTheme.values.map((theme) {
                final colors = ThemeService.themeColors[theme]!;
                final isSelected = themeService.currentTheme == theme;
                final isDefault = theme == AppColorTheme.violet;
                final locked = !canUse && !isDefault;

                return GestureDetector(
                  onTap: locked
                      ? _openPaywall
                      : () => themeService.setTheme(theme),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colors['primary']!, colors['secondary']!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: colors['primary']!, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [BoxShadow(color: colors['primary']!.withValues(alpha: 0.4), blurRadius: 8)]
                              : null,
                        ),
                        child: locked
                            ? const Icon(Icons.lock, color: Colors.white, size: 18)
                            : isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        themeService.themeName(theme),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard(PremiumService premium, AppLocalizations l10n) {
    if (premium.isPremium) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.auroraGradient,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('👑', style: TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.premiumActive, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(l10n.allFeaturesUnlocked, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.05),
              AppTheme.secondaryColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('👑', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  l10n.upgradePremium,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _premiumFeature(l10n.unlimitedBirthdays),
            _premiumFeature(l10n.planningFeature),
            _premiumFeature(l10n.wishlistFeature),
            _premiumFeature(l10n.bigBirthdaysFeature),
            _premiumFeature(l10n.relationTreeFeature),
            _premiumFeature(l10n.moreReminders),
            _premiumFeature(l10n.extraThemes),
            _premiumFeature(l10n.adFreeFeature),
            _premiumFeature(l10n.exportCsv),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.auroraGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: _openPaywall,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(l10n.seePrices, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _premiumFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppTheme.accentMint, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: titleColor ?? AppTheme.primaryColor),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: titleColor)),
        subtitle: Text(subtitle),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
        onTap: onTap,
      ),
    );
  }


  void _openPaywall() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const PaywallScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
  }

  Future<void> _exportData() async {
    final provider = context.read<BirthdayProvider>();
    final birthdays = provider.allBirthdays;

    if (birthdays.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inga f\u00f6delsedagar att exportera')),
      );
      return;
    }

    final csvBuffer = StringBuffer();
    csvBuffer.writeln('Namn,F\u00f6delsedatum,\u00c5lder,Telefon,E-post,Adress,Relation,Anteckningar');

    for (final b in birthdays) {
      final date = DateFormat('yyyy-MM-dd').format(b.date);
      final name = _csvEscape(b.name);
      final phone = _csvEscape(b.phone ?? '');
      final email = _csvEscape(b.email ?? '');
      final address = _csvEscape(b.address ?? '');
      final relation = _csvEscape(AppLocalizations.of(context).get(b.relationTypeLabelKey));
      final notes = _csvEscape(b.notes ?? '');
      csvBuffer.writeln('$name,$date,${b.age},$phone,$email,$address,$relation,$notes');
    }

    final size = MediaQuery.of(context).size;
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/fodelsedagar.csv');
      await file.writeAsString(csvBuffer.toString());
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'F\u00f6delsedagar export',
        sharePositionOrigin: Rect.fromLTWH(
          size.width / 2 - 50,
          size.height / 2 - 50,
          100,
          100,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export misslyckades: $e')),
      );
    }
  }

  Future<void> _importCsv() async {
    final l10n = AppLocalizations.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();

      if (lines.length < 2) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.get('csv_no_valid_rows'))),
        );
        return;
      }

      // Skip header row
      final provider = context.read<BirthdayProvider>();
      final existingNames = provider.allBirthdays
          .map((b) => b.name.toLowerCase().trim())
          .toSet();

      int imported = 0;
      for (int i = 1; i < lines.length; i++) {
        final fields = _parseCsvLine(lines[i]);
        if (fields.length < 2) continue;

        final name = fields[0].trim();
        if (name.isEmpty) continue;

        // Skip duplicates
        if (existingNames.contains(name.toLowerCase().trim())) continue;

        // Parse date - try multiple formats
        DateTime? date;
        final dateStr = fields[1].trim();
        for (final fmt in ['yyyy-MM-dd', 'dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy/MM/dd', 'dd-MM-yyyy']) {
          try {
            date = DateFormat(fmt).parseStrict(dateStr);
            break;
          } catch (_) {}
        }
        if (date == null) continue;

        final phone = fields.length > 3 ? fields[3].trim() : null;
        final email = fields.length > 4 ? fields[4].trim() : null;
        final address = fields.length > 5 ? fields[5].trim() : null;
        final notes = fields.length > 7 ? fields[7].trim() : null;

        final birthday = Birthday(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i',
          name: name,
          date: date,
          phone: phone != null && phone.isNotEmpty ? phone : null,
          email: email != null && email.isNotEmpty ? email : null,
          address: address != null && address.isNotEmpty ? address : null,
          notes: notes != null && notes.isNotEmpty ? notes : null,
        );

        await provider.addBirthday(birthday);
        existingNames.add(name.toLowerCase().trim());
        imported++;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(imported > 0
              ? l10n.get('csv_imported').replaceAll('{count}', '$imported')
              : l10n.get('csv_no_valid_rows')),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.get('csv_import_failed')}: $e')),
      );
    }
  }

  /// Parse a single CSV line, handling quoted fields
  List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    bool inQuotes = false;
    final current = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final c = line[i];
      if (inQuotes) {
        if (c == '"' && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else if (c == '"') {
          inQuotes = false;
        } else {
          current.write(c);
        }
      } else {
        if (c == '"') {
          inQuotes = true;
        } else if (c == ',') {
          fields.add(current.toString());
          current.clear();
        } else {
          current.write(c);
        }
      }
    }
    fields.add(current.toString());
    return fields;
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  void _confirmDeleteAll(BirthdayProvider provider, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllData),
        content: Text(l10n.deleteAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              for (final b in provider.allBirthdays) {
                await provider.deleteBirthday(b.id);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.deleteAll),
          ),
        ],
      ),
    );
  }
}
