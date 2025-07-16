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
        ChangeNotifierProvider.value(value: userProvider),
      ],
      child: MyApp(userProvider: userProvider), // ✅ FIXED HERE
    ),
  );
}

class MyApp extends StatelessWidget {
  final UserProvider userProvider;
  const MyApp({super.key, required this.userProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider.value(value: userProvider),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'Retail CRM',
            theme: ThemeData.light(),
            darkTheme: mistyDarkTheme,
            themeMode: theme.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            initialRoute: '/login',
            routes: {'/login': (context) => const LoginScreen()},
          );
        },
      ),
    );
  }
}
