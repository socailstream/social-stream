import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_stream_next/src/core/theme/app_colors.dart';
import 'package:social_stream_next/src/data/services/cloudinary_service.dart';
import 'package:social_stream_next/src/data/providers/user_provider.dart';
import 'package:social_stream_next/src/data/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = false;
  bool _isInitialized = false;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _currentProfilePicUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _initializeUserData(dynamic userData, dynamic currentUser) {
    if (!_isInitialized) {
      // Initialize with userData if available, otherwise use currentUser data
      _nameController.text = userData?.name ?? currentUser?.displayName ?? '';
      _emailController.text = currentUser?.email ?? '';
      _phoneController.text = userData?.phoneNumber ?? '';
      _bioController.text = userData?.bio ?? '';
      _currentProfilePicUrl = userData?.profilePicUrl;
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userDataAsync = ref.watch(userDataStreamProvider);
    final currentUser = ref.watch(currentFirebaseUserProvider);

    return userDataAsync.when(
      data: (userData) {
        _initializeUserData(userData, currentUser);

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Edit Profile',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton(
                onPressed: _isLoading ? null : () => _saveProfile(userData),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Save',
                        style: TextStyle(
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Picture Section
                      _buildProfilePictureSection(userData),
                      const Gap(32),
                      // Personal Information Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              'Update your personal details here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Gap(24),
                          ],
                        ),
                      ),
                      // Form Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                icon: Icons.person_outline,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                              const Gap(20),
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email Address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                enabled: false, // Email is read-only
                                validator: (value) =>
                                    null, // No validation needed since it's read-only
                              ),
                              const Gap(8),
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  'Email cannot be changed',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              const Gap(20),
                              _buildTextField(
                                controller: _phoneController,
                                label: 'Phone Number (Optional)',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: (value) => null, // Optional field
                              ),
                              const Gap(36),
                            ],
                          ),
                        ),
                      ),
                      // About Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About (Optional)',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              'Tell us a little about yourself',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Gap(24),
                            _buildTextField(
                              controller: _bioController,
                              label: 'Bio (Optional)',
                              icon: Icons.notes_outlined,
                              maxLines: 5,
                              validator: (value) => null, // Optional field
                            ),
                            const Gap(48),
                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _saveProfile(userData),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brandBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Save Changes',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ),
                            const Gap(32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Edit Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Edit Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const Gap(16),
              Text(
                'Error loading profile',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Gap(8),
              TextButton(
                onPressed: () => ref.invalidate(userDataStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection(dynamic userData) {
    final displayName = userData?.name ?? 'User';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
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
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.brandBlue,
                      const Color(0xFFB429F9),
                    ],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 65,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _selectedImageBytes != null
                        ? MemoryImage(_selectedImageBytes!)
                        : (_currentProfilePicUrl != null
                            ? NetworkImage(_currentProfilePicUrl!)
                            : null) as ImageProvider?,
                    child: (_selectedImage == null &&
                            _currentProfilePicUrl == null)
                        ? Text(
                            displayName.isNotEmpty
                                ? displayName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: InkWell(
                  onTap: _changeProfilePicture,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt,
                        size: 20, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          TextButton.icon(
            onPressed: _changeProfilePicture,
            icon: Icon(Icons.edit, size: 18, color: AppColors.brandBlue),
            label: Text(
              'Change Photo',
              style: TextStyle(
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            enabled: enabled,
            validator: validator,
            style: TextStyle(
              fontSize: 15,
              color: enabled ? Colors.black87 : Colors.grey[600],
            ),
            decoration: InputDecoration(
              hintText: 'Enter your $label',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 15,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 12),
                child: Icon(icon, color: AppColors.brandBlue, size: 22),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.brandBlue,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: enabled ? Colors.white : Colors.grey[100],
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines > 1 ? 16 : 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    }
  }

  void _removeProfilePicture() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _currentProfilePicUrl = null;
    });
  }

  void _changeProfilePicture() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const Gap(24),
            const Text(
              'Change Profile Picture',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const Gap(8),
            Text(
              'Choose how you want to update your photo',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const Gap(28),
            _buildPhotoOption(
              icon: Icons.camera_alt,
              title: 'Take Photo',
              subtitle: 'Use your camera',
              color: AppColors.brandBlue,
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            const Gap(12),
            _buildPhotoOption(
              icon: Icons.photo_library,
              title: 'Choose from Gallery',
              subtitle: 'Select from your photos',
              color: AppColors.brandBlue,
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            const Gap(12),
            _buildPhotoOption(
              icon: Icons.delete_outline,
              title: 'Remove Photo',
              subtitle: 'Use default avatar',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _removeProfilePicture();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Profile picture will be removed when you save'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
            const Gap(24),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
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
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadProfilePicture(String uid) async {
    if (_selectedImage == null) {
      return _currentProfilePicUrl;
    }

    try {
      // Create Cloudinary service
      final cloudinaryService = CloudinaryService();

      // Upload profile picture to Cloudinary
      final result = await cloudinaryService.uploadImageXFile(_selectedImage!);
      return result.url;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> _saveProfile(dynamic userData) async {
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    print('🔵 Starting profile update...');
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user from Firebase Auth
      final currentUser = ref.read(currentFirebaseUserProvider);

      if (currentUser == null) {
        print('❌ No authenticated user found');
        throw Exception('No authenticated user found. Please login again.');
      }

      // Use uid from userData if available, otherwise from currentUser
      final uid = userData?.uid ?? currentUser.uid;
      print('✅ User ID: $uid');

      final authService = ref.read(firebaseAuthServiceProvider);
      final firestore = FirebaseFirestore.instance;

      // Upload profile picture if selected
      String? profilePicUrl;
      if (_selectedImage != null) {
        print('📤 Uploading profile picture...');
        profilePicUrl = await _uploadProfilePicture(uid);
        print('✅ Profile picture uploaded: $profilePicUrl');
      } else if (_currentProfilePicUrl == null) {
        // User removed the profile picture
        profilePicUrl = null;
        print('🗑️ Profile picture removed');
      } else {
        // Keep existing profile picture
        profilePicUrl = _currentProfilePicUrl;
        print('📷 Keeping existing profile picture');
      }

      // Prepare update data - always update to ensure document exists
      Map<String, dynamic> updateData = {
        'uid': uid,
        'email': _emailController.text.trim(),
      };

      print('📝 Preparing update data...');

      // Update display name in Firebase Auth if changed
      final newName = _nameController.text.trim();
      if (newName.isNotEmpty && newName != (userData?.name ?? '')) {
        print('📝 Updating display name to: $newName');
        await authService.updateDisplayName(newName);
        print('✅ Display name updated in Firebase Auth');
      }
      // Always save name to Firestore
      if (newName.isNotEmpty) {
        updateData['name'] = newName;
        print('✅ Name added to update: $newName');
      }

      // Update phone number (optional)
      final newPhone = _phoneController.text.trim();
      if (newPhone.isNotEmpty) {
        updateData['phoneNumber'] = newPhone;
        print('✅ Phone added to update: $newPhone');
      } else if (userData?.phoneNumber != null) {
        // Remove phone number if cleared
        updateData['phoneNumber'] = null;
        print('🗑️ Phone number removed');
      }

      // Update bio (optional)
      final newBio = _bioController.text.trim();
      if (newBio.isNotEmpty) {
        updateData['bio'] = newBio;
        print(
            '✅ Bio added to update: ${newBio.substring(0, newBio.length > 20 ? 20 : newBio.length)}...');
      } else if (userData?.bio != null) {
        // Remove bio if cleared
        updateData['bio'] = null;
        print('🗑️ Bio removed');
      }

      // Update profile picture if changed
      if (profilePicUrl != null) {
        updateData['profilePicUrl'] = profilePicUrl;
      } else if (_currentProfilePicUrl == null &&
          userData?.profilePicUrl != null) {
        // Remove profile picture if cleared
        updateData['profilePicUrl'] = null;
      } else if (_currentProfilePicUrl != null) {
        updateData['profilePicUrl'] = _currentProfilePicUrl;
      }

      // Add createdAt if this is a new document
      if (userData == null) {
        updateData['createdAt'] = FieldValue.serverTimestamp();
        print('🆕 New document - adding createdAt');
      }

      print('📤 Saving to Firestore...');
      print('📊 Update data: $updateData');

      // Always update - this will create document if it doesn't exist
      await firestore
          .collection('users')
          .doc(uid)
          .set(
            updateData,
            SetOptions(merge: true),
          )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏱️ Firestore update timed out after 30 seconds');
          throw Exception('Update timed out. Please check your connection.');
        },
      );

      print('✅✅✅ Profile updated successfully in Firestore!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
        print('✅ Navigated back to profile screen');
      }
    } catch (e) {
      print('❌❌❌ Profile update failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('🏁 Profile update process completed');
    }
  }
}
