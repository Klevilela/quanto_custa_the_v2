import 'package:flutter/material.dart';
import 'package:quanto_custa_the_v2/view/homepage/homepage.dart';
import 'package:quanto_custa_the_v2/view/login/pagina_login.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue, // Cor principal (AppBar, botões, etc.)
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login',
      routes: <String, WidgetBuilder> {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
      
    );
  }
}
