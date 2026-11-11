import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_project/main.dart';
import 'dashboard.dart';
import 'collection.dart';
import 'main.dart';

// Palette shared with the login screen.
const _ink = Color(0xFF14213D);
const _teal = Color(0xFF1F7A8C);
const _red = Color(0xFFD62828);
const _cream = Color(0xFFFFF8E1);
const _background = Color(0xFFFFF6CC);


/// REUSABLE APP_DRAW FILE SO NO NEED TO HAVE THIS CODE EVERYWHERE

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.displayName ?? 'No Name'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: _red,
              child: Text((user?.displayName ?? user?.email ?? '?')[0].toUpperCase(),
                style: const TextStyle(fontSize: 24.0),),
            ),

          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('My Home'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.collections),
            title: Text('My collection'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CollectionScreen()),
              );
            },
          ),
          ListTile(
              leading: Icon(Icons.settings),
              title: Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (!context.mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }

          ),
        ],
      ),
    );
  }
}
