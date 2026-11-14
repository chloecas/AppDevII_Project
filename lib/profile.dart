import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app_drawer.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.bio,
    this.createdAt,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? bio;
  final DateTime? createdAt;

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return UserProfile(
      uid: doc.id,
      displayName: (d['displayName'] ?? 'Trainer') as String,
      email: (d['email'] ?? '') as String,
      photoUrl: d['photoUrl'] as String?,
      bio: d['bio'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      drawer: const AppDrawer(),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userRef.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Could not load profile\n${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // First login: no document yet, so create one from the auth account.
          if (!snap.data!.exists) {
            userRef.set({
              'displayName': user.displayName ?? 'Trainer',
              'email': user.email ?? '',
              'photoUrl': user.photoURL,
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            return const Center(child: CircularProgressIndicator());
          }

          final profile = UserProfile.fromDoc(snap.data!);
          return _ProfileBody(profile: profile, userRef: userRef);
        },
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile, required this.userRef});

  final UserProfile profile;
  final DocumentReference<Map<String, dynamic>> userRef;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final joined = profile.createdAt;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundImage:
            profile.photoUrl != null ? NetworkImage(profile.photoUrl!) : null,
            child: profile.photoUrl == null
                ? Text(
              profile.displayName.isNotEmpty
                  ? profile.displayName[0].toUpperCase()
                  : '?',
              style: textTheme.headlineMedium,
            )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(profile.displayName, style: textTheme.headlineSmall)),
        Center(child: Text(profile.email, style: textTheme.bodyMedium)),
        if (joined != null)
          Center(
            child: Text(
              'Joined ${joined.year}-${joined.month.toString().padLeft(2, '0')}-${joined.day.toString().padLeft(2, '0')}',
              style: textTheme.bodySmall,
            ),
          ),
        if (profile.bio != null && profile.bio!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(profile.bio!, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 20),

        // Collection stats
        FutureBuilder<AggregateQuerySnapshot>(
          future: userRef.collection('collection').count().get(),
          builder: (context, snap) {
            final count = snap.data?.count;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.style),
                title: const Text('Cards in collection'),
                trailing: Text(
                  count?.toString() ?? '-',
                  style: textTheme.titleLarge,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        FilledButton.icon(
          icon: const Icon(Icons.edit),
          label: const Text('Edit profile'),
          onPressed: () => _edit(context),
        ),
      ],
    );
  }

  Future<void> _edit(BuildContext context) async {
    final nameCtrl = TextEditingController(text: profile.displayName);
    final bioCtrl = TextEditingController(text: profile.bio ?? '');

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            TextField(
              controller: bioCtrl,
              decoration: const InputDecoration(labelText: 'Bio'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );

    if (save == true) {
      final name = nameCtrl.text.trim();
      await userRef.set({
        if (name.isNotEmpty) 'displayName': name,
        'bio': bioCtrl.text.trim(),
      }, SetOptions(merge: true));
    }
  }
}