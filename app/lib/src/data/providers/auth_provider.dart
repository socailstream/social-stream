import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_stream_next/src/data/services/firebase_auth_service.dart';

// Firebase Auth Service Provider
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

// Auth State Provider - listens to authentication state changes
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.authStateChanges;
});

// Current User Provider
final currentUserProvider = Provider<User?>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.currentUser;
});

// Auth Controller Provider - handles auth operations
final authControllerProvider = Provider<AuthController>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return AuthController(authService: authService);
});

class AuthController {
  final FirebaseAuthService authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthController({required this.authService});

  // Helper method to save user to Firestore
  Future<void> _saveUserToFirestore(String uid, String email, String name) async {
    try {
      // Use server timestamp for consistency
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'phoneNumber': null,
        'bio': null,
        'profilePicUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ Firestore data saved successfully for user: $uid');
    } catch (e) {
      print('⚠️ Firestore save error: $e');
      // Still throw to handle in signup
      rethrow;
    }
  }

  // Sign up
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      print('📝 Creating Firebase account...');
      final credential = await authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Firebase account created');
      
      // Update display name and save to Firestore
      if (credential.user != null) {
        // Update display name
        try {
          print('📝 Updating display name...');
          await authService.updateDisplayName(name);
          print('✅ Display name updated');
        } catch (e) {
          print('⚠️ Display name error: $e');
        }
        
        // Save to Firestore in BACKGROUND (non-blocking for faster signup)
        print('📝 Saving user data to Firestore in background...');
        _saveUserToFirestore(credential.user!.uid, email, name).then((_) {
          print('✅ User data saved to Firestore');
        }).catchError((e) {
          print('⚠️ Failed to save user data to Firestore: $e');
          // No problem - will be created on first login if needed
        });
        
        // Send email verification in background (non-blocking)
        print('📧 Sending verification email in background...');
        authService.sendEmailVerification().then((_) {
          print('✅ Verification email sent');
        }).catchError((e) {
          print('⚠️ Email verification error: $e');
        });
      }
      
      print('✅ Signup process completed successfully');
      return null; // Success
    } catch (e) {
      print('❌ Signup error: $e');
      return e.toString();
    }
  }

  // Sign in
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Attempting to sign in...');
      final credential = await authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Sign in successful');
      
      // Ensure user data exists in Firestore (in background for faster login)
      if (credential.user != null) {
        final uid = credential.user!.uid;
        print('📝 Checking Firestore data for user: $uid');
        
        // Do this in background to not slow down login
        _firestore.collection('users').doc(uid).get().then((userDoc) {
          if (!userDoc.exists) {
            print('⚠️ User data not found in Firestore, creating in background...');
            final displayName = credential.user!.displayName ?? email.split('@')[0];
            _saveUserToFirestore(uid, email, displayName).then((_) {
              print('✅ User data created in Firestore');
            }).catchError((e) {
              print('❌ Failed to create user data: $e');
            });
          } else {
            print('✅ User data found in Firestore');
          }
        }).catchError((e) {
          print('⚠️ Firestore check error (ignored): $e');
        });
      }
      
      return null; // Success
    } catch (e) {
      print('❌ Sign in error: $e');
      return e.toString();
    }
  }

  // Sign out
  Future<void> signOut() async {
    await authService.signOut();
  }

  // Update profile
  Future<String?> updateProfile({
    String? displayName,
    String? email,
  }) async {
    try {
      if (displayName != null) {
        await authService.updateDisplayName(displayName);
      }
      if (email != null) {
        await authService.updateEmail(email);
      }
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }

  // Change password
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      print('🔐 Starting password change process...');
      
      // Re-authenticate first
      final user = authService.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return 'No user logged in. Please login again.';
      }
      
      if (user.email == null) {
        print('❌ User email not found');
        return 'User email not found. Please login again.';
      }
      
      print('📝 Re-authenticating user: ${user.email}');
      await authService.reauthenticateWithCredential(
        email: user.email!,
        password: currentPassword,
      );
      print('✅ Re-authentication successful');
      
      // Update password
      print('📝 Updating password...');
      await authService.updatePassword(newPassword);
      print('✅✅✅ Password updated successfully in Firebase Auth!');
      
      return null; // Success
    } catch (e) {
      print('❌ Password change error: $e');
      return e.toString();
    }
  }

  // Delete account
  Future<String?> deleteAccount(String password) async {
    try {
      print('🗑️ Starting account deletion process...');
      
      // Get current user
      final user = authService.currentUser;
      if (user == null) {
        print('❌ No user logged in');
        return 'No user logged in. Please login again.';
      }
      
      if (user.email == null) {
        print('❌ User email not found');
        return 'User email not found. Please login again.';
      }
      
      final uid = user.uid;
      print('📝 User ID: $uid');
      print('📝 User Email: ${user.email}');
      
      // Re-authenticate first (security requirement)
      print('🔐 Re-authenticating user...');
      await authService.reauthenticateWithCredential(
        email: user.email!,
        password: password,
      );
      print('✅ Re-authentication successful');
      
      // Delete user data from Firestore
      print('🗑️ Deleting user data from Firestore...');
      try {
        await _firestore.collection('users').doc(uid).delete();
        print('✅ Firestore data deleted');
      } catch (e) {
        print('⚠️ Failed to delete Firestore data: $e');
        // Continue with account deletion even if Firestore fails
      }
      
      // Delete Firebase Auth account
      print('🗑️ Deleting Firebase Auth account...');
      await authService.deleteAccount();
      print('✅✅✅ Account deleted successfully from Firebase Auth!');
      
      return null; // Success
    } catch (e) {
      print('❌ Account deletion error: $e');
      return e.toString();
    }
  }
}

