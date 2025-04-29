import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Rx<User?> firebaseUser = Rx<User?>(null);
  Rx<UserModel?> userModel = Rx<UserModel?>(null);

  @override
  void onReady() {
    super.onReady();
    firebaseUser = Rx<User?>(_auth.currentUser);

    // Listen for auth changes
    firebaseUser.bindStream(_auth.userChanges());
    ever(firebaseUser, _setInitialScreen);
  }

  // Set initial screen based on user authentication state
  _setInitialScreen(User? user) async {
    if (user == null) {
      Get.offAllNamed('/login');
    } else {
      await _getAndSetUserData();
      Get.offAllNamed('/home');
    }
  }

  // Get user data from Firestore
  Future<void> _getAndSetUserData() async {
    if (firebaseUser.value != null) {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.value!.uid)
          .get();

      if (userDoc.exists) {
        userModel.value =
            UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }
    }
  }

  // User registration with email and password
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    XFile? profilePic,
  }) async {
    try {
      // Create user account
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String profileUrl = '';

      // Upload profile picture if provided
      if (profilePic != null) {
        profileUrl =
            await _uploadProfilePicture(File(profilePic.path), cred.user!.uid);
      }

      // Create user model
      UserModel user = UserModel(
        uid: cred.user!.uid,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        profileImageUrl: profileUrl,
        lastSeen: DateTime.now().toString(),
      );

      // Save user data to Firestore
      await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .set(user.toMap());

      return true;
    } catch (e) {
      Get.snackbar(
        'Error Creating Account',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // Login with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      Get.snackbar(
        'Error Logging In',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      Get.snackbar(
        'Error Signing Out',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Upload profile picture to Firebase Storage
  Future<String> _uploadProfilePicture(File image, String uid) async {
    try {
      Reference ref = _storage.ref().child('profilePics').child(uid);
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: ${e.toString()}');
      return '';
    }
  }

  // Update user online status
  Future<void> updateUserStatus(bool isOnline) async {
    try {
      if (firebaseUser.value != null) {
        // Check if user document exists first
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(firebaseUser.value!.uid)
            .get();

        if (userDoc.exists) {
          await _firestore
              .collection('users')
              .doc(firebaseUser.value!.uid)
              .update({
            'isOnline': isOnline,
            'lastSeen': DateTime.now().toString(),
          });
        } else {
          // Create the user document if it doesn't exist
          UserModel user = UserModel(
            uid: firebaseUser.value!.uid,
            name: firebaseUser.value!.displayName ?? 'User',
            email: firebaseUser.value!.email ?? '',
            phoneNumber: firebaseUser.value!.phoneNumber ?? '',
            profileImageUrl: firebaseUser.value!.photoURL ?? '',
            lastSeen: DateTime.now().toString(),
            isOnline: isOnline,
          );

          await _firestore
              .collection('users')
              .doc(firebaseUser.value!.uid)
              .set(user.toMap());
        }
      }
    } catch (e) {
      print('Error updating user status: ${e.toString()}');
    }
  }
}
