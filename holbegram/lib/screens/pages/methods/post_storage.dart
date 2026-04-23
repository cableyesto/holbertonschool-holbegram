import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../auth/methods/user_storage.dart';

class PostStorage {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dgdt9oi05/image/destroy";
  final String cloudinaryPreset = "ml_default";

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

      // Add postId to user's posts array
      await _firestore.collection('users').doc(uid).update({
        'posts': FieldValue.arrayUnion([postId])
      });

      return 'Ok';
    } catch (e) {
      return e.toString();
    }
  }

  String _extractPublicIdFromUrl(String url) {
    // URL format: https://res.cloudinary.com/{cloud_name}/image/upload/v{version}/{folder}/{public_id}.{format}
    // Extract the public_id including folder
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;

    // Find the index of 'upload'
    final uploadIndex = pathSegments.indexOf('upload');
    if (uploadIndex == -1 || uploadIndex + 2 >= pathSegments.length) {
      throw Exception('Invalid Cloudinary URL format');
    }

    // Get everything after 'upload' and version (skip v{version})
    final publicIdWithExtension = pathSegments.sublist(uploadIndex + 2).join('/');

    // Remove file extension
    final lastDotIndex = publicIdWithExtension.lastIndexOf('.');
    if (lastDotIndex != -1) {
      return publicIdWithExtension.substring(0, lastDotIndex);
    }

    return publicIdWithExtension;
  }

  Future<String> savePost(String postId, String uid) async {
    print('=== savePost called ===');
    print('postId: $postId');
    print('uid: $uid');

    try {
      print('Attempting to add postId to user saved array...');

      // Add postId to user's saved array
      await _firestore.collection('users').doc(uid).update({
        'saved': FieldValue.arrayUnion([postId])
      });

      print('Successfully saved post!');
      return 'success';
    } catch (e) {
      print('Error saving post: $e');
      return e.toString();
    }
  }

  Future<String> unsavePost(String postId, String uid) async {
    print('=== unsavePost called ===');
    print('postId: $postId');
    print('uid: $uid');

    try {
      print('Attempting to remove postId from user saved array...');

      // Remove postId from user's saved array
      await _firestore.collection('users').doc(uid).update({
        'saved': FieldValue.arrayRemove([postId])
      });

      print('Successfully unsaved post!');
      return 'success';
    } catch (e) {
      print('Error unsaving post: $e');
      return e.toString();
    }
  }

  Future<void> deletePost(String postId, String publicId) async {
    try {
      // Get post to extract the actual public_id from postUrl
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) {
        print('Post not found');
        return;
      }

      final postData = postDoc.data() as Map<String, dynamic>;
      final postUrl = postData['postUrl'] as String;
      final extractedPublicId = _extractPublicIdFromUrl(postUrl);

      // Delete image from Cloudinary
      final response = await http.post(
        Uri.parse(cloudinaryUrl),
        body: {
          'upload_preset': cloudinaryPreset,
          'public_id': extractedPublicId,
        },
      );

      print('Cloudinary delete response: ${response.statusCode}');
      print('Cloudinary delete body: ${response.body}');

      // Delete post from Firestore
      await _firestore.collection('posts').doc(postId).delete();

      // Remove postId from the poster's posts array
      final uid = postData['uid'] as String;
      await _firestore.collection('users').doc(uid).update({
        'posts': FieldValue.arrayRemove([postId])
      });

      // Remove postId from all users' saved arrays
      final usersSnapshot = await _firestore
          .collection('users')
          .where('saved', arrayContains: postId)
          .get();

      for (var userDoc in usersSnapshot.docs) {
        await _firestore.collection('users').doc(userDoc.id).update({
          'saved': FieldValue.arrayRemove([postId])
        });
      }
    } catch (e) {
      print('Error deleting post: $e');
      rethrow;
    }
  }
}
