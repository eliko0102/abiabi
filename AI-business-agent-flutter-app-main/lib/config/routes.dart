import 'package:flutter/material.dart';

/// App Routes Configuration
class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String dashboard = '/dashboard';
  static const String splash = '/splash';

  static Map<String, Function> getRoutes() {
    return {
      login: (_) => const SizedBox(),
      signup: (_) => const SizedBox(),
      dashboard: (_) => const SizedBox(),
      splash: (_) => const SizedBox(),
    };
  }
}
