import 'dart:io';

import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class AwsService {
  final String _accessKey;
  final String _secretKey;
  final String _bucketName;
  final String _region;
  final String _s3Endpoint;
  
  AwsService({
    required String accessKey,
    required String secretKey,
    required String bucketName,
    required String region,
  }) : 
    _accessKey = accessKey,
    _secretKey = secretKey,
    _bucketName = bucketName,
    _region = region,
    _s3Endpoint = 'https://$bucketName.s3.amazonaws.com';
    
  Future<String> uploadFile(File file) async {
    try {
      const uuid = Uuid();
      final fileExtension = path.extension(file.path);
      final fileName = '${uuid.v4()}$fileExtension';

      final result = await AwsS3.uploadFile(
        accessKey: _accessKey,
        secretKey: _secretKey,
        file: file,
        bucket: _bucketName,
        region: _region,
        filename: fileName,
        contentType: _getContentType(fileExtension),
      );

      print('Upload result: $result');


      return '$_s3Endpoint/$fileName';
    } catch (e) {
      print('Error uploading file to S3: $e');
      throw Exception('Failed to upload file to AWS S3');

    }
  }
  
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
