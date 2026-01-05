import "package:flutter/material.dart";
import "package:gap/gap.dart";
import 'package:firebase_auth/firebase_auth.dart';
import "package:social_stream_next/src/core/theme/app_spacing.dart";
import "package:social_stream_next/src/presentation/views/auth/login_screen.dart";
import "package:social_stream_next/src/presentation/widgets/custom_elevated_btn.dart";

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreen();
}

class _AuthScreen extends State<AuthScreen> {
  bool _isLoading = false;

  Future<void> _checkVerificationEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Email not verified.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
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
        body: SafeArea(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.9,
          child: Column(
            children: [
              const Text(
                "Authentication",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Gap(AppSpacing.xs),
              const Text(
                  "A verification email has been sent to your email address.\n"
                  "Please verify and then click the button below to continue."),
              const Gap(AppSpacing.sm),
              const Gap(AppSpacing.large),
              CustomElevatedBtn(
                btnText: "Continue",
                isLoading: _isLoading,
                onPressed: _checkVerificationEmail,
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
