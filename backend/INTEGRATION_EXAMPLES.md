# Integration Examples

## How to Use Cloudinary in Your Social Stream App

### Example 1: Creating a Post with Media Upload

#### Frontend (Flutter/Dart)
```dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PostService {
  final String baseUrl = 'http://localhost:5000/api';
  
  /// Upload image and create post
  Future<Map<String, dynamic>> createPostWithMedia(
    File imageFile,
    String caption,
    List<String> platforms,
    String token,
  ) async {
    // Step 1: Upload image to Cloudinary
    var uploadRequest = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload/image'),
    );
    
    uploadRequest.headers['Authorization'] = 'Bearer $token';
    uploadRequest.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );
    
    var uploadResponse = await uploadRequest.send();
    var uploadData = await uploadResponse.stream.bytesToString();
    var uploadJson = jsonDecode(uploadData);
    
    if (!uploadJson['success']) {
      throw Exception('Failed to upload image');
    }
    
    String imageUrl = uploadJson['data']['url'];
    
    // Step 2: Create post with the uploaded image URL
    var postResponse = await http.post(
      Uri.parse('$baseUrl/posts'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'content': caption,
        'mediaUrls': [imageUrl],
        'platforms': platforms,
        'status': 'published',
      }),
    );
    
    return jsonDecode(postResponse.body);
  }
  
  /// Upload multiple images
  Future<List<String>> uploadMultipleImages(
    List<File> files,
    String token,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload/multiple'),
    );
    
    request.headers['Authorization'] = 'Bearer $token';
    
    for (var file in files) {
      request.files.add(
        await http.MultipartFile.fromPath('files', file.path),
      );
    }
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    var json = jsonDecode(responseData);
    
    if (!json['success']) {
      throw Exception('Failed to upload images');
    }
    
    return (json['data'] as List)
        .map((item) => item['url'] as String)
        .toList();
  }
  
  /// Delete media when post is deleted
  Future<void> deletePostMedia(String mediaUrl, String token) async {
    await http.delete(
      Uri.parse('$baseUrl/upload/by-url'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'url': mediaUrl,
        'resourceType': mediaUrl.contains('/video/') ? 'video' : 'image',
      }),
    );
  }
}
```

### Example 2: Backend Post Creation with Cloudinary URLs

#### Backend (Node.js) - Update Post Controller

Add this helper function to your post controller:

```javascript
// controllers/post.controller.js

/**
 * Create post with media upload
 * Handles both direct URL and file upload
 */
exports.createPostWithMedia = async (req, res) => {
  try {
    const { content, platforms, scheduledDate, status = 'draft' } = req.body;
    let mediaUrls = [];

    // If files are uploaded in the request
    if (req.files && req.files.length > 0) {
      const cloudinaryService = require('../services/cloudinary.service');
      
      // Upload all files to Cloudinary
      const uploadPromises = req.files.map(file => {
        const isVideo = file.mimetype.startsWith('video/');
        const folder = `social-stream/users/${req.user._id}/${isVideo ? 'videos' : 'images'}`;
        
        if (isVideo) {
          return cloudinaryService.uploadVideo(file.buffer, { folder });
        }
        return cloudinaryService.uploadImage(file.buffer, { folder });
      });
      
      const uploadResults = await Promise.all(uploadPromises);
      mediaUrls = uploadResults.map(result => result.url);
    }

    // Create the post
    const post = new Post({
      user: req.user._id,
      content,
      mediaUrls,
      platforms,
      scheduledDate: scheduledDate ? new Date(scheduledDate) : undefined,
      status
    });

    await post.save();
    await post.populate('user', 'displayName photoURL email');

    res.status(201).json({
      success: true,
      message: 'Post created successfully',
      data: post
    });
  } catch (error) {
    console.error('❌ Create post with media error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create post',
      error: error.message
    });
  }
};

/**
 * Delete post and its media from Cloudinary
 */
exports.deletePostWithMedia = async (req, res) => {
  try {
    const post = await Post.findById(req.params.id);

    if (!post) {
      return res.status(404).json({
        success: false,
        message: 'Post not found'
      });
    }

    // Verify ownership
    if (post.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this post'
      });
    }

    // Delete media from Cloudinary
    if (post.mediaUrls && post.mediaUrls.length > 0) {
      const cloudinaryService = require('../services/cloudinary.service');
      
      for (const url of post.mediaUrls) {
        try {
          const publicId = cloudinaryService.extractPublicId(url);
          if (publicId) {
            const resourceType = url.includes('/video/') ? 'video' : 'image';
            await cloudinaryService.deleteMedia(publicId, resourceType);
          }
        } catch (error) {
          console.error('Failed to delete media:', url, error.message);
          // Continue even if media deletion fails
        }
      }
    }

    // Delete the post
    await post.deleteOne();

    res.status(200).json({
      success: true,
      message: 'Post and media deleted successfully'
    });
  } catch (error) {
    console.error('❌ Delete post with media error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete post',
      error: error.message
    });
  }
};
```

### Example 3: Image Optimization for Different Platforms

```javascript
// services/cloudinary.service.js - Add these helper methods

/**
 * Get optimized image URLs for different social media platforms
 */
getOptimizedForPlatform(publicId, platform) {
  const platformSpecs = {
    instagram: {
      post: { width: 1080, height: 1080, crop: 'fill' },
      story: { width: 1080, height: 1920, crop: 'fill' }
    },
    facebook: {
      post: { width: 1200, height: 630, crop: 'fill' },
      cover: { width: 820, height: 312, crop: 'fill' }
    },
    pinterest: {
      pin: { width: 1000, height: 1500, crop: 'fill' }
    },
    twitter: {
      post: { width: 1200, height: 675, crop: 'fill' }
    }
  };

  const spec = platformSpecs[platform]?.post || { width: 1200, height: 630 };
  
  return cloudinary.url(publicId, {
    ...spec,
    quality: 'auto',
    fetch_format: 'auto'
  });
}
```

### Example 4: Video Processing

```javascript
/**
 * Upload video with automatic optimization
 */
async uploadOptimizedVideo(file, options = {}) {
  const defaultOptions = {
    folder: 'social-stream/videos',
    resource_type: 'video',
    transformation: [
      { quality: 'auto' },
      { video_codec: 'auto' },
      { audio_codec: 'auto' }
    ],
    eager: [
      { 
        width: 1080, 
        height: 1920, 
        crop: 'fill',
        format: 'mp4',
        video_codec: 'h264'
      }
    ],
    eager_async: true,
    ...options
  };

  return await this.uploadVideo(file, defaultOptions);
}
```

### Example 5: Thumbnail Generation

```javascript
// When creating a post with video, generate thumbnail
async function createVideoPostWithThumbnail(videoFile, caption, token) {
  // Upload video
  const videoResult = await cloudinaryService.uploadVideo(videoFile.buffer);
  
  // Generate thumbnail from video
  const thumbnailUrl = cloudinaryService.getThumbnailUrl(
    videoResult.publicId,
    640,
    360
  );
  
  // Create post with both video and thumbnail
  const post = await Post.create({
    user: userId,
    content: caption,
    mediaUrls: [videoResult.url],
    thumbnailUrl: thumbnailUrl,
    status: 'published'
  });
  
  return post;
}
```

### Example 6: Batch Upload with Progress

```dart
// Flutter - Upload multiple images with progress tracking
Future<void> uploadImagesWithProgress(
  List<File> files,
  String token,
  Function(double) onProgress,
) async {
  List<String> uploadedUrls = [];
  
  for (int i = 0; i < files.length; i++) {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload/image'),
    );
    
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      await http.MultipartFile.fromPath('file', files[i].path),
    );
    
    var response = await request.send();
    var data = await response.stream.bytesToString();
    var json = jsonDecode(data);
    
    if (json['success']) {
      uploadedUrls.add(json['data']['url']);
    }
    
    // Update progress
    onProgress((i + 1) / files.length);
  }
  
  return uploadedUrls;
}
```

## Best Practices

1. **Always upload media first**, then create the post with the returned URLs
2. **Delete media from Cloudinary** when posts are deleted
3. **Use transformation parameters** in URLs for responsive images
4. **Cache thumbnail URLs** to avoid generating them repeatedly
5. **Handle upload errors gracefully** and provide user feedback
6. **Validate file types and sizes** on the frontend before uploading
7. **Use progressive upload** for better user experience with large files

## Common Patterns

### Pattern 1: Upload → Create Post → Publish
```javascript
1. Upload media to Cloudinary → Get URL
2. Create post in MongoDB with URL
3. Publish to social media platforms using the Cloudinary URL
```

### Pattern 2: Optimized Multi-Platform Posting
```javascript
1. Upload original media to Cloudinary
2. Generate platform-specific optimized URLs
3. Post to each platform with its optimized version
```

### Pattern 3: Draft with Scheduled Publishing
```javascript
1. Upload media to Cloudinary
2. Create draft post with media URLs
3. Schedule post for later
4. Scheduler service publishes using stored URLs
```
