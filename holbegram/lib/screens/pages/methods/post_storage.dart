import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../auth/methods/user_storage.dart';

class PostStorage {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> uploadPost(
    String caption,
    String uid,
    String username,
    String profImage,
    Uint8List image,
  ) async {
    try {
      // Upload image to Cloudinary
      String postUrl = await StorageMethods().uploadImageToStorage(
        true, // isPost
        'posts', // folder name
        image,
      );

      // Generate unique post ID
      String postId = const Uuid().v1();

      // Create post document in Firestore
      await _firestore.collection('posts').doc(postId).set({
        'caption': caption,
        'uid': uid,
        'username': username,
        'postId': postId,
        'datePublished': DateTime.now(),
        'postUrl': postUrl,
        'profImage': profImage,
        'likes': [],
      });

      return 'Ok';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> deletePost(String postId, String publicId) async {
    try {
      // Delete post from Firestore
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }
}
