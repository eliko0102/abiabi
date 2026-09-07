import 'package:flutter/material.dart';
import 'config/api_config.dart';
import 'services/mongo_auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'providers/auth_provider.dart';
import 'utils/error_handler.dart';

void main() {
  runApp(const AiBusinessAgentApp());
}

class AiBusinessAgentApp extends StatefulWidget {
  const AiBusinessAgentApp({super.key});

  @override
  State<AiBusinessAgentApp> createState() => _AiBusinessAgentAppState();
}

class _AiBusinessAgentAppState extends State<AiBusinessAgentApp> {
  late AuthProvider _authProvider;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Check if user is already authenticated
    // In a real app, you might check SharedPreferences or secure storage
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0B1120),
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'AI Business Agent',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1120),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4F46E5),
          secondary: Color(0xFF14B8A6),
          surface: Color(0xFF1A2332),
        ),
      ),
      home: _authProvider.isAuthenticated
          ? DashboardWrapper(authProvider: _authProvider)
          : LoginScreen(),
      routes: {
        '/login': (_) => LoginScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/dashboard': (_) => DashboardWrapper(authProvider: _authProvider),
      },
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('Route not found'),
          ),
        ),
      ),
    );
  }
}

/// Wrapper for authenticated screens
class DashboardWrapper extends StatefulWidget {
  final AuthProvider authProvider;

  const DashboardWrapper({
    super.key,
    required this.authProvider,
  });

  @override
  State<DashboardWrapper> createState() => _DashboardWrapperState();
}

class _DashboardWrapperState extends State<DashboardWrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Business Agent'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xoş gəlmisiniz, ${widget.authProvider.currentUser?['name'] ?? 'İstifadəçi'}!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'E-poçt: ${widget.authProvider.currentUser?['email'] ?? 'N/A'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (widget.authProvider.currentUser?['businessType'] != null)
                        Text(
                          'Biznes: ${widget.authProvider.currentUser?['businessType']}',
                          style: const TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Features Section
              const Text(
                'Mevcut Xüsusiyyətlər',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Chat Feature
              Card(
                child: ListTile(
                  leading: const Icon(Icons.chat),
                  title: const Text('AI Söhbəti'),
                  subtitle: const Text('AI assistenti ilə söhbəşə başlayın'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    ErrorHandler.showInfo(
                      context,
                      'Chat xüsusiyyəti tezliklə əlavə olunacaq',
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Location Analysis
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Məkan Analizi'),
                  subtitle: const Text('Biznes yerlərini analiz edin'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    ErrorHandler.showInfo(
                      context,
                      'Məkan analizi tezliklə əlavə olunacaq',
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // ROI Calculator
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calculate),
                  title: const Text('ROI Hesablaması'),
                  subtitle: const Text('Gəlir potensialını hesablayın'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    ErrorHandler.showInfo(
                      context,
                      'ROI hesablaması tezliklə əlavə olunacaq',
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Debug Info
              if (ApiConfig.backendUrl.contains('localhost'))
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🔧 Debug Info',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Backend URL: ${ApiConfig.backendUrl}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Token aktiv: ${widget.authProvider.token != null ? '✅' : '❌'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıxış'),
        content: const Text('Tətbiqdən çıxmaq istəyirsinizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ləğv Et'),
          ),
          TextButton(
            onPressed: () async {
              await widget.authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: const Text('Çıx'),
          ),
        ],
      ),
    );
  }
}
