import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/birthday_provider.dart';
import '../services/premium_service.dart';
import '../utils/app_theme.dart';
import '../widgets/birthday_card.dart';
import '../widgets/today_banner.dart';
import 'add_birthday_screen.dart';
import 'birthday_detail_screen.dart';
import '../widgets/ad_banner.dart';
import 'calendar_screen.dart';
import 'paywall_screen.dart';
import 'relation_tree_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isSearching = false;
  final _searchController = TextEditingController();
  final _relationTreeKey = GlobalKey<RelationTreeScreenState>();
  bool _notificationsDenied = false;
  bool _notificationsBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BirthdayProvider>().loadBirthdays();
      _checkNotificationPermission();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNotificationPermission();
    }
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    if (mounted) {
      // Only warn if permanently denied (user explicitly said no)
      // or if denied but NOT in the initial "not determined" state
      setState(() => _notificationsDenied = status.isPermanentlyDenied);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildBirthdayList(),
          const CalendarScreen(),
          RelationTreeScreen(key: _relationTreeKey),
          const SettingsScreen(),
        ],
      ),
      floatingActionButton: _currentIndex == 3
          ? null // No FAB on settings tab
          : Container(
              decoration: BoxDecoration(
                gradient: _currentIndex == 2
                    ? const LinearGradient(colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)])
                    : AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () {
                  if (_currentIndex == 2) {
                    // Relations tab: open add link dialog
                    final state = _relationTreeKey.currentState;
                    if (state != null && state.hasProfile) {
                      state.showAddLinkDialog();
                    }
                  } else {
                    _navigateToAdd(context);
                  }
                },
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: Icon(
                  _currentIndex == 2 ? Icons.link_rounded : Icons.add_rounded,
                  size: 30,
                ),
              ),
            ),
      persistentFooterButtons: const [AdBannerWidget()],
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.surfaceDark.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.8),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.cake_outlined),
                  activeIcon: const Icon(Icons.cake),
                  label: l.birthdays,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.calendar_month_outlined),
                  activeIcon: const Icon(Icons.calendar_month),
                  label: l.calendar,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.hub_outlined),
                  activeIcon: const Icon(Icons.hub),
                  label: l.relations,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.settings_outlined),
                  activeIcon: const Icon(Icons.settings),
                  label: l.settings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBirthdayList() {
    final l = AppLocalizations.of(context);
    return Consumer<BirthdayProvider>(
      builder: (context, provider, _) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              title: _isSearching
                  ? Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: l.searchName,
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey.shade400),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: provider.setSearchQuery,
                      ),
                    )
                  : Text(l.birthdays),
              actions: [
                IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close_rounded : Icons.search_rounded,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        provider.setSearchQuery('');
                      }
                    });
                  },
                ),
                PopupMenuButton<SortMode>(
                  icon: const Icon(Icons.tune_rounded, size: 22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onSelected: provider.setSortMode,
                  itemBuilder: (context) => [
                    _sortMenuItem(SortMode.upcoming, l.upcoming, Icons.schedule_rounded, provider),
                    _sortMenuItem(SortMode.name, l.nameAZ, Icons.sort_by_alpha_rounded, provider),
                    _sortMenuItem(SortMode.age, l.age, Icons.elderly_rounded, provider),
                    _sortMenuItem(SortMode.recentlyAdded, l.recentlyAdded, Icons.access_time_rounded, provider),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ),
            if (provider.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (provider.allBirthdays.isEmpty)
              SliverFillRemaining(child: _buildEmptyState())
            else ...[
              SliverToBoxAdapter(
                child: TodayBanner(todaysBirthdays: provider.todaysBirthdays),
              ),
              if (_notificationsDenied && !_notificationsBannerDismissed)
                SliverToBoxAdapter(
                  child: _buildNotificationWarning(),
                ),
              if (provider.birthdays.isNotEmpty && provider.todaysBirthdays.isEmpty)
                SliverToBoxAdapter(
                  child: _buildQuickStats(provider),
                ),
              if (provider.birthdays.isEmpty && provider.searchQuery.isNotEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 56,
                            color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          l.noResults,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final birthday = provider.birthdays[index];
                      return BirthdayCard(
                        birthday: birthday,
                        onTap: () => _navigateToDetail(context, birthday.id),
                        onLongPress: () => _showDeleteDialog(
                            context, provider, birthday.id, birthday.name),
                      );
                    },
                    childCount: provider.birthdays.length,
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildQuickStats(BirthdayProvider provider) {
    final l = AppLocalizations.of(context);
    final upcoming7 = provider.allBirthdays
        .where((b) => b.daysUntilBirthday <= 7 && b.daysUntilBirthday > 0)
        .length;
    final thisMonth = provider.allBirthdays
        .where((b) => b.date.month == DateTime.now().month)
        .length;

    if (upcoming7 == 0 && thisMonth == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          if (upcoming7 > 0)
            _statPill(l.get('within_7_days_count').replaceAll('{count}', '$upcoming7'), AppTheme.secondaryColor),
          if (upcoming7 > 0 && thisMonth > 0) const SizedBox(width: 8),
          if (thisMonth > 0)
            _statPill(l.get('this_month_count').replaceAll('{count}', '$thisMonth'), AppTheme.primaryColor),
        ],
      ),
    );
  }

  Widget _buildNotificationWarning() {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_off_rounded, color: Color(0xFFDC2626), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.notificationsOff,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.riskMissingBirthdays,
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFFDC2626).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                final requested = await Permission.notification.request();
                if (requested.isPermanentlyDenied) {
                  openAppSettings();
                }
                _checkNotificationPermission();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l.activate,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => setState(() => _notificationsBannerDismissed = true),
              child: Icon(Icons.close, size: 16, color: const Color(0xFFDC2626).withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  PopupMenuItem<SortMode> _sortMenuItem(
      SortMode mode, String label, IconData icon, BirthdayProvider provider) {
    final isSelected = provider.sortMode == mode;
    return PopupMenuItem(
      value: mode,
      child: Row(
        children: [
          Icon(icon, size: 20,
              color: isSelected ? AppTheme.primaryColor : Colors.grey),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryColor : null,
              )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.15),
                    AppTheme.secondaryColor.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text('🎂', style: TextStyle(fontSize: 56)),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l.noBirthdaysYetTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l.addFirstBirthday,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: () => _navigateToAdd(context),
                icon: const Icon(Icons.add_rounded),
                label: Text(l.addBirthdayBtn),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAdd(BuildContext context) {
    final premium = context.read<PremiumService>();
    final provider = context.read<BirthdayProvider>();

    if (!premium.canAddBirthday(provider.allBirthdays.length)) {
      _showPaywall(context);
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AddBirthdayScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _showPaywall(BuildContext context) {
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

  void _navigateToDetail(BuildContext context, String id) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BirthdayDetailScreen(birthdayId: id),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, BirthdayProvider provider, String id, String name) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.delete, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(l.get('delete_confirm_name').replaceAll('{name}', name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () {
              provider.deleteBirthday(id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF4757),
            ),
            child: Text(l.delete),
          ),
        ],
      ),
    );
  }
}
