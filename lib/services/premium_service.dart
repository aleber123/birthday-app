import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PremiumPlan { free, monthly, yearly, lifetime }

class PremiumService extends ChangeNotifier {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  static const String _premiumKey = 'is_premium_lifetime';
  static const String _planKey = 'premium_plan';

  // Product IDs – must match App Store Connect / Google Play Console
  static const String monthlyId = 'com.alexanderbergqvist.birthdayreminder.monthly';
  static const String yearlyId = 'com.alexanderbergqvist.birthdayreminder.yearly';
  static const String lifetimeId = 'com.alexanderbergqvist.birthdayreminder.forever';

  static const Set<String> _productIds = {monthlyId, yearlyId, lifetimeId};

  // Free tier limits
  static const int maxFreeBirthdays = 10;
  static const int maxFreeRemindersPerPerson = 1;

  // Fallback pricing (shown if store products haven't loaded yet)
  static const Map<String, Map<PremiumPlan, double>> pricing = {
    'sv': {PremiumPlan.monthly: 29, PremiumPlan.yearly: 199, PremiumPlan.lifetime: 499},
    'nb': {PremiumPlan.monthly: 29, PremiumPlan.yearly: 199, PremiumPlan.lifetime: 499},
    'da': {PremiumPlan.monthly: 25, PremiumPlan.yearly: 169, PremiumPlan.lifetime: 449},
    'fi': {PremiumPlan.monthly: 2.99, PremiumPlan.yearly: 19.99, PremiumPlan.lifetime: 49.99},
    'is': {PremiumPlan.monthly: 2.99, PremiumPlan.yearly: 19.99, PremiumPlan.lifetime: 49.99},
    'en': {PremiumPlan.monthly: 2.99, PremiumPlan.yearly: 19.99, PremiumPlan.lifetime: 49.99},
  };

  static const Map<String, String> currencySymbols = {
    'sv': 'kr', 'nb': 'kr', 'da': 'kr', 'fi': '€', 'is': '€', 'en': '\$',
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  List<ProductDetails> _products = [];
  bool _storeAvailable = false;

  bool _isPremium = false;
  PremiumPlan _currentPlan = PremiumPlan.free;
  bool _purchaseInProgress = false;
  String? _purchaseError;

  bool get isPremium => _isPremium;
  PremiumPlan get currentPlan => _currentPlan;
  bool get purchaseInProgress => _purchaseInProgress;
  String? get purchaseError => _purchaseError;
  List<ProductDetails> get products => _products;
  bool get storeAvailable => _storeAvailable;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Only trust cached state for lifetime (non-expiring) purchases.
    // Subscriptions must be verified via the App Store on every launch.
    final cachedPlanIndex = prefs.getInt(_planKey) ?? 0;
    final cachedPlan = PremiumPlan.values[cachedPlanIndex];
    if (cachedPlan == PremiumPlan.lifetime &&
        (prefs.getBool(_premiumKey) ?? false)) {
      _isPremium = true;
      _currentPlan = PremiumPlan.lifetime;
    } else {
      // Start as free – subscriptions will be restored via purchaseStream
      _isPremium = false;
      _currentPlan = PremiumPlan.free;
      await prefs.setBool(_premiumKey, false);
      await prefs.setInt(_planKey, 0);
    }

    // Initialize In-App Purchase listener (not available on web)
    try {
      _storeAvailable = await _iap.isAvailable();
      if (_storeAvailable) {
        _subscription = _iap.purchaseStream.listen(
          _onPurchaseUpdated,
          onDone: () => _subscription?.cancel(),
          onError: (error) => debugPrint('IAP stream error: $error'),
        );
        await _loadProducts();
        // Restore purchases to verify active subscriptions with the App Store
        await _iap.restorePurchases();
      }
    } catch (e) {
      debugPrint('IAP initialization failed (expected on web): $e');
      _storeAvailable = false;
    }

    notifyListeners();
  }

  Future<void> _loadProducts() async {
    final response = await _iap.queryProductDetails(_productIds);
    if (response.error != null) {
      debugPrint('IAP query error: ${response.error}');
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('IAP products not found: ${response.notFoundIDs}');
    }
    _products = response.productDetails;
    notifyListeners();
  }

  void _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _purchaseInProgress = true;
          _purchaseError = null;
          notifyListeners();
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndActivate(purchase);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.error:
          _purchaseInProgress = false;
          _purchaseError = purchase.error?.message ?? 'Köpet misslyckades';
          notifyListeners();
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          _purchaseInProgress = false;
          _purchaseError = null;
          notifyListeners();
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
      }
    }
  }

  Future<void> _verifyAndActivate(PurchaseDetails purchase) async {
    // Determine which plan was purchased
    PremiumPlan plan = PremiumPlan.free;
    if (purchase.productID == monthlyId) {
      plan = PremiumPlan.monthly;
    } else if (purchase.productID == yearlyId) {
      plan = PremiumPlan.yearly;
    } else if (purchase.productID == lifetimeId) {
      plan = PremiumPlan.lifetime;
    }

    if (plan != PremiumPlan.free) {
      _isPremium = true;
      _currentPlan = plan;

      // Only persist lifetime purchases locally – subscriptions are
      // re-verified via restorePurchases() on every app launch.
      if (plan == PremiumPlan.lifetime) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_premiumKey, true);
        await prefs.setInt(_planKey, plan.index);
      }
    }

    _purchaseInProgress = false;
    _purchaseError = null;
    notifyListeners();
  }

  // --- Gating helpers ---

  bool canAddBirthday(int currentCount) {
    if (_isPremium) return true;
    return currentCount < maxFreeBirthdays;
  }

  bool canAddMoreReminders(int currentReminders) {
    if (_isPremium) return true;
    return currentReminders < maxFreeRemindersPerPerson;
  }

  bool get canExport => _isPremium;
  bool get canUseThemes => _isPremium;
  bool get canUsePlanning => _isPremium;
  bool get canUseWishlist => _isPremium;
  bool get isAdFree => _isPremium;

  int get remainingFreeBirthdays => _isPremium ? -1 : maxFreeBirthdays;

  // --- Price helpers ---

  /// Returns the real store price if available, otherwise fallback
  String getPrice(PremiumPlan plan, String languageCode) {
    final productId = _planToProductId(plan);
    final storeProduct = _products.where((p) => p.id == productId).firstOrNull;

    if (storeProduct != null) {
      return storeProduct.price;
    }

    // Fallback to hardcoded prices
    final prices = pricing[languageCode] ?? pricing['en']!;
    final currency = currencySymbols[languageCode] ?? '\$';
    final price = prices[plan] ?? 0;

    if (languageCode == 'fi' || languageCode == 'is' || languageCode == 'en') {
      return '$currency${price.toStringAsFixed(2)}';
    }
    return '${price.toInt()} $currency';
  }

  String getMonthlyEquivalent(PremiumPlan plan, String languageCode) {
    if (plan != PremiumPlan.yearly) return '';

    final productId = _planToProductId(plan);
    final storeProduct = _products.where((p) => p.id == productId).firstOrNull;

    if (storeProduct != null) {
      final monthly = storeProduct.rawPrice / 12;
      final currencyCode = storeProduct.currencyCode;
      return '${monthly.toStringAsFixed(0)} $currencyCode/mån';
    }

    // Fallback
    final prices = pricing[languageCode] ?? pricing['en']!;
    final currency = currencySymbols[languageCode] ?? '\$';
    final price = prices[plan] ?? 0;
    final monthly = price / 12;
    if (languageCode == 'fi' || languageCode == 'is' || languageCode == 'en') {
      return '$currency${monthly.toStringAsFixed(2)}/mån';
    }
    return '${monthly.toInt()} $currency/mån';
  }

  String _planToProductId(PremiumPlan plan) {
    switch (plan) {
      case PremiumPlan.monthly:
        return monthlyId;
      case PremiumPlan.yearly:
        return yearlyId;
      case PremiumPlan.lifetime:
        return lifetimeId;
      case PremiumPlan.free:
        return '';
    }
  }

  // --- Purchase methods (real In-App Purchase) ---

  Future<bool> purchase(PremiumPlan plan) async {
    if (!_storeAvailable) {
      _purchaseError = 'App Store är inte tillgänglig';
      notifyListeners();
      return false;
    }

    final productId = _planToProductId(plan);
    final product = _products.where((p) => p.id == productId).firstOrNull;

    if (product == null) {
      _purchaseError = 'Produkten kunde inte hittas. Försök igen senare.';
      notifyListeners();
      return false;
    }

    _purchaseInProgress = true;
    _purchaseError = null;
    notifyListeners();

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      // Both subscriptions (monthly/yearly) and the lifetime one-time purchase
      // must use buyNonConsumable. The buyConsumable method is only for
      // consumable items (e.g. coins) and can cause StoreKit to skip the
      // subscription confirmation sheet on iOS (Guideline 2.1).
      final bool success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      debugPrint('IAP buyProduct returned: $success');
    } catch (e) {
      _purchaseInProgress = false;
      _purchaseError = 'Köpet misslyckades: $e';
      notifyListeners();
      return false;
    }

    // The actual result comes via _onPurchaseUpdated stream
    return true;
  }

  Future<bool> restorePurchases() async {
    if (!_storeAvailable) return false;

    try {
      await _iap.restorePurchases();
      // Results come via _onPurchaseUpdated stream
      return true;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }

  Future<void> cancelSubscription() async {
    // Deep link to subscription management on iOS/Android
    // Users manage subscriptions through the App Store / Google Play
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
