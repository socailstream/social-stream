import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:social_stream_next/src/core/theme/app_colors.dart';
import 'package:social_stream_next/src/core/utils/timezone_helper.dart';
import 'package:social_stream_next/src/data/services/social_api_service.dart';
import 'package:social_stream_next/src/presentation/views/main.dart';
import 'dart:async';

class ConnectedAccountsScreen extends StatefulWidget {
  const ConnectedAccountsScreen({super.key});

  @override
  State<ConnectedAccountsScreen> createState() => _ConnectedAccountsScreenState();
}

class _ConnectedAccountsScreenState extends State<ConnectedAccountsScreen> {
  final SocialApiService _apiService = SocialApiService();
  List<ConnectedAccount> _connectedAccounts = [];
  bool _isLoading = true;
  StreamSubscription? _oauthSubscription;

  @override
  void initState() {
    super.initState();
    _loadConnectedAccounts();
    
    // Listen for OAuth completion events
    _oauthSubscription = oauthCompletionController.stream.listen((platform) {
      if (platform.startsWith('error:')) {
        final platformName = platform.split(':')[1];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect $platformName'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // OAuth successful - refresh accounts
        _loadConnectedAccounts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $platform connected successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _oauthSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadConnectedAccounts() async {
    setState(() => _isLoading = true);
    try {
      print('🔄 Loading connected accounts...');
      final accounts = await _apiService.getConnectedAccounts();
      print('📊 Loaded ${accounts.length} accounts: ${accounts.map((a) => a.platform).join(", ")}');
      if (mounted) {
        setState(() {
          _connectedAccounts = accounts;
          _isLoading = false;
        });
        print('✅ UI updated with ${_connectedAccounts.length} accounts');
      }
    } catch (e) {
      print('❌ Error loading accounts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load connected accounts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isConnected(String platform) {
    final connected = _connectedAccounts.any((acc) => acc.platform == platform);
    print('🔍 Checking if $platform is connected: $connected (total accounts: ${_connectedAccounts.length})');
    return connected;
  }

  ConnectedAccount? _getAccount(String platform) {
    try {
      final account = _connectedAccounts.firstWhere((acc) => acc.platform == platform);
      print('✅ Found account for $platform: ${account.accountName}');
      return account;
    } catch (e) {
      print('❌ No account found for $platform');
      return null;
    }
  }

  Future<void> _connectAccount(String platform) async {
    try {
      String? authUrl;
      
      switch (platform) {
        case 'facebook':
          authUrl = await _apiService.connectFacebook();
          break;
        case 'instagram':
          authUrl = await _apiService.connectInstagram();
          break;
        case 'pinterest':
          authUrl = await _apiService.connectPinterest();
          break;
      }

      if (authUrl != null) {
        final uri = Uri.parse(authUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          
          // Show info message - will auto-refresh when user returns
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Complete the login in your browser. The app will auto-refresh when you return.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to connect $platform')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showRefreshDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Initiated'),
        content: const Text(
          'Please complete the authentication in your browser.\n\n'
          'Once done, tap "Refresh" to see your connected account.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadConnectedAccounts();
            },
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnectAccount(String platform) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Account'),
        content: Text('Are you sure you want to disconnect $platform?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _apiService.disconnectAccount(platform);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$platform disconnected successfully')),
        );
        _loadConnectedAccounts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connected Accounts'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadConnectedAccounts,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Connect your social media accounts to post directly from Social Stream',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const Gap(24),
                  
                  // Facebook
                  _buildSocialAccountTile(
                    platform: 'facebook',
                    icon: Icons.facebook,
                    color: const Color(0xFF1877F2),
                    label: 'Facebook',
                  ),
                  const Gap(12),
                  
                  // Instagram
                  _buildSocialAccountTile(
                    platform: 'instagram',
                    icon: Icons.camera_alt,
                    color: const Color(0xFFE4405F),
                    label: 'Instagram',
                  ),
                  const Gap(12),
                  
                  // Pinterest
                  _buildSocialAccountTile(
                    platform: 'pinterest',
                    icon: Icons.push_pin,
                    color: const Color(0xFFE60023),
                    label: 'Pinterest',
                  ),
                  
                  const Gap(32),
                  
                  if (_connectedAccounts.isNotEmpty) ...[
                    const Divider(),
                    const Gap(16),
                    const Text(
                      'Connected Accounts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(16),
                    ..._connectedAccounts.map((account) => _buildConnectedAccountCard(account)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSocialAccountTile({
    required String platform,
    required IconData icon,
    required Color color,
    required String label,
  }) {
    final isConnected = _isConnected(platform);
    final account = _getAccount(platform);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? color : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: isConnected
            ? Text(
                account?.accountName ?? 'Connected',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              )
            : const Text('Not connected'),
        trailing: SizedBox(
          width: 100,
          child: isConnected
              ? OutlinedButton(
                  onPressed: () => _disconnectAccount(platform),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Disconnect'),
                )
              : ElevatedButton(
                  onPressed: () => _connectAccount(platform),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Connect'),
                ),
        ),
      ),
    );
  }

  Widget _buildConnectedAccountCard(ConnectedAccount account) {
    IconData icon;
    Color color;
    
    switch (account.platform) {
      case 'facebook':
        icon = Icons.facebook;
        color = const Color(0xFF1877F2);
        break;
      case 'instagram':
        icon = Icons.camera_alt;
        color = const Color(0xFFE4405F);
        break;
      case 'pinterest':
        icon = Icons.push_pin;
        color = const Color(0xFFE60023);
        break;
      default:
        icon = Icons.link;
        color = AppColors.brandBlue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          account.accountName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Connected ${_formatDate(account.connectedAt)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: account.isActive
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.error, color: Colors.orange),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = TimezoneHelper.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }
}
