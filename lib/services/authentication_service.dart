import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}

class User {
  String uid;
  String name;
  String email;
  String? avatarUrl;
  DateTime createdAt;

  User({
    required this.uid,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.createdAt,
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt,
    };
  }

  /// Create User from Firestore document
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      avatarUrl: data['avatarUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  /// Initialize auth state listener
  void initializeAuthStateListener() {
    _firebaseAuth.authStateChanges().listen((
      firebase_auth.User? firebaseUser,
    ) async {
      if (firebaseUser != null) {
        // User is logged in - fetch their profile
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .get();
          if (userDoc.exists) {
            _currentUser = User.fromFirestore(userDoc);
          }
        } catch (e) {
          print('Error loading user profile: $e');
        }
      } else {
        // User is logged out
        _currentUser = null;
      }
    });
  }

  /// Register user with email and password
  Future<String> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = userCredential.user!.uid;

      // Create user profile in Firestore
      final newUser = User(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        createdAt: DateTime.now(),
      );

      // Try to save to Firestore, but don't block if it fails
      try {
        await _firestore
            .collection('users')
            .doc(uid)
            .set(newUser.toFirestore())
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () =>
                  throw TimeoutException('Firestore write timeout'),
            );
      } catch (firestoreError) {
        print(
          'Warning: Could not save user profile to Firestore: $firestoreError',
        );
        // Continue anyway - user is created in Firebase Auth
      }

      _currentUser = newUser;
      return 'Success';
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Email already registered';
      } else if (e.code == 'weak-password') {
        return 'Password is too weak';
      } else if (e.code == 'invalid-email') {
        return 'Invalid email format';
      }
      return 'Registration failed: ${e.message}';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Login user with email and password
  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = userCredential.user!.uid;

      // Fetch user profile from Firestore
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        _currentUser = User.fromFirestore(userDoc);
        return 'Success';
      } else {
        return 'User profile not found';
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'Email not registered';
      } else if (e.code == 'wrong-password') {
        return 'Incorrect password';
      } else if (e.code == 'invalid-credential') {
        return 'Invalid email or password';
      }
      return 'Login failed: ${e.message}';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Update current user profile
  Future<String> updateCurrentUser({
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    try {
      if (_currentUser == null) return 'No logged-in user';

      final uid = _currentUser!.uid;

      // Update email if changed
      if (email != _currentUser!.email) {
        await _firebaseAuth.currentUser!.verifyBeforeUpdateEmail(email.trim());
      }

      // Update user profile in Firestore
      final updatedUser = User(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
        createdAt: _currentUser!.createdAt,
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .update(updatedUser.toFirestore());

      _currentUser = updatedUser;
      return 'Success';
    } on firebase_auth.FirebaseAuthException catch (e) {
      return 'Update failed: ${e.message}';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Logout user
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _currentUser = null;
  }

  /// Get user by ID
  Future<User?> getUserById(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return User.fromFirestore(userDoc);
      }
    } catch (e) {
      print('Error fetching user: $e');
    }
    return null;
  }

  /// Check if email is already registered
  Future<bool> isEmailRegistered(String email) async {
    try {
      final methods = await _firebaseAuth.fetchSignInMethodsForEmail(
        email.trim(),
      );
      return methods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
