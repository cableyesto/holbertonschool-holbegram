import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthMethode {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthMethode()
      : _auth = FirebaseAuth.instance,
        _firestore = FirebaseFirestore.instance;

  Future<String> login({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      return 'Please fill all the fields';
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return 'success';
    } catch (e) {
      print('Login Error: ${e.toString()}');
      return e.toString();
    }
  }

  Future<String> signUpUser({
    required String email,
    required String password,
    required String username,
    Uint8List? file,
  }) async {
    if (email.isEmpty || password.isEmpty || username.isEmpty) {
      print('SignUp Error: Please fill all the fields');
      return 'Please fill all the fields';
    }

    try {
      print('Creating user with email: $email');
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      print('User created with UID: ${user?.uid}');

      Users users = Users(
        uid: user!.uid,
        email: email,
        username: username,
        bio: '',
        photoUrl: '',
        followers: [],
        following: [],
        posts: [],
        saved: [],
        searchKey: username[0].toUpperCase(),
      );

      print('Saving user to Firestore...');
      //await _firestore.collection("users").doc(user.uid).set(users.toJson());
      await _firestore
          .collection("users")
          .doc(user.uid)
          .set(users.toJson())
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Firestore write timeout - check network connection');
            },
          );
      print('User saved successfully!');

      return 'success';
    } catch (e) {
      print('SignUp Error: ${e.toString()}');
      return e.toString();
    }
  }
}
