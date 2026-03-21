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
  final DateTime nextBillingDate;
  final String category;
  final String status;

  Subscription({
    this.id,
    required this.name,
    required this.price,
    required this.billingPeriod,
    required this.nextBillingDate,
    required this.category,
    required this.status,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as int?,
      name: json['name'] as String,
      price: (json['cost'] as num).toDouble(),
      billingPeriod: json['type_interval'] as String,
      nextBillingDate: DateTime.parse(json['next_pay'] as String),
      category: json['category'] as String,
      status: 'Активная',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'billing_period': billingPeriod,
      'next_billing_date': nextBillingDate.toIso8601String(),
      'category': category,
      'status': status,
    };
  }
}

class SubscriptionDraft {
  final String name;
  final double price;
  final String billingPeriod;
  final DateTime nextBillingDate;
  final String category;
  final String status;

  SubscriptionDraft({
    required this.name,
    required this.price,
    required this.billingPeriod,
    required this.nextBillingDate,
    required this.category,
    required this.status,
  });
}
