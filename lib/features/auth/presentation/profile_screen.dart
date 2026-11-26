import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Student profile')),
      body: user == null
          ? Center(
              child: FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Go to sign in'),
              ),
            )
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: 440,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return const Text('Could not load your profile.');
                              }
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final profile = snapshot.data!.data();
                              if (profile == null) {
                                return const Text('Your student profile is missing.');
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile['displayName'] as String? ?? 'Student',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Email: ${profile['email'] ?? user.email ?? ''}'),
                                  Text('Programme: ${profile['major'] ?? ''}'),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton(
                            onPressed: () async {
                              try {
                                await FirebaseAuth.instance.signOut();
                                if (context.mounted) context.go('/login');
                              } on FirebaseAuthException {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not sign out. Try again.'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Sign out'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}