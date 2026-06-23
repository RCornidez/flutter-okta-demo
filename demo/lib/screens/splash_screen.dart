import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/auth_client.dart';
import '../env/environment_cubit.dart';
import '../env/environment_state.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _channel = MethodChannel('com.okta.trial_8077266/auth');
  AuthClient? _auth;

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler(_onMethodCall);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkInitialLink());
  }

  // Called by native when the app is already running and receives a deep link.
  Future<dynamic> _onMethodCall(MethodCall call) async {
    if (call.method == 'onLink') {
      await _handleCallbackUri(call.arguments as String);
    }
  }

  // Called on startup in case the app was launched cold via the callback URI.
  Future<void> _checkInitialLink() async {
    final uri = await _channel.invokeMethod<String>('getInitialLink');
    if (uri != null && mounted) await _handleCallbackUri(uri);
  }

  Future<void> _handleCallbackUri(String uri) async {
    if (_auth == null) return;
    try {
      final tokens = await _auth!.handleCallback(uri);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(tokens: tokens)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EnvironmentCubit, EnvironmentState>(
      builder: (context, env) {
        if (env.domain.isNotEmpty) _auth ??= AuthClient(env);
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Icon(Icons.lock_outline,
                      size: 72, color: Colors.deepPurple),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to your account or create a new one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed:
                        _auth != null ? () => _auth!.loginRedirect() : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child:
                        const Text('Login', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _auth != null
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      SignupScreen(auth: _auth!)),
                            )
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Sign Up',
                        style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
