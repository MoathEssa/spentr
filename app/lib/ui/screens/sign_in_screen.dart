import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../widgets/placeholder_view.dart';

/// Sign in and Sign up share one screen; [_isSignUp] switches between them.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isSignUp = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_isSignUp ? 'Create your account' : 'Welcome to Spentr')),
      body: PlaceholderView(
        purpose: 'Sign in or create an account so shifts can sync and be '
            'restored on a new phone.',
        states: const [
          'Default',
          'Invalid email',
          'Password required',
          'Signing in…',
          'Wrong credentials',
          'Offline',
        ],
        actions: [
          if (_isSignUp)
            PlaceholderAction(
              'Create account',
              Icons.person_add_alt_1,
              () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.rateSetup),
              primary: true,
            )
          else
            PlaceholderAction(
              'Sign in',
              Icons.login,
              () => Navigator.pushReplacementNamed(context, AppRoutes.home),
              primary: true,
            ),
          PlaceholderAction(
            _isSignUp
                ? 'Already registered? Sign in'
                : 'New to Spentr? Create an account',
            Icons.swap_horiz,
            () => setState(() => _isSignUp = !_isSignUp),
          ),
        ],
      ),
    );
  }
}
