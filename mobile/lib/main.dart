import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RivalRoomsApp());
}

class RivalRoomsApp extends StatelessWidget {
  const RivalRoomsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RivalRooms',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFB547),
          brightness: Brightness.dark,
          surface: const Color(0xFF17191F),
        ),
        scaffoldBackgroundColor: const Color(0xFF101116),
        useMaterial3: true,
      ),
      home: const _LaunchScreen(),
    );
  }
}

class _LaunchScreen extends StatelessWidget {
  const _LaunchScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sports_esports, size: 64, color: Color(0xFFFFB547)),
                const SizedBox(height: 20),
                Text('RIVALROOMS', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900, letterSpacing: 2.2,
                )),
                const SizedBox(height: 8),
                Text('Play together. Anywhere.', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 28),
                const Text('Independent build • Platform foundation'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
