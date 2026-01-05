import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:social_stream_next/src/core/theme/app_colors.dart';
import 'package:social_stream_next/src/core/utils/timezone_helper.dart';
import 'package:social_stream_next/src/data/services/social_api_service.dart';
import 'package:social_stream_next/src/presentation/views/posts/add_post_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = TimezoneHelper.now();
  DateTime _focusedMonth = TimezoneHelper.now();
  String _selectedFilter = 'All';
  bool _isLoading = false;
  List<Map<String, dynamic>> _posts = [];
  final SocialApiService _apiService = SocialApiService();

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    
    try {
      // Get first and last day of current month
      final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
      final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0, 23, 59, 59);
      
      final posts = await _apiService.getPostsByDateRange(
        startDate: firstDay,
        endDate: lastDay,
        platform: _selectedFilter != 'All' ? _selectedFilter.toLowerCase() : null,
      );
      
      if (mounted) {
        setState(() {
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading posts: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Calendar',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: _selectedFilter != 'All' 
                                ? AppColors.brandBlue.withOpacity(0.1)
                                : Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.filter_list_rounded,
                                color: _selectedFilter != 'All' 
                                  ? AppColors.brandBlue 
                                  : Colors.black87,
                                size: 22,
                              ),
                              onPressed: _showFilterDialog,
                              tooltip: 'Filter',
                            ),
                          ),
                          const Gap(8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.today_rounded,
                                color: Colors.black87,
                                size: 22,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedDate = TimezoneHelper.now();
                                  _focusedMonth = TimezoneHelper.now();
                                });
                              },
                              tooltip: 'Today',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Filter Chips
                  if (_selectedFilter != 'All')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.brandBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.brandBlue.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedFilter,
                                  style: TextStyle(
                                    color: AppColors.brandBlue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const Gap(6),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedFilter = 'All';
                                    });
                                  },
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: AppColors.brandBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Calendar View
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Gap(16),
                    // Month Navigator
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.chevron_left_rounded, size: 24),
                              onPressed: () {
                                setState(() {
                                  _focusedMonth = DateTime(
                                    _focusedMonth.year,
                                    _focusedMonth.month - 1,
                                  );
                                });
                                _loadPosts();
                              },
                            ),
                          ),
                          Text(
                            '${_getMonthName(_focusedMonth.month)} ${_focusedMonth.year}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.chevron_right_rounded, size: 24),
                              onPressed: () {
                                setState(() {
                                  _focusedMonth = DateTime(
                                    _focusedMonth.year,
                                    _focusedMonth.month + 1,
                                  );
                                });
                                _loadPosts();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Gap(16),

                    // Calendar Grid
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width - 32,
                          ),
                          child: _buildCalendarGrid(),
                        ),
                      ),
                    ),

                    const Gap(20),

                    // Selected Date Posts
                    _buildSelectedDatePosts(),

                    const Gap(80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.brandBlue,
              const Color(0xFFB429F9),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandBlue.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddPostScreen()),
            ).then((_) => _loadPosts()); // Reload posts after returning
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text(
            'Create Post',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday % 7;

    return Column(
      children: [
        // Week days header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((day) => SizedBox(
                    width: 44,
                    child: Center(
                      child: Text(
                        day,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.grey[700],
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const Gap(12),
        // Calendar days
        ...List.generate(
          ((daysInMonth + startWeekday) / 7).ceil(),
          (weekIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (dayIndex) {
                  final dayNumber = weekIndex * 7 + dayIndex - startWeekday + 1;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox(width: 44, height: 44);
                  }

                  final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
                  final isSelected = _isSameDay(date, _selectedDate);
                  final isToday = _isSameDay(date, TimezoneHelper.now());
                  final postCount = _getPostCountForDate(date);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  AppColors.brandBlue,
                                  AppColors.brandBlue.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected
                            ? null
                            : isToday
                                ? AppColors.brandBlue.withOpacity(0.08)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isToday && !isSelected
                            ? Border.all(color: AppColors.brandBlue, width: 2)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.brandBlue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                fontSize: 15,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          if (postCount > 0)
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : AppColors.brandBlue,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Center(
                                  child: Text(
                                    '$postCount',
                                    style: TextStyle(
                                      color: isSelected ? AppColors.brandBlue : Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectedDatePosts() {
    final posts = _getPostsForDate(_selectedDate);
    final isToday = _isSameDay(_selectedDate, TimezoneHelper.now());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday ? 'Today\'s Posts' : 'Posts on ${_selectedDate.day} ${_getMonthName(_selectedDate.month)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      '${posts.length} ${posts.length == 1 ? 'post' : 'posts'} scheduled',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(20),
          if (posts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.event_busy_rounded,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    ),
                    const Gap(16),
                    Text(
                      'No posts scheduled',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      'Create a post for this day',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...posts.map((post) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PostItem(post: post),
                )),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  int _getPostCountForDate(DateTime date) {
    return _posts.where((post) {
      final scheduledDate = DateTime.tryParse(post['scheduledDate']?.toString() ?? '');
      if (scheduledDate == null) return false;
      
      return scheduledDate.year == date.year &&
          scheduledDate.month == date.month &&
          scheduledDate.day == date.day;
    }).length;
  }

  List<Map<String, dynamic>> _getPostsForDate(DateTime date) {
    return _posts.where((post) {
      final scheduledDate = DateTime.tryParse(post['scheduledDate']?.toString() ?? '');
      if (scheduledDate == null) return false;
      
      return scheduledDate.year == date.year &&
          scheduledDate.month == date.month &&
          scheduledDate.day == date.day;
    }).map((post) {
      // Format the post data for UI
      final scheduledDate = DateTime.parse(post['scheduledDate']);
      final hour = scheduledDate.hour > 12 ? scheduledDate.hour - 12 : scheduledDate.hour;
      final minute = scheduledDate.minute.toString().padLeft(2, '0');
      final period = scheduledDate.hour >= 12 ? 'PM' : 'AM';
      
      final platforms = (post['platforms'] as List?)?.map((p) => p.toString()).toList() ?? 
          [post['platform']?.toString() ?? 'Unknown'];
      
      // Capitalize platform names
      final formattedPlatforms = platforms.map((p) => 
        p.substring(0, 1).toUpperCase() + p.substring(1).toLowerCase()
      ).toList();
      
      final content = post['content']?.toString() ?? 'Untitled Post';
      final truncatedContent = content.length > 50 ? '${content.substring(0, 50)}...' : content;
      
      return {
        'title': truncatedContent,
        'time': '$hour:$minute $period',
        'platforms': formattedPlatforms,
        'status': (post['status']?.toString() ?? 'scheduled').substring(0, 1).toUpperCase() + 
                  (post['status']?.toString() ?? 'scheduled').substring(1),
      };
    }).toList();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Filter Posts',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4),
                child: Text(
                  'Platforms',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              _FilterOption('All', _selectedFilter == 'All', Icons.apps_rounded),
              _FilterOption('Facebook', _selectedFilter == 'Facebook', Icons.facebook),
              _FilterOption('Instagram', _selectedFilter == 'Instagram', Icons.photo_camera_rounded),
              _FilterOption('Pinterest', _selectedFilter == 'Pinterest', Icons.push_pin),
              const Gap(16),
              Divider(color: Colors.grey[300], thickness: 1),
              const Gap(16),
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4),
                child: Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              _FilterOption('Scheduled', _selectedFilter == 'Scheduled', Icons.schedule_rounded),
              _FilterOption('Posted', _selectedFilter == 'Posted', Icons.check_circle_rounded),
              _FilterOption('Draft', _selectedFilter == 'Draft', Icons.drafts_rounded),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _FilterOption(String label, bool isSelected, IconData icon) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
        Navigator.pop(context);
        _loadPosts(); // Reload posts with new filter
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandBlue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.brandBlue.withOpacity(0.3) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                  ? AppColors.brandBlue.withOpacity(0.15) 
                  : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.brandBlue : Colors.grey[600],
              ),
            ),
            const Gap(12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.brandBlue : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.brandBlue,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _PostItem extends StatelessWidget {
  final Map<String, dynamic> post;

  const _PostItem({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.brandBlue,
                  const Color(0xFFB429F9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['title'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: (post['platforms'] as List<String>)
                      .map((platform) => _PlatformBadge(platform: platform))
                      .toList(),
                ),
                const Gap(6),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[500]),
                    const Gap(4),
                    Text(
                      post['time'],
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              post['status'],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.brandBlue,
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

  IconData _getPlatformIcon() {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.photo_camera_rounded;
      case 'pinterest':
        return Icons.push_pin;
      default:
        return Icons.public;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getPlatformColor().withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _getPlatformColor().withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPlatformIcon(),
            size: 11,
            color: _getPlatformColor(),
          ),
          const Gap(4),
          Text(
            platform,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: _getPlatformColor(),
            ),
          ),
        ],
      ),
    );
  }
}
