import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/api_service.dart';

class NoteUnlockDialog extends StatefulWidget {
  const NoteUnlockDialog({Key? key}) : super(key: key);

  @override
  State<NoteUnlockDialog> createState() => _NoteUnlockDialogState();
}

class _NoteUnlockDialogState extends State<NoteUnlockDialog> {
  final TextEditingController _pinController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _obscurePin = true;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verifyPin() async {
    final pin = _pinController.text.trim();
    
    if (pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your security password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await _apiService.verifyPin(pin);
    
    if (!mounted) return;

    if (result['success']) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect security password'),
          backgroundColor: Colors.red,
        ),
      );
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.darkSurface,
      title: const Row(
        children: [
          Icon(Icons.lock, color: AppColors.pinkLavender),
          SizedBox(width: 12),
          Text(
            'Locked Note',
            style: TextStyle(color: AppColors.cyanAzure),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Enter your security password to unlock this note',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _pinController,
            obscureText: _obscurePin,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Security Password',
              labelStyle: const TextStyle(color: AppColors.pinkLavender),
              prefixIcon: const Icon(
                Icons.password,
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
              fillColor: AppColors.darkBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.cyanAzure,
                  width: 2,
                ),
              ),
            ),
            onSubmitted: (_) => _verifyPin(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _verifyPin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cyanAzure,
          ),
          child: const Text(
            'Unlock',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
