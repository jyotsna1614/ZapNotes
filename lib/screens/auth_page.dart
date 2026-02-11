import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import '../services/api_service.dart';  // Changed from auth_service.dart
import '../widgets/auth_text_field.dart';
import '../widgets/gradient_background.dart';
import 'home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isSignUp = true;
  bool _isLoading = false;  // Add loading state
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscurePin = true;
  
  String _pinType = 'pin';  // Changed from 'numeric' to 'pin'

  final ApiService _apiService = ApiService();  // Changed from AuthService

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      // Prevent multiple submissions
      if (_isLoading) return;
      
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await _apiService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          secretCode: _pinController.text,
          vaultKeyType: _pinType, // 'numeric' or 'alphanumeric'
        );

        if (!mounted) return;

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Account created successfully!'),
              backgroundColor: AppColors.pinkLavender,
            ),
          );

          // Auto switch to sign in
          setState(() {
            _isSignUp = false;
            _passwordController.clear();
            _confirmPasswordController.clear();
            _pinController.clear();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Sign up failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handleSignIn() async {
    if (_formKey.currentState!.validate()) {
      // Prevent multiple submissions
      if (_isLoading) return;
      
      setState(() {
        _isLoading = true;
      });

      try {
        final result = await _apiService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        if (result['success']) {
          // Save login state
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Invalid email or password'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Email validation helper
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Password validation helper
  bool _isValidPassword(String password) {
    return password.length >= 6 && 
           RegExp(r'[a-zA-Z]').hasMatch(password) && 
           RegExp(r'[0-9]').hasMatch(password);
  }

  // PIN validation helper
  bool _isValidPin(String pin) {
    return pin.length >= 4 && 
           RegExp(r'[a-zA-Z]').hasMatch(pin) && 
           RegExp(r'[0-9]').hasMatch(pin);
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
                    const SizedBox(height: 48),
                    _buildEmailField(),
                    const SizedBox(height: 20),
                    _buildPasswordField(),
                    const SizedBox(height: 20),
                    if (_isSignUp) _buildConfirmPasswordField(),
                    if (_isSignUp) const SizedBox(height: 20),
                    if (_isSignUp) _buildSecurityPasswordTypeDropdown(),
                    if (_isSignUp) const SizedBox(height: 20),
                    if (_isSignUp) _buildSecurityPasswordField(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    const SizedBox(height: 24),
                    _buildToggleAuthMode(),
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cyanAzure,
                AppColors.pinkLavender,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyanAzure.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.note_alt_rounded,
            size: 60,
            color: Colors.white,
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
    return Text(
      _isSignUp ? 'Sign Up' : 'Sign In',
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.cyanAzure,
      ),
    );
  }

  Widget _buildEmailField() {
    return AuthTextField(
      controller: _emailController,
      labelText: 'Email',
      prefixIcon: Icons.email_outlined,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        if (!_isValidEmail(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return AuthTextField(
      controller: _passwordController,
      labelText: 'Password',
      prefixIcon: Icons.lock_outline,
      obscureText: _obscurePassword,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.cyanAzure,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (_isSignUp && !_isValidPassword(value)) {
          return 'Password must contain letters and numbers (min 6 chars)';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return AuthTextField(
      controller: _confirmPasswordController,
      labelText: 'Confirm Password',
      prefixIcon: Icons.lock_outline,
      obscureText: _obscureConfirmPassword,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.cyanAzure,
        ),
        onPressed: () {
          setState(() {
            _obscureConfirmPassword = !_obscureConfirmPassword;
          });
        },
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
    );
  }

  Widget _buildSecurityPasswordTypeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.darkSurface,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonFormField<String>(
        value: _pinType,
        dropdownColor: AppColors.darkSurface,
        decoration: const InputDecoration(
          labelText: 'Select Security Password Type',
          labelStyle: TextStyle(color: AppColors.pinkLavender),
          prefixIcon: Icon(
            Icons.security,
            color: AppColors.pinkLavender,
          ),
          border: InputBorder.none,
        ),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.cyanAzure),
        items: const [
          DropdownMenuItem(
            value: 'pin',
            child: Text('PIN (Numeric Only)'),
          ),
          DropdownMenuItem(
            value: 'phrase',
            child: Text('Alphanumeric Password'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _pinType = value!;
            _pinController.clear();
          });
        },
      ),
    );
  }

  Widget _buildSecurityPasswordField() {
    return TextFormField(
      controller: _pinController,
      obscureText: _obscurePin,
      keyboardType: _pinType == 'pin' 
          ? TextInputType.number 
          : TextInputType.text,
      inputFormatters: _pinType == 'pin'
          ? [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ]
          : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Create Security Password',
        labelStyle: const TextStyle(color: AppColors.pinkLavender),
        prefixIcon: Icon(
          _pinType == 'pin' ? Icons.dialpad : Icons.password,
          color: AppColors.pinkLavender,
        ),
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
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.cyanAzure,
            width: 2,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a security password';
        }
        if (_pinType == 'pin') {
          if (value.length != 6) {
            return 'PIN must be exactly 6 digits';
          }
        } else {
          if (!_isValidPin(value)) {
            return 'Password must contain letters and numbers (min 4 chars)';
          }
        }
        return null;
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : (_isSignUp ? _handleSignUp : _handleSignIn),
        style: ElevatedButton.styleFrom(
          shadowColor: AppColors.cyanAzure.withOpacity(0.5),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isSignUp ? 'Sign Up' : 'Sign In',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleAuthMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isSignUp ? 'Already have an account? ' : "Don't have an account? ",
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isSignUp = !_isSignUp;
              _passwordController.clear();
              _confirmPasswordController.clear();
              _pinController.clear();
            });
          },
          child: Text(
            _isSignUp ? 'Sign In' : 'Sign Up',
            style: const TextStyle(
              color: AppColors.pinkLavender,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}