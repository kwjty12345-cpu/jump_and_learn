import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _major = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  User? _createdUser;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _major.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    return (value ?? '').trim().isEmpty ? 'This field is required.' : null;
  }

  Future<void> _register() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final name = _name.text.trim();
    final email = _email.text.trim();
    final major = _major.text.trim();
    final password = _password.text;

    try {
      var user = _createdUser;
      if (user == null) {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);
        user = credential.user!;
        _createdUser = user;
      }

      final profile = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final existing = await transaction.get(profile);
        if (existing.exists) return;

        transaction.set(profile, {
          'displayName': name,
          'email': user!.email ?? email,
          'major': major,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) context.go('/lobby');
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = switch (error.code) {
          'email-already-in-use' => 'This email already has an account.',
          'invalid-email' => 'Enter a valid email address.',
          'weak-password' => 'Choose a stronger password.',
          'operation-not-allowed' => 'Email registration is unavailable.',
          _ => 'Could not create your account. Please try again.',
        };
      });
    } on FirebaseException {
      if (!mounted) return;
      setState(() {
        _error = 'Your account was created, but your profile could not be saved. '
            'Tap Retry profile save.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const plum = Color(0xFF693850);
    final accountCreated = _createdUser != null;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF30182E), Color(0xFF78435B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SizedBox(
                  width: double.infinity,
                  child: Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Create student account',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(color: plum, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            _field('Display name', _name),
                            _field(
                              'Email',
                              _email,
                              enabled: !accountCreated,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            _field('Programme / Major', _major),
                            if (!accountCreated) ...[
                              _field('Password', _password, obscure: true),
                              _field(
                                'Confirm password',
                                _confirmPassword,
                                obscure: true,
                                validator: (value) => value == _password.text
                                    ? null
                                    : 'Passwords do not match.',
                              ),
                            ],
                            if (_error != null)
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            const SizedBox(height: 16),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: plum),
                              onPressed: _saving ? null : _register,
                              child: Text(
                                _saving
                                    ? 'Saving…'
                                    : accountCreated
                                    ? 'Retry profile save'
                                    : 'Create account',
                              ),
                            ),
                            TextButton(
                              onPressed: _saving ? null : () => context.go('/login'),
                              child: const Text('Back to sign in'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled && !_saving,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator ?? _required,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}