import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:social_stream_next/src/data/models/user_model.dart';
import 'package:social_stream_next/src/data/providers/auth_provider.dart';

// Firestore instance provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// Stream provider for real-time user data from Firestore
// Removed autoDispose to keep data cached and load faster
final userDataStreamProvider = StreamProvider<UserModel?>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(null);
      }
      
      return firestore
          .collection('users')
          .doc(user.uid)
          .snapshots(
            includeMetadataChanges: false, // Reduce updates, only when data actually changes
          )
          .map((snapshot) {
            if (!snapshot.exists) {
              return null;
            }
            return UserModel.fromMap(snapshot.data()!);
          });
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// Provider for current Firebase Auth user
final currentFirebaseUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

