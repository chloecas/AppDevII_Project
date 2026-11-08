import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_project/app_drawer.dart';

import 'carddex_api.dart';
import 'collection.dart';

// Palette shared with the login screen.
const _ink = Color(0xFF14213D);
const _teal = Color(0xFF1F7A8C);
const _red = Color(0xFFD62828);
const _cream = Color(0xFFFFF8E1);
const _background = Color(0xFFFFF6CC);

final _api = CardDexApi();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _ink,
        elevation: 0,
        title: Text('Home Page', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      /// Nav Bar
      drawer: const AppDrawer(),


      body: Center(
        child: Text(
          'Welcome to Card Vault',
          style: TextStyle(fontSize: 18.0),
        ),
      ),
    );
  }
}
