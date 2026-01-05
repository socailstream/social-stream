import "package:firebase_auth/firebase_auth.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:social_stream_next/src/core/utils/timezone_helper.dart";

class AuthRepository {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _db = FirebaseFirestore.instance;

    Future<User?> signUp(String email, String password, String name) async {        
        try {
            UserCredential result = await _auth.createUserWithEmailAndPassword(
                email: email, 
                password: password
            );

            User? user = result.user;

            if( user != null) {
                await _db.collection('users').doc(user.uid).set({
                    'uid': user.uid,
                    'email': email,
                    'name': name,
                    'createdAt':  TimezoneHelper.now()
                });

                await user.sendEmailVerification();
            }
            
            
        return user;

        } on FirebaseAuthException catch(e) {
            switch (e.code) {
              case 'weak-password':
                throw Exception("The password provided is too weak.");
              case 'email-already-in-use':
                throw Exception("An  account already exists for that email.");
              case 'invalid-email':
                throw Exception("The email address is invalid.");    
              default:
                throw Exception("Sign up failed: ${e.message}");
            }
        }
        
         catch (e) {
          throw Exception("Unexpected error: $e");
        }

    }

}