import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

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
}
