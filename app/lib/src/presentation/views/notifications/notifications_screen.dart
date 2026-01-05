import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_stream_next/src/core/theme/app_colors.dart';
import 'package:social_stream_next/src/core/utils/timezone_helper.dart';
import 'package:social_stream_next/src/data/services/social_api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SocialApiService _apiService = SocialApiService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      final activities = await _apiService.getRecentActivity(limit: 50);
      if (mounted) {
        setState(() {
          _notifications = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatTime(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return TimezoneHelper.getRelativeTime(date);
    } catch (e) {
      return dateString;
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'published':
        return Icons.check_circle;
      case 'scheduled':
        return Icons.schedule;
      case 'failed':
        return Icons.error_outline;
      case 'likes':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'share':
        return Icons.share;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'published':
        return const Color(0xFF9C27B0);
      case 'scheduled':
        return const Color(0xFF2196F3);
      case 'failed':
        return const Color(0xFFF44336);
      case 'likes':
        return const Color(0xFFE91E63);
      case 'comment':
        return const Color(0xFF4CAF50);
      case 'share':
        return const Color(0xFF00BCD4);
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _getUnreadNotifications() {
    return _notifications.where((n) => n['isUnread'] == true).toList();
  }

  List<Map<String, dynamic>> _getTodayNotifications() {
    final today = TimezoneHelper.startOfDay();
    return _notifications.where((n) {
      try {
        final notifDate = DateTime.parse(n['time']);
        return notifDate.isAfter(today);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  List<Map<String, dynamic>> _getEarlierNotifications() {
    final today = TimezoneHelper.startOfDay();
    return _notifications.where((n) {
      try {
        final notifDate = DateTime.parse(n['time']);
        return notifDate.isBefore(today);
      } catch (e) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.done_all, color: AppColors.brandBlue, size: 20),
              ),
              onPressed: () {
                // Mark all as read
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read')),
                );
              },
              tooltip: 'Mark all as read',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.settings, color: Colors.black87, size: 20),
              ),
              onPressed: () {
                // Notification settings
              },
              tooltip: 'Settings',
            ),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : _buildAllNotifications(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[300],
          ),
          const Gap(16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const Gap(8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllNotifications() {
    final unreadNotifications = _getUnreadNotifications();
    final todayNotifications = _getTodayNotifications();
    final earlierNotifications = _getEarlierNotifications();

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Unread Section
          if (unreadNotifications.isNotEmpty) ...[
            _buildSectionHeader('Unread', unreadNotifications.length.toString()),
            const Gap(12),
            ...unreadNotifications.map((notification) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NotificationCard(
                icon: _getIconForType(notification['type'] ?? ''),
                title: notification['title'] ?? '',
                description: notification['description'] ?? '',
                time: _formatTime(notification['time']),
                color: _getColorForType(notification['type'] ?? ''),
                isUnread: notification['isUnread'] ?? false,
              ),
            )).toList(),
            const Gap(24),
          ],

          // Today Section
          if (todayNotifications.isNotEmpty) ...[
            _buildSectionHeader('Today', ''),
            const Gap(12),
            ...todayNotifications.map((notification) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NotificationCard(
                icon: _getIconForType(notification['type'] ?? ''),
                title: notification['title'] ?? '',
                description: notification['description'] ?? '',
                time: _formatTime(notification['time']),
                color: _getColorForType(notification['type'] ?? ''),
                isUnread: notification['isUnread'] ?? false,
              ),
            )).toList(),
            const Gap(24),
          ],

          // Earlier Section
          if (earlierNotifications.isNotEmpty) ...[
            _buildSectionHeader('Earlier', ''),
            const Gap(12),
            ...earlierNotifications.map((notification) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _NotificationCard(
                icon: _getIconForType(notification['type'] ?? ''),
                title: notification['title'] ?? '',
                description: notification['description'] ?? '',
                time: _formatTime(notification['time']),
                color: _getColorForType(notification['type'] ?? ''),
                isUnread: notification['isUnread'] ?? false,
              ),
            )).toList(),
          ],

          const Gap(16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String count) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: -0.3,
            ),
          ),
          if (count.isNotEmpty) ...[
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandBlue,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String time;
  final Color color;
  final bool isUnread;

  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
    required this.color,
    this.isUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Handle notification tap
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread ? color.withOpacity(0.3) : Colors.grey[200]!,
            width: isUnread ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const Gap(14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const Gap(8),
                      if (isUnread)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const Gap(6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(8),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[500]),
                      const Gap(5),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
