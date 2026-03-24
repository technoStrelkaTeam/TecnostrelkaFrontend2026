import 'dart:convert';

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

class AiInsights {
  final double rationalityScore;
  final List<String> recommendCancel;
  final List<String> recommendKeep;
  final List<String> alternatives;
  final String shortCommentRu;

  AiInsights({
    required this.rationalityScore,
    required this.recommendCancel,
    required this.recommendKeep,
    required this.alternatives,
    required this.shortCommentRu,
  });

  factory AiInsights.fromJson(Map<String, dynamic> json) {
    return AiInsights(
      rationalityScore: _asDouble(json['rationality_score']) ?? 0,
      recommendCancel: _stringList(json['recommend_cancel']),
      recommendKeep: _stringList(json['recommend_keep']),
      alternatives: _stringList(json['alternatives']),
      shortCommentRu: (json['short_comment_ru'] ?? '').toString(),
    );
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => _stringFromValue(e))
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
    if (value is Map) {
      final parsed = _stringFromValue(value);
      return parsed.trim().isEmpty ? <String>[] : [parsed];
    }
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    return <String>[];
  }

  static String _stringFromValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map) {
      final name = value['name'] ?? value['title'] ?? value['service'] ?? value['label'];
      if (name != null) {
        return name.toString();
      }
      return jsonEncode(value);
    }
    return value.toString();
  }
}
