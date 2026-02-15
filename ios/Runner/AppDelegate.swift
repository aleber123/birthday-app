import Flutter
import UIKit
import StoreKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register the payment queue observer as early as possible.
    // Apple requires this in didFinishLaunchingWithOptions to ensure
    // the app receives all payment queue notifications, including
    // interrupted purchases and promoted in-app purchases.
    SKPaymentQueue.default().add(self)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// MARK: - SKPaymentTransactionObserver
extension AppDelegate: SKPaymentTransactionObserver {
  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    // Transactions are handled by the Flutter in_app_purchase plugin.
    // This observer is registered early to ensure iOS delivers all
    // queued transactions to the plugin when it attaches its own listener.
  }
}
