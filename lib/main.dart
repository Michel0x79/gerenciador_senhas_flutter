import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/password_provider.dart';
import 'screens/auth_screen.dart';
// import 'screens/home_screen.dart';
import 'services/auth_service.dart';
// import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => PasswordProvider())],
      child: MaterialApp(
        title: 'Gerenciador de Senhas',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 2),
        ),
        home: FutureBuilder<bool>(
          future: AuthService().hasMasterPassword(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return const AuthScreen();
          },
        ),
      ),
    );
  }
}
