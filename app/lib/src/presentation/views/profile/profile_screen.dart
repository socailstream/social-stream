import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:social_stream_next/src/core/theme/app_colors.dart';
import 'package:social_stream_next/src/data/providers/auth_provider.dart';
import 'package:social_stream_next/src/data/providers/user_provider.dart';
import 'package:social_stream_next/src/data/services/social_api_service.dart';
import 'package:social_stream_next/src/presentation/views/profile/edit_profile_screen.dart';
import 'package:social_stream_next/src/presentation/views/profile/change_password_screen.dart';
import 'package:social_stream_next/src/presentation/views/settings/connected_accounts_screen.dart';
import 'package:social_stream_next/src/presentation/views/auth/login_screen.dart';


class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final SocialApiService _apiService = SocialApiService();
  List<ConnectedAccount> _connectedAccounts = [];
  bool _isLoadingAccounts = true;

  @override
  void initState() {
    super.initState();
    _loadConnectedAccounts();
  }

  Future<void> _loadConnectedAccounts() async {
    try {
      final accounts = await _apiService.getConnectedAccounts();
      if (mounted) {
        setState(() {
          _connectedAccounts = accounts;
          _isLoadingAccounts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAccounts = false;
        });
      }
    }
  }

  void _navigateToConnectedAccounts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConnectedAccountsScreen()),
    );
    // Refresh accounts after returning
    _loadConnectedAccounts();
  }

  @override
  Widget build(BuildContext context) {
    final userDataAsync = ref.watch(userDataStreamProvider);
    final currentUser = ref.watch(currentFirebaseUserProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: userDataAsync.when(
          data: (userData) => SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                _buildProfileHeader(userData, currentUser),
                const Gap(24),

                // Account Section
                _buildSection(
                  title: 'Account',
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline,
                      title: 'Edit Profile',
                      subtitle: 'Update your personal information',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      subtitle: 'Update your password',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                    _SettingsTile(
                      icon: Icons.link,
                      title: 'Connected Accounts',
                      subtitle: _isLoadingAccounts 
                          ? 'Loading...' 
                          : '${_connectedAccounts.length} account${_connectedAccounts.length != 1 ? 's' : ''} connected',
                      trailing: _ConnectedAccountsIcons(accounts: _connectedAccounts),
                      onTap: _navigateToConnectedAccounts,
                    ),
                  ],
                ),

                const Gap(16),

                // Danger Zone
                _buildSection(
                  title: 'Danger Zone',
                  children: [
                    _SettingsTile(
                      icon: Icons.delete_outline,
                      title: 'Delete Account',
                      subtitle: 'Permanently delete your account',
                      titleColor: Colors.red,
                      onTap: () {
                        _showDeleteAccountDialog();
                      },
                    ),
                  ],
                ),

                const Gap(24),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),

                const Gap(16),

                // App Version
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const Gap(24),
              ],
            ),
          ),
          loading: () => SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header Skeleton
                _buildProfileHeaderSkeleton(),
                const Gap(24),

                // Account Section Skeleton
                _buildSectionSkeleton(),

                const Gap(16),

                // Danger Zone Skeleton
                _buildSectionSkeleton(),

                const Gap(24),

                // Logout Button Skeleton
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const Gap(16),
              ],
            ),
          ),
          error: (error, stack) => SingleChildScrollView(
            child: Column(
              children: [
                const Gap(100),
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const Gap(16),
                Text(
                  'Error loading profile data',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Gap(8),
                TextButton(
                  onPressed: () {
                    ref.invalidate(userDataStreamProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic userData, dynamic currentUser) {
    // Get display name from Firebase Auth user or Firestore
    final displayName = userData?.name ?? 
                       currentUser?.displayName ?? 
                       'User';
    
    // Get email from Firebase Auth user
    final email = currentUser?.email ?? 'No email';
    
    // Get phone number from Firestore or Firebase Auth
    final phoneNumber = userData?.phoneNumber ?? 
                       currentUser?.phoneNumber ?? 
                       'No phone number';
    
    // Get profile picture URL
    final profilePicUrl = userData?.profilePicUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.brandBlue,
                      const Color(0xFFB429F9),
                    ],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: profilePicUrl != null 
                        ? NetworkImage(profilePicUrl) 
                        : null,
                    child: profilePicUrl == null
                        ? Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          const Gap(16),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(4),
          Text(
            email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const Gap(4),
          Text(
            phoneNumber,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          // Show bio if available
          if (userData?.bio != null && userData!.bio!.isNotEmpty) ...[
            const Gap(12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                userData.bio!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Gap(16),
          ...children,
        ],
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Close confirmation dialog
              Navigator.of(context).pop();
              
              try {
                // Logout from Firebase
                final authController = ref.read(authControllerProvider);
                await authController.signOut();
                
                // Navigate to LoginScreen after successful logout
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false, // Remove all previous routes
                  );
                  
                  // Show success message after navigation
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logged out successfully'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  });
                }
              } catch (e) {
                // If error occurs, show error message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning, color: Colors.red, size: 24),
              ),
              const Gap(12),
              const Expanded(
                child: Text(
                  'Delete Account',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action cannot be undone. All your data will be permanently deleted.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const Gap(20),
              const Text(
                'Enter your password to confirm:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(8),
              TextField(
                controller: passwordController,
                obscureText: true,
                enabled: !isDeleting,
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting
                  ? null
                  : () {
                      passwordController.dispose();
                      Navigator.pop(context);
                    },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      final password = passwordController.text.trim();
                      
                      if (password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter your password'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        isDeleting = true;
                      });

                      await _deleteAccount(password, context);
                      
                      passwordController.dispose();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: isDeleting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Delete Account'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount(String password, BuildContext dialogContext) async {
    print('🗑️ Starting account deletion process...');
    
    try {
      final authController = ref.read(authControllerProvider);
      final currentUser = ref.read(currentFirebaseUserProvider);
      
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      print('🔐 Deleting account for user: ${currentUser.uid}');
      
      final error = await authController.deleteAccount(password).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏱️ Account deletion timed out');
          return 'Account deletion is taking too long. Please try again.';
        },
      );

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext); // Close dialog
      }

      if (error != null) {
        print('❌ Account deletion failed: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_formatDeleteError(error)),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        print('✅✅✅ Account deleted successfully!');
        if (mounted) {
          // Navigate to login screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
            (route) => false,
          );
          
          // Show success message
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deleted successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      print('❌❌❌ Exception during account deletion: $e');
      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String _formatDeleteError(String error) {
    if (error.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (error.contains('requires-recent-login')) {
      return 'Please logout and login again before deleting your account.';
    } else if (error.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection.';
    }
    return error;
  }

  // Skeleton loaders for better loading experience
  Widget _buildProfileHeaderSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar skeleton
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const Gap(16),
          // Name skeleton
          Container(
            width: 150,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Gap(8),
          // Email skeleton
          Container(
            width: 200,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Gap(8),
          // Phone skeleton
          Container(
            width: 180,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title skeleton
          Container(
            width: 100,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Gap(16),
          // Tile skeletons
          ...List.generate(
            2,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const Gap(6),
                        Container(
                          width: 180,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (titleColor ?? AppColors.brandBlue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: titleColor ?? AppColors.brandBlue,
                size: 22,
              ),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? Colors.black87,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onTap != null)
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// Dynamic connected accounts icons based on real data
class _ConnectedAccountsIcons extends StatelessWidget {
  final List<ConnectedAccount> accounts;

  const _ConnectedAccountsIcons({required this.accounts});

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'pinterest':
        return const Color(0xFFE60023);
      default:
        return Colors.grey;
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt;
      case 'pinterest':
        return Icons.push_pin;
      default:
        return Icons.link;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const Icon(Icons.chevron_right, color: Colors.grey);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...accounts.take(3).map((account) {
          return Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _getPlatformColor(account.platform),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getPlatformIcon(account.platform),
                size: 12,
                color: Colors.white,
              ),
            ),
          );
        }),
        const Gap(4),
        const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      ],
    );
  }
}
