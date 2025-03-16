import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/auth_service.dart';
import '../../theme/app_theme.dart';

class RegisterPage extends StatefulWidget {
  static const String routeName = '/register';

  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      // Navigate to home page is handled by the auth state listener in app.dart
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('email-already-in-use')
            ? 'This email is already in use. Please try another email.'
            : 'An error occurred. Please try again later.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Create Account'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppTheme.primaryColor,
        ),
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
    child: Form(
    key: _formKey,
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
    Text(
    'Join Action Tracker',
    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
    fontWeight: FontWeight.bold,
    color: AppTheme.primaryColor,
    ),
    ),
    const SizedBox(height: 8),
    Text(
    'Create an account to track your actions and compete with others',
    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
    color: AppTheme.textSecondaryColor,
    ),
    ),
    const SizedBox(height: 32),
    TextFormField(
    controller: _nameController,
    decoration: const InputDecoration(
    labelText: 'Display Name',
    prefixIcon: Icon(Icons.person_outline),
    ),
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Please enter your name';
    }
    return null;
    },
    ),
    const SizedBox(height: 16),
    TextFormField(
    controller: _emailController,
    keyboardType: TextInputType.emailAddress,
    decoration: const InputDecoration(
    labelText: 'Email',
    prefixIcon: Icon(Icons.email_outlined),
    ),
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Please enter your email';
    }
    if (!value.contains('@') || !value.contains('.')) {
    return 'Please enter a valid email';
    }
    return null;
    },
    ),
    const SizedBox(height: 16),
    TextFormField(
    controller: _passwordController,
    obscureText: true,
    decoration: const InputDecoration(
    labelText: 'Password',
    prefixIcon: Icon(Icons.lock_outline),
    ),
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Please enter a password';
    }
    if (value.length < 6) {
    return 'Password must be at least 6 characters';
    }
    return null;
    },
    ),
    const SizedBox(height: 16),
    TextFormField(
    controller: _confirmPasswordController,
    obscureText: true,
    decoration: const InputDecoration(
    labelText: 'Confirm Password',
    prefixIcon: Icon(Icons.lock_outline),
    ),
    validator: (value) {
    if (value == null || value.isEmpty) {
    return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
    return 'Passwords do not match';
    }
    return null;
    },
    ),
    if (_errorMessage.isNotEmpty) ...[
    const SizedBox(height: 16),
    Text(
    _errorMessage,
      style: TextStyle(
        color: AppTheme.errorColor,
        fontSize: 14,
      ),
    ),
    ],
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: _isLoading ? null : _register,
        child: _isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Text('Create Account'),
      ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Text('Already have an account? Sign In'),
      ),
    ],
    ),
    ),
        ),
        ),
    );
  }
}