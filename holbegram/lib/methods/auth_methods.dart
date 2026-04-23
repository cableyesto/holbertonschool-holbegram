import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    String photoUrl = '',
  }) async {
    if (email.isEmpty || password.isEmpty || username.isEmpty) {
      return 'Please fill all the fields';
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      Users users = Users(
        uid: user!.uid,
        email: email,
        username: username,
        bio: '',
        photoUrl: photoUrl,
        followers: [],
        following: [],
        posts: [],
        saved: [],
        searchKey: username[0].toUpperCase(),
      );

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

      return 'success';
    } catch (e) {
      print('SignUp Error: ${e.toString()}');
      return e.toString();
    }
  }

  Future<Users> getUserDetails() async {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('No user is currently signed in');
    }

    DocumentSnapshot snap = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();

    return Users.fromSnap(snap);
  }
}
