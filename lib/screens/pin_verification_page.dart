import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/gradient_background.dart';
import 'home_page.dart';
import 'auth_page.dart';

class PinVerificationPage extends StatefulWidget {
  const PinVerificationPage({Key? key}) : super(key: key);

  @override
  State<PinVerificationPage> createState() => _PinVerificationPageState();
}

class _PinVerificationPageState extends State<PinVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  bool _obscurePin = true;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handlePinVerification() async {
    if (_formKey.currentState!.validate()) {
      final result = await _authService.verifyPin(_pinController.text);

      if (!mounted) return;

      if (result) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid PIN'),
            backgroundColor: Colors.red,
          ),
        );
        _pinController.clear();
      }
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildAppLogo(),
                    const SizedBox(height: 32),
                    _buildTitle(),
                    const SizedBox(height: 8),
                    _buildSubtitle(),
                    const SizedBox(height: 48),
                    _buildPinField(),
                    const SizedBox(height: 32),
                    _buildVerifyButton(),
                    const SizedBox(height: 16),
                    _buildLogoutButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppLogo() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.cyanAzure.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'ZapNotes',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.cyanAzure,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Enter Your PIN',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.cyanAzure,
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Enter your PIN to access ZapNotes',
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildPinField() {
    return AuthTextField(
      controller: _pinController,
      labelText: 'PIN',
      prefixIcon: Icons.pin_outlined,
      obscureText: _obscurePin,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.cyanAzure,
        ),
        onPressed: () {
          setState(() {
            _obscurePin = !_obscurePin;
          });
        },
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your PIN';
        }
        return null;
      },
    );
  }

  Widget _buildVerifyButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _handlePinVerification,
        style: ElevatedButton.styleFrom(
          shadowColor: AppColors.cyanAzure.withOpacity(0.5),
        ),
        child: const Text(
          'Verify PIN',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return TextButton(
      onPressed: _handleLogout,
      child: const Text(
        'Logout',
        style: TextStyle(
          color: AppColors.pinkLavender,
          fontSize: 16,
        ),
      ),
    );
  }
}