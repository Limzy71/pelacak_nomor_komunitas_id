import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PhoneRepApp());
}

class PhoneRepApp extends StatefulWidget {
  const PhoneRepApp({super.key});

  @override
  State<PhoneRepApp> createState() => _PhoneRepAppState();
}

class _PhoneRepAppState extends State<PhoneRepApp> {
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _apiService,
      builder: (context, child) {
        return MaterialApp(
          title: 'PhoneRep Mobile Check',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: HomeScreen(apiService: _apiService),
        );
      },
    );
  }
}
