import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_stream_next/src/core/theme/app_colors.dart';
import 'package:social_stream_next/src/core/utils/timezone_helper.dart';
import 'package:social_stream_next/src/data/services/social_api_service.dart';
import 'package:social_stream_next/src/data/services/analytics_service.dart';
import 'package:social_stream_next/src/presentation/views/settings/connected_accounts_screen.dart';
import 'package:social_stream_next/src/presentation/views/posts/add_post_screen.dart';
import 'package:social_stream_next/src/presentation/views/analytics/analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SocialApiService _apiService = SocialApiService();
  final AnalyticsService _analyticsService = AnalyticsService();
  List<ConnectedAccount> _connectedAccounts = [];
  Map<String, dynamic>? _dashboardStats;
  List<Map<String, dynamic>> _scheduledPosts = [];
  List<Map<String, dynamic>> _recentActivity = [];
  AnalyticsOverview? _analyticsOverview;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _apiService.getConnectedAccounts(),
        _apiService.getDashboardStats(),
        _apiService.getScheduledPosts(),
        _apiService.getRecentActivity(limit: 5),
        _analyticsService
            .getOverview()
            .then<AnalyticsOverview?>((v) => v)
            .catchError((e) {
          print('Analytics not available: $e');
          return null;
        }),
      ]);

      if (mounted) {
        setState(() {
          _connectedAccounts = results[0] as List<ConnectedAccount>;
          _dashboardStats = results[1] as Map<String, dynamic>;
          _scheduledPosts = results[2] as List<Map<String, dynamic>>;
          _recentActivity = results[3] as List<Map<String, dynamic>>;
          _analyticsOverview = results[4] as AnalyticsOverview?;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToConnectedAccounts() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConnectedAccountsScreen()),
    );
    // Refresh dashboard after returning
    _loadDashboardData();
  }

  void _navigateToCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPostScreen()),
    );
  }

  void _navigateToCalendar() {
    // Navigate to calendar tab (index 1 in main navigation)
    // Since we're in the HomeScreen inside MainNavigation, we need to use a callback
    // For now, we'll show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tap the Calendar tab in the bottom navigation'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: Colors.white,
                elevation: 0,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Welcome back!',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.black87),
                    onPressed: () {},
                  ),
                ],
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Summary Cards
                    _SummarySection(
                      stats: _dashboardStats,
                      isLoading: _isLoading,
                    ),
                    const Gap(24),

                    // Quick Actions
                    _QuickActionsSection(
                      onAddAccount: _navigateToConnectedAccounts,
                      onCreatePost: _navigateToCreatePost,
                      onCalendar: _navigateToCalendar,
                      onAnalytics: _showAnalytics,
                    ),
                    const Gap(24),

                    // Connected Accounts Preview
                    if (_connectedAccounts.isNotEmpty) ...[
                      _ConnectedAccountsPreview(
                        accounts: _connectedAccounts,
                        onViewAll: _navigateToConnectedAccounts,
                      ),
                      const Gap(24),
                    ],

                    // Scheduled Posts Overview
                    _ScheduledPostsSection(
                      scheduledPosts: _scheduledPosts,
                      isLoading: _isLoading,
                    ),
                    const Gap(24),

                    // Engagement Snapshot
                    _EngagementSection(
                      analytics: _analyticsOverview,
                      isLoading: _isLoading,
                    ),
                    const Gap(24),

                    // Recent Notifications
                    _NotificationsPreviewSection(
                      activities: _recentActivity,
                      isLoading: _isLoading,
                    ),
                    const Gap(20),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Summary Cards Section
class _SummarySection extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final bool isLoading;

  const _SummarySection({
    required this.stats,
    required this.isLoading,
  });

  String _getNextPostTime() {
    if (stats == null || stats!['nextPost'] == null) return '--';
    try {
      final nextPostTime = DateTime.parse(stats!['nextPost']['time']);
      final now = TimezoneHelper.now();
      final today = DateTime(now.year, now.month, now.day);
      final postDay =
          DateTime(nextPostTime.year, nextPostTime.month, nextPostTime.day);

      final hour =
          nextPostTime.hour > 12 ? nextPostTime.hour - 12 : nextPostTime.hour;
      final minute = nextPostTime.minute.toString().padLeft(2, '0');
      final period = nextPostTime.hour >= 12 ? 'PM' : 'AM';

      if (postDay == today) {
        return '$hour:$minute';
      } else if (postDay == today.add(const Duration(days: 1))) {
        return 'Tmrw';
      } else {
        return '${nextPostTime.month}/${nextPostTime.day}';
      }
    } catch (e) {
      return '--';
    }
  }

  String _getNextPostSubtitle() {
    if (stats == null || stats!['nextPost'] == null) return 'No posts';
    try {
      final nextPostTime = DateTime.parse(stats!['nextPost']['time']);
      final now = TimezoneHelper.now();
      final today = DateTime(now.year, now.month, now.day);
      final postDay =
          DateTime(nextPostTime.year, nextPostTime.month, nextPostTime.day);

      if (postDay == today) {
        return 'Today';
      } else if (postDay == today.add(const Duration(days: 1))) {
        return 'Tomorrow';
      } else {
        return '${nextPostTime.day}/${nextPostTime.month}';
      }
    } catch (e) {
      return 'scheduled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectedCount = stats?['connectedAccounts'] ?? 0;
    final scheduledCount = stats?['scheduledPosts'] ?? 0;
    final postedTodayCount = stats?['postedToday'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.link,
                title: 'Connected',
                value: isLoading ? '...' : '$connectedCount',
                subtitle: 'Accounts',
                color: const Color(0xFF4CAF50),
              ),
            ),
            const Gap(12),
            Expanded(
              child: _SummaryCard(
                icon: Icons.schedule,
                title: 'Scheduled',
                value: isLoading ? '...' : '$scheduledCount',
                subtitle: 'Posts',
                color: const Color(0xFF2196F3),
              ),
            ),
          ],
        ),
        const Gap(12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                icon: Icons.check_circle,
                title: 'Total Posts',
                value: isLoading ? '...' : '$postedTodayCount',
                subtitle: 'Published',
                color: const Color(0xFF9C27B0),
              ),
            ),
            const Gap(12),
            Expanded(
              child: _SummaryCard(
                icon: Icons.access_time,
                title: 'Next Post',
                value: isLoading ? '...' : _getNextPostTime(),
                subtitle: _getNextPostSubtitle(),
                color: const Color(0xFFFF9800),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Gap(12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// Quick Actions Section
class _QuickActionsSection extends StatelessWidget {
  final VoidCallback onAddAccount;
  final VoidCallback onCreatePost;
  final VoidCallback onCalendar;
  final VoidCallback onAnalytics;

  const _QuickActionsSection({
    required this.onAddAccount,
    required this.onCreatePost,
    required this.onCalendar,
    required this.onAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _QuickActionButton(
              icon: Icons.add_circle_outline,
              label: 'Create Post',
              color: AppColors.brandBlue,
              onTap: onCreatePost,
            ),
            _QuickActionButton(
              icon: Icons.link,
              label: 'Add Account',
              color: const Color(0xFF4CAF50),
              onTap: onAddAccount,
            ),
            _QuickActionButton(
              icon: Icons.calendar_today,
              label: 'Calendar',
              color: const Color(0xFFFF9800),
              onTap: onCalendar,
            ),
            _QuickActionButton(
              icon: Icons.analytics,
              label: 'Analytics',
              color: const Color(0xFF9C27B0),
              onTap: onAnalytics,
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const Gap(8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Connected Accounts Preview Section
class _ConnectedAccountsPreview extends StatelessWidget {
  final List<ConnectedAccount> accounts;
  final VoidCallback onViewAll;

  const _ConnectedAccountsPreview({
    required this.accounts,
    required this.onViewAll,
  });

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
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Connected Accounts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: const Text('Manage'),
              ),
            ],
          ),
          const Gap(12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: accounts.map((account) {
              final color = _getPlatformColor(account.platform);
              final icon = _getPlatformIcon(account.platform);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 18),
                    const Gap(6),
                    Text(
                      account.accountName,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const Gap(4),
                    Icon(
                      account.isActive ? Icons.check_circle : Icons.warning,
                      color: account.isActive ? Colors.green : Colors.orange,
                      size: 14,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// Scheduled Posts Section
class _ScheduledPostsSection extends StatelessWidget {
  final List<Map<String, dynamic>> scheduledPosts;
  final bool isLoading;

  const _ScheduledPostsSection({
    required this.scheduledPosts,
    required this.isLoading,
  });

  String _formatScheduledTime(String? dateString) {
    if (dateString == null) return 'Not scheduled';
    try {
      final scheduledDate = DateTime.parse(dateString);
      final now = TimezoneHelper.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      final postDay =
          DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);

      final hour = scheduledDate.hour > 12
          ? scheduledDate.hour - 12
          : scheduledDate.hour;
      final minute = scheduledDate.minute.toString().padLeft(2, '0');
      final period = scheduledDate.hour >= 12 ? 'PM' : 'AM';

      if (postDay == today) {
        return 'Today at $hour:$minute $period';
      } else if (postDay == tomorrow) {
        return 'Tomorrow at $hour:$minute $period';
      } else {
        return '${scheduledDate.month}/${scheduledDate.day} at $hour:$minute $period';
      }
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Scheduled Posts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ],
        ),
        const Gap(12),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (scheduledPosts.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.schedule, size: 48, color: Colors.grey[400]),
                  const Gap(8),
                  Text(
                    'No scheduled posts',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...scheduledPosts.take(3).map((post) {
            final platforms = (post['platforms'] as List?)
                    ?.map((p) => p.toString())
                    .toList() ??
                [post['platform']?.toString() ?? 'Unknown'];

            final title = post['content']?.toString() ?? 'Untitled Post';
            final truncatedTitle =
                title.length > 50 ? '${title.substring(0, 50)}...' : title;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ScheduledPostCard(
                title: truncatedTitle,
                platforms: platforms,
                time: _formatScheduledTime(post['scheduledDate']?.toString()),
                status: 'Scheduled',
                statusColor: const Color(0xFF2196F3),
              ),
            );
          }).toList(),
      ],
    );
  }
}

class _ScheduledPostCard extends StatelessWidget {
  final String title;
  final List<String> platforms;
  final String time;
  final String status;
  final Color statusColor;

  const _ScheduledPostCard({
    required this.title,
    required this.platforms,
    required this.time,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.brandBlue.withOpacity(0.3),
                  const Color(0xFFB429F9).withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image, color: Colors.white, size: 28),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(4),
                Row(
                  children: platforms
                      .map((platform) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _PlatformBadge(platform: platform),
                          ))
                      .toList(),
                ),
                const Gap(6),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  final String platform;

  const _PlatformBadge({required this.platform});

  Color _getPlatformColor() {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getPlatformColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _getPlatformColor().withOpacity(0.3)),
      ),
      child: Text(
        platform,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _getPlatformColor(),
        ),
      ),
    );
  }
}

// Engagement Section
class _EngagementSection extends StatelessWidget {
  final AnalyticsOverview? analytics;
  final bool isLoading;

  const _EngagementSection({
    required this.analytics,
    required this.isLoading,
  });

  String _formatNumber(dynamic value) {
    if (value == null) return '0';

    final num numValue = value is num ? value : 0;

    if (numValue >= 1000000) {
      return '${(numValue / 1000000).toStringAsFixed(1)}M';
    } else if (numValue >= 1000) {
      return '${(numValue / 1000).toStringAsFixed(1)}K';
    } else {
      return numValue.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final engagement = analytics?.totalEngagement ?? {};
    final likes = engagement['likes'] ?? 0;
    final comments = engagement['comments'] ?? 0;
    final shares = engagement['shares'] ?? 0;
    final saves = engagement['saves'] ?? 0;

    // Get platform metrics
    final platforms = analytics?.platforms ?? [];
    final totalPosts = analytics?.totalPosts ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.brandBlue.withOpacity(0.1),
                          AppColors.brandBlue.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      size: 20,
                      color: AppColors.brandBlue,
                    ),
                  ),
                  const Gap(12),
                  const Text(
                    'Analytics Overview',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              if (analytics != null && analytics!.period.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const Gap(6),
                      Text(
                        analytics!.period == 'last_7_days'
                            ? 'Last 7 days'
                            : analytics!.period.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Gap(16),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (analytics == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.analytics_outlined,
                        size: 48, color: Colors.grey[400]),
                    const Gap(8),
                    Text(
                      'No analytics data available',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                // Total Engagement Grid
                Row(
                  children: [
                    Expanded(
                      child: _CompactEngagementCard(
                        icon: Icons.favorite,
                        value: _formatNumber(likes),
                        label: 'Likes',
                        color: const Color(0xFFE91E63),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: _CompactEngagementCard(
                        icon: Icons.comment,
                        value: _formatNumber(comments),
                        label: 'Comments',
                        color: const Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                Row(
                  children: [
                    Expanded(
                      child: _CompactEngagementCard(
                        icon: Icons.share,
                        value: _formatNumber(shares),
                        label: 'Shares',
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: _CompactEngagementCard(
                        icon: Icons.bookmark,
                        value: _formatNumber(saves),
                        label: 'Saves',
                        color: const Color(0xFFFF9800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// Platform Insight Card
class _PlatformInsightCard extends StatelessWidget {
  final String platform;
  final String accountName;
  final Map<String, dynamic> metrics;

  const _PlatformInsightCard({
    required this.platform,
    required this.accountName,
    required this.metrics,
  });

  Color _getPlatformColor() {
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

  IconData _getPlatformIcon() {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt;
      case 'pinterest':
        return Icons.push_pin;
      default:
        return Icons.public;
    }
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    final num numValue = value is num ? value : 0;

    if (numValue >= 1000000) {
      return '${(numValue / 1000000).toStringAsFixed(1)}M';
    } else if (numValue >= 1000) {
      return '${(numValue / 1000).toStringAsFixed(1)}K';
    } else {
      return numValue.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getPlatformColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getPlatformIcon(), color: color, size: 20),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      platform.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      accountName,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: metrics.entries.map((entry) {
              return _MetricItem(
                label: entry.key,
                value: _formatNumber(entry.value),
                color: color,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.color,
  });

  String _formatLabel(String label) {
    return label
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatLabel(label) + ':',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CompactEngagementCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _CompactEngagementCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Gap(10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
              letterSpacing: -0.5,
            ),
          ),
          const Gap(4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallEngagementStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _SmallEngagementStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const Gap(6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _EngagementStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _EngagementStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const Gap(8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

// Notifications Preview Section
class _NotificationsPreviewSection extends StatelessWidget {
  final List<Map<String, dynamic>> activities;
  final bool isLoading;

  const _NotificationsPreviewSection({
    required this.activities,
    required this.isLoading,
  });

  String _formatActivityTime(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final activityDate = DateTime.parse(dateString);
      return TimezoneHelper.getRelativeTime(activityDate);
    } catch (e) {
      return dateString;
    }
  }

  IconData _getActivityIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'published':
        return Icons.check_circle;
      case 'scheduled':
        return Icons.schedule;
      case 'failed':
        return Icons.error;
      case 'mention':
        return Icons.alternate_email;
      case 'comment':
        return Icons.comment;
      default:
        return Icons.notifications;
    }
  }

  Color _getActivityColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'published':
        return const Color(0xFF4CAF50);
      case 'scheduled':
        return const Color(0xFF2196F3);
      case 'failed':
        return const Color(0xFFF44336);
      case 'mention':
        return const Color(0xFF2196F3);
      case 'comment':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF9C27B0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All'),
            ),
          ],
        ),
        const Gap(12),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (activities.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.notifications_none,
                      size: 48, color: Colors.grey[400]),
                  const Gap(8),
                  Text(
                    'No recent activity',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...activities.take(3).map((activity) {
            final type = activity['type']?.toString() ?? 'notification';
            final title = activity['title']?.toString() ?? 'Activity';
            final description = activity['description']?.toString() ?? '';
            final time = _formatActivityTime(activity['time']?.toString());

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _NotificationItem(
                icon: _getActivityIcon(type),
                title: title,
                description: description,
                time: time,
                color: _getActivityColor(type),
              ),
            );
          }).toList(),
      ],
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String time;
  final Color color;

  const _NotificationItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
