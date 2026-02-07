import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import '../services/auth_service.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscurePin = true;
  
  // PIN type selection: 'numeric' or 'alphanumeric'
  String _pinType = 'numeric';

  final AuthService _authService = AuthService();

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
      final result = await _authService.signUp(
        _emailController.text,
        _passwordController.text,
        _pinController.text,
      );

      if (!mounted) return;

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: AppColors.pinkLavender,
          ),
        );

        setState(() {
          _isSignUp = false;
          _passwordController.clear();
          _confirmPasswordController.clear();
          _pinController.clear();
        });
      }
    }
  }

  Future<void> _handleSignIn() async {
    if (_formKey.currentState!.validate()) {
      final result = await _authService.signIn(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      if (result) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                    // Field 1: Email
                    _buildEmailField(),
                    const SizedBox(height: 20),
                    // Field 2: Password
                    _buildPasswordField(),
                    const SizedBox(height: 20),
                    // Field 3: Confirm Password (only in Sign Up)
                    if (_isSignUp) _buildConfirmPasswordField(),
                    if (_isSignUp) const SizedBox(height: 20),
                    // Field 4: Select Security Password Type (only in Sign Up)
                    if (_isSignUp) _buildSecurityPasswordTypeDropdown(),
                    if (_isSignUp) const SizedBox(height: 20),
                    // Field 5: Create Security Password (only in Sign Up)
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
        if (!_authService.isValidEmail(value)) {
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
        if (_isSignUp && !_authService.isValidPassword(value)) {
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
            value: 'numeric',
            child: Text('PIN (Numeric Only)'),
          ),
          DropdownMenuItem(
            value: 'alphanumeric',
            child: Text('Alphanumeric Password'),
          ),
        ],
        onChanged: (value) {
          setState(() {
            _pinType = value!;
            // Clear PIN field when switching types
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
      keyboardType: _pinType == 'numeric' 
          ? TextInputType.number 
          : TextInputType.text,
      inputFormatters: _pinType == 'numeric'
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Create Security Password',
        labelStyle: const TextStyle(color: AppColors.pinkLavender),
        prefixIcon: Icon(
          _pinType == 'numeric' ? Icons.dialpad : Icons.password,
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
        if (_pinType == 'numeric') {
          if (value.length < 4) {
            return 'PIN must be at least 4 digits';
          }
        } else {
          if (!_authService.isValidPin(value)) {
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
        onPressed: _isSignUp ? _handleSignUp : _handleSignIn,
        style: ElevatedButton.styleFrom(
          shadowColor: AppColors.cyanAzure.withOpacity(0.5),
        ),
        child: Text(
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