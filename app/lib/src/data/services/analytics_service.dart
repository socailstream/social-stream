import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social_stream_next/src/core/config/env_config.dart';

class AnalyticsOverview {
  final int totalPosts;
  final Map<String, dynamic> totalEngagement;
  final List<Map<String, dynamic>> platforms;
  final String period;

  AnalyticsOverview({
    required this.totalPosts,
    required this.totalEngagement,
    required this.platforms,
    required this.period,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverview(
      totalPosts: json['totalPosts'] ?? 0,
      totalEngagement: json['totalEngagement'] ?? {},
      platforms: (json['platforms'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ?? [],
      period: json['period'] ?? 'last_30_days',
    );
  }
}

class PlatformMetrics {
  final String platform;
  final Map<String, dynamic> insights;
  final List<Map<String, dynamic>> recentPosts;

  PlatformMetrics({
    required this.platform,
    required this.insights,
    required this.recentPosts,
  });

  factory PlatformMetrics.fromJson(Map<String, dynamic> json, String platform) {
    return PlatformMetrics(
      platform: platform,
      insights: json['insights'] ?? {},
      recentPosts: (json['recentPosts'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}

class AnalyticsService {
  // Automatically detect platform and use correct URL
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/analytics';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return '${EnvConfig.ngrokBaseUrl}/api/analytics';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://localhost:5000/api/analytics';
    } else {
      return 'http://192.168.1.100:5000/api/analytics';
    }
  }

  Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get analytics overview across all platforms
  Future<AnalyticsOverview> getOverview() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      print('📡 Fetching analytics overview from: $baseUrl/overview');
      final response = await http.get(
        Uri.parse('$baseUrl/overview'),
        headers: _getHeaders(token),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('📥 Analytics overview status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final data = responseData['data'] ?? responseData;
        print('📊 Parsed analytics data: platforms count = ${(data['platforms'] as List?)?.length ?? 0}');
        return AnalyticsOverview.fromJson(data);
      } else {
        print('❌ Error response: ${response.body}');
        throw Exception('Failed to load analytics: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Analytics overview error: $e');
      rethrow;
    }
  }

  /// Get Facebook-specific metrics
  Future<PlatformMetrics> getFacebookMetrics() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      print('📡 Fetching Facebook metrics from: $baseUrl/facebook');
      final response = await http.get(
        Uri.parse('$baseUrl/facebook'),
        headers: _getHeaders(token),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('📥 Facebook metrics status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final data = responseData['data'] ?? responseData;
        return PlatformMetrics.fromJson(data, 'facebook');
      } else {
        throw Exception('Failed to load Facebook metrics: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Facebook metrics error: $e');
      rethrow;
    }
  }

  /// Get Instagram-specific metrics
  Future<PlatformMetrics> getInstagramMetrics() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      print('📡 Fetching Instagram metrics from: $baseUrl/instagram');
      final response = await http.get(
        Uri.parse('$baseUrl/instagram'),
        headers: _getHeaders(token),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('📥 Instagram metrics status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final data = responseData['data'] ?? responseData;
        return PlatformMetrics.fromJson(data, 'instagram');
      } else {
        throw Exception('Failed to load Instagram metrics: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Instagram metrics error: $e');
      rethrow;
    }
  }

  /// Get Pinterest-specific metrics
  Future<PlatformMetrics> getPinterestMetrics() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      print('📡 Fetching Pinterest metrics from: $baseUrl/pinterest');
      final response = await http.get(
        Uri.parse('$baseUrl/pinterest'),
        headers: _getHeaders(token),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('📥 Pinterest metrics status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final data = responseData['data'] ?? responseData;
        return PlatformMetrics.fromJson(data, 'pinterest');
      } else {
        throw Exception('Failed to load Pinterest metrics: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Pinterest metrics error: $e');
      rethrow;
    }
  }

  /// Get metrics for a specific post
  Future<Map<String, dynamic>> getPostMetrics(String postId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      print('📡 Fetching post metrics from: $baseUrl/post/$postId');
      final response = await http.get(
        Uri.parse('$baseUrl/post/$postId'),
        headers: _getHeaders(token),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('📥 Post metrics status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load post metrics: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Post metrics error: $e');
      rethrow;
    }
  }

  /// Get engagement trends over time
  Future<Map<String, dynamic>> getTrends({int days = 7}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      print('📡 Fetching trends from: $baseUrl/trends?days=$days');
      final response = await http.get(
        Uri.parse('$baseUrl/trends?days=$days'),
        headers: _getHeaders(token),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      print('📥 Trends status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load trends: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Trends error: $e');
      rethrow;
    }
  }
}
