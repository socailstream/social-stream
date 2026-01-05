# Cloudinary Media Upload Guide

## Overview
The backend now uses **Cloudinary** instead of Firebase Storage for all media uploads. Cloudinary provides better performance, automatic optimization, and powerful transformation capabilities.

## Configuration

### Environment Variables
The following variables are configured in `.env`:
```
CLOUDINARY_API_KEY=163469593474357
CLOUDINARY_API_SECRET=kfX_Qp7nq9zIHYt4vg_uaxi_fVI
CLOUDINARY_CLOUD_NAME=dbr7upaqm
```

## API Endpoints

All upload endpoints require authentication (Bearer token in Authorization header).

### Base URL
```
http://localhost:5000/api/upload
```

### 1. Upload Single Image
**POST** `/api/upload/image`

**Request:**
- Content-Type: `multipart/form-data`
- Body: `file` (form-data field with image file)

**Response:**
```json
{
  "success": true,
  "message": "Image uploaded successfully",
  "data": {
    "url": "https://res.cloudinary.com/dbr7upaqm/image/upload/v1234567890/social-stream/users/USER_ID/images/filename.jpg",
    "publicId": "social-stream/users/USER_ID/images/filename",
    "format": "jpg",
    "width": 1920,
    "height": 1080,
    "bytes": 245678,
    "resourceType": "image"
  }
}
```

### 2. Upload Single Video
**POST** `/api/upload/video`

**Request:**
- Content-Type: `multipart/form-data`
- Body: `file` (form-data field with video file)

**Response:**
```json
{
  "success": true,
  "message": "Video uploaded successfully",
  "data": {
    "url": "https://res.cloudinary.com/dbr7upaqm/video/upload/v1234567890/social-stream/users/USER_ID/videos/video.mp4",
    "publicId": "social-stream/users/USER_ID/videos/video",
    "format": "mp4",
    "duration": 30.5,
    "width": 1920,
    "height": 1080,
    "bytes": 5245678,
    "resourceType": "video"
  }
}
```

### 3. Upload Multiple Files
**POST** `/api/upload/multiple`

**Request:**
- Content-Type: `multipart/form-data`
- Body: `files` (multiple files in form-data)
- Max files: 10
- Max size: 100MB per file

**Response:**
```json
{
  "success": true,
  "message": "Files uploaded successfully",
  "count": 3,
  "data": [
    {
      "url": "https://res.cloudinary.com/...",
      "publicId": "social-stream/users/USER_ID/images/img1",
      "format": "jpg",
      "resourceType": "image"
    },
    {
      "url": "https://res.cloudinary.com/...",
      "publicId": "social-stream/users/USER_ID/videos/vid1",
      "format": "mp4",
      "resourceType": "video"
    }
  ]
}
```

### 4. Delete Media by Public ID
**DELETE** `/api/upload`

**Request:**
```json
{
  "publicId": "social-stream/users/USER_ID/images/filename",
  "resourceType": "image"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Media deleted successfully",
  "data": {
    "success": true,
    "message": "Media deleted successfully",
    "publicId": "social-stream/users/USER_ID/images/filename"
  }
}
```

### 5. Delete Media by URL
**DELETE** `/api/upload/by-url`

**Request:**
```json
{
  "url": "https://res.cloudinary.com/dbr7upaqm/image/upload/v1234567890/social-stream/users/USER_ID/images/filename.jpg",
  "resourceType": "image"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Media deleted successfully",
  "data": {
    "success": true,
    "message": "Media deleted successfully",
    "publicId": "social-stream/users/USER_ID/images/filename"
  }
}
```

### 6. Get Optimized Image URL
**GET** `/api/upload/optimize`

**Query Parameters:**
- `publicId` (required): Public ID of the image
- `width` (optional): Target width
- `height` (optional): Target height
- `quality` (optional): Quality setting (auto, best, good, eco, low)
- `format` (optional): Target format (jpg, png, webp, etc.)

**Example:**
```
GET /api/upload/optimize?publicId=social-stream/users/USER_ID/images/filename&width=800&quality=auto
```

**Response:**
```json
{
  "success": true,
  "data": {
    "url": "https://res.cloudinary.com/dbr7upaqm/image/upload/w_800,q_auto/social-stream/users/USER_ID/images/filename.jpg"
  }
}
```

## Usage Examples

### Using cURL

#### Upload Image
```bash
curl -X POST http://localhost:5000/api/upload/image \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@/path/to/image.jpg"
```

#### Upload Video
```bash
curl -X POST http://localhost:5000/api/upload/video \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@/path/to/video.mp4"
```

#### Upload Multiple Files
```bash
curl -X POST http://localhost:5000/api/upload/multiple \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "files=@/path/to/image1.jpg" \
  -F "files=@/path/to/image2.jpg" \
  -F "files=@/path/to/video.mp4"
```

#### Delete Media
```bash
curl -X DELETE http://localhost:5000/api/upload/by-url \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://res.cloudinary.com/dbr7upaqm/image/upload/v1234567890/social-stream/users/USER_ID/images/filename.jpg",
    "resourceType": "image"
  }'
```

### Using JavaScript/Fetch

```javascript
// Upload Image
const uploadImage = async (file, token) => {
  const formData = new FormData();
  formData.append('file', file);

  const response = await fetch('http://localhost:5000/api/upload/image', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`
    },
    body: formData
  });

  return await response.json();
};

// Upload Multiple Files
const uploadMultiple = async (files, token) => {
  const formData = new FormData();
  files.forEach(file => {
    formData.append('files', file);
  });

  const response = await fetch('http://localhost:5000/api/upload/multiple', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`
    },
    body: formData
  });

  return await response.json();
};

// Delete Media
const deleteMedia = async (url, resourceType, token) => {
  const response = await fetch('http://localhost:5000/api/upload/by-url', {
    method: 'DELETE',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ url, resourceType })
  });

  return await response.json();
};
```

### Using Flutter/Dart

```dart
import 'package:http/http.dart' as http;
import 'dart:io';

Future<Map<String, dynamic>> uploadImage(File file, String token) async {
  var request = http.MultipartRequest(
    'POST',
    Uri.parse('http://localhost:5000/api/upload/image'),
  );
  
  request.headers['Authorization'] = 'Bearer $token';
  request.files.add(await http.MultipartFile.fromPath('file', file.path));
  
  var response = await request.send();
  var responseData = await response.stream.bytesToString();
  
  return jsonDecode(responseData);
}

Future<Map<String, dynamic>> deleteMedia(String url, String token) async {
  final response = await http.delete(
    Uri.parse('http://localhost:5000/api/upload/by-url'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'url': url,
      'resourceType': 'image',
    }),
  );
  
  return jsonDecode(response.body);
}
```

## Features

### Automatic Optimizations
- **Quality Optimization**: Images are automatically optimized for web delivery
- **Format Conversion**: Automatic format selection (WebP for modern browsers)
- **Responsive Images**: Easy generation of different sizes for responsive design

### Supported File Types
- **Images**: JPG, PNG, GIF, WebP, SVG, BMP, TIFF
- **Videos**: MP4, MOV, AVI, MKV, WebM, FLV

### File Size Limits
- Maximum file size: **100MB** per file
- Maximum files per request (multiple upload): **10 files**

### Storage Structure
Files are organized by user and type:
```
social-stream/
  └── users/
      └── {userId}/
          ├── images/
          │   └── filename.jpg
          └── videos/
              └── video.mp4
```

## Transformation Examples

Cloudinary provides powerful on-the-fly transformations. You can append transformation parameters to any image URL:

### Resize
```
https://res.cloudinary.com/dbr7upaqm/image/upload/w_800,h_600,c_fill/social-stream/users/USER_ID/images/filename.jpg
```

### Quality
```
https://res.cloudinary.com/dbr7upaqm/image/upload/q_auto:best/social-stream/users/USER_ID/images/filename.jpg
```

### Format
```
https://res.cloudinary.com/dbr7upaqm/image/upload/f_webp/social-stream/users/USER_ID/images/filename.jpg
```

### Combined
```
https://res.cloudinary.com/dbr7upaqm/image/upload/w_800,h_600,c_fill,q_auto,f_auto/social-stream/users/USER_ID/images/filename.jpg
```

## Migration from Firebase Storage

If you have existing media in Firebase Storage, you'll need to:

1. Download existing media from Firebase
2. Upload to Cloudinary using the new endpoints
3. Update database records with new Cloudinary URLs
4. Delete old Firebase Storage files

## Error Handling

All endpoints return consistent error responses:

```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message"
}
```

Common errors:
- `400`: Invalid request (missing file, invalid parameters)
- `401`: Unauthorized (missing or invalid token)
- `413`: File too large
- `415`: Unsupported media type
- `500`: Server error (Cloudinary upload failed)

## Benefits over Firebase Storage

1. **Better Performance**: CDN-optimized delivery worldwide
2. **Automatic Optimization**: Images are automatically compressed and optimized
3. **Transformations**: On-the-fly image transformations (resize, crop, quality)
4. **Format Selection**: Automatic format selection based on browser support
5. **Cost-Effective**: More generous free tier and better pricing
6. **Rich Media**: Built-in support for video transformations and delivery
