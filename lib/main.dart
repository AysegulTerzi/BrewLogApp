import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/database_service.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'package:firedart/firedart.dart';

const apiKey = 'AIzaSyBJ_VQLWV0f7Zl8d4wKjiWBC6LsF4sVPYY';
const projectId = 'brewlogapp';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Firestore.initialize(projectId);
  FirebaseAuth.initialize(apiKey, VolatileStore());

  runApp(const BrewLogApp());
}

class BrewLogApp extends StatelessWidget {
  const BrewLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DatabaseService>(
          create: (_) => DatabaseService(),
        ),
      ],
      child: MaterialApp(
        title: 'Brew Log',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const HomeScreen(),
      ),
    );
  }
}
