import 'package:flutter/material.dart';
import 'screens/balance_screen.dart';
import 'screens/login_admin.dart';

void main() {
  // Certifique-se de que o binding do Flutter esteja inicializado
  WidgetsFlutterBinding.ensureInitialized();
  runApp(PeseiApp());
}

class PeseiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pesei!',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      // Rota inicial é a tela de pesagem
      initialRoute: '/',
      routes: {
        '/': (context) => BalanceScreen(),
        // Rota para login admin
        '/admin_login': (context) => LoginAdmin(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
