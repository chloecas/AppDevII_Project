import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'registration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

 runApp(const CardVaultApp());
}


const String appName = 'CardVault';

class CardVaultApp extends StatelessWidget {
  const CardVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFFD62828);
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC53939),
          primary: ink,
          surface: const Color(0xFFEEF1F5),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF6CC),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCBD2DC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFCBD2DC)),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _logIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter your email and password.');
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = 'That email address is not valid.';
          break;
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Try again later.';
          break;
        default:
          message = e.message ?? 'Login failed.';
      }
      _showMessage(message);
    }
  }

  void _forgotPassword() {
    // TODO: open password reset flow.
  }

  void _goToSignUp() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const Registration()));
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: _CardLogo()),
                  const SizedBox(height: 24),
                  Text(appName,
                      textAlign: TextAlign.center,
                      style: text.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Log in to track your cards and view your collection',
                      textAlign: TextAlign.center,
                      style: text.bodyMedium
                          ?.copyWith(color: Color(0xFFC53939))),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _hidePassword ? 'Show password' : 'Hide password',
                        icon: Icon(_hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _logIn,
                    style: FilledButton.styleFrom(
                      backgroundColor: Color(0xFFF5A623),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Log in'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('New here?',
                            style: text.bodySmall
                                ?.copyWith(color: Color(0xFFC53939))),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: _goToSignUp,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color:Color(0xFFF5A623)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Create an account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardLogo extends StatelessWidget {
  const _CardLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 188,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Transform.rotate(
              angle: -0.07,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE066), Color(0xFFF5A623)],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Basic',
                              style: TextStyle(
                                  fontSize: 9, fontWeight: FontWeight.w600)),
                          Text('HP 100',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFD62828))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: const Color(0xFFB8C0CC), width: 2),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF7B2FF7),
                                Color(0xFFF107A3),
                                Color(0xFFFF9F1C),
                              ],
                            ),
                          ),
                          child: const Stack(
                            children: [
                              Center(
                                child: Icon(Icons.auto_awesome,
                                    size: 44, color: Colors.white),
                              ),
                              Positioned(
                                top: 8,
                                left: 10,
                                child: Icon(Icons.star,
                                    size: 12, color: Color(0xFFFFE066)),
                              ),
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Icon(Icons.star,
                                    size: 10, color: Color(0xFF9EF0FF)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _line(0xFF1F7A8C, 1.0),
                      const SizedBox(height: 4),
                      _line(0xFFD62828, 0.7),
                      const SizedBox(height: 4),
                      _line(0xFFB8C0CC, 0.5),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -10,
            right: -14,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF14213D),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(color: Color(0x40000000), blurRadius: 6),
                ],
              ),
              child: const Text('10',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(int color, double widthFactor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: 5,
          decoration: BoxDecoration(
            color: Color(color),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}