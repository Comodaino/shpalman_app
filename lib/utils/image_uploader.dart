import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  // Get Cloudinary credentials from environment variables
  final String _cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  final String _apiKey = dotenv.env['CLOUDINARY_API_KEY'] ?? '';
  final String _apiSecret = dotenv.env['CLOUDINARY_API_SECRET'] ?? '';
  final String _uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

  // Upload image and return public URL
  Future<String> uploadImage(XFile imageFile, {String folder = 'poops'}) async {
    try {
      // Set up the API URL
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      // Create multipart request
      final request = http.MultipartRequest('POST', uri);

      // Add required Cloudinary parameters
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder;
      request.fields['api_key'] = _apiKey;

      // If you want to sign the request instead of using unsigned upload preset
      if (_apiSecret.isNotEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        request.fields['timestamp'] = timestamp.toString();

        // Generate signature
        final signatureString = 'folder=$folder&timestamp=$timestamp&upload_preset=$_uploadPreset${_apiSecret}';
        final bytes = utf8.encode(signatureString);
        final signature = sha1.convert(bytes).toString();
        request.fields['signature'] = signature;
      }

      // Add the image file
      if (kIsWeb) {
        // For web, read the file as bytes
        final imageBytes = await http.readBytes(Uri.parse(imageFile.path));
        final filename = imageFile.name;

        request.files.add(http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
          contentType: MediaType('image', 'jpeg'), // Adjust based on file type
        ));
      } else {
        // For mobile platforms
        final file = File(imageFile.path);
        final filename = file.path.split('/').last;

        request.files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: filename,
          contentType: MediaType('image', 'jpeg'), // Adjust based on file type
        ));
      }

      // Send the request
      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);

      // Parse the JSON response
      final Map<String, dynamic> parsedResponse = jsonDecode(responseString);

      // Check if upload was successful
      if (response.statusCode == 200) {
        // Return the secure URL of the uploaded image
        return parsedResponse['secure_url'] as String;
      } else {
        throw Exception('Failed to upload image: ${parsedResponse['error']['message']}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }
}


