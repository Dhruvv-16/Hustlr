import 'package:equatable/equatable.dart';

/// Flat-priced plan tiers. Prices never vary per worker — they are fixed product SKUs.
enum PlanTier { basic, standard, full, elite }

extension PlanTierPrice on PlanTier {
  int get weeklyPremium => switch (this) {
        PlanTier.basic => 29,
        PlanTier.standard => 49,
        PlanTier.full => 79,
        PlanTier.elite => 109,
      };

  String get displayName => switch (this) {
        PlanTier.basic => 'Basic Shield',
        PlanTier.standard => 'Standard Shield',
        PlanTier.full => 'Full Shield',
        PlanTier.elite => 'Elite Shield',
      };

  String get apiKey => switch (this) {
        PlanTier.basic => 'basic',
        PlanTier.standard => 'standard',
        PlanTier.full => 'full',
        PlanTier.elite => 'elite',
      };

  static PlanTier fromString(String s) {
    return PlanTier.values.firstWhere(
      (t) => t.apiKey == s.toLowerCase(),
      orElse: () => PlanTier.standard,
    );
  }
}

enum PolicyStatus { active, expired, cancelled, pending }

extension PolicyStatusLabel on PolicyStatus {
  static PolicyStatus fromString(String s) {
    return switch (s.toLowerCase()) {
      'active' => PolicyStatus.active,
      'expired' => PolicyStatus.expired,
      'cancelled' => PolicyStatus.cancelled,
      _ => PolicyStatus.pending,
    };
  }

  String get displayLabel => switch (this) {
        PolicyStatus.active => 'ACTIVE',
        PolicyStatus.expired => 'EXPIRED',
        PolicyStatus.cancelled => 'CANCELLED',
        PolicyStatus.pending => 'PENDING',
      };
}

/// Immutable domain model for an insurance policy.
/// Separate from [PolicyModel] in mock_data_service.dart.
class Policy extends Equatable {
  final String id;
  final String userId;
  final PlanTier tier;
  final PolicyStatus status;
  final DateTime? startDate;
  final DateTime? endDate;
  final int basePremium;
  final int weeklyPremium;

  const Policy({
    required this.id,
    required this.userId,
    required this.tier,
    required this.status,
    this.startDate,
    this.endDate,
    required this.basePremium,
    required this.weeklyPremium,
  });

  factory Policy.fromJson(Map<String, dynamic> json) {
    final tierStr = json['plan_tier'] as String? ?? 'standard';
    final statusStr = json['status'] as String? ?? 'pending';
    final startStr = json['start_date'] as String?;
    final endStr = json['end_date'] as String?;

    return Policy(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      tier: PlanTierPrice.fromString(tierStr),
      status: PolicyStatusLabel.fromString(statusStr),
      startDate: startStr != null ? DateTime.tryParse(startStr) : null,
      endDate: endStr != null ? DateTime.tryParse(endStr) : null,
      basePremium: (json['base_premium'] as num?)?.toInt() ?? 0,
      weeklyPremium: (json['weekly_premium'] as num?)?.toInt() ?? 0,
    );
  }

  Policy copyWith({
    String? id,
    String? userId,
    PlanTier? tier,
    PolicyStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? basePremium,
    int? weeklyPremium,
  }) {
    return Policy(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      basePremium: basePremium ?? this.basePremium,
      weeklyPremium: weeklyPremium ?? this.weeklyPremium,
    );
  }

  bool get isActive => status == PolicyStatus.active;

  @override
  List<Object?> get props => [
        id,
        userId,
        tier,
        status,
        startDate,
        endDate,
        basePremium,
        weeklyPremium,
      ];
}
