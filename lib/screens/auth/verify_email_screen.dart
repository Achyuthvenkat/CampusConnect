import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../utils/theme.dart';
import '../../widgets/common/custom_button.dart';
import '../home/main_navigation.dart';
import '../auth/login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _emailSent = false;

  Future<void> _resendEmail() async {
    final authProvider = context.read<app_auth.AuthProvider>();
    await authProvider.sendEmailVerification();
    setState(() => _emailSent = true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification email sent!'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  Future<void> _checkVerification() async {
    final authProvider = context.read<app_auth.AuthProvider>();
    final user = authProvider.currentUser;
    await user?.reload();
    if (!mounted) return;
    if (user?.emailVerified == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not verified yet. Check your inbox.'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<app_auth.AuthProvider>();
    final email = authProvider.currentUser?.email ?? 'your email';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),
              const Text(
                'Verify Your Email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We\'ve sent a verification link to:\n$email\n\nPlease check your inbox and click the link to verify your account.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              CustomButton(
                label: 'I\'ve Verified My Email',
                onPressed: _checkVerification,
                width: double.infinity,
              ),
              const SizedBox(height: 12),
              CustomButton(
                label: _emailSent ? 'Email Sent!' : 'Resend Email',
                onPressed: _emailSent ? null : _resendEmail,
                isOutlined: true,
                width: double.infinity,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () async {
                  await authProvider.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
