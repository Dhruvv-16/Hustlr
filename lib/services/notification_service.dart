import '../models/notification_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  static void initialize() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground Notification: ${message.notification?.title}");
    });

    // When notification is clicked
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final route = message.data['route'];

      print("Clicked Notification -> Route: $route");

      if (route == "dashboard") {
        // Navigator.pushNamed(context, '/dashboard');
      } else if (route == "wallet") {
        // Navigator.pushNamed(context, '/wallet');
      } else if (route == "claims") {
        // Navigator.pushNamed(context, '/claims');
      }
    });
  }

  final List<HustlrNotification> _notifications = [];

  List<HustlrNotification> get all =>
      _notifications..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void markAllRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
  }

  void markRead(String id) {
    _notifications.firstWhere((n) => n.id == id).isRead = true;
  }

  void addRainAlert(String zone) {
    _notifications.insert(0, HustlrNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'rain_alert',
      title: 'Heavy rain expected in $zone',
      body: 'Your coverage auto-activates. No action needed.',
      color: 'blue',
      createdAt: DateTime.now(),
    ));
  }

  void addClaimApproved(int tranche1Amount) {
    _notifications.insert(0, HustlrNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'claim_approved',
      title: 'Claim approved — ₹$tranche1Amount credited',
      body: '70% of your payout has been added to your wallet.',
      color: 'green',
      createdAt: DateTime.now(),
    ));
  }

  void addClaimCreated({required String triggerType, required int amount}) {
    _notifications.insert(0, HustlrNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'claim_created',
      title: '$triggerType — Claim Filed',
      body: 'Your claim has been created. Awaiting verification.',
      color: 'blue',
      createdAt: DateTime.now(),
    ));
  }

  void addWalletCredited({required int amount}) {
    _notifications.insert(0, HustlrNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'wallet_credited',
      title: '₹$amount credited to wallet',
      body: 'Payout has been added to your wallet balance.',
      color: 'green',
      createdAt: DateTime.now(),
    ));
  }

  void addDisruptionAlert({required String triggerType, required String zone}) {
    _notifications.insert(0, HustlrNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'disruption_alert',
      title: '$triggerType in $zone',
      body: 'Disruption detected in your zone. Coverage may apply.',
      color: 'amber',
      createdAt: DateTime.now(),
    ));
  }

  void addPremiumDeducted(int amount) {
    _notifications.insert(0, HustlrNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'premium_deducted',
      title: 'Weekly premium deducted — ₹$amount',
      body: 'You are covered for this week. Stay safe.',
      color: 'green',
      createdAt: DateTime.now(),
    ));
  }

  // Only call this when user has NO active policy
  void addMissedPayout(int amount) {
    _notifications.insert(0, HustlrNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'missed_payout',
      title: 'You missed ₹$amount today',
      body: 'If you were covered, this would be in your wallet right now.',
      color: 'amber',
      createdAt: DateTime.now(),
    ));
  }

  void addShiftPaused() {
    _notifications.insert(0, HustlrNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'shift_paused',
      title: 'GPS signal lost — coverage paused',
      body: 'Re-enable location to resume your shift protection. Claims during this gap cannot be verified.',
      color: 'red',
      createdAt: DateTime.now(),
    ));
  }

  void addShiftResumed() {
    _notifications.insert(0, HustlrNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'shift_resumed',
      title: 'Location restored — you\'re covered again',
      body: 'Your shift protection has resumed. The gap has been logged.',
      color: 'green',
      createdAt: DateTime.now(),
    ));
  }

  void addFraudAlert() {
    _notifications.insert(0, HustlrNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: 'fraud_alert',
      title: 'Suspicious Location Activity',
      body: 'Your coverage is temporarily suspended due to impossible GPS jumping (Velocity Fraud).',
      color: 'red',
      createdAt: DateTime.now(),
    ));
  }
}
