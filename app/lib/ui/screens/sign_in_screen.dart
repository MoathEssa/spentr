import 'package:flutter/material.dart';

import '../../core/routes.dart';

/// Sign in and Sign up share one screen; [_isSignUp] switches between them.
///
/// The form validates the email and password locally. The ASP.NET Core
/// account API (E6) is Phase 4 work, so a valid form continues to the app
/// without a server check; shifts stay on this phone until then.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  static const emailFieldKey = Key('sign-in-email');
  static const passwordFieldKey = Key('sign-in-password');
  static const confirmFieldKey = Key('sign-in-confirm');

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static const _minPasswordLength = 8;

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _isSignUp = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your email address.';
    if (!_emailPattern.hasMatch(text)) {
      return 'Enter a valid email, such as name@example.com.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Enter your password.';
    if (_isSignUp && text.length < _minPasswordLength) {
      return 'Use at least $_minPasswordLength characters.';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if ((value ?? '').isEmpty) return 'Enter the password again.';
    if (value != _password.text) return 'The passwords do not match.';
    return null;
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _confirm.clear();
    });
    _formKey.currentState?.reset();
  }

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_isSignUp) {
      Navigator.pushNamed(context, AppRoutes.rateSetup);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
          title: Text(_isSignUp ? 'Create your account' : 'Welcome to Spentr')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Text(
                _isSignUp
                    ? 'Track your shifts and see what your time is worth.'
                    : 'Sign in to keep tracking your time.',
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              TextFormField(
                key: SignInScreen.emailFieldKey,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                  border: OutlineInputBorder(),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: SignInScreen.passwordFieldKey,
                controller: _password,
                obscureText: !_showPassword,
                textInputAction:
                    _isSignUp ? TextInputAction.next : TextInputAction.done,
                onFieldSubmitted: _isSignUp ? null : (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  helperText: _isSignUp
                      ? 'At least $_minPasswordLength characters'
                      : null,
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    tooltip: _showPassword ? 'Hide password' : 'Show password',
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(_showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                  ),
                ),
                validator: _validatePassword,
              ),
              if (_isSignUp) ...[
                const SizedBox(height: 16),
                TextFormField(
                  key: SignInScreen.confirmFieldKey,
                  controller: _confirm,
                  obscureText: !_showPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateConfirm,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submit,
                icon: Icon(_isSignUp ? Icons.person_add_alt_1 : Icons.login),
                label: Text(_isSignUp ? 'Create account' : 'Sign in'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _toggleMode,
                child: Text(_isSignUp
                    ? 'Already registered? Sign in'
                    : 'New to Spentr? Create an account'),
              ),
              const SizedBox(height: 16),
              Card(
                color: scheme.secondaryContainer,
                child: ListTile(
                  leading: Icon(Icons.phone_android,
                      color: scheme.onSecondaryContainer),
                  title: Text(
                    'Cloud accounts are coming soon. For now your shifts are '
                    'saved on this phone.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSecondaryContainer),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
