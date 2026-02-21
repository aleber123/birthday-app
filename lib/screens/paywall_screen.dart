import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/premium_service.dart';
import '../services/facebook_analytics_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../l10n/app_localizations.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  PremiumPlan _selectedPlan = PremiumPlan.yearly;
  final PremiumService _premium = PremiumService();

  @override
  void initState() {
    super.initState();
    _premium.addListener(_onPremiumChanged);
    FacebookAnalyticsService.instance.logInitiateCheckout(planName: 'paywall_view');
  }

  @override
  void dispose() {
    _premium.removeListener(_onPremiumChanged);
    super.dispose();
  }

  void _onPremiumChanged() {
    if (!mounted) return;
    setState(() {});

    // If purchase succeeded, fire FB Purchase event and show success
    if (_premium.isPremium) {
      final price = _selectedPlan == PremiumPlan.yearly ? 49.0 : 9.0;
      FacebookAnalyticsService.instance.logPurchase(
        amount: price,
        currency: 'SEK',
        parameters: {'plan': _selectedPlan == PremiumPlan.yearly ? 'yearly' : 'monthly'},
      );
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('\u{1F451} ', style: TextStyle(fontSize: 18)),
              Text(l10n.premiumActive),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    // If there was an error, show it
    if (_premium.purchaseError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_premium.purchaseError!),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final premium = _premium;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A1030), const Color(0xFF0D0D1A)]
                : [const Color(0xFFF5F0FF), const Color(0xFFFFE8F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white54 : Colors.grey.shade600,
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Crown icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppTheme.auroraGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('👑', style: TextStyle(fontSize: 36)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        l10n.upgradePremium,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.allFeaturesUnlocked,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Features list
                      _buildFeaturesList(l10n, isDark),
                      const SizedBox(height: 32),

                      // Plan selector
                      Text(
                        l10n.choosePlan,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildPlanCard(
                        plan: PremiumPlan.yearly,
                        title: l10n.yearly,
                        price: premium.getPrice(PremiumPlan.yearly, lang),
                        subtitle: premium.getMonthlyEquivalent(PremiumPlan.yearly, lang),
                        badge: l10n.save43,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildPlanCard(
                        plan: PremiumPlan.monthly,
                        title: l10n.monthly,
                        price: premium.getPrice(PremiumPlan.monthly, lang),
                        subtitle: '',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildPlanCard(
                        plan: PremiumPlan.lifetime,
                        title: l10n.lifetime,
                        price: premium.getPrice(PremiumPlan.lifetime, lang),
                        subtitle: '⚡',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 28),

                      // Purchase button
                      _buildPurchaseButton(premium, lang, l10n),
                      const SizedBox(height: 12),

                      // Restore purchases
                      TextButton(
                        onPressed: () async {
                          await premium.restorePurchases();
                          // Results come via the listener (_onPremiumChanged)
                        },
                        child: Text(
                          'Återställ köp',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Legal text
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Prenumerationen förnyas automatiskt om den inte avbryts minst 24 timmar före slutet av den aktuella perioden. Betalning debiteras via ditt Apple ID / Google Play-konto.',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // Privacy Policy & Terms of Use links (required by App Store Guideline 3.1.2)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => launchUrl(
                              Uri.parse(AppConstants.termsOfUseUrl),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: Text(
                              'Användarvillkor (EULA)',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : Colors.grey.shade500,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '·',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : Colors.grey.shade500,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => launchUrl(
                              Uri.parse(AppConstants.privacyPolicyUrl),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: Text(
                              'Integritetspolicy',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : Colors.grey.shade500,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList(AppLocalizations l10n, bool isDark) {
    final features = [
      ('♾️', l10n.unlimitedBirthdays),
      ('🔔', l10n.moreReminders),
      ('🎨', l10n.extraThemes),
      ('📤', l10n.exportCsv),
      ('🎁', '\u00d6nskelista per person'),
      ('📵', 'Helt reklamfritt'),
      ('📲', 'Dela via AirDrop'),
      ('📋', 'F\u00f6delsedagsplanering'),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.8),
            ),
          ),
          child: Column(
            children: features.map((f) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(f.$1, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        f.$2,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.accentMint,
                      size: 20,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required PremiumPlan plan,
    required String title,
    required String price,
    required String subtitle,
    required bool isDark,
    String? badge,
  }) {
    final isSelected = _selectedPlan == plan;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.15),
                    AppTheme.secondaryColor.withValues(alpha: 0.08),
                  ],
                )
              : null,
          color: isSelected
              ? null
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),

            // Plan info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppTheme.primaryColor : null,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: AppTheme.warmGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),

            // Price
            Text(
              price,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppTheme.primaryColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(
      PremiumService premium, String lang, AppLocalizations l10n) {
    final isLoading = premium.purchaseInProgress;
    final canPurchase = premium.storeAvailable && premium.products.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.auroraGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FilledButton(
          onPressed: (isLoading || !canPurchase)
              ? null
              : () {
                  FacebookAnalyticsService.instance.logInitiateCheckout(
                    planName: _selectedPlan == PremiumPlan.yearly ? 'yearly' : 'monthly',
                  );
                  premium.purchase(_selectedPlan);
                  // Result comes via _onPremiumChanged listener
                },
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  '${l10n.upgradePremium} \u2013 ${premium.getPrice(_selectedPlan, lang)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
