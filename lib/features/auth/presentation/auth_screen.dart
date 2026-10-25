import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitpay/features/auth/data/auth_provider.dart';
import 'package:splitpay/features/groups/presentation/group_screen.dart';
import 'package:splitpay/shared/widgets/async_elevated_button.dart';
import 'package:splitpay/shared/widgets/splitpay_card.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
      if (next.user != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const GroupScreen()),
          (route) => false,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Phone Sign In',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            letterSpacing: -0.01,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: SplitPayCard(
            padding: const EdgeInsets.all(24.0),
            child: authState.codeSent
                ? _buildOtpView(ref, authState)
                : _buildPhoneView(ref, authState),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneView(WidgetRef ref, AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Welcome to SplitPay',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02,
            color: Color(0xFF0F172A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your details to continue',
          style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Full Name'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone (+1234567890)'),
        ),
        const SizedBox(height: 32),
        AsyncElevatedButton(
          isLoading: state.isLoading,
          onPressed: () {
            final phone = _phoneController.text.trim();
            final name = _nameController.text.trim();
            if (phone.isNotEmpty) {
              ref
                  .read(authProvider.notifier)
                  .sendOtp(phoneNumber: phone, displayName: name);
            }
          },
          child: const Text('Send Code'),
        ),
      ],
    );
  }

  Widget _buildOtpView(WidgetRef ref, AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Verify your number',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02,
            color: Color(0xFF0F172A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter OTP sent to\n${_phoneController.text.trim()}',
          style: const TextStyle(fontSize: 15, color: Color(0xFF64748B)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.03,
          ),
          decoration: const InputDecoration(
            counterText: '',
            labelText: '6-digit OTP',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ),
        const SizedBox(height: 32),
        AsyncElevatedButton(
          isLoading: state.isLoading,
          onPressed: () {
            ref
                .read(authProvider.notifier)
                .verifyOtp(
                  otp: _otpController.text.trim(),
                  displayName: _nameController.text.trim(),
                  phoneNumber: _phoneController.text.trim(),
                );
          },
          child: const Text('Verify & Finish'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => ref.read(authProvider.notifier).reset(),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
          child: const Text('Change Phone Number'),
        ),
      ],
    );
  }
}
