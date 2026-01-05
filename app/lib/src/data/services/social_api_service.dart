import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:social_stream_next/src/core/utils/timezone_helper.dart';
import 'package:social_stream_next/src/core/config/env_config.dart';

class ConnectedAccount {
  final String platform;
  final String accountId;
  final String accountName;
  final String? profileImage;
  final bool isActive;
  final DateTime connectedAt;
  final DateTime? expiresAt;

  ConnectedAccount({
    required this.platform,
    required this.accountId,
    required this.accountName,
    this.profileImage,
    required this.isActive,
    required this.connectedAt,
    this.expiresAt,
  });

  factory ConnectedAccount.fromJson(Map<String, dynamic> json) {
    try {
      return ConnectedAccount(
        platform: json['platform'] ?? '',
        accountId: json['accountId'] ?? '',
        accountName: json['accountName'] ?? 'Unknown',
        profileImage: json['profileImage'],
        isActive: json['isActive'] ?? true,
        connectedAt: json['connectedAt'] != null 
            ? DateTime.parse(json['connectedAt']) 
            : TimezoneHelper.now(),
        expiresAt: json['expiresAt'] != null 
            ? DateTime.parse(json['expiresAt']) 
            : null,
      );
    } catch (e) {
      print('❌ Error parsing ConnectedAccount: $e');
      print('JSON: $json');
      rethrow;
    }
  }
}

class SocialApiService {
  // Automatically detect platform and use correct URL
  static String get baseUrl {
    if (kIsWeb) {
      // Web - use localhost or same origin
      return 'http://localhost:5000/api/social';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android Emulator - use ngrok URL from env
      return '${EnvConfig.ngrokBaseUrl}/api/social';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS Simulator
      return 'http://localhost:5000/api/social';
    } else {
      // For real devices, update this with your computer's IP
      // Find your IP: ipconfig (Windows) or ifconfig (Mac/Linux)
      return 'http://192.168.1.100:5000/api/social';
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

  /// Get all connected accounts
  Future<List<ConnectedAccount>> getConnectedAccounts() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        print('❌ No auth token - user not logged in');
        throw Exception('Not authenticated');
      }

      print('📡 Calling: $baseUrl/accounts');
      final response = await http.get(
        Uri.parse('$baseUrl/accounts'),
        headers: _getHeaders(token),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - check if backend is running');
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final List accounts = data['data'] ?? [];
          print('✅ Found ${accounts.length} connected accounts');
          
          // Parse each account safely
          List<ConnectedAccount> parsedAccounts = [];
          for (var acc in accounts) {
            try {
              parsedAccounts.add(ConnectedAccount.fromJson(acc));
            } catch (e) {
              print('⚠️ Skipping invalid account: $e');
            }
          }
          
          return parsedAccounts;
        } else {
          print('⚠️ API returned success=false');
          return [];
        }
      } else {
        print('❌ API error: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('API returned ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching connected accounts: $e');
      rethrow; // Re-throw to show error to user
    }
  }

  /// Connect Facebook account
  Future<String?> connectFacebook() async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/facebook/connect'),
        headers: _getHeaders(token),
      );
      print('📡 Facebook connect response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['authUrl'];
        }
      }
      return null;
    } catch (e) {
      print('Error connecting Facebook: $e');
      return null;
    }
  }

  /// Connect Instagram account
  Future<String?> connectInstagram() async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/instagram/connect'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['authUrl'];
        }
      }
      return null;
    } catch (e) {
      print('Error connecting Instagram: $e');
      return null;
    }
  }

  /// Connect Pinterest account
  Future<String?> connectPinterest() async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.get(
        Uri.parse('$baseUrl/pinterest/connect'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['authUrl'];
        }
      }
      return null;
    } catch (e) {
      print('Error connecting Pinterest: $e');
      return null;
    }
  }

  /// Disconnect account
  Future<bool> disconnectAccount(String platform) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Not authenticated');

      final response = await http.delete(
        Uri.parse('$baseUrl/$platform/disconnect'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error disconnecting $platform: $e');
      return false;
    }
  }

  /// Publish post to social media platforms
  Future<Map<String, dynamic>> publishPost({
    required String caption,
    String? mediaUrl,
    required List<String> platforms,
    DateTime? scheduledDate,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Not authenticated');

      final postUrl = baseUrl.replaceAll('/social', '/posts/publish');
      print('📡 Publishing to: $postUrl');
      
      final body = {
        'caption': caption,
        'platforms': platforms,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (scheduledDate != null) 'scheduledDate': scheduledDate.toIso8601String(),
      };

      print('📤 Request body: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse(postUrl),
        headers: _getHeaders(token),
        body: json.encode(body),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - posting may take some time');
        },
      );

      print('📥 Publish response status: ${response.statusCode}');
      print('📥 Publish response body: ${response.body}');

      final data = json.decode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 400) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to publish post');
      }
    } catch (e) {
      print('❌ Error publishing post: $e');
      rethrow;
    }
  }

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Not authenticated');

      final dashboardUrl = baseUrl.replaceAll('/social', '/dashboard/stats');
      
      final response = await http.get(
        Uri.parse(dashboardUrl),
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['data'];
        }
      }
      throw Exception('Failed to load dashboard stats');
    } catch (e) {
      print('❌ Error fetching dashboard stats: $e');
      rethrow;
    }
  }

  /// Get scheduled posts
  Future<List<Map<String, dynamic>>> getScheduledPosts() async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Not authenticated');

      final postsUrl = baseUrl.replaceAll('/social', '/posts/scheduled');
      
      final response = await http.get(
        Uri.parse(postsUrl),
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching scheduled posts: $e');
      return [];
    }
  }

  /// Get recent activity
  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 10}) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Not authenticated');

      final activityUrl = baseUrl.replaceAll('/social', '/dashboard/activity?limit=$limit');
      
      final response = await http.get(
        Uri.parse(activityUrl),
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching recent activity: $e');
      return [];
    }
  }

  /// Get posts by date range for calendar view
  Future<List<Map<String, dynamic>>> getPostsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? platform,
    String? status,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) throw Exception('Not authenticated');

      final queryParams = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        if (platform != null && platform != 'All') 'platform': platform,
        if (status != null && status != 'All') 'status': status,
      };

      final uri = Uri.parse(baseUrl.replaceAll('/social', '/posts/by-date-range'))
          .replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['data'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching posts by date range: $e');
      return [];
    }
  }
}
