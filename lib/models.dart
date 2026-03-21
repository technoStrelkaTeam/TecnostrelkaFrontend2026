class UserProfile {
  final int id;
  final String name;
  final String? username;
  final String email;

  UserProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String?,
      email: json['email'] as String,
    );
  }
}

class AuthResult {
  final String token;
  final UserProfile user;

  AuthResult({required this.token, required this.user});
}

class Subscription {
  final int? id;
  final String name;
  final double price;
  final String billingPeriod;
  final int interval;
  final DateTime nextBillingDate;
  final String category;

  Subscription({
    this.id,
    required this.name,
    required this.price,
    required this.billingPeriod,
    required this.interval,
    required this.nextBillingDate,
    required this.category,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final rawPeriod = (json['type_interval'] ?? json['billing_period']) as String;
    final normalizedPeriod = _normalizeBillingPeriod(rawPeriod);
    return Subscription(
      id: json['id'] as int?,
      name: json['name'] as String,
      price: ((json['cost'] ?? json['price']) as num).toDouble(),
      billingPeriod: normalizedPeriod,
      interval: (json['interval'] ?? 1) as int,
      nextBillingDate: DateTime.parse(
        (json['next_pay'] ?? json['next_billing_date']) as String,
      ),
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cost': price,
      'type_interval': billingPeriod,
      'interval': interval,
      'next_pay': nextBillingDate.toIso8601String(),
      'category': category,
    };
  }

  static String _normalizeBillingPeriod(String value) {
    switch (value) {
      case 'monthly':
        return 'month';
      case 'yearly':
        return 'year';
      case 'weekly':
        return 'week';
      default:
        return value;
    }
  }
}

class SubscriptionDraft {
  final String name;
  final double price;
  final String billingPeriod;
  final int interval;
  final DateTime nextBillingDate;
  final String category;

  SubscriptionDraft({
    required this.name,
    required this.price,
    required this.billingPeriod,
    required this.interval,
    required this.nextBillingDate,
    required this.category,
  });
}
