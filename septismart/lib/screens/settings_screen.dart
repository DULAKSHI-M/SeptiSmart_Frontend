import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../login_screen.dart'; // adjust if your path differs

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  User? get _user => FirebaseAuth.instance.currentUser;

  String _displayName() {
    final u = _user;
    if (u == null) return 'Guest';
    // Prefer displayName; otherwise fall back to email (before the @ if possible)
    if ((u.displayName ?? '').trim().isNotEmpty) return u.displayName!.trim();
    final email = u.email ?? '';
    if (email.contains('@')) return email.split('@').first;
    return email.isNotEmpty ? email : 'User';
  }

  String _email() => _user?.email ?? '—';

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Go to Login and clear the stack
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _displayName();
    final email = _email();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User card
          Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  name.isNotEmpty ? name.trim()[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(name),
              subtitle: Text(email),
            ),
          ),
          const SizedBox(height: 16),

          // Tanks section (hardcoded)
          const Text(
            'Tanks',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.water_drop), // ✅ valid icon
                  title: Text('Tank 1'),
                  subtitle: Text('Configured'),
                  
                ),
                Divider(height: 0),
                ListTile(
                  leading: Icon(Icons.water_drop), // ✅ use same or another icon
                  title: Text('Tank 2'),
                  subtitle: Text('Configured'),
                 
                ),

              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout button
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
    );
  }
}
