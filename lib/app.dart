import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'models.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

class SubscriptionApp extends StatefulWidget {
  const SubscriptionApp({super.key});

  @override
  State<SubscriptionApp> createState() => _SubscriptionAppState();
}

class _SubscriptionAppState extends State<SubscriptionApp> {
  late final ApiClient _apiClient;
  UserProfile? _user;
  String? _token;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
  }

  void _handleAuth(AuthResult result) {
    setState(() {
      _user = result.user;
      _token = result.token;
      _apiClient.updateToken(result.token);
    });
  }

  void _handleLogout() {
    setState(() {
      _user = null;
      _token = null;
      _apiClient.updateToken(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Центр подписок',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: _token == null
          ? AuthScreen(apiClient: _apiClient, onAuth: _handleAuth)
          : HomeScreen(
              apiClient: _apiClient,
              user: _user!,
              onLogout: _handleLogout,
            ),
    );
  }
}
