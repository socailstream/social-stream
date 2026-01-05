import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:social_stream_next/src/core/config/env_config.dart';

/// Service for uploading media to Cloudinary via backend API
class CloudinaryService {
  // Get base URL for upload endpoints
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return EnvConfig.ngrokBaseUrl;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'http://localhost:5000';
    } else {
      return 'http://192.168.1.100:5000';
    }
  }

  Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  String _getExtensionFromXFile(XFile file) {
    final name = (file.name.isNotEmpty ? file.name : file.path).toLowerCase();
    final parts = name.split('.');
    if (parts.length < 2) return 'jpg';
    return parts.last;
  }

  MediaType _guessMediaType({required String resourceType, required String ext}) {
    final e = ext.toLowerCase();
    if (resourceType == 'video') {
      if (e == 'mov') return MediaType('video', 'quicktime');
      if (e == 'avi') return MediaType('video', 'x-msvideo');
      if (e == 'mkv') return MediaType('video', 'x-matroska');
      if (e == 'webm') return MediaType('video', 'webm');
      return MediaType('video', 'mp4');
    }

    if (e == 'png') return MediaType('image', 'png');
    if (e == 'gif') return MediaType('image', 'gif');
    if (e == 'webp') return MediaType('image', 'webp');
    if (e == 'heic' || e == 'heif') return MediaType('image', 'heic');
    return MediaType('image', 'jpeg');
  }

  Future<http.MultipartFile> _buildMultipartFile({
    required XFile file,
    required String fieldName,
    required MediaType contentType,
  }) async {
    if (kIsWeb) {
      final Uint8List bytes = await file.readAsBytes();
      return http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: file.name.isNotEmpty ? file.name : 'upload',
        contentType: contentType,
      );
    }

    return http.MultipartFile.fromPath(
      fieldName,
      file.path,
      contentType: contentType,
    );
  }

  /// Upload an image XFile to Cloudinary
  Future<CloudinaryUploadResult> uploadImageXFile(XFile file) async {
    try {
      final token = await _getAuthToken();
      
      if (token == null) {
        throw Exception('Not authenticated. Please login again.');
      }
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/upload/image'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';

      final ext = _getExtensionFromXFile(file);
      final mediaType = _guessMediaType(resourceType: 'image', ext: ext);
      request.files.add(await _buildMultipartFile(
        file: file,
        fieldName: 'file',
        contentType: mediaType,
      ));
      
      print('📤 Uploading image to Cloudinary...');
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: $responseData');
      
      var json = jsonDecode(responseData);
      
      if (response.statusCode == 200 && json['success']) {
        print('✅ Image uploaded successfully');
        return CloudinaryUploadResult.fromJson(json['data']);
      } else {
        print('❌ Upload failed: ${json['message']}');
        throw Exception(json['message'] ?? 'Upload failed');
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload a video XFile to Cloudinary
  Future<CloudinaryUploadResult> uploadVideoXFile(XFile file) async {
    try {
      final token = await _getAuthToken();
      
      if (token == null) {
        throw Exception('Not authenticated. Please login again.');
      }
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/upload/video'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';

      final ext = _getExtensionFromXFile(file);
      final mediaType = _guessMediaType(resourceType: 'video', ext: ext);
      request.files.add(await _buildMultipartFile(
        file: file,
        fieldName: 'file',
        contentType: mediaType,
      ));
      
      print('📤 Uploading video to Cloudinary...');
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var json = jsonDecode(responseData);
      
      if (response.statusCode == 200 && json['success']) {
        print('✅ Video uploaded successfully');
        return CloudinaryUploadResult.fromJson(json['data']);
      } else {
        throw Exception(json['message'] ?? 'Upload failed');
      }
    } catch (e) {
      print('❌ Error uploading video: $e');
      throw Exception('Failed to upload video: $e');
    }
  }

  /// Upload multiple files to Cloudinary
  Future<List<CloudinaryUploadResult>> uploadMultipleXFiles(List<XFile> files) async {
    try {
      final token = await _getAuthToken();
      
      if (token == null) {
        throw Exception('Not authenticated. Please login again.');
      }
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/upload/multiple'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      
      for (var file in files) {
        final ext = _getExtensionFromXFile(file);
        final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
        final mediaType = _guessMediaType(
          resourceType: isVideo ? 'video' : 'image',
          ext: ext,
        );
        request.files.add(await _buildMultipartFile(
          file: file,
          fieldName: 'files',
          contentType: mediaType,
        ));
      }
      
      print('📤 Uploading ${files.length} files to Cloudinary...');
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var json = jsonDecode(responseData);
      
      if (response.statusCode == 200 && json['success']) {
        print('✅ ${files.length} files uploaded successfully');
        List<CloudinaryUploadResult> results = [];
        for (var item in json['data']) {
          results.add(CloudinaryUploadResult.fromJson(item));
        }
        return results;
      } else {
        throw Exception(json['message'] ?? 'Upload failed');
      }
    } catch (e) {
      print('❌ Error uploading files: $e');
      throw Exception('Failed to upload files: $e');
    }
  }

  /// Delete media from Cloudinary by URL
  Future<void> deleteMedia(String url) async {
    try {
      final token = await _getAuthToken();
      
      if (token == null) {
        throw Exception('Not authenticated. Please login again.');
      }
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/upload/by-url'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'url': url,
          'resourceType': url.contains('/video/') ? 'video' : 'image',
        }),
      );
      
      final json = jsonDecode(response.body);
      
      if (response.statusCode == 200 && json['success']) {
        print('✅ Media deleted successfully');
      } else {
        throw Exception(json['message'] ?? 'Delete failed');
      }
    } catch (e) {
      print('❌ Error deleting media: $e');
      throw Exception('Failed to delete media: $e');
    }
  }

  /// Get optimized image URL with transformations
  Future<String> getOptimizedUrl({
    required String publicId,
    int? width,
    int? height,
    String? quality,
    String? format,
  }) async {
    try {
      final token = await _getAuthToken();
      
      if (token == null) {
        throw Exception('Not authenticated. Please login again.');
      }
      
      final queryParams = <String, String>{
        'publicId': publicId,
        if (width != null) 'width': width.toString(),
        if (height != null) 'height': height.toString(),
        if (quality != null) 'quality': quality,
        if (format != null) 'format': format,
      };
      
      final uri = Uri.parse('$baseUrl/api/upload/optimize')
          .replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      final json = jsonDecode(response.body);
      
      if (response.statusCode == 200 && json['success']) {
        return json['data']['url'];
      } else {
        throw Exception(json['message'] ?? 'Failed to get optimized URL');
      }
    } catch (e) {
      print('❌ Error getting optimized URL: $e');
      throw Exception('Failed to get optimized URL: $e');
    }
  }
}

/// Result of a Cloudinary upload
class CloudinaryUploadResult {
  final String url;
  final String publicId;
  final String format;
  final int? width;
  final int? height;
  final int bytes;
  final String resourceType;
  final double? duration; // For videos

  CloudinaryUploadResult({
    required this.url,
    required this.publicId,
    required this.format,
    this.width,
    this.height,
    required this.bytes,
    required this.resourceType,
    this.duration,
  });

  factory CloudinaryUploadResult.fromJson(Map<String, dynamic> json) {
    return CloudinaryUploadResult(
      url: json['url'],
      publicId: json['publicId'],
      format: json['format'],
      width: json['width'],
      height: json['height'],
      bytes: json['bytes'],
      resourceType: json['resourceType'],
      duration: json['duration']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'publicId': publicId,
      'format': format,
      'width': width,
      'height': height,
      'bytes': bytes,
      'resourceType': resourceType,
      'duration': duration,
    };
  }
}
