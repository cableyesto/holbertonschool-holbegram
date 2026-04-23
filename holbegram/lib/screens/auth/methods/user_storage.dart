import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StorageMethods {
  final String cloudinaryUrl = "https://api.cloudinary.com/v1_1/dgdt9oi05/image/upload";
  final String cloudinaryPreset = "ml_default";

  Future<String> uploadImageToStorage(
      bool isPost,
      String childName,
      Uint8List file,
  ) async {
    try {
      String uniqueId = const Uuid().v1();
      var uri = Uri.parse(cloudinaryUrl);

      print('=== Cloudinary Upload Debug ===');
      print('URL: $cloudinaryUrl');
      print('Upload Preset: $cloudinaryPreset');
      print('Folder: $childName');
      print('File size: ${file.length} bytes');
      print('Unique ID: $uniqueId');

      var request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = cloudinaryPreset;
      request.fields['folder'] = childName;
      // Always use uniqueId for public_id (profile pics and posts)
      request.fields['public_id'] = uniqueId;

      var multipartFile = http.MultipartFile.fromBytes(
        'file',
        file,
        filename: '$uniqueId.jpg'
      );
      request.files.add(multipartFile);

      print('Sending request to Cloudinary...');
      var response = await request.send();

      print('Response Status Code: ${response.statusCode}');

      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);

      print('Response Body: $responseString');

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(responseString);
        print('Upload successful! URL: ${jsonResponse['secure_url']}');
        return jsonResponse['secure_url'];
      } else {
        print('Upload failed with status ${response.statusCode}');
        print('Error response: $responseString');
        throw Exception(
          'Cloudinary upload failed: ${response.statusCode} - $responseString'
        );
      }
    } catch (e) {
      print('Exception during Cloudinary upload: $e');
      rethrow;
    }
  }
}
