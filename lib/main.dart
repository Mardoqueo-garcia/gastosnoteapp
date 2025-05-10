import 'package:flutter/material.dart';
import 'package:gastosnoteapp/screen/home_screen.dart';
import 'package:gastosnoteapp/screen/edit_gasto_screen.dart';


void main() {
  runApp(const GastoNoteApp());
}

class GastoNoteApp extends StatelessWidget {
  const GastoNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GastosNotes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),

        // para poder navegar en el model hacia la pagina edit
        routes: {
          '/edit': (context) => const EditGastoScreen(),
        },
    );
  }
}