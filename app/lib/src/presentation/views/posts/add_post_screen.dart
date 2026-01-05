import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:social_stream_next/src/core/theme/app_colors.dart';
import 'package:social_stream_next/src/core/utils/timezone_helper.dart';
import 'package:social_stream_next/src/core/config/env_config.dart';
import 'package:social_stream_next/src/data/services/social_api_service.dart';
import 'package:social_stream_next/src/data/services/cloudinary_service.dart';
import 'package:social_stream_next/src/presentation/views/main_navigation.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _schedulePost = false;
  DateTime _selectedDate = TimezoneHelper.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  XFile? _selectedMedia;
  bool _isGeneratingCaption = false;
  bool _isAnalyzingPost = false;
  List<ConnectedAccount> _connectedAccounts = [];
  bool _isLoadingAccounts = true;
  final Map<String, bool> _selectedPlatforms = {
    'facebook': false,
    'instagram': false,
    'pinterest': false,
  };

  bool get _isVideo {
    if (_selectedMedia == null) return false;
    final path = _selectedMedia!.path.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.avi') ||
        path.endsWith('.mkv');
  }

  @override
  void initState() {
    super.initState();
    _loadConnectedAccounts();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _loadConnectedAccounts() async {
    try {
      final accounts = await SocialApiService().getConnectedAccounts();
      setState(() {
        _connectedAccounts = accounts;
        _isLoadingAccounts = false;
        // Auto-select connected platforms
        for (var account in accounts) {
          _selectedPlatforms[account.platform] = true;
        }
      });
    } catch (e) {
      print('Error loading accounts: $e');
      setState(() => _isLoadingAccounts = false);
    }
  }

  Future<void> _selectImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _selectedMedia = image);
      }
    } catch (e) {
      _showError('Error selecting image: $e');
    }
  }

  Future<void> _selectVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );
      if (video != null) {
        setState(() => _selectedMedia = video);
      }
    } catch (e) {
      _showError('Error selecting video: $e');
    }
  }

  Future<void> _selectMedia() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Choose Image'),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Choose Video'),
              onTap: () => Navigator.pop(context, 'video'),
            ),
          ],
        ),
      ),
    );

    if (result == 'image') {
      await _selectImage();
    } else if (result == 'video') {
      await _selectVideo();
    }
  }

  Future<String?> _uploadMediaToStorage(XFile file) async {
    try {
      print('📤 Starting upload to Cloudinary...');

      // Create Cloudinary service
      final cloudinaryService = CloudinaryService();

      // Upload media based on type
      final result = _isVideo
          ? await cloudinaryService.uploadVideoXFile(file)
          : await cloudinaryService.uploadImageXFile(file);

      print('✅ Media uploaded successfully: ${result.url}');
      return result.url;
    } catch (e) {
      print('❌ Error uploading media: $e');
      throw Exception('Failed to upload media: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create Post',
          style: TextStyle(color: Colors.black87),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveAsDraft,
            child: const Text('Save Draft'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media Picker Section
              _buildMediaPicker(),
              const Gap(24),

              // Caption Section
              _buildCaptionSection(),
              const Gap(24),

              // AI Caption Generator
              _buildAICaptionGenerator(),
              const Gap(24),

              // Platform Selection
              _buildPlatformSelection(),
              const Gap(24),

              // Schedule Section
              _buildScheduleSection(),
              const Gap(32),

              // Action Buttons
              _buildActionButtons(),
              const Gap(20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPicker() {
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
          const Text(
            'Media',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(16),
          if (_selectedMedia == null)
            GestureDetector(
              onTap: _selectMedia,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 48, color: Colors.grey[600]),
                      const Gap(12),
                      Text(
                        'Tap to select image or video',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _isVideo
                      ? Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.black,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_circle_outline,
                                  size: 64,
                                  color: Colors.white,
                                ),
                                Gap(8),
                                Text(
                                  'Video selected',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        )
                      : FutureBuilder<Uint8List>(
                          future: _selectedMedia!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox(
                                height: 200,
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }
                            return Image.memory(
                              snapshot.data!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedMedia = null;
                      });
                    },
                  ),
                ),
              ],
            ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Image'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectVideo,
                  icon: const Icon(Icons.videocam),
                  label: const Text('Video'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionSection() {
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
                'Caption',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_captionController.text.length}/2200',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const Gap(12),
          TextField(
            controller: _captionController,
            maxLines: 6,
            maxLength: 2200,
            onChanged: (value) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Write your caption here...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.brandBlue, width: 2),
              ),
              counterText: '',
            ),
          ),
          const Gap(12),
          Wrap(
            spacing: 8,
            children: [
              IconButton(
                icon: const Icon(Icons.tag),
                onPressed: () {
                  // Add hashtag
                },
                tooltip: 'Add Hashtag',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.location_on),
                onPressed: () {
                  // Add location
                },
                tooltip: 'Add Location',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.emoji_emotions),
                onPressed: () {
                  // Add emoji
                },
                tooltip: 'Add Emoji',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAICaptionGenerator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00D4FF).withOpacity(0.1),
            const Color(0xFFB429F9).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandBlue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.auto_awesome, color: AppColors.brandBlue),
              ),
              const Gap(12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Post Assistant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Generate captions and get AI insights for your post',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(12),
          ElevatedButton.icon(
            onPressed: _isGeneratingCaption ? null : _generateAICaption,
            icon: _isGeneratingCaption
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
                _isGeneratingCaption ? 'Generating...' : 'Generate Caption'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Gap(10),
          OutlinedButton.icon(
            onPressed: _isAnalyzingPost ? null : _askAIAboutPost,
            icon: _isAnalyzingPost
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.brandBlue),
                    ),
                  )
                : const Icon(Icons.insights, color: AppColors.brandBlue),
            label: Text(_isAnalyzingPost ? 'Analyzing...' : 'Post Insights'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandBlue,
              minimumSize: const Size(double.infinity, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: AppColors.brandBlue.withOpacity(0.4)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformSelection() {
    if (_isLoadingAccounts) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_connectedAccounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No connected accounts. Connect accounts in settings.'),
        ),
      );
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Platforms',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(8),
          Text(
            '${_connectedAccounts.length} connected account(s)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const Gap(16),
          ..._connectedAccounts.map((account) {
            final platformData = _getPlatformData(account.platform);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PlatformTile(
                platform: account.accountName,
                icon: platformData['icon'],
                color: platformData['color'],
                isSelected: _selectedPlatforms[account.platform] ?? false,
                onChanged: (value) {
                  setState(() {
                    _selectedPlatforms[account.platform] = value;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
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
          const Text(
            'Schedule',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Post Now'),
                  value: false,
                  groupValue: _schedulePost,
                  onChanged: (value) {
                    setState(() {
                      _schedulePost = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Schedule'),
                  value: true,
                  groupValue: _schedulePost,
                  onChanged: (value) {
                    setState(() {
                      _schedulePost = value!;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          if (_schedulePost) ...[
            const Gap(16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime.format(context)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _publishPost,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _schedulePost ? 'Schedule Post' : 'Publish Now',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const Gap(12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: _previewPost,
            icon: const Icon(Icons.visibility),
            label: const Text('Preview'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generateAICaption() async {
    if (_isGeneratingCaption) return;

    setState(() => _isGeneratingCaption = true);

    try {
      // Initialize Gemini AI
      final apiKey = EnvConfig.geminiApiKey;
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      // Build prompt based on context
      String prompt = 'Generate exactly 3 engaging social media captions';

      if (_captionController.text.isNotEmpty) {
        prompt += ' based on this context: "${_captionController.text}"';
      }

      if (_selectedMedia != null && !_isVideo) {
        prompt +=
            '. Analyze the provided image and create captions that relate to what you see in the image';
      } else if (_selectedMedia != null && _isVideo) {
        prompt += ' for a video post';
      }

      prompt +=
          '. Each caption should be creative, include relevant emojis, and be optimized for social media engagement. IMPORTANT: Return ONLY the 3 captions, one per line, with no introductory text, explanations, numbering, or any other text. Just the captions.';

      final content = <Content>[];

      // Add image if available (not video)
      if (_selectedMedia != null && !_isVideo) {
        final imageBytes = await _selectedMedia!.readAsBytes();
        content.add(Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]));
      } else {
        content.add(Content.text(prompt));
      }

      final response = await model.generateContent(content);

      if (response.text != null) {
        final captions = response.text!
            .split('\n')
            .map((line) => line.trim())
            .where((line) =>
                line.isNotEmpty &&
                    !line.toLowerCase().startsWith('here') &&
                    !line.toLowerCase().contains('caption') &&
                    line.length < 200 ||
                line.contains('✨') ||
                line.contains('🌟') ||
                line.contains('💫') ||
                line.contains('❤') ||
                line.contains('😊') ||
                line.contains('🎉'))
            .take(3)
            .toList();

        if (!mounted) return;

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _AICaptionBottomSheet(
            captions: captions.isNotEmpty
                ? captions
                : ['Generated caption unavailable'],
            onSelectCaption: (caption) {
              setState(() => _captionController.text = caption);
            },
            onRegenerate: _generateAICaption,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to generate caption: $e');
    } finally {
      setState(() => _isGeneratingCaption = false);
    }
  }

  String _getMediaMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  Future<void> _askAIAboutPost() async {
    if (_isAnalyzingPost) return;

    if (_selectedMedia == null) {
      _showError('Please upload an image first');
      return;
    }
    if (_isVideo) {
      _showError('Ask AI about post currently supports images only');
      return;
    }
    if (_captionController.text.trim().isEmpty) {
      _showError('Please write a caption first');
      return;
    }

    setState(() => _isAnalyzingPost = true);

    try {
      final apiKey = EnvConfig.geminiApiKey;
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final caption = _captionController.text.trim();
      final prompt =
          'You are a social media strategist. Analyze this post draft and image.\n'
          'Caption draft: "$caption"\n\n'
          'Provide: \n'
          '1) Overall assessment (1-2 sentences)\n'
          '2) 6 actionable improvements to increase engagement/reach\n'
          '3) 10 relevant hashtags (mix broad + niche)\n'
          '4) CTA suggestion (1 line)\n'
          '5) Audience targeting suggestions (3 bullets)\n'
          '6) Potential reach factors (qualitative; no guarantees)\n'
          '7) Platform tips for Instagram, Facebook, Pinterest (1-2 bullets each)\n\n'
          'Format with clear section headings. Keep it concise and practical.';

      final imageBytes = await _selectedMedia!.readAsBytes();
      final mimeType = _getMediaMimeType(_selectedMedia!.name);

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart(mimeType, imageBytes),
        ]),
      ]);

      final analysisText = response.text?.trim();
      if (!mounted) return;

      if (analysisText == null || analysisText.isEmpty) {
        _showError('AI analysis unavailable. Please try again.');
        return;
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _AIPostInsightsBottomSheet(
          analysisText: analysisText,
          onGenerateCaptions: () {
            Navigator.pop(context);
            _generateCaptionsFromInsights(analysisText);
          },
        ),
      );
    } catch (e) {
      _showError('Failed to analyze post: $e');
    } finally {
      if (mounted) {
        setState(() => _isAnalyzingPost = false);
      }
    }
  }

  Future<void> _generateCaptionsFromInsights(String insightsMarkdown) async {
    if (_isGeneratingCaption) return;

    setState(() => _isGeneratingCaption = true);

    try {
      final apiKey = EnvConfig.geminiApiKey;
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      final captionDraft = _captionController.text.trim();

      final prompt =
          'Using the insights/recommendations below, write exactly 3 improved final social media captions.\n'
          'Keep them engaging, natural, include relevant emojis, and optimized for reach/engagement.\n'
          'If useful, incorporate the intent of this draft caption: "$captionDraft"\n\n'
          'INSIGHTS (Markdown):\n$insightsMarkdown\n\n'
          'IMPORTANT: Return ONLY the 3 captions, one per line, with no numbering, headings, or extra text.';

      final content = <Content>[];
      if (_selectedMedia != null && !_isVideo) {
        final imageBytes = await _selectedMedia!.readAsBytes();
        final mimeType = _getMediaMimeType(_selectedMedia!.name);
        content.add(
          Content.multi([
            TextPart(prompt),
            DataPart(mimeType, imageBytes),
          ]),
        );
      } else {
        content.add(Content.text(prompt));
      }

      final response = await model.generateContent(content);

      final raw = response.text ?? '';
      final captions = raw
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .take(3)
          .toList();

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _AICaptionBottomSheet(
          captions: captions.isNotEmpty
              ? captions
              : ['Generated caption unavailable'],
          onSelectCaption: (caption) {
            setState(() => _captionController.text = caption);
          },
          onRegenerate: () => _generateCaptionsFromInsights(insightsMarkdown),
        ),
      );
    } catch (e) {
      _showError('Failed to generate caption from insights: $e');
    } finally {
      if (mounted) {
        setState(() => _isGeneratingCaption = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _navigateToHomeAfterPost() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainNavigation()),
      (route) => false,
    );
  }

  Map<String, dynamic> _getPlatformData(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return {'icon': Icons.facebook, 'color': const Color(0xFF1877F2)};
      case 'instagram':
        return {'icon': Icons.camera_alt, 'color': const Color(0xFFE4405F)};
      case 'pinterest':
        return {'icon': Icons.push_pin, 'color': const Color(0xFFE60023)};
      default:
        return {'icon': Icons.share, 'color': Colors.grey};
    }
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: TimezoneHelper.now(),
      lastDate: TimezoneHelper.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _publishPost() async {
    // Validation
    if (_captionController.text.trim().isEmpty) {
      _showError('Please enter a caption');
      return;
    }

    final selectedPlatforms = _selectedPlatforms.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedPlatforms.isEmpty) {
      _showError('Please select at least one platform');
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                Gap(16),
                Text('Publishing your post...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Prepare scheduled date/time
      DateTime? scheduledDateTime;
      if (_schedulePost) {
        scheduledDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      }

      // Upload media to Firebase Storage if present
      String? mediaUrl;
      if (_selectedMedia != null) {
        try {
          print('📤 Uploading media to Firebase Storage...');
          mediaUrl = await _uploadMediaToStorage(_selectedMedia!);
          print('✅ Media uploaded successfully');
        } catch (storageError) {
          // Close loading dialog
          if (mounted) Navigator.pop(context);

          if (!mounted) return;

          // Ask user if they want to continue without media
          final continueWithoutMedia = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange),
                  Gap(8),
                  Text('Upload Failed'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Failed to upload media to Firebase Storage:'),
                  const Gap(8),
                  Text(
                    storageError.toString().replaceFirst('Exception: ', ''),
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                  const Gap(16),
                  const Text(
                      'Would you like to post without media (text only)?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Post Without Media'),
                ),
              ],
            ),
          );

          if (continueWithoutMedia != true) {
            return; // User cancelled
          }

          // Continue without media - show loading again
          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      Gap(16),
                      Text('Publishing your post...'),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }

      // Publish to social media
      final result = await SocialApiService().publishPost(
        caption: _captionController.text.trim(),
        mediaUrl: mediaUrl,
        platforms: selectedPlatforms,
        scheduledDate: scheduledDateTime,
      );

      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Wait a frame to ensure dialog is fully closed
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      // Show results
      final bool success = result['success'] == true;
      final bool scheduled = result['data']?['scheduled'] == true;
      final List? results = result['data']?['results'];
      final List? errors = result['data']?['errors'];

      if (success) {
        // Handle scheduled posts
        if (scheduled) {
          await showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.schedule, color: Colors.blue),
                  Gap(8),
                  Text('Post Scheduled'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result['message'] ?? 'Your post has been scheduled'),
                  const Gap(16),
                  const Text(
                    'The post will be automatically published at the scheduled time.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext); // Close dialog only
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          // After dialog closes, go to Home screen
          _navigateToHomeAfterPost();
          return;
        }

        // Handle immediate posts
        final successCount = results?.length ?? 0;
        final errorCount = errors?.length ?? 0;

        String message = 'Published to $successCount platform(s)';

        if (errorCount > 0) {
          message += '\nFailed on $errorCount platform(s)';
        }

        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  successCount > 0 ? Icons.check_circle : Icons.warning,
                  color: successCount > 0 ? Colors.green : Colors.orange,
                ),
                const Gap(8),
                Text(successCount > 0 ? 'Success' : 'Partial Success'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                if (errors != null && errors.isNotEmpty) ...[
                  const Gap(16),
                  const Text(
                    'Errors:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...errors.map((error) => Text(
                        '• ${error['platform']}: ${error['error']}',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      )),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // Close dialog only
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
        // After dialog closes, go to Home screen
        _navigateToHomeAfterPost();
      } else {
        _showError(result['message'] ?? 'Failed to publish post');
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      _showError('Error: ${e.toString()}');
    }
  }

  void _previewPost() {
    // Show preview dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Post Preview'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedMedia != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _isVideo
                      ? Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.black,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_circle_outline,
                                  size: 64,
                                  color: Colors.white,
                                ),
                                Gap(8),
                                Text(
                                  'Video selected',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        )
                      : FutureBuilder<Uint8List>(
                          future: _selectedMedia!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox(
                                height: 200,
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }
                            return Image.memory(
                              snapshot.data!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                ),
              if (_selectedMedia != null) const Gap(12),
              Text(
                _captionController.text,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAsDraft() async {
    // TODO: Save to local storage or backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class _PlatformTile extends StatelessWidget {
  final String platform;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  const _PlatformTile({
    required this.platform,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) => onChanged(value ?? false),
        title: Text(
          platform,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? color : Colors.black87,
          ),
        ),
        secondary: Icon(icon, color: color),
        activeColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _AICaptionBottomSheet extends StatelessWidget {
  final List<String> captions;
  final Function(String) onSelectCaption;
  final VoidCallback onRegenerate;

  const _AICaptionBottomSheet({
    required this.captions,
    required this.onSelectCaption,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.78,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.brandBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: AppColors.brandBlue,
                      ),
                    ),
                    const Gap(12),
                    const Expanded(
                      child: Text(
                        'AI Generated Captions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Gap(8),
                const Text(
                  'Select a caption or regenerate for more options',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: ListView.separated(
                    itemCount: captions.length,
                    separatorBuilder: (_, __) => const Gap(12),
                    itemBuilder: (context, index) {
                      final caption = captions[index];
                      return GestureDetector(
                        onTap: () {
                          onSelectCaption(caption);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  caption,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Gap(16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onRegenerate();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Regenerate'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                Gap(MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AIPostInsightsBottomSheet extends StatelessWidget {
  final String analysisText;
  final VoidCallback onGenerateCaptions;

  const _AIPostInsightsBottomSheet({
    required this.analysisText,
    required this.onGenerateCaptions,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.insights, color: AppColors.brandBlue),
                ),
                const Gap(12),
                const Expanded(
                  child: Text(
                    'AI Post Insights',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Gap(8),
            const Text(
              'Suggestions, recommendations, and reach factors for your post.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const Gap(16),
            Expanded(
              child: SingleChildScrollView(
                child: SelectionArea(
                  child: MarkdownBody(
                    data: analysisText,
                    styleSheet: MarkdownStyleSheet.fromTheme(
                      Theme.of(context),
                    ).copyWith(
                      p: const TextStyle(fontSize: 14, height: 1.4),
                      listBullet: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ),
                ),
              ),
            ),
            const Gap(12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onGenerateCaptions,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate captions from insights'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Gap(MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
