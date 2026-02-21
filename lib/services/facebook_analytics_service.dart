import 'dart:io';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';

/// Wraps Facebook App Events (Conversions API) for Meta ad attribution.
///
/// Usage:
///   await FacebookAnalyticsService.instance.init();
///   FacebookAnalyticsService.instance.logPurchase(amount: 49.0, currency: 'SEK');
class FacebookAnalyticsService {
  FacebookAnalyticsService._();
  static final FacebookAnalyticsService instance = FacebookAnalyticsService._();

  final _fb = FacebookAppEvents();
  bool _initialized = false;

  /// Call once at app startup (after ATT dialog).
  Future<void> init() async {
    if (_initialized) return;
    try {
      await _fb.setAutoLogAppEventsEnabled(true);
      await _fb.setAdvertiserTracking(enabled: true);
      _initialized = true;
      debugPrint('[FB] Analytics initialized');
    } catch (e) {
      debugPrint('[FB] Init error: $e');
    }
  }

  /// Disable tracking (call if user opts out or ATT denied).
  Future<void> disable() async {
    try {
      await _fb.setAutoLogAppEventsEnabled(false);
      await _fb.setAdvertiserTracking(enabled: false);
    } catch (e) {
      debugPrint('[FB] Disable error: $e');
    }
  }

  // ── Standard Meta events ──────────────────────────────────

  /// Fired when a subscription/purchase completes.
  Future<void> logPurchase({
    required double amount,
    String currency = 'SEK',
    Map<String, dynamic>? parameters,
  }) async {
    if (!_initialized) return;
    try {
      await _fb.logPurchase(amount: amount, currency: currency, parameters: parameters);
      debugPrint('[FB] Purchase: $amount $currency');
    } catch (e) {
      debugPrint('[FB] logPurchase error: $e');
    }
  }

  /// Fired when the paywall is shown (InitiateCheckout).
  Future<void> logInitiateCheckout({String? planName}) async {
    if (!_initialized) return;
    try {
      await _fb.logInitiatedCheckout(
        parameters: planName != null ? {'plan': planName} : null,
      );
      debugPrint('[FB] InitiateCheckout: $planName');
    } catch (e) {
      debugPrint('[FB] logInitiateCheckout error: $e');
    }
  }

  /// Fired when a free trial starts.
  Future<void> logStartTrial({String? planName}) async {
    if (!_initialized) return;
    try {
      await _fb.logEvent(
        name: 'StartTrial',
        parameters: planName != null ? {'plan': planName} : null,
      );
      debugPrint('[FB] StartTrial: $planName');
    } catch (e) {
      debugPrint('[FB] logStartTrial error: $e');
    }
  }

  /// Fired when user completes onboarding / adds first birthday.
  Future<void> logCompleteRegistration() async {
    if (!_initialized) return;
    try {
      await _fb.logCompletedRegistration(registrationMethod: 'app');
      debugPrint('[FB] CompleteRegistration');
    } catch (e) {
      debugPrint('[FB] logCompleteRegistration error: $e');
    }
  }

  /// Fired when user views a birthday detail screen.
  Future<void> logViewContent({required String contentType, String? contentId}) async {
    if (!_initialized) return;
    try {
      await _fb.logViewContent(
        id: contentId,
        type: contentType,
        currency: null,
        price: null,
      );
      debugPrint('[FB] ViewContent: $contentType');
    } catch (e) {
      debugPrint('[FB] logViewContent error: $e');
    }
  }

  /// Fired when user adds an item to wishlist.
  Future<void> logAddToWishlist({String? itemName}) async {
    if (!_initialized) return;
    try {
      await _fb.logAddToWishlist(
        parameters: itemName != null ? {'item_name': itemName} : null,
      );
      debugPrint('[FB] AddToWishlist: $itemName');
    } catch (e) {
      debugPrint('[FB] logAddToWishlist error: $e');
    }
  }

  /// Fired when user imports contacts (Lead event).
  Future<void> logImportContacts({int count = 0}) async {
    if (!_initialized) return;
    try {
      await _fb.logEvent(
        name: 'Lead',
        parameters: {'contact_count': count},
      );
      debugPrint('[FB] Lead (ImportContacts): $count');
    } catch (e) {
      debugPrint('[FB] logImportContacts error: $e');
    }
  }
}

/// Handles iOS App Tracking Transparency dialog and initializes FB accordingly.
class AttPermissionHandler {
  /// Call this once from main.dart after the first frame.
  static Future<void> requestAndInit() async {
    if (!Platform.isIOS) {
      await FacebookAnalyticsService.instance.init();
      return;
    }

    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;

      if (status == TrackingStatus.notDetermined) {
        // Wait a moment so the app UI is visible before showing the dialog
        await Future.delayed(const Duration(milliseconds: 500));
        final result = await AppTrackingTransparency.requestTrackingAuthorization();
        if (result == TrackingStatus.authorized) {
          await FacebookAnalyticsService.instance.init();
        } else {
          await FacebookAnalyticsService.instance.disable();
        }
      } else if (status == TrackingStatus.authorized) {
        await FacebookAnalyticsService.instance.init();
      } else {
        await FacebookAnalyticsService.instance.disable();
      }
    } catch (e) {
      debugPrint('[ATT] Error: $e');
      await FacebookAnalyticsService.instance.init();
    }
  }
}
