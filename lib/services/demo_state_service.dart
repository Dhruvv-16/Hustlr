import 'package:hive/hive.dart';
import '../../services/storage_service.dart';

class DemoStateService {
  static final instance = DemoStateService._();
  DemoStateService._();

  List<Map<String, dynamic>> _claims = [];
  int _walletBalance = 0;
  List<Map<String, dynamic>> _transactions = [];

  List<Map<String, dynamic>> get claims => List.from(_claims);
  int get walletBalance => _walletBalance;
  List<Map<String, dynamic>> get transactions => List.from(_transactions);

  void addClaim(Map<String, dynamic> claim) {
    _claims.insert(0, claim);
  }

  void approveClaim(String claimId) {
    final idx = _claims.indexWhere((c) => c['id'] == claimId);
    if (idx >= 0) {
      _claims[idx] = Map.from(_claims[idx])..['status'] = 'APPROVED';
    }
  }

  void creditWallet(int amount, String description) {
    _walletBalance += amount;
    _transactions.insert(0, {
      'id':          'TXN_${DateTime.now().millisecondsSinceEpoch}',
      'amount':      amount,
      'type':        'credit',
      'description': description,
      'created_at':  DateTime.now().toIso8601String(),
    });
  }

  void debitWallet(int amount, String description) {
    _walletBalance -= amount;
    _transactions.insert(0, {
      'id':          'TXN_${DateTime.now().millisecondsSinceEpoch}',
      'amount':      -amount,
      'type':        'debit',
      'description': description,
      'created_at':  DateTime.now().toIso8601String(),
    });
  }

  Future<void> reset() async {
    _claims.clear();
    _walletBalance = 0;
    _transactions.clear();
    // Also clear storage if implemented
    await StorageService.instance.clearDemoState();
  }
}
