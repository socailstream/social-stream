import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:social_stream_next/src/core/theme/app_colors.dart';
import 'package:social_stream_next/src/data/providers/auth_provider.dart';
import 'package:social_stream_next/src/presentation/views/auth/login_screen.dart';
import 'package:social_stream_next/src/presentation/widgets/custom_elevated_btn.dart';
import 'package:social_stream_next/src/presentation/widgets/custom_text_field.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _acceptTerms = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add listener for password strength indicator
    _passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    print('🔵 Starting signup process...');
    print('Name: $name');
    print('Email: $email');

    // Validation
    if (name.isEmpty) {
      print('❌ Validation failed: Name is empty');
      _showError("Please enter your name");
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      print('❌ Validation failed: Invalid email');
      _showError("Please enter a valid email");
      return;
    }

    if (password.length < 6) {
      print('❌ Validation failed: Password too short');
      _showError("Password must be at least 6 characters");
      return;
    }

    if (password != confirm) {
      print('❌ Validation failed: Passwords do not match');
      _showError("Passwords do not match");
      return;
    }

    if (!_acceptTerms) {
      print('❌ Validation failed: Terms not accepted');
      _showError("Please accept terms and conditions");
      return;
    }

    print('✅ All validations passed');

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Calling Firebase signup...');
      final authController = ref.read(authControllerProvider);
      
      // Add timeout to prevent infinite loading (increased to 30 seconds)
      final error = await authController.signUp(
        email: email,
        password: password,
        name: name,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏱️ Signup timed out after 30 seconds');
          return 'Signup is taking too long. Please check your internet connection and try again.';
        },
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (error != null) {
          print('❌ Signup error: $error');
          _showError(error);
        } else {
          print('✅ Signup successful!');
          print('🔄 Navigating to login screen...');
          
          // Navigate to Login Screen immediately
          if (mounted) {
            // First sign out in the background (don't wait for it)
            final authController = ref.read(authControllerProvider);
            authController.signOut().catchError((e) {
              print('⚠️ SignOut error (ignored): $e');
            });
            
            // Navigate immediately
            await Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
              (route) => false, // Remove all previous routes
            );
            
            print('✅ Navigation successful!');
            
            // Show success message after navigation
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Account created successfully! Please login to continue."),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      print('❌ Exception during signup: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError('An error occurred: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Password strength checker
  String _getPasswordStrength(String password) {
    if (password.isEmpty) return '';
    if (password.length < 6) return 'Weak';
    if (password.length < 10) return 'Medium';
    return 'Strong';
  }

  Color _getPasswordStrengthColor(String strength) {
    switch (strength) {
      case 'Weak':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Strong':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Back Button
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF00D4FF).withOpacity(0.1),
                              const Color(0xFF3D5AFE).withOpacity(0.1),
                              const Color(0xFFB429F9).withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          "assets/logo/appLogo.png",
                          height: 70,
                          width: 70,
                        ),
                      ),
                    ),

                    const Gap(24),

                    // Title
                    const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandBlue,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      "Join us and start your journey",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),

                    const Gap(32),

                    // Full Name Field
                    const Text(
                      "Full Name",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Gap(8),
                    CustomTextField(
                      hintText: "Enter your full name",
                      icon: Icons.person_outline,
                      keyboardType: TextInputType.name,
                      controller: _nameController,
                    ),

                    const Gap(20),

                    // Email Field
                    const Text(
                      "Email Address",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Gap(8),
                    CustomTextField(
                      hintText: "Enter your email",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                    ),

                    const Gap(20),

                    // Password Field
                    const Text(
                      "Password",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Gap(8),
                    CustomTextField(
                      hintText: "Create a password",
                      icon: Icons.lock_outlined,
                      keyboardType: TextInputType.visiblePassword,
                      isPassword: true,
                      controller: _passwordController,
                    ),

                    // Password Strength Indicator
                    if (_passwordController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Text(
                              "Password strength: ",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              _getPasswordStrength(_passwordController.text),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getPasswordStrengthColor(
                                  _getPasswordStrength(_passwordController.text),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Gap(20),

                    // Confirm Password Field
                    const Text(
                      "Confirm Password",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Gap(8),
                    CustomTextField(
                      hintText: "Re-enter your password",
                      icon: Icons.lock_outlined,
                      keyboardType: TextInputType.visiblePassword,
                      isPassword: true,
                      controller: _confirmController,
                    ),

                    const Gap(20),

                    // Terms and Conditions Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _acceptTerms,
                            onChanged: (value) {
                              setState(() {
                                _acceptTerms = value ?? false;
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const Gap(8),
                        Expanded(
                          child: Wrap(
                            children: [
                              Text(
                                "I agree to the ",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // TODO: Show terms and conditions
                                },
                                child: const Text(
                                  "Terms & Conditions",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.brandBlue,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              Text(
                                " and ",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // TODO: Show privacy policy
                                },
                                child: const Text(
                                  "Privacy Policy",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.brandBlue,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Gap(32),

                    // Sign Up Button
                    CustomElevatedBtn(
                      btnText: _isLoading ? "Creating Account..." : "Create Account",
                      isLoading: _isLoading,
                      onPressed: _handleSignUp,
                    ),

                    const Gap(24),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
