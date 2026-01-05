import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_stream_next/src/core/theme/app_theme.dart';
import 'package:social_stream_next/src/presentation/views/splash_screen.dart';
import 'package:social_stream_next/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'package:social_stream_next/src/core/config/env_config.dart';
import 'dart:async';

// Global stream controller to notify about OAuth completions
final oauthCompletionController = StreamController<String>.broadcast();

void main() async {
  // Need this command whenever we need to call native plugins like Firebase.
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment configuration
  await EnvConfig.initialize();
  
  // Initialize Firebase only if not already initialized (prevents duplicate-app error)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Enable Firestore offline persistence for faster loading
    // Data will be cached locally and load instantly on subsequent visits
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (e) {
    // Firebase already initialized - this can happen during hot reload
    if (e.toString().contains('duplicate-app')) {
      // Already initialized, no action needed
    } else {
      rethrow;
    }
  }

  // Handle OAuth callbacks
  _handleOAuthCallback();

  runApp(const ProviderScope(child: SocialStream()));
}

void _handleOAuthCallback() async {
  final appLinks = AppLinks();
  
  // Handle initial link
  try {
    final initialLink = await appLinks.getInitialLink();
    if (initialLink != null) {
      _processOAuthCallback(initialLink.toString());
    }
  } catch (e) {
    print('Error getting initial link: $e');
  }

  // Handle link stream
  appLinks.uriLinkStream.listen((uri) {
    _processOAuthCallback(uri.toString());
  }, onError: (err) {
    print('Error handling link: $err');
  });
}

void _processOAuthCallback(String link) {
  final uri = Uri.parse(link);
  if (uri.scheme == 'socialstream' && uri.host == 'callback') {
    final platform = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    final success = uri.queryParameters['success'];
    final error = uri.queryParameters['error'];

    if (error != null) {
      print('❌ OAuth error for $platform: $error');
      oauthCompletionController.add('error:$platform');
    } else if (success == 'true' && platform != null) {
      print('✅ OAuth completed successfully for $platform');
      // Notify listeners that OAuth completed
      oauthCompletionController.add(platform);
    }
  }
}



class SocialStream extends StatelessWidget {
  const SocialStream({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Social Stream",
      debugShowCheckedModeBanner: false,
      theme: LightAppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}


