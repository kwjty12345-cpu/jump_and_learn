import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSigningIn = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Enter your email and password.');
      return;
    }

    setState(() {
      _isSigningIn = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) context.go('/lobby');
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      final message = switch (error.code) {
        'invalid-email' => 'Enter a valid email address.',
        'invalid-credential' || 'wrong-password' || 'user-not-found' =>
          'The email or password is incorrect.',
        'network-request-failed' => 'Check your internet connection and try again.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'operation-not-allowed' => 'Email sign-in is currently unavailable.',
        _ => 'Could not sign in. Please try again.',
      };

      setState(() => _errorMessage = message);
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const plum = Color(0xFF693850);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF30182E), Color(0xFF78435B)],
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
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Color(0xFFF4E8EF),
                              child: Icon(Icons.layers_outlined, color: plum),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Jump & Learn',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: plum,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Sign in to your student account.',
                            style: TextStyle(color: Color(0xFF645862)),
                          ),
                          const SizedBox(height: 28),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _fieldDecoration(
                              'Email',
                              Icons.email_outlined,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: _fieldDecoration(
                              'Password',
                              Icons.lock_outline,
                            ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
  onPressed: _isSigningIn ? null : _signIn,
  style: FilledButton.styleFrom(
    minimumSize: const Size(0, 48),
    backgroundColor: plum,
    foregroundColor: Colors.white,
  ),
  child: Text(_isSigningIn ? 'Signing in…' : 'Sign in'),
),
TextButton(
  onPressed: _isSigningIn ? null : () => context.go('/register'),
  child: const Text('Create a student account'),
),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
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
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFFCF8FB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}