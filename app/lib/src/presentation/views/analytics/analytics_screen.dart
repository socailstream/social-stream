import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_stream_next/src/data/services/analytics_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final AnalyticsService _analyticsService = AnalyticsService();
  late TabController _tabController;

  AnalyticsOverview? _overview;
  PlatformMetrics? _facebookMetrics;
  PlatformMetrics? _instagramMetrics;
  PlatformMetrics? _pinterestMetrics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _analyticsService.getOverview(),
        _analyticsService
            .getFacebookMetrics()
            .then<PlatformMetrics?>((value) => value)
            .catchError((e) {
          print('Facebook metrics error: $e');
          return null;
        }),
        _analyticsService
            .getInstagramMetrics()
            .then<PlatformMetrics?>((value) => value)
            .catchError((e) {
          print('Instagram metrics error: $e');
          return null;
        }),
        _analyticsService
            .getPinterestMetrics()
            .then<PlatformMetrics?>((value) => value)
            .catchError((e) {
          print('Pinterest metrics error: $e');
          return null;
        }),
      ]);

      if (mounted) {
        setState(() {
          _overview = results[0] as AnalyticsOverview?;
          _facebookMetrics = results[1] as PlatformMetrics?;
          _instagramMetrics = results[2] as PlatformMetrics?;
          _pinterestMetrics = results[3] as PlatformMetrics?;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading analytics: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Analytics',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00D4FF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF00D4FF),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Facebook'),
            Tab(text: 'Instagram'),
            Tab(text: 'Pinterest'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildPlatformTab(_facebookMetrics, 'Facebook',
                    const Color(0xFF1877F2), Icons.facebook),
                _buildPlatformTab(_instagramMetrics, 'Instagram',
                    const Color(0xFFE4405F), Icons.camera_alt),
                _buildPlatformTab(_pinterestMetrics, 'Pinterest',
                    const Color(0xFFE60023), Icons.push_pin),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_overview == null) {
      return const Center(
        child: Text('No analytics data available'),
      );
    }

    final engagement = _overview!.totalEngagement;
    final totalLikes = engagement['likes'] ?? 0;
    final totalComments = engagement['comments'] ?? 0;
    final totalShares = engagement['shares'] ?? 0;
    final totalSaves = engagement['saves'] ?? 0;
    final totalInteractions =
        totalLikes + totalComments + totalShares + totalSaves;

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildHeroStatCard(
                    'Total Posts',
                    _formatNumber(_overview!.totalPosts),
                    Icons.article_outlined,
                    const Color(0xFF2196F3),
                    'Published',
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _buildHeroStatCard(
                    'Engagement',
                    _formatNumber(totalInteractions),
                    Icons.show_chart,
                    const Color(0xFF4CAF50),
                    'Total',
                  ),
                ),
              ],
            ),
            const Gap(24),

            // Engagement Breakdown Grid
            const Text(
              'Engagement Breakdown',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(12),
            Row(
              children: [
                Expanded(
                  child: _buildEngagementCard(
                    Icons.favorite,
                    'Likes',
                    _formatNumber(totalLikes),
                    const Color(0xFFE91E63),
                    totalInteractions > 0
                        ? (totalLikes / totalInteractions * 100)
                        : 0,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _buildEngagementCard(
                    Icons.comment,
                    'Comments',
                    _formatNumber(totalComments),
                    const Color(0xFF2196F3),
                    totalInteractions > 0
                        ? (totalComments / totalInteractions * 100)
                        : 0,
                  ),
                ),
              ],
            ),
            const Gap(12),
            Row(
              children: [
                Expanded(
                  child: _buildEngagementCard(
                    Icons.share,
                    'Shares',
                    _formatNumber(totalShares),
                    const Color(0xFF4CAF50),
                    totalInteractions > 0
                        ? (totalShares / totalInteractions * 100)
                        : 0,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _buildEngagementCard(
                    Icons.bookmark,
                    'Saves',
                    _formatNumber(totalSaves),
                    const Color(0xFFFF9800),
                    totalInteractions > 0
                        ? (totalSaves / totalInteractions * 100)
                        : 0,
                  ),
                ),
              ],
            ),
            const Gap(24),

            // Platform Performance
            const Text(
              'Platform Performance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(12),
            if (_overview!.platforms.isNotEmpty)
              ..._overview!.platforms.map((platformData) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildEnhancedPlatformCard(
                    platformData['platform'] ?? '',
                    platformData,
                  ),
                );
              }).toList()
            else
              Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.analytics_outlined,
                          size: 64, color: Colors.grey[300]),
                      const Gap(16),
                      Text(
                        'No platform data available',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        'Connect your social accounts to see analytics',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformTab(
    PlatformMetrics? metrics,
    String platformName,
    Color color,
    IconData icon,
  ) {
    if (metrics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const Gap(16),
            Text(
              'No $platformName data available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const Gap(8),
            Text(
              'Connect your $platformName account to see analytics',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: Colors.white, size: 40),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          platformName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          'Platform Analytics',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(24),

            // Platform Insights Grid
            const Text(
              'Key Metrics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(12),
            _buildMetricsGrid(metrics.insights, color),
            const Gap(24),

            // Recent Posts
            if (metrics.recentPosts.isNotEmpty) ...[
              const Text(
                'Recent Posts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(12),
              ...metrics.recentPosts.map((post) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPostCard(post, color),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const Gap(16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const Gap(4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const Gap(12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformCard(String platform, Map<String, dynamic> data) {
    Color color;
    IconData icon;

    switch (platform.toLowerCase()) {
      case 'facebook':
        color = const Color(0xFF1877F2);
        icon = Icons.facebook;
        break;
      case 'instagram':
        color = const Color(0xFFE4405F);
        icon = Icons.camera_alt;
        break;
      case 'pinterest':
        color = const Color(0xFFE60023);
        icon = Icons.push_pin;
        break;
      default:
        color = Colors.grey;
        icon = Icons.public;
    }

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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Gap(16),
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
                const Gap(4),
                Text(
                  '${_formatNumber(data['posts'] ?? 0)} posts',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatNumber(data['engagement'] ?? 0),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, Color color) {
    final likes = post['likes'] ?? 0;
    final comments = post['comments'] ?? 0;
    final shares = post['shares'] ?? post['saves'] ?? 0;
    final totalEngagement = likes + comments + shares;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                child: Icon(Icons.article_outlined, color: color, size: 20),
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  _formatInsightKey(post['createdTime']?.toString() ?? 'Post'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (totalEngagement > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatNumber(totalEngagement),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          const Gap(12),
          Text(
            post['message'] ?? post['title'] ?? 'No content',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEnhancedPostStat(
                  Icons.favorite,
                  _formatNumber(likes),
                  'Likes',
                  const Color(0xFFE91E63),
                ),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                _buildEnhancedPostStat(
                  Icons.comment,
                  _formatNumber(comments),
                  'Comments',
                  const Color(0xFF2196F3),
                ),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                _buildEnhancedPostStat(
                  Icons.share,
                  _formatNumber(shares),
                  shares == post['saves'] ? 'Saves' : 'Shares',
                  const Color(0xFF4CAF50),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const Gap(6),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedPostStat(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const Gap(4),
        Text(
          value,
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> insights, Color color) {
    final entries = insights.entries.toList();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: entries.map((entry) {
        return Container(
          width: (MediaQuery.of(context).size.width - 56) / 2,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatInsightKey(entry.key),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Gap(8),
              Text(
                _formatNumber(entry.value),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatInsightKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  // New UI widgets
  Widget _buildHeroStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const Gap(16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Gap(4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementCard(
    IconData icon,
    String label,
    String value,
    Color color,
    double percentage,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              if (percentage > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          const Gap(12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Gap(4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPlatformCard(
    String platform,
    Map<String, dynamic> platformData,
  ) {
    final metrics = platformData['metrics'] as Map<String, dynamic>? ?? {};
    final accountName = platformData['accountName'] ?? '';

    Color color;
    IconData icon;
    switch (platform.toLowerCase()) {
      case 'facebook':
        color = const Color(0xFF1877F2);
        icon = Icons.facebook;
        break;
      case 'instagram':
        color = const Color(0xFFE4405F);
        icon = Icons.camera_alt;
        break;
      case 'pinterest':
        color = const Color(0xFFE60023);
        icon = Icons.push_pin;
        break;
      default:
        color = Colors.grey;
        icon = Icons.public;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.8), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      platform.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      accountName,
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
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
          const Gap(16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: metrics.entries.map((entry) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatInsightKey(entry.key),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Gap(6),
                    Text(
                      _formatNumber(entry.value),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
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
