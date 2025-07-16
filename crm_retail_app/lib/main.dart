import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/login_screen.dart';
import 'features/theme/misty_dark_theme.dart';
import 'features/theme/theme_notifier.dart';
import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Explicitly initialize UserProvider and call init
  final userProvider = UserProvider();
  await userProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider.value(
          value: userProvider,
        ), // ✅ Inject initialized instance
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, theme, _) {
        return MaterialApp(
          title: 'Retail CRM',
          theme: ThemeData.light(),
          darkTheme: mistyDarkTheme,
          themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          debugShowCheckedModeBanner: false,
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            // '/dashboard': (context) => const DashboardScreen(),
          },
        );
      },
    );
  }
}
