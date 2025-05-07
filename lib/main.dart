import 'package:calo_snap/core/services/fake_gemini_service.dart';
import 'package:calo_snap/features/meals/presentation/screens/meal_history_screen.dart';
import 'package:calo_snap/features/meals/presentation/screens/recognize_food_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/services/gemini_service.dart';

const geminiApiKey = 'AIzaSyAIHDwdy6qj3UbEgZyZ77xPSIMNoFPCOaI';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ProviderScope(
      overrides: [
        geminiServiceProvider.overrideWith((ref) => FakeGeminiService()),
      ],
      child: CaloSnapApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Scaffold(body: Center(child: Text('Hello World!'))),
    );
  }
}

class CaloSnapApp extends ConsumerWidget {
  const CaloSnapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'CaloSnap',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const RecognizeFoodScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const MealHistoryScreen(),
    ),
  ],
);
