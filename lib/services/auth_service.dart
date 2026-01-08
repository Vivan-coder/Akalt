import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/restaurant_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      debugPrint(
        'AuthService: Attempting signInWithEmailAndPassword for $email',
      );
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('AuthService: Login success for ${result.user?.uid}');
      return result;
    } catch (e) {
      debugPrint('AuthService: Login error: $e');
      rethrow;
    }
  }

  // Sign up
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
    String username,
    String role,
  ) async {
    try {
      debugPrint(
        'AuthService: Attempting createUserWithEmailAndPassword for $email',
      );
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('AuthService: Signup success for ${result.user?.uid}');

      // Create user document in Firestore
      if (result.user != null) {
        debugPrint('AuthService: Creating user document in Firestore');
        // Update Firebase Auth display name
        await result.user!.updateDisplayName(username);

        UserModel newUser = UserModel(
          uid: result.user!.uid,
          email: email,
          username: username,
          role: role,
        );
        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(newUser.toMap());
        debugPrint('AuthService: Firestore user document created');

        // Create initial restaurant document if business role
        if (role == 'business') {
          debugPrint('AuthService: Initializing restaurant template');
          RestaurantModel initialRestaurant = RestaurantModel(
            id: result.user!.uid,
            name: username,
            cuisine: 'Unknown',
            rating: 0.0,
            imageUrl: '',
            address: '',
            distance: 0.0,
            latitude: 0.0,
            longitude: 0.0,
            whatsAppNumber: '',
            talabatUrl: '',
            jahezUrl: '',
          );
          await _firestore
              .collection('restaurants')
              .doc(result.user!.uid)
              .set(initialRestaurant.toMap());
          debugPrint('AuthService: Business profile template created');
        }
      }

      return result;
    } catch (e) {
      debugPrint('AuthService: Signup error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user details
  Future<UserModel?> getUserDetails(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Stream user details
  Stream<UserModel?> streamUserDetails(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }
}
